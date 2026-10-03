package com.invoicely.backend.controller;

import com.invoicely.backend.dto.ApiResponse;
import com.invoicely.backend.dto.DashboardStatsResponse;
import com.invoicely.backend.model.Role;
import com.invoicely.backend.repository.ClientRepository;
import com.invoicely.backend.repository.ExpenseRepository;
import com.invoicely.backend.repository.InvoiceRepository;
import com.invoicely.backend.security.UserPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;

@RestController
@RequestMapping("/api/v1/dashboard")
@Tag(name = "Dashboard", description = "Aggregated analytics and financial summary (Role-Scoped)")
public class DashboardController {

    private final InvoiceRepository invoiceRepository;
    private final ExpenseRepository expenseRepository;
    private final ClientRepository clientRepository;

    @Autowired
    public DashboardController(InvoiceRepository invoiceRepository,
                               ExpenseRepository expenseRepository,
                               ClientRepository clientRepository) {
        this.invoiceRepository = invoiceRepository;
        this.expenseRepository = expenseRepository;
        this.clientRepository = clientRepository;
    }

    @GetMapping("/stats")
    @Operation(summary = "Get aggregated dashboard statistics (revenue, overdue, total expenses, clients) scoped to company")
    public ResponseEntity<ApiResponse<DashboardStatsResponse>> getDashboardStats(@AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = (principal != null && principal.getRole() != Role.DEVELOPER) ? principal.getCompanyId() : null;
        DashboardStatsResponse stats = new DashboardStatsResponse();

        if (companyId != null) {
            stats.setTotalInvoices(invoiceRepository.countByCompanyId(companyId));
            stats.setPaidInvoices(invoiceRepository.countByCompanyIdAndStatusIgnoreCase(companyId, "Paid"));
            stats.setOverdueInvoices(invoiceRepository.countByCompanyIdAndStatusIgnoreCase(companyId, "Overdue"));
            stats.setDraftInvoices(invoiceRepository.countByCompanyIdAndStatusIgnoreCase(companyId, "Draft"));
            stats.setTotalClients(clientRepository.countByCompanyId(companyId));

            BigDecimal revenue = invoiceRepository.sumTotalRevenueByCompanyId(companyId);
            stats.setTotalRevenue(revenue != null ? revenue : BigDecimal.ZERO);

            BigDecimal expenses = expenseRepository.sumTotalExpensesByCompanyId(companyId);
            stats.setTotalExpenses(expenses != null ? expenses : BigDecimal.ZERO);
        } else {
            stats.setTotalInvoices(invoiceRepository.count());
            stats.setPaidInvoices(invoiceRepository.countByStatusIgnoreCase("Paid"));
            stats.setOverdueInvoices(invoiceRepository.countByStatusIgnoreCase("Overdue"));
            stats.setDraftInvoices(invoiceRepository.countByStatusIgnoreCase("Draft"));
            stats.setTotalClients(clientRepository.count());

            BigDecimal revenue = invoiceRepository.sumTotalRevenue();
            stats.setTotalRevenue(revenue != null ? revenue : BigDecimal.ZERO);

            BigDecimal expenses = expenseRepository.sumTotalExpenses();
            stats.setTotalExpenses(expenses != null ? expenses : BigDecimal.ZERO);
        }

        // Outstanding balance approximation: total revenue - amount paid, or zero
        stats.setOutstandingAmount(BigDecimal.ZERO);

        return ResponseEntity.ok(ApiResponse.ok(stats));
    }
}
