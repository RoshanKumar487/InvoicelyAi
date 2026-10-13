package com.invoicely.backend.controller;

import com.invoicely.backend.dto.ApiResponse;
import com.invoicely.backend.dto.PayrollSummaryKpiDto;
import com.invoicely.backend.model.PayrollEntry;
import com.invoicely.backend.model.PayrollRun;
import com.invoicely.backend.model.Role;
import com.invoicely.backend.security.UserPrincipal;
import com.invoicely.backend.service.PayrollService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/payroll")
@Tag(name = "Payroll Engine", description = "Batch payroll runs, employee salary lines, statutory calculations, and payment tracking")
public class PayrollController {

    private final PayrollService payrollService;

    public PayrollController(PayrollService payrollService) {
        this.payrollService = payrollService;
    }

    @GetMapping("/runs")
    @Operation(summary = "List historical and active payroll runs")
    public ResponseEntity<ApiResponse<List<PayrollRun>>> getRuns(
            @RequestParam(required = false) Long companyId,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long resolvedCompanyId = resolveCompanyId(principal, companyId);
        List<PayrollRun> runs = payrollService.listRuns(resolvedCompanyId);
        return ResponseEntity.ok(ApiResponse.ok(runs));
    }

    @GetMapping("/runs/{id}")
    @Operation(summary = "Get specific payroll run by ID")
    public ResponseEntity<ApiResponse<PayrollRun>> getRun(
            @PathVariable Long id,
            @RequestParam(required = false) Long companyId,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long resolvedCompanyId = resolveCompanyId(principal, companyId);
        PayrollRun run = payrollService.getRun(id, resolvedCompanyId);
        return ResponseEntity.ok(ApiResponse.ok(run));
    }

    @PostMapping("/runs/generate")
    @PreAuthorize("hasAnyRole('ADMIN', 'DEVELOPER')")
    @Operation(summary = "Generate/recalculate a batch payroll run for a month/year")
    public ResponseEntity<ApiResponse<PayrollRun>> generateRun(
            @RequestParam int month,
            @RequestParam int year,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate scheduledPayDate,
            @RequestParam(required = false) String title,
            @RequestParam(required = false) Long companyId,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long resolvedCompanyId = resolveCompanyId(principal, companyId);
        PayrollRun run = payrollService.generatePayrollRun(resolvedCompanyId, month, year, scheduledPayDate, title);
        return new ResponseEntity<>(ApiResponse.ok("Payroll calculated successfully", run), HttpStatus.CREATED);
    }

    @GetMapping("/entries")
    @Operation(summary = "List employee payroll lines for grid table with filter and search")
    public ResponseEntity<ApiResponse<List<PayrollEntry>>> getEntries(
            @RequestParam(required = false) Long runId,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Long companyId,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long resolvedCompanyId = resolveCompanyId(principal, companyId);
        List<PayrollEntry> entries = payrollService.listEntries(resolvedCompanyId, runId, status, search);
        return ResponseEntity.ok(ApiResponse.ok(entries));
    }

    @GetMapping("/kpis")
    @Operation(summary = "Get 4 KPI summary cards (Total Gross, Paid, Pending, Overdue)")
    public ResponseEntity<ApiResponse<PayrollSummaryKpiDto>> getKpis(
            @RequestParam(required = false) Long runId,
            @RequestParam(required = false) Long companyId,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long resolvedCompanyId = resolveCompanyId(principal, companyId);
        PayrollSummaryKpiDto kpi = payrollService.getPayrollKpis(resolvedCompanyId, runId);
        return ResponseEntity.ok(ApiResponse.ok(kpi));
    }

    @PutMapping("/entries/{id}/status")
    @PreAuthorize("hasAnyRole('ADMIN', 'DEVELOPER')")
    @Operation(summary = "Update employee payroll line status (PAID, PENDING, ON_HOLD)")
    public ResponseEntity<ApiResponse<PayrollEntry>> updateEntryStatus(
            @PathVariable Long id,
            @RequestBody Map<String, String> body,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long resolvedCompanyId = resolveCompanyId(principal, null);
        String status = body.getOrDefault("status", "PAID");
        PayrollEntry updated = payrollService.updateEntryStatus(id, status, resolvedCompanyId);
        return ResponseEntity.ok(ApiResponse.ok("Salary status updated", updated));
    }

    @PostMapping("/entries/batch-status")
    @PreAuthorize("hasAnyRole('ADMIN', 'DEVELOPER')")
    @Operation(summary = "Bulk update selected employee payroll entries via checkboxes")
    public ResponseEntity<ApiResponse<List<PayrollEntry>>> batchUpdateStatus(
            @RequestBody Map<String, Object> body,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long resolvedCompanyId = resolveCompanyId(principal, null);
        @SuppressWarnings("unchecked")
        List<Object> rawIds = (List<Object>) body.get("ids");
        String status = (String) body.getOrDefault("status", "PAID");

        List<Long> ids = rawIds.stream()
                .map(obj -> Long.valueOf(obj.toString()))
                .toList();

        List<PayrollEntry> updated = payrollService.batchUpdateStatus(ids, status, resolvedCompanyId);
        return ResponseEntity.ok(ApiResponse.ok("Updated " + updated.size() + " payroll records", updated));
    }

    private Long resolveCompanyId(UserPrincipal principal, Long requestedCompanyId) {
        if (principal == null) return requestedCompanyId;
        if (principal.getRole() == Role.DEVELOPER) return requestedCompanyId != null ? requestedCompanyId : principal.getCompanyId();
        return principal.getCompanyId() != null ? principal.getCompanyId() : requestedCompanyId;
    }
}
