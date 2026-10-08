package com.invoicely.backend.controller;

import com.invoicely.backend.dto.ApiResponse;
import com.invoicely.backend.model.Client;
import com.invoicely.backend.model.Role;
import com.invoicely.backend.security.UserPrincipal;
import com.invoicely.backend.service.ClientService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/clients")
@Tag(name = "Clients", description = "Client relationship management endpoints (Multi-tenant & Role-Scoped)")
public class ClientController {

    private final ClientService clientService;

    @Autowired
    public ClientController(ClientService clientService) {
        this.clientService = clientService;
    }

    @GetMapping
    @Operation(summary = "Get all clients or filter by search query (Scoped to company or global for Developer)")
    public ResponseEntity<ApiResponse<List<Client>>> getAllClients(
            @RequestParam(required = false) String search,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = resolveCompanyId(principal);
        List<Client> clients = clientService.getClients(companyId, search);
        return ResponseEntity.ok(ApiResponse.ok(clients));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get client by ID")
    public ResponseEntity<ApiResponse<Client>> getClientById(
            @PathVariable Long id,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = resolveCompanyId(principal);
        return ResponseEntity.ok(ApiResponse.ok(clientService.getClientById(id, companyId)));
    }

    @PostMapping
    @Operation(summary = "Create a new client")
    public ResponseEntity<ApiResponse<Client>> createClient(
            @RequestBody Client client,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = resolveCompanyId(principal);
        Client created = clientService.createClient(client, companyId);
        return new ResponseEntity<>(ApiResponse.ok("Client created successfully", created), HttpStatus.CREATED);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update an existing client")
    public ResponseEntity<ApiResponse<Client>> updateClient(
            @PathVariable Long id,
            @RequestBody Client client,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = resolveCompanyId(principal);
        Client updated = clientService.updateClient(id, client, companyId);
        return ResponseEntity.ok(ApiResponse.ok("Client updated successfully", updated));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete client by ID")
    public ResponseEntity<ApiResponse<Void>> deleteClient(
            @PathVariable Long id,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = resolveCompanyId(principal);
        clientService.deleteClient(id, companyId);
        return ResponseEntity.ok(ApiResponse.ok("Client deleted successfully", null));
    }

    private Long resolveCompanyId(UserPrincipal principal) {
        if (principal == null) return null;
        if (principal.getRole() == Role.DEVELOPER) return null;
        return principal.getCompanyId();
    }
}
