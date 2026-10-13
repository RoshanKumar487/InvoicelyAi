package com.invoicely.backend.controller;

import com.invoicely.backend.dto.ApiResponse;
import com.invoicely.backend.model.InvoiceTemplate;
import com.invoicely.backend.model.Role;
import com.invoicely.backend.security.UserPrincipal;
import com.invoicely.backend.service.InvoiceTemplateService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/templates")
@Tag(name = "Invoice Template Studio", description = "Endpoints for creating, managing, and publishing custom invoice templates (Multi-tenant)")
public class InvoiceTemplateController {

    private final InvoiceTemplateService templateService;

    @Autowired
    public InvoiceTemplateController(InvoiceTemplateService templateService) {
        this.templateService = templateService;
    }

    @GetMapping
    @Operation(summary = "Get all invoice templates for authenticated company")
    public ResponseEntity<ApiResponse<List<InvoiceTemplate>>> getTemplates(
            @AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = resolveCompanyId(principal);
        List<InvoiceTemplate> templates = templateService.getTemplates(companyId);
        return ResponseEntity.ok(ApiResponse.ok(templates));
    }

    @GetMapping("/active")
    @Operation(summary = "Get the active or default published invoice template")
    public ResponseEntity<ApiResponse<InvoiceTemplate>> getActiveTemplate(
            @AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = resolveCompanyId(principal);
        InvoiceTemplate template = templateService.getActiveOrDefaultTemplate(companyId);
        return ResponseEntity.ok(ApiResponse.ok(template));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get invoice template by ID")
    public ResponseEntity<ApiResponse<InvoiceTemplate>> getTemplateById(
            @PathVariable Long id,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = resolveCompanyId(principal);
        InvoiceTemplate template = templateService.getTemplateById(id, companyId);
        return ResponseEntity.ok(ApiResponse.ok(template));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'DEVELOPER')")
    @Operation(summary = "Save or create an invoice template draft")
    public ResponseEntity<ApiResponse<InvoiceTemplate>> saveDraft(
            @RequestBody InvoiceTemplate draft,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = resolveCompanyId(principal);
        Long userId = principal != null ? principal.getId() : null;
        InvoiceTemplate saved = templateService.saveDraft(draft, companyId, userId);
        return new ResponseEntity<>(ApiResponse.ok("Template draft saved successfully", saved), HttpStatus.CREATED);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'DEVELOPER')")
    @Operation(summary = "Update an existing invoice template draft")
    public ResponseEntity<ApiResponse<InvoiceTemplate>> updateDraft(
            @PathVariable Long id,
            @RequestBody InvoiceTemplate draft,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = resolveCompanyId(principal);
        Long userId = principal != null ? principal.getId() : null;
        draft.setId(id);
        InvoiceTemplate saved = templateService.saveDraft(draft, companyId, userId);
        return ResponseEntity.ok(ApiResponse.ok("Template updated successfully", saved));
    }

    @PostMapping("/{id}/publish")
    @PreAuthorize("hasAnyRole('ADMIN', 'DEVELOPER')")
    @Operation(summary = "Publish an invoice template to make it the default for new invoices")
    public ResponseEntity<ApiResponse<InvoiceTemplate>> publishTemplate(
            @PathVariable Long id,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = resolveCompanyId(principal);
        Long userId = principal != null ? principal.getId() : null;
        InvoiceTemplate published = templateService.publishTemplate(id, companyId, userId);
        return ResponseEntity.ok(ApiResponse.ok("Template published successfully as default", published));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'DEVELOPER')")
    @Operation(summary = "Delete an invoice template")
    public ResponseEntity<ApiResponse<Void>> deleteTemplate(
            @PathVariable Long id,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = resolveCompanyId(principal);
        templateService.deleteTemplate(id, companyId);
        return ResponseEntity.ok(ApiResponse.ok("Template deleted successfully", null));
    }

    private Long resolveCompanyId(UserPrincipal principal) {
        if (principal == null) return null;
        if (principal.getRole() == Role.DEVELOPER) return null;
        return principal.getCompanyId();
    }
}
