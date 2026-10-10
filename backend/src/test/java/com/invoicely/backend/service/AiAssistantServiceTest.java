package com.invoicely.backend.service;

import com.invoicely.backend.model.Role;
import com.invoicely.backend.model.UserStatus;
import com.invoicely.backend.repository.ClientRepository;
import com.invoicely.backend.repository.ExpenseRepository;
import com.invoicely.backend.repository.InvoiceRepository;
import com.invoicely.backend.repository.PendingAiCommandRepository;
import com.invoicely.backend.repository.CompanyKnowledgeStore;
import com.invoicely.backend.security.UserPrincipal;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.web.client.RestClient;
import org.springframework.web.server.ResponseStatusException;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verifyNoInteractions;

class AiAssistantServiceTest {

    private final InvoiceRepository invoiceRepository = mock(InvoiceRepository.class);
    private final ExpenseRepository expenseRepository = mock(ExpenseRepository.class);
    private final ClientRepository clientRepository = mock(ClientRepository.class);
    private final PendingAiCommandRepository pendingRepository = mock(PendingAiCommandRepository.class);
    private final InvoiceService invoiceService = mock(InvoiceService.class);
    private final ExpenseService expenseService = mock(ExpenseService.class);
    private final ClientService clientService = mock(ClientService.class);
    private final CompanyKnowledgeService knowledgeService = mock(CompanyKnowledgeService.class);

    @Test
    void rejectsGlobalDeveloperDataAccess() {
        AiAssistantService service = service("configured-key");
        UserPrincipal developer = principal(Role.DEVELOPER, 1L, "INVOICES,EXPENSES,CLIENTS,REPORTS");

        ResponseStatusException exception = assertThrows(ResponseStatusException.class,
                () -> service.answer("Show my invoices", developer));

        assertEquals(HttpStatus.FORBIDDEN, exception.getStatusCode());
        verifyNoInteractions(invoiceRepository, expenseRepository, clientRepository);
    }

    @Test
    void rejectsUsersWithoutDataPermissions() {
        AiAssistantService service = service("configured-key");
        UserPrincipal user = principal(Role.EMPLOYEE, 42L, "");

        ResponseStatusException exception = assertThrows(ResponseStatusException.class,
                () -> service.answer("Show my invoices", user));

        assertEquals(HttpStatus.FORBIDDEN, exception.getStatusCode());
        verifyNoInteractions(invoiceRepository, expenseRepository, clientRepository);
    }

    @Test
    void reportsMissingProviderConfigurationExplicitly() {
        AiAssistantService service = service("");
        UserPrincipal user = principal(Role.ADMIN, 42L, "REPORTS");

        ResponseStatusException exception = assertThrows(ResponseStatusException.class,
                () -> service.answer("Show my report", user));

        assertEquals(HttpStatus.SERVICE_UNAVAILABLE, exception.getStatusCode());
        verifyNoInteractions(invoiceRepository, expenseRepository, clientRepository);
    }

    @Test
    void refusesToConfirmACommandThatDoesNotBelongToTheCurrentUserAndCompany() {
        AiAssistantService service = service("configured-key");

        ResponseStatusException exception = assertThrows(ResponseStatusException.class,
                () -> service.confirm("another-users-command", principal(Role.ADMIN, 42L, "INVOICES")));

        assertEquals(HttpStatus.NOT_FOUND, exception.getStatusCode());
    }

    @Test
    void knowledgeRetrievalFailureFallsBackGracefully() {
        org.mockito.Mockito.when(knowledgeService.retrieve(org.mockito.ArgumentMatchers.anyLong(), org.mockito.ArgumentMatchers.anyString()))
                .thenThrow(new RuntimeException("Embedding service offline"));
        AiAssistantService service = service("configured-key");
        UserPrincipal user = principal(Role.ADMIN, 42L, "INVOICES,EXPENSES,CLIENTS");

        // Will attempt to call Gemini model with empty knowledge fallback
        // It should NOT throw from knowledgeService.retrieve
        assertThrows(ResponseStatusException.class, () -> service.answer("Summarize my business", user));
    }

    private AiAssistantService service(String apiKey) {
        return new AiAssistantService(invoiceRepository, expenseRepository, clientRepository,
                pendingRepository, invoiceService, expenseService, clientService,
                knowledgeService, RestClient.builder(), new ObjectMapper(), apiKey, "gemini-2.0-flash");
    }

    private UserPrincipal principal(Role role, Long companyId, String permissions) {
        return new UserPrincipal(7L, "Test User", "test@example.com", "", role,
                UserStatus.ACTIVE, companyId, permissions);
    }
}
