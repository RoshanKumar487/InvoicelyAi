package com.invoicely.backend.controller;

import com.invoicely.backend.dto.ApiResponse;
import com.invoicely.backend.dto.NotificationTemplateDto;
import com.invoicely.backend.dto.SaveNotificationTemplateRequest;
import com.invoicely.backend.dto.TemplatePreviewRequest;
import com.invoicely.backend.dto.TemplatePreviewResponse;
import com.invoicely.backend.model.NotificationChannel;
import com.invoicely.backend.model.NotificationTemplate;
import com.invoicely.backend.model.Role;
import com.invoicely.backend.security.UserPrincipal;
import com.invoicely.backend.service.NotificationTemplateService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/notification-templates")
@Tag(name = "Notification & Email Templates", description = "Email and WhatsApp template management, customization from Settings, and live previews")
public class NotificationTemplateController {

    private final NotificationTemplateService templateService;

    public NotificationTemplateController(NotificationTemplateService templateService) {
        this.templateService = templateService;
    }

    @GetMapping
    @Operation(summary = "Get all email and WhatsApp templates available for current company (with seeded defaults)")
    public ResponseEntity<ApiResponse<List<NotificationTemplateDto>>> getTemplates(
            @RequestParam(required = false) Long companyId,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long resolvedCompanyId = resolveCompanyId(principal, companyId);
        List<NotificationTemplateDto> templates = templateService.getTemplatesForCompany(resolvedCompanyId);
        return ResponseEntity.ok(ApiResponse.ok(templates));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get a specific notification template by ID")
    public ResponseEntity<ApiResponse<NotificationTemplateDto>> getTemplateById(
            @PathVariable Long id,
            @RequestParam(required = false) Long companyId,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long resolvedCompanyId = resolveCompanyId(principal, companyId);
        return ResponseEntity.ok(ApiResponse.ok(templateService.getTemplateById(id, resolvedCompanyId)));
    }

    @GetMapping("/by-name/{templateName}")
    @Operation(summary = "Get effective template by name (e.g. PAYMENT_REMINDER, COMPANY_INVITE)")
    public ResponseEntity<ApiResponse<NotificationTemplateDto>> getTemplateByName(
            @PathVariable String templateName,
            @RequestParam(required = false) NotificationChannel channel,
            @RequestParam(required = false) Long companyId,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long resolvedCompanyId = resolveCompanyId(principal, companyId);
        NotificationTemplate template = templateService.getEffectiveTemplate(resolvedCompanyId, templateName, channel);
        return ResponseEntity.ok(ApiResponse.ok(NotificationTemplateDto.fromEntity(template)));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'DEVELOPER')")
    @Operation(summary = "Save or customize an email / WhatsApp template from Settings")
    public ResponseEntity<ApiResponse<NotificationTemplateDto>> saveTemplate(
            @Valid @RequestBody SaveNotificationTemplateRequest request,
            @RequestParam(required = false) Long companyId,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long resolvedCompanyId = resolveCompanyId(principal, companyId);
        NotificationTemplateDto saved = templateService.saveOrUpdateTemplate(resolvedCompanyId, request, principal);
        return new ResponseEntity<>(ApiResponse.ok("Template saved successfully", saved), HttpStatus.CREATED);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'DEVELOPER')")
    @Operation(summary = "Update an existing email / WhatsApp template by ID")
    public ResponseEntity<ApiResponse<NotificationTemplateDto>> updateTemplate(
            @PathVariable Long id,
            @Valid @RequestBody SaveNotificationTemplateRequest request,
            @RequestParam(required = false) Long companyId,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long resolvedCompanyId = resolveCompanyId(principal, companyId);
        NotificationTemplateDto updated = templateService.updateTemplateById(id, resolvedCompanyId, request, principal);
        return ResponseEntity.ok(ApiResponse.ok("Template updated successfully", updated));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'DEVELOPER')")
    @Operation(summary = "Reset or delete custom company template (reverting to system default)")
    public ResponseEntity<ApiResponse<Void>> deleteTemplate(
            @PathVariable Long id,
            @RequestParam(required = false) Long companyId,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long resolvedCompanyId = resolveCompanyId(principal, companyId);
        templateService.deleteOrResetTemplate(id, resolvedCompanyId);
        return ResponseEntity.ok(ApiResponse.ok("Template reset to system default", null));
    }

    @PostMapping("/preview")
    @Operation(summary = "Preview rendered template subject and body with live invoice data or realistic samples")
    public ResponseEntity<ApiResponse<TemplatePreviewResponse>> previewTemplate(
            @RequestBody TemplatePreviewRequest request,
            @RequestParam(required = false) Long companyId,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long resolvedCompanyId = resolveCompanyId(principal, companyId);
        TemplatePreviewResponse response = templateService.previewTemplate(resolvedCompanyId, request);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    private Long resolveCompanyId(UserPrincipal principal, Long requestedCompanyId) {
        if (principal == null) return requestedCompanyId;
        if (principal.getRole() == Role.DEVELOPER) return requestedCompanyId != null ? requestedCompanyId : principal.getCompanyId();
        return principal.getCompanyId();
    }
}
