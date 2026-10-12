package com.invoicely.backend.dto;

import com.invoicely.backend.model.NotificationChannel;
import com.invoicely.backend.model.NotificationStatus;
import com.invoicely.backend.model.RecipientType;
import com.invoicely.backend.model.UserNotification;

import java.time.OffsetDateTime;

public class UserNotificationDto {

    private Long id;
    private Long companyId;
    private Long userId;
    private String recipientTo;
    private String recipientName;
    private RecipientType recipientType;
    private NotificationChannel channel;
    private String templateName;
    private String title;
    private String body;
    private String metadataJson;
    private NotificationStatus status;
    private Integer retryCount;
    private Integer maxRetries;
    private String errorMessage;
    private OffsetDateTime scheduledAt;
    private OffsetDateTime sentAt;
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;

    public UserNotificationDto() {}

    public static UserNotificationDto fromEntity(UserNotification entity) {
        UserNotificationDto dto = new UserNotificationDto();
        dto.setId(entity.getId());
        dto.setCompanyId(entity.getCompanyId());
        dto.setUserId(entity.getUserId());
        dto.setRecipientTo(entity.getRecipientTo());
        dto.setRecipientName(entity.getRecipientName());
        dto.setRecipientType(entity.getRecipientType());
        dto.setChannel(entity.getChannel());
        dto.setTemplateName(entity.getTemplateName());
        dto.setTitle(entity.getTitle());
        dto.setBody(entity.getBody());
        dto.setMetadataJson(entity.getMetadataJson());
        dto.setStatus(entity.getStatus());
        dto.setRetryCount(entity.getRetryCount());
        dto.setMaxRetries(entity.getMaxRetries());
        dto.setErrorMessage(entity.getErrorMessage());
        dto.setScheduledAt(entity.getScheduledAt());
        dto.setSentAt(entity.getSentAt());
        dto.setCreatedAt(entity.getCreatedAt());
        dto.setUpdatedAt(entity.getUpdatedAt());
        return dto;
    }

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
