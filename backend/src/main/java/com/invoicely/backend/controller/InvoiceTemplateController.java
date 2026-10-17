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

    @GetMapping("/settings")
    @Operation(summary = "Get or initialize customized template settings and section booleans for the user's organization")
    public ResponseEntity<ApiResponse<InvoiceTemplate>> getTemplateSettings(
            @RequestParam(required = false) String orgCode,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = resolveCompanyId(principal);
        InvoiceTemplate settings = templateService.getOrCreateSettings(companyId, orgCode, principal);
        return ResponseEntity.ok(ApiResponse.ok("Template settings loaded", settings));
    }

    @PutMapping("/settings")
    @Operation(summary = "Create or update customized template settings and section boolean flags for the user's organization")
    public ResponseEntity<ApiResponse<InvoiceTemplate>> updateTemplateSettings(
            @RequestBody java.util.Map<String, Object> payload,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = resolveCompanyId(principal);
        InvoiceTemplate saved = templateService.upsertSettings(payload, companyId, principal);
        return ResponseEntity.ok(ApiResponse.ok("Template settings updated successfully", saved));
    }

    @PostMapping("/settings")
    @Operation(summary = "Create or update customized template settings and section boolean flags for the user's organization")
    public ResponseEntity<ApiResponse<InvoiceTemplate>> saveTemplateSettingsPost(
            @RequestBody java.util.Map<String, Object> payload,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = resolveCompanyId(principal);
        InvoiceTemplate saved = templateService.upsertSettings(payload, companyId, principal);
        return ResponseEntity.ok(ApiResponse.ok("Template settings saved successfully", saved));
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
    @Operation(summary = "Save or create an invoice template draft")
    public ResponseEntity<ApiResponse<InvoiceTemplate>> saveDraft(
            @RequestBody java.util.Map<String, Object> payload,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = resolveCompanyId(principal);
        InvoiceTemplate saved = templateService.upsertSettings(payload, companyId, principal);
        return new ResponseEntity<>(ApiResponse.ok("Template draft saved successfully", saved), HttpStatus.CREATED);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update an existing invoice template draft")
    public ResponseEntity<ApiResponse<InvoiceTemplate>> updateDraft(
            @PathVariable Long id,
            @RequestBody java.util.Map<String, Object> payload,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = resolveCompanyId(principal);
        payload.put("id", id);
        InvoiceTemplate saved = templateService.upsertSettings(payload, companyId, principal);
        return ResponseEntity.ok(ApiResponse.ok("Template updated successfully", saved));
    }

    @PostMapping("/{id}/publish")
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
        if (principal == null) return 1L;
        if (principal.getCompanyId() != null) return principal.getCompanyId();
        return 1L;
    }
}
