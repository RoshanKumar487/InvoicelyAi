package com.invoicely.backend.controller;

import com.invoicely.backend.dto.*;
import com.invoicely.backend.model.NotificationAuditLog;
import com.invoicely.backend.model.NotificationChannel;
import com.invoicely.backend.model.NotificationStatus;
import com.invoicely.backend.model.Role;
import com.invoicely.backend.security.UserPrincipal;
import com.invoicely.backend.service.NotificationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/notifications")
@Tag(name = "Notifications & Messaging Dispatcher", description = "Asynchronous email & WhatsApp queuing, reminders, join invites, and audit logs")
public class NotificationController {

    private final NotificationService notificationService;

    public NotificationController(NotificationService notificationService) {
        this.notificationService = notificationService;
    }

    @PostMapping("/send-reminder")
    @Operation(summary = "Queue payment reminder to client for an invoice (Email or WhatsApp)")
    public ResponseEntity<ApiResponse<UserNotificationDto>> sendReminder(
            @Valid @RequestBody SendReminderRequest request,
            @AuthenticationPrincipal UserPrincipal principal) {
        UserNotificationDto queued = notificationService.queueInvoiceReminder(request, principal);
        return new ResponseEntity<>(ApiResponse.ok("Payment reminder queued for asynchronous delivery", queued), HttpStatus.ACCEPTED);
    }

    @PostMapping("/send-invite")
    @PreAuthorize("hasAnyRole('ADMIN', 'DEVELOPER')")
    @Operation(summary = "Admin sends invite to join company workspace (Email or WhatsApp)")
    public ResponseEntity<ApiResponse<UserNotificationDto>> sendInvite(
            @Valid @RequestBody SendInviteRequest request,
            @AuthenticationPrincipal UserPrincipal principal) {
        UserNotificationDto queued = notificationService.queueCompanyInvite(request, principal);
        return new ResponseEntity<>(ApiResponse.ok("Company invitation queued for asynchronous delivery", queued), HttpStatus.ACCEPTED);
    }

    @PostMapping("/send-join-request-response")
    @PreAuthorize("hasAnyRole('ADMIN', 'DEVELOPER')")
    @Operation(summary = "Admin pushes join request response or status update using customized best request template")
    public ResponseEntity<ApiResponse<UserNotificationDto>> sendJoinRequestResponse(
            @Valid @RequestBody SendJoinRequestNotificationRequest request,
            @AuthenticationPrincipal UserPrincipal principal) {
        UserNotificationDto queued = notificationService.queueJoinRequestNotification(request, principal);
        return new ResponseEntity<>(ApiResponse.ok("Join request response queued for delivery", queued), HttpStatus.ACCEPTED);
    }

    @PostMapping("/send-custom")
    @Operation(summary = "Send custom notification/email to client or user using template")
    public ResponseEntity<ApiResponse<UserNotificationDto>> sendCustom(
            @Valid @RequestBody SendCustomNotificationRequest request,
            @AuthenticationPrincipal UserPrincipal principal) {
        UserNotificationDto queued = notificationService.queueCustomNotification(request, principal);
        return new ResponseEntity<>(ApiResponse.ok("Custom notification queued for asynchronous delivery", queued), HttpStatus.ACCEPTED);
    }

    @GetMapping("/queue")
    @Operation(summary = "Get notification outbox / queue with status and channel filters")
    public ResponseEntity<ApiResponse<Page<UserNotificationDto>>> getQueue(
            @RequestParam(required = false) NotificationStatus status,
            @RequestParam(required = false) NotificationChannel channel,
            @RequestParam(required = false) Long companyId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long resolvedCompanyId = resolveCompanyId(principal, companyId);
        Page<UserNotificationDto> result = notificationService.getQueue(
                resolvedCompanyId,
                status,
                channel,
                PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"))
        );
        return ResponseEntity.ok(ApiResponse.ok(result));
    }

    @GetMapping("/audit-logs")
    @Operation(summary = "Get notification audit history (records sent, retry, and stuck/failed delivery logs)")
    public ResponseEntity<ApiResponse<Page<NotificationAuditLog>>> getAuditLogs(
            @RequestParam(required = false) Long notificationId,
            @RequestParam(required = false) Long companyId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long resolvedCompanyId = resolveCompanyId(principal, companyId);
        Page<NotificationAuditLog> logs = notificationService.getAuditLogs(
                resolvedCompanyId,
                notificationId,
                PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"))
        );
        return ResponseEntity.ok(ApiResponse.ok(logs));
    }

    @PostMapping("/queue/{id}/retry")
    @Operation(summary = "Retry a failed or stuck notification")
    public ResponseEntity<ApiResponse<UserNotificationDto>> retryNotification(
            @PathVariable Long id,
            @RequestParam(required = false) Long companyId,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long resolvedCompanyId = resolveCompanyId(principal, companyId);
        UserNotificationDto retried = notificationService.retryNotification(id, resolvedCompanyId);
        return ResponseEntity.ok(ApiResponse.ok("Notification reset to PENDING for scheduler pickup", retried));
    }

    @DeleteMapping("/queue/{id}")
    @Operation(summary = "Cancel a pending notification in the outbox queue")
    public ResponseEntity<ApiResponse<Void>> cancelNotification(
            @PathVariable Long id,
            @RequestParam(required = false) Long companyId,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long resolvedCompanyId = resolveCompanyId(principal, companyId);
        notificationService.cancelNotification(id, resolvedCompanyId);
        return ResponseEntity.ok(ApiResponse.ok("Notification cancelled successfully", null));
    }

    @GetMapping("/metrics")
    @Operation(summary = "Get real-time notification queue and delivery metrics")
    public ResponseEntity<ApiResponse<NotificationMetricsDto>> getMetrics(
            @RequestParam(required = false) Long companyId,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long resolvedCompanyId = resolveCompanyId(principal, companyId);
        NotificationMetricsDto metrics = notificationService.getMetrics(resolvedCompanyId);
        return ResponseEntity.ok(ApiResponse.ok(metrics));
    }

    private Long resolveCompanyId(UserPrincipal principal, Long requestedCompanyId) {
        if (principal == null) return requestedCompanyId;
        if (principal.getRole() == Role.DEVELOPER) return requestedCompanyId != null ? requestedCompanyId : principal.getCompanyId();
        return principal.getCompanyId();
    }
}
