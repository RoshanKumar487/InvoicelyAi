package com.invoicely.backend.model;

import jakarta.persistence.*;
import java.time.OffsetDateTime;

@Entity
@Table(name = "notification_audit_logs", indexes = {
    @Index(name = "idx_notif_audit_notif_id", columnList = "notification_id, created_at"),
    @Index(name = "idx_notif_audit_company", columnList = "company_id, created_at"),
    @Index(name = "idx_notif_audit_status", columnList = "status")
})
public class NotificationAuditLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "notification_id", nullable = false)
    private Long notificationId;

    @Column(name = "company_id")
    private Long companyId;

    @Enumerated(EnumType.STRING)
    @Column(length = 20)
    private NotificationChannel channel = NotificationChannel.EMAIL;

    @Column(name = "recipient_to", length = 255)
    private String recipientTo;

    @Column(name = "attempt_number", nullable = false)
    private Integer attemptNumber = 1;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private AuditStatus status = AuditStatus.SUCCESS;

    @Column(name = "provider_response_code", length = 100)
    private String providerResponseCode;

    @Column(name = "error_details", columnDefinition = "TEXT")
    private String errorDetails;

    @Column(name = "duration_ms")
    private Long durationMs = 0L;

    @Column(name = "created_at", nullable = false)
    private OffsetDateTime createdAt = OffsetDateTime.now();

    public NotificationAuditLog() {}

    public NotificationAuditLog(Long notificationId, Long companyId, NotificationChannel channel,
                                String recipientTo, Integer attemptNumber, AuditStatus status,
                                String providerResponseCode, String errorDetails, Long durationMs) {
        this.notificationId = notificationId;
        this.companyId = companyId;
        this.channel = channel != null ? channel : NotificationChannel.EMAIL;
        this.recipientTo = recipientTo;
        this.attemptNumber = attemptNumber != null ? attemptNumber : 1;
        this.status = status != null ? status : AuditStatus.SUCCESS;
        this.providerResponseCode = providerResponseCode;
        this.errorDetails = errorDetails;
        this.durationMs = durationMs != null ? durationMs : 0L;
        this.createdAt = OffsetDateTime.now();
    }

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) createdAt = OffsetDateTime.now();
        if (attemptNumber == null) attemptNumber = 1;
        if (durationMs == null) durationMs = 0L;
    }

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getNotificationId() { return notificationId; }
    public void setNotificationId(Long notificationId) { this.notificationId = notificationId; }

    public Long getCompanyId() { return companyId; }
    public void setCompanyId(Long companyId) { this.companyId = companyId; }

    public NotificationChannel getChannel() { return channel; }
    public void setChannel(NotificationChannel channel) { this.channel = channel; }

    public String getRecipientTo() { return recipientTo; }
    public void setRecipientTo(String recipientTo) { this.recipientTo = recipientTo; }

    public Integer getAttemptNumber() { return attemptNumber; }
    public void setAttemptNumber(Integer attemptNumber) { this.attemptNumber = attemptNumber; }

    public AuditStatus getStatus() { return status; }
    public void setStatus(AuditStatus status) { this.status = status; }

    public String getProviderResponseCode() { return providerResponseCode; }
    public void setProviderResponseCode(String providerResponseCode) { this.providerResponseCode = providerResponseCode; }

    public String getErrorDetails() { return errorDetails; }
    public void setErrorDetails(String errorDetails) { this.errorDetails = errorDetails; }

    public Long getDurationMs() { return durationMs; }
    public void setDurationMs(Long durationMs) { this.durationMs = durationMs; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }
}
