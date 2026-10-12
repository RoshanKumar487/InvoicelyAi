package com.invoicely.backend.controller;

import com.invoicely.backend.dto.ApiResponse;
import com.invoicely.backend.model.CompanyAuditLog;
import com.invoicely.backend.model.Role;
import com.invoicely.backend.security.UserPrincipal;
import com.invoicely.backend.service.AuditLogService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/audit-logs")
@Tag(name = "Audit Logs", description = "Track and audit user actions across invoices, expenses, clients, workforce and security settings")
public class AuditLogController {

    private final AuditLogService auditLogService;

    @Autowired
    public AuditLogController(AuditLogService auditLogService) {
        this.auditLogService = auditLogService;
    }

    @GetMapping
    @Operation(summary = "Get audit logs (Admins see all company activity; Staff sees only their own activity)")
    public ResponseEntity<ApiResponse<List<CompanyAuditLog>>> getAuditLogs(
            @RequestParam(required = false) String module,
            @RequestParam(required = false) String action,
            @RequestParam(required = false) Long companyId,
            @RequestParam(required = false) Long userId,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long resolvedCompanyId = resolveCompanyId(principal, companyId);
        Long resolvedUserId = (principal != null && principal.getRole() == Role.EMPLOYEE)
                ? principal.getId()
                : userId;

        List<CompanyAuditLog> logs = auditLogService.getAuditLogs(resolvedCompanyId, resolvedUserId, module, action);
        return ResponseEntity.ok(ApiResponse.ok(logs));
    }

    @PostMapping
    @Operation(summary = "Record an activity audit log entry")
    public ResponseEntity<ApiResponse<CompanyAuditLog>> recordLog(
            @RequestBody CompanyAuditLog log,
            @AuthenticationPrincipal UserPrincipal principal) {
        if (principal != null) {
            if (principal.getCompanyId() != null) log.setCompanyId(principal.getCompanyId());
            if (log.getUserId() == null) log.setUserId(principal.getId());
            if (log.getUserName() == null || log.getUserName().trim().isEmpty()) log.setUserName(principal.getFullName());
            if (log.getUserRole() == null || log.getUserRole().trim().isEmpty()) log.setUserRole(principal.getRole().name());
        }
        CompanyAuditLog saved = auditLogService.recordLog(log);
        return new ResponseEntity<>(ApiResponse.ok("Activity logged successfully", saved), HttpStatus.CREATED);
    }

    private Long resolveCompanyId(UserPrincipal principal, Long requestedCompanyId) {
        if (principal == null) return requestedCompanyId;
        if (principal.getRole() == Role.DEVELOPER) return requestedCompanyId;
        return principal.getCompanyId() != null ? principal.getCompanyId() : requestedCompanyId;
    }
}
