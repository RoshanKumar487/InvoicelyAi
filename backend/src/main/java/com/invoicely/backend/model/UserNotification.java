package com.invoicely.backend.model;

import jakarta.persistence.*;
import java.time.OffsetDateTime;

@Entity
@Table(name = "user_notifications", indexes = {
    @Index(name = "idx_user_notif_status_scheduled", columnList = "status, scheduled_at, created_at"),
    @Index(name = "idx_user_notif_company", columnList = "company_id, created_at"),
    @Index(name = "idx_user_notif_recipient", columnList = "recipient_to")
})
public class UserNotification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "company_id")
    private Long companyId;

    @Column(name = "user_id")
    private Long userId;

    @Column(name = "recipient_to", nullable = false)
    private String recipientTo;

    @Column(name = "recipient_name")
    private String recipientName;

    @Enumerated(EnumType.STRING)
    @Column(name = "recipient_type", length = 30)
    private RecipientType recipientType = RecipientType.CLIENT;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private NotificationChannel channel = NotificationChannel.EMAIL;

    @Column(name = "template_name", nullable = false, length = 100)
    private String templateName;

    @Column(nullable = false, length = 255)
    private String title;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String body;

    @Column(name = "metadata_json", columnDefinition = "TEXT")
    private String metadataJson = "{}";

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private NotificationStatus status = NotificationStatus.PENDING;

    @Column(name = "retry_count", nullable = false)
    private Integer retryCount = 0;

    @Column(name = "max_retries", nullable = false)
    private Integer maxRetries = 3;

    @Column(name = "error_message", columnDefinition = "TEXT")
    private String errorMessage;

    @Column(name = "scheduled_at", nullable = false)
    private OffsetDateTime scheduledAt = OffsetDateTime.now();

    @Column(name = "sent_at")
    private OffsetDateTime sentAt;

    @Column(name = "created_at", nullable = false)
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt = OffsetDateTime.now();

    public UserNotification() {}

    public UserNotification(Long companyId, Long userId, String recipientTo, String recipientName,
                            RecipientType recipientType, NotificationChannel channel, String templateName,
                            String title, String body, String metadataJson, OffsetDateTime scheduledAt) {
        this.companyId = companyId;
        this.userId = userId;
        this.recipientTo = recipientTo;
        this.recipientName = recipientName;
        this.recipientType = recipientType != null ? recipientType : RecipientType.CLIENT;
        this.channel = channel != null ? channel : NotificationChannel.EMAIL;
        this.templateName = templateName;
        this.title = title;
        this.body = body;
        this.metadataJson = metadataJson != null ? metadataJson : "{}";
        this.status = NotificationStatus.PENDING;
        this.retryCount = 0;
        this.maxRetries = 3;
        this.scheduledAt = scheduledAt != null ? scheduledAt : OffsetDateTime.now();
        this.createdAt = OffsetDateTime.now();
        this.updatedAt = OffsetDateTime.now();
    }

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) createdAt = OffsetDateTime.now();
        if (updatedAt == null) updatedAt = OffsetDateTime.now();
        if (scheduledAt == null) scheduledAt = OffsetDateTime.now();
        if (status == null) status = NotificationStatus.PENDING;
        if (retryCount == null) retryCount = 0;
        if (maxRetries == null) maxRetries = 3;
        if (channel == null) channel = NotificationChannel.EMAIL;
        if (recipientType == null) recipientType = RecipientType.CLIENT;
        if (metadataJson == null) metadataJson = "{}";
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = OffsetDateTime.now();
    }

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getCompanyId() { return companyId; }
    public void setCompanyId(Long companyId) { this.companyId = companyId; }

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public String getRecipientTo() { return recipientTo; }
    public void setRecipientTo(String recipientTo) { this.recipientTo = recipientTo; }

    public String getRecipientName() { return recipientName; }
    public void setRecipientName(String recipientName) { this.recipientName = recipientName; }

    public RecipientType getRecipientType() { return recipientType; }
    public void setRecipientType(RecipientType recipientType) { this.recipientType = recipientType; }

    public NotificationChannel getChannel() { return channel; }
    public void setChannel(NotificationChannel channel) { this.channel = channel; }

    public String getTemplateName() { return templateName; }
    public void setTemplateName(String templateName) { this.templateName = templateName; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getBody() { return body; }
    public void setBody(String body) { this.body = body; }

    public String getMetadataJson() { return metadataJson; }
    public void setMetadataJson(String metadataJson) { this.metadataJson = metadataJson; }

    public NotificationStatus getStatus() { return status; }
    public void setStatus(NotificationStatus status) { this.status = status; }

    public Integer getRetryCount() { return retryCount; }
    public void setRetryCount(Integer retryCount) { this.retryCount = retryCount; }

    public Integer getMaxRetries() { return maxRetries; }
    public void setMaxRetries(Integer maxRetries) { this.maxRetries = maxRetries; }

    public String getErrorMessage() { return errorMessage; }
    public void setErrorMessage(String errorMessage) { this.errorMessage = errorMessage; }

    public OffsetDateTime getScheduledAt() { return scheduledAt; }
    public void setScheduledAt(OffsetDateTime scheduledAt) { this.scheduledAt = scheduledAt; }

    public OffsetDateTime getSentAt() { return sentAt; }
    public void setSentAt(OffsetDateTime sentAt) { this.sentAt = sentAt; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }

    public OffsetDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }
}
