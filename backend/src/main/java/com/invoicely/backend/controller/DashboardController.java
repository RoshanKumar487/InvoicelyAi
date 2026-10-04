package com.invoicely.backend.controller;

import com.invoicely.backend.dto.ApiResponse;
import com.invoicely.backend.dto.DashboardStatsResponse;
import com.invoicely.backend.dto.DeveloperOverviewDto;
import com.invoicely.backend.model.Company;
import com.invoicely.backend.model.Role;
import com.invoicely.backend.repository.ClientRepository;
import com.invoicely.backend.repository.CompanyRepository;
import com.invoicely.backend.repository.ExpenseRepository;
import com.invoicely.backend.repository.InvoiceRepository;
import com.invoicely.backend.repository.UserRepository;
import com.invoicely.backend.security.UserPrincipal;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/api/v1/dashboard")
@Tag(name = "Dashboard", description = "Aggregated analytics and financial summary (Role-Scoped)")
public class DashboardController {

    private final InvoiceRepository invoiceRepository;
    private final ExpenseRepository expenseRepository;
    private final ClientRepository clientRepository;
    private final CompanyRepository companyRepository;
    private final UserRepository userRepository;

    @Autowired
    public DashboardController(InvoiceRepository invoiceRepository,
                               ExpenseRepository expenseRepository,
                               ClientRepository clientRepository,
                               CompanyRepository companyRepository,
                               UserRepository userRepository) {
        this.invoiceRepository = invoiceRepository;
        this.expenseRepository = expenseRepository;
        this.clientRepository = clientRepository;
        this.companyRepository = companyRepository;
        this.userRepository = userRepository;
    }

    @GetMapping("/stats")
    @Operation(summary = "Get aggregated dashboard statistics (revenue, overdue, total expenses, clients) scoped to role")
    public ResponseEntity<ApiResponse<DashboardStatsResponse>> getDashboardStats(
            @RequestParam(required = false) Long companyId,
            @AuthenticationPrincipal UserPrincipal principal) {
        DashboardStatsResponse stats = new DashboardStatsResponse();

        if (principal != null && principal.getRole() == Role.EMPLOYEE) {
            // Staff sees only what they created within their company
            Long userCompanyId = principal.getCompanyId();
            Long userId = principal.getId();

            if (userCompanyId != null) {
                stats.setTotalInvoices(invoiceRepository.countByCompanyIdAndCreatedByUserId(userCompanyId, userId));
                stats.setPaidInvoices(invoiceRepository.countByCompanyIdAndCreatedByUserIdAndStatusIgnoreCase(userCompanyId, userId, "Paid"));
                stats.setOverdueInvoices(invoiceRepository.countByCompanyIdAndCreatedByUserIdAndStatusIgnoreCase(userCompanyId, userId, "Overdue"));
                stats.setDraftInvoices(invoiceRepository.countByCompanyIdAndCreatedByUserIdAndStatusIgnoreCase(userCompanyId, userId, "Draft"));
                stats.setTotalClients(clientRepository.countByCompanyId(userCompanyId));

                BigDecimal revenue = invoiceRepository.sumTotalRevenueByCompanyIdAndCreatedByUserId(userCompanyId, userId);
                stats.setTotalRevenue(revenue != null ? revenue : BigDecimal.ZERO);

                BigDecimal expenses = expenseRepository.sumTotalExpensesByCompanyIdAndCreatedByUserId(userCompanyId, userId);
                stats.setTotalExpenses(expenses != null ? expenses : BigDecimal.ZERO);
            }
        } else {
            // Admin of company OR Developer (filtered by companyId or global)
            Long resolvedCompanyId = (principal != null && principal.getRole() == Role.ADMIN)
                    ? principal.getCompanyId()
                    : companyId;

            if (resolvedCompanyId != null) {
                stats.setTotalInvoices(invoiceRepository.countByCompanyId(resolvedCompanyId));
                stats.setPaidInvoices(invoiceRepository.countByCompanyIdAndStatusIgnoreCase(resolvedCompanyId, "Paid"));
                stats.setOverdueInvoices(invoiceRepository.countByCompanyIdAndStatusIgnoreCase(resolvedCompanyId, "Overdue"));
                stats.setDraftInvoices(invoiceRepository.countByCompanyIdAndStatusIgnoreCase(resolvedCompanyId, "Draft"));
                stats.setTotalClients(clientRepository.countByCompanyId(resolvedCompanyId));

                BigDecimal revenue = invoiceRepository.sumTotalRevenueByCompanyId(resolvedCompanyId);
                stats.setTotalRevenue(revenue != null ? revenue : BigDecimal.ZERO);

                BigDecimal expenses = expenseRepository.sumTotalExpensesByCompanyId(resolvedCompanyId);
                stats.setTotalExpenses(expenses != null ? expenses : BigDecimal.ZERO);
            } else {
                // Global platform totals
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
        }

        stats.setOutstandingAmount(BigDecimal.ZERO);
        return ResponseEntity.ok(ApiResponse.ok(stats));
    }

    @GetMapping("/developer-overview")
    @Operation(summary = "Get global multi-company platform overview and company breakdown (Developer only)")
    public ResponseEntity<ApiResponse<DeveloperOverviewDto>> getDeveloperOverview(@AuthenticationPrincipal UserPrincipal principal) {
        if (principal == null || principal.getRole() != Role.DEVELOPER) {
            throw new AccessDeniedException("Only platform DEVELOPERs can view global multi-company analytics.");
        }

        DeveloperOverviewDto overview = new DeveloperOverviewDto();
        overview.setTotalCompanies(companyRepository.count());
        overview.setTotalUsers(userRepository.count());
        overview.setTotalInvoices(invoiceRepository.count());
        overview.setTotalExpenses(expenseRepository.count());

        BigDecimal totalRev = invoiceRepository.sumTotalRevenue();
        overview.setTotalPlatformRevenue(totalRev != null ? totalRev : BigDecimal.ZERO);

        BigDecimal totalExp = expenseRepository.sumTotalExpenses();
        overview.setTotalPlatformExpenses(totalExp != null ? totalExp : BigDecimal.ZERO);

        List<Company> allCompanies = companyRepository.findAll();
        List<DeveloperOverviewDto.CompanyPlatformStatsDto> companyStatsList = new ArrayList<>();

        for (Company c : allCompanies) {
            DeveloperOverviewDto.CompanyPlatformStatsDto dto = new DeveloperOverviewDto.CompanyPlatformStatsDto();
            dto.setCompanyId(c.getId());
            dto.setCompanyCode(c.getCompanyCode());
            dto.setCompanyName(c.getCompanyName());
            dto.setEmail(c.getEmail());
            dto.setLocation(c.getLocation());
            dto.setUserCount(userRepository.findByCompanyId(c.getId()).size());
            dto.setInvoiceCount(invoiceRepository.countByCompanyId(c.getId()));
            dto.setExpenseCount(expenseRepository.countByCompanyId(c.getId()));

            BigDecimal cRev = invoiceRepository.sumTotalRevenueByCompanyId(c.getId());
            dto.setTotalRevenue(cRev != null ? cRev : BigDecimal.ZERO);

            BigDecimal cExp = expenseRepository.sumTotalExpensesByCompanyId(c.getId());
            dto.setTotalExpenses(cExp != null ? cExp : BigDecimal.ZERO);

            companyStatsList.add(dto);
        }

        overview.setCompanies(companyStatsList);
        return ResponseEntity.ok(ApiResponse.ok(overview));
    }
}
