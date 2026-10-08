package com.invoicely.backend.controller;

import com.invoicely.backend.dto.ApiResponse;
import com.invoicely.backend.model.Invoice;
import com.invoicely.backend.model.Role;
import com.invoicely.backend.security.UserPrincipal;
import com.invoicely.backend.service.InvoiceService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/invoices")
@Tag(name = "Invoices", description = "Invoice creation, status tracking, calculations, and updates")
public class InvoiceController {

    private final InvoiceService invoiceService;

    @Autowired
    public InvoiceController(InvoiceService invoiceService) {
        this.invoiceService = invoiceService;
    }

    @GetMapping
    @Operation(summary = "Get all invoices with optional status or client filter (Scoped to staff for Employee, company for Admin, global/filtered for Developer)")
    public ResponseEntity<ApiResponse<List<Invoice>>> getAllInvoices(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) Long clientId,
            @RequestParam(required = false) Long companyId,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long resolvedCompanyId = resolveCompanyId(principal, companyId);
        Long createdByUserId = (principal != null && principal.getRole() == Role.EMPLOYEE) ? principal.getId() : null;
        List<Invoice> invoices = invoiceService.getInvoices(resolvedCompanyId, createdByUserId, status, clientId);
        return ResponseEntity.ok(ApiResponse.ok(invoices));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get invoice by database ID")
    public ResponseEntity<ApiResponse<Invoice>> getInvoiceById(
            @PathVariable Long id,
            @RequestParam(required = false) Long companyId,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long resolvedCompanyId = resolveCompanyId(principal, companyId);
        Long createdByUserId = (principal != null && principal.getRole() == Role.EMPLOYEE) ? principal.getId() : null;
        return ResponseEntity.ok(ApiResponse.ok(invoiceService.getInvoiceById(id, resolvedCompanyId, createdByUserId)));
    }

    @GetMapping("/by-number/{invoiceNumber}")
    @Operation(summary = "Get invoice by invoice number (e.g. INV-2026-001)")
    public ResponseEntity<ApiResponse<Invoice>> getInvoiceByNumber(
            @PathVariable String invoiceNumber,
            @RequestParam(required = false) Long companyId,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long resolvedCompanyId = resolveCompanyId(principal, companyId);
        return ResponseEntity.ok(ApiResponse.ok(invoiceService.getInvoiceByNumber(invoiceNumber, resolvedCompanyId)));
    }

    @PostMapping
    @Operation(summary = "Create a new invoice")
    public ResponseEntity<ApiResponse<Invoice>> createInvoice(
            @RequestBody Invoice invoice,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = (principal != null && principal.getRole() != Role.DEVELOPER) ? principal.getCompanyId() : invoice.getCompanyId();
        Long createdByUserId = (principal != null) ? principal.getId() : null;
        String createdByUserName = (principal != null) ? principal.getFullName() : "";
        Invoice created = invoiceService.createInvoice(invoice, companyId, createdByUserId, createdByUserName);
        return new ResponseEntity<>(ApiResponse.ok("Invoice created successfully", created), HttpStatus.CREATED);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update an existing invoice")
    public ResponseEntity<ApiResponse<Invoice>> updateInvoice(
            @PathVariable Long id,
            @RequestBody Invoice invoice,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = resolveCompanyId(principal, invoice.getCompanyId());
        Long createdByUserId = (principal != null && principal.getRole() == Role.EMPLOYEE) ? principal.getId() : null;
        Invoice updated = invoiceService.updateInvoice(id, invoice, companyId, createdByUserId);
        return ResponseEntity.ok(ApiResponse.ok("Invoice updated successfully", updated));
    }

    @PatchMapping("/{id}/status")
    @Operation(summary = "Update invoice status (Draft, Sent, Paid, Overdue, Cancelled)")
    public ResponseEntity<ApiResponse<Invoice>> updateStatus(
            @PathVariable Long id,
            @RequestParam String status,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = resolveCompanyId(principal, null);
        Long createdByUserId = (principal != null && principal.getRole() == Role.EMPLOYEE) ? principal.getId() : null;
        Invoice updated = invoiceService.updateStatus(id, status, companyId, createdByUserId);
        return ResponseEntity.ok(ApiResponse.ok("Invoice status updated", updated));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete invoice by ID")
    public ResponseEntity<ApiResponse<Void>> deleteInvoice(
            @PathVariable Long id,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = resolveCompanyId(principal, null);
        Long createdByUserId = (principal != null && principal.getRole() == Role.EMPLOYEE) ? principal.getId() : null;
        invoiceService.deleteInvoice(id, companyId, createdByUserId);
        return ResponseEntity.ok(ApiResponse.ok("Invoice deleted successfully", null));
    }

    private Long resolveCompanyId(UserPrincipal principal, Long requestedCompanyId) {
        if (principal == null) return requestedCompanyId;
        if (principal.getRole() == Role.DEVELOPER) return requestedCompanyId; // Developer can query globally or filter by requested company
        return principal.getCompanyId();
    }
}
