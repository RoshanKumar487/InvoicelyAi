package com.invoicely.backend.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.invoicely.backend.dto.*;
import com.invoicely.backend.exception.ResourceNotFoundException;
import com.invoicely.backend.model.*;
import com.invoicely.backend.repository.*;
import com.invoicely.backend.security.UserPrincipal;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.HashMap;
import java.util.Map;

@Service
public class NotificationService {

    private final UserNotificationRepository notificationRepository;
    private final NotificationAuditLogRepository auditLogRepository;
    private final NotificationTemplateService templateService;
    private final TemplateRenderer templateRenderer;
    private final InvoiceRepository invoiceRepository;
    private final CompanyRepository companyRepository;
    private final CompanyJoinRequestRepository joinRequestRepository;
    private final ObjectMapper objectMapper;

    public NotificationService(UserNotificationRepository notificationRepository,
                               NotificationAuditLogRepository auditLogRepository,
                               NotificationTemplateService templateService,
                               TemplateRenderer templateRenderer,
                               InvoiceRepository invoiceRepository,
                               CompanyRepository companyRepository,
                               CompanyJoinRequestRepository joinRequestRepository) {
        this.notificationRepository = notificationRepository;
        this.auditLogRepository = auditLogRepository;
        this.templateService = templateService;
        this.templateRenderer = templateRenderer;
        this.invoiceRepository = invoiceRepository;
        this.companyRepository = companyRepository;
        this.joinRequestRepository = joinRequestRepository;
        this.objectMapper = new ObjectMapper();
    }

    /**
     * Queues an invoice reminder (Email or WhatsApp) to a client.
     */
    @Transactional
    public UserNotificationDto queueInvoiceReminder(SendReminderRequest request, UserPrincipal principal) {
        Invoice invoice = invoiceRepository.findById(request.getInvoiceId())
                .orElseThrow(() -> new ResourceNotFoundException("Invoice not found with ID " + request.getInvoiceId()));

        Long companyId = invoice.getCompanyId();
        if (companyId == null && principal != null) {
            companyId = principal.getCompanyId();
        }

        Company company = companyId != null ? companyRepository.findById(companyId).orElse(null) : null;

        NotificationChannel channel = request.getChannel() != null ? request.getChannel() : NotificationChannel.EMAIL;
        String templateName = request.getTemplateName();
        if (templateName == null || templateName.isBlank()) {
            templateName = channel == NotificationChannel.WHATSAPP ? "WHATSAPP_PAYMENT_REMINDER" : "PAYMENT_REMINDER";
        }

        NotificationTemplate template = templateService.getEffectiveTemplate(companyId, templateName, channel);

        // Prepare variables
        Map<String, Object> vars = templateRenderer.extractInvoiceVariables(invoice, company);
        if (request.getCustomMessage() != null && !request.getCustomMessage().isBlank()) {
            vars.put("customMessage", request.getCustomMessage());
        }

        String renderedTitle = templateRenderer.render(template.getSubject() != null ? template.getSubject() : template.getTitle(), vars);
        String renderedBody = templateRenderer.render(template.getBody(), vars);

        // Resolve recipient contact
        String recipientTo = request.getOverrideRecipient();
        if (recipientTo == null || recipientTo.isBlank()) {
            recipientTo = channel == NotificationChannel.WHATSAPP ? invoice.getClientPhone() : invoice.getClientEmail();
        }

        if (recipientTo == null || recipientTo.isBlank()) {
            throw new IllegalArgumentException("Client has no " + (channel == NotificationChannel.WHATSAPP ? "phone number" : "email address") + " configured.");
        }

        Map<String, Object> metadata = new HashMap<>();
        metadata.put("invoiceId", invoice.getId());
        metadata.put("invoiceNumber", invoice.getInvoiceNumber());
        metadata.put("clientId", invoice.getClientId());
        metadata.put("clientName", invoice.getClientName());
        metadata.put("queuedByUserId", principal != null ? principal.getId() : null);
        metadata.put("queuedByUserName", principal != null ? principal.getFullName() : "System");

        String metadataJson;
        try {
            metadataJson = objectMapper.writeValueAsString(metadata);
        } catch (Exception e) {
            metadataJson = "{}";
        }

        OffsetDateTime scheduledAt = request.getScheduledAt() != null ? request.getScheduledAt() : OffsetDateTime.now();

        UserNotification notification = new UserNotification(
                companyId,
                null,
                recipientTo,
                invoice.getClientName(),
                RecipientType.CLIENT,
                channel,
                templateName,
                renderedTitle,
                renderedBody,
                metadataJson,
                scheduledAt
        );

        UserNotification saved = notificationRepository.save(notification);

        // Update invoice reminder sent timestamp
        invoice.setReminderLastSent(System.currentTimeMillis());
        invoiceRepository.save(invoice);

        return UserNotificationDto.fromEntity(saved);
    }

    /**
     * Queues an invitation to join the company workspace (Email or WhatsApp).
     */
    @Transactional
    public UserNotificationDto queueCompanyInvite(SendInviteRequest request, UserPrincipal principal) {
        Long companyId = principal != null ? principal.getCompanyId() : null;
        Company company = companyId != null ? companyRepository.findById(companyId).orElse(null) : null;

        NotificationChannel channel = request.getChannel() != null ? request.getChannel() : NotificationChannel.EMAIL;
        String templateName = "COMPANY_INVITE";

        NotificationTemplate template = templateService.getEffectiveTemplate(companyId, templateName, channel);

        String inviterName = principal != null ? principal.getFullName() : "Company Admin";
        String inviteLink = "https://invoicelyai.onrender.com/join?code=" + (company != null ? company.getCompanyCode() : "");

        Map<String, Object> vars = templateRenderer.extractInviteVariables(
                company,
                request.getInviteeName(),
                request.getInviteeEmail(),
                inviterName,
                request.getRole(),
                inviteLink
        );

        if (request.getCustomNote() != null) {
            vars.put("customNote", request.getCustomNote());
        }

        String renderedTitle = templateRenderer.render(template.getSubject(), vars);
        String renderedBody = templateRenderer.render(template.getBody(), vars);

        String recipientTo = channel == NotificationChannel.WHATSAPP && request.getInviteePhone() != null && !request.getInviteePhone().isBlank()
                ? request.getInviteePhone()
                : request.getInviteeEmail();

        Map<String, Object> metadata = new HashMap<>();
        metadata.put("inviteeEmail", request.getInviteeEmail());
        metadata.put("inviteePhone", request.getInviteePhone());
        metadata.put("role", request.getRole());
        metadata.put("companyCode", company != null ? company.getCompanyCode() : "");
        metadata.put("inviterUserId", principal != null ? principal.getId() : null);

        String metadataJson;
        try {
            metadataJson = objectMapper.writeValueAsString(metadata);
        } catch (Exception e) {
            metadataJson = "{}";
        }

        OffsetDateTime scheduledAt = request.getScheduledAt() != null ? request.getScheduledAt() : OffsetDateTime.now();

        UserNotification notification = new UserNotification(
                companyId,
                null,
                recipientTo,
                request.getInviteeName(),
                RecipientType.EMPLOYEE,
                channel,
                templateName,
                renderedTitle,
                renderedBody,
                metadataJson,
                scheduledAt
        );

        UserNotification saved = notificationRepository.save(notification);
        return UserNotificationDto.fromEntity(saved);
    }

    /**
     * Queues an admin response / push message for a company join request.
     */
    @Transactional
    public UserNotificationDto queueJoinRequestNotification(SendJoinRequestNotificationRequest request, UserPrincipal principal) {
        CompanyJoinRequest joinRequest = joinRequestRepository.findById(request.getJoinRequestId())
                .orElseThrow(() -> new ResourceNotFoundException("Join request not found with ID " + request.getJoinRequestId()));

        Long companyId = joinRequest.getCompanyId();
        Company company = companyRepository.findById(companyId).orElse(null);

        NotificationChannel channel = request.getChannel() != null ? request.getChannel() : NotificationChannel.EMAIL;

        String templateName = request.getTemplateName();
        if (templateName == null || templateName.isBlank()) {
            templateName = "REJECTED".equalsIgnoreCase(request.getAction())
                    ? "JOIN_REQUEST_REJECTED"
                    : "JOIN_REQUEST_APPROVED";
        }

        NotificationTemplate template = templateService.getEffectiveTemplate(companyId, templateName, channel);

        Map<String, Object> vars = templateRenderer.extractJoinRequestVariables(
                joinRequest,
                company,
                request.getCustomMessage()
        );

        String renderedTitle = templateRenderer.render(template.getSubject(), vars);
        String renderedBody = templateRenderer.render(template.getBody(), vars);

        String recipientTo = channel == NotificationChannel.WHATSAPP && joinRequest.getUserMobile() != null && !joinRequest.getUserMobile().isBlank()
                ? joinRequest.getUserMobile()
                : joinRequest.getUserEmail();

        Map<String, Object> metadata = new HashMap<>();
        metadata.put("joinRequestId", joinRequest.getId());
        metadata.put("action", request.getAction());
        metadata.put("userId", joinRequest.getUserId());

        String metadataJson;
        try {
            metadataJson = objectMapper.writeValueAsString(metadata);
        } catch (Exception e) {
            metadataJson = "{}";
        }

        UserNotification notification = new UserNotification(
                companyId,
                joinRequest.getUserId(),
                recipientTo,
                joinRequest.getUserFullName(),
                RecipientType.EMPLOYEE,
                channel,
                templateName,
                renderedTitle,
                renderedBody,
                metadataJson,
                OffsetDateTime.now()
        );

        UserNotification saved = notificationRepository.save(notification);
        return UserNotificationDto.fromEntity(saved);
    }

    /**
     * Queues a custom notification to any client or team member.
     */
    @Transactional
    public UserNotificationDto queueCustomNotification(SendCustomNotificationRequest request, UserPrincipal principal) {
        Long companyId = principal != null ? principal.getCompanyId() : null;
        NotificationChannel channel = request.getChannel() != null ? request.getChannel() : NotificationChannel.EMAIL;

        String templateName = request.getTemplateName() != null ? request.getTemplateName() : "CUSTOM";
        String title = request.getTitle();
        String body = request.getBody();

        if (title == null || body == null) {
            NotificationTemplate template = templateService.getEffectiveTemplate(companyId, templateName, channel);
            if (title == null) title = template.getSubject();
            if (body == null) body = template.getBody();
        }

        if (request.getVariables() != null) {
            title = templateRenderer.render(title, request.getVariables());
            body = templateRenderer.render(body, request.getVariables());
        }

        OffsetDateTime scheduledAt = request.getScheduledAt() != null ? request.getScheduledAt() : OffsetDateTime.now();

        UserNotification notification = new UserNotification(
                companyId,
                null,
                request.getRecipientTo(),
                request.getRecipientName(),
                request.getRecipientType() != null ? request.getRecipientType() : RecipientType.CLIENT,
                channel,
                templateName,
                title,
                body,
                "{}",
                scheduledAt
        );

        UserNotification saved = notificationRepository.save(notification);
        return UserNotificationDto.fromEntity(saved);
    }

    /**
     * Retries a stuck or failed notification.
     */
    @Transactional
    public UserNotificationDto retryNotification(Long id, Long companyId) {
        UserNotification notification = notificationRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Notification not found with ID " + id));

        if (companyId != null && notification.getCompanyId() != null && !companyId.equals(notification.getCompanyId())) {
            throw new ResourceNotFoundException("Notification not found for current company");
        }

        notification.setStatus(NotificationStatus.PENDING);
        notification.setRetryCount(0);
        notification.setErrorMessage(null);
        notification.setScheduledAt(OffsetDateTime.now());

        UserNotification saved = notificationRepository.save(notification);
        return UserNotificationDto.fromEntity(saved);
    }

    /**
     * Cancels a pending notification.
     */
    @Transactional
    public void cancelNotification(Long id, Long companyId) {
        UserNotification notification = notificationRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Notification not found with ID " + id));

        if (companyId != null && notification.getCompanyId() != null && !companyId.equals(notification.getCompanyId())) {
            throw new ResourceNotFoundException("Notification not found for current company");
        }

        notification.setStatus(NotificationStatus.CANCELLED);
        notificationRepository.save(notification);
    }

    /**
     * Gets paginated notification queue records for a company.
     */
    public Page<UserNotificationDto> getQueue(Long companyId, NotificationStatus status, NotificationChannel channel, Pageable pageable) {
        Page<UserNotification> page;
        if (status != null && channel != null) {
            page = notificationRepository.findByCompanyIdAndStatusAndChannel(companyId, status, channel, pageable);
        } else if (status != null) {
            page = notificationRepository.findByCompanyIdAndStatus(companyId, status, pageable);
        } else if (channel != null) {
            page = notificationRepository.findByCompanyIdAndChannel(companyId, channel, pageable);
        } else {
            page = notificationRepository.findByCompanyId(companyId, pageable);
        }
        return page.map(UserNotificationDto::fromEntity);
    }

    /**
     * Gets audit logs for a company or specific notification.
     */
    public Page<NotificationAuditLog> getAuditLogs(Long companyId, Long notificationId, Pageable pageable) {
        if (notificationId != null) {
            return notificationRepository.findById(notificationId)
                    .map(n -> auditLogRepository.findByCompanyIdOrderByCreatedAtDesc(companyId, pageable))
                    .orElseThrow(() -> new ResourceNotFoundException("Notification not found"));
        }
        return auditLogRepository.findByCompanyIdOrderByCreatedAtDesc(companyId, pageable);
    }

    /**
     * Gets notification performance metrics.
     */
    public NotificationMetricsDto getMetrics(Long companyId) {
        long total = notificationRepository.countByCompanyId(companyId);
        long pending = notificationRepository.countByCompanyIdAndStatus(companyId, NotificationStatus.PENDING);
        long processing = notificationRepository.countByCompanyIdAndStatus(companyId, NotificationStatus.PROCESSING);
        long sent = notificationRepository.countByCompanyIdAndStatus(companyId, NotificationStatus.SENT);
        long failed = notificationRepository.countByCompanyIdAndStatus(companyId, NotificationStatus.FAILED);
        long stuck = failed; // Failed items that exhausted retries

        return new NotificationMetricsDto(total, pending, processing, sent, failed, stuck);
    }
}
