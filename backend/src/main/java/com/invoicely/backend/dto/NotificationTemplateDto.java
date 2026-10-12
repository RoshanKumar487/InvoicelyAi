package com.invoicely.backend.dto;

import com.invoicely.backend.model.NotificationChannel;
import com.invoicely.backend.model.NotificationTemplate;

import java.time.OffsetDateTime;

public class NotificationTemplateDto {

    private Long id;
    private Long companyId;
    private String templateName;
    private NotificationChannel channel;
    private String subject;
    private String title;
    private String body;
    private String metadataJson;
    private Long createdByUserId;
    private String createdByUserName;
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;
    private Boolean isActive;

    public NotificationTemplateDto() {}

    public static NotificationTemplateDto fromEntity(NotificationTemplate entity) {
        NotificationTemplateDto dto = new NotificationTemplateDto();
        dto.setId(entity.getId());
        dto.setCompanyId(entity.getCompanyId());
        dto.setTemplateName(entity.getTemplateName());
        dto.setChannel(entity.getChannel());
        dto.setSubject(entity.getSubject());
        dto.setTitle(entity.getTitle());
        dto.setBody(entity.getBody());
        dto.setMetadataJson(entity.getMetadataJson());
        dto.setCreatedByUserId(entity.getCreatedByUserId());
        dto.setCreatedByUserName(entity.getCreatedByUserName());
        dto.setCreatedAt(entity.getCreatedAt());
        dto.setUpdatedAt(entity.getUpdatedAt());
        dto.setIsActive(entity.getIsActive());
        return dto;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getCompanyId() { return companyId; }
    public void setCompanyId(Long companyId) { this.companyId = companyId; }

    public String getTemplateName() { return templateName; }
    public void setTemplateName(String templateName) { this.templateName = templateName; }

    public NotificationChannel getChannel() { return channel; }
    public void setChannel(NotificationChannel channel) { this.channel = channel; }

    public String getSubject() { return subject; }
    public void setSubject(String subject) { this.subject = subject; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getBody() { return body; }
    public void setBody(String body) { this.body = body; }

    public String getMetadataJson() { return metadataJson; }
    public void setMetadataJson(String metadataJson) { this.metadataJson = metadataJson; }

    public Long getCreatedByUserId() { return createdByUserId; }
    public void setCreatedByUserId(Long createdByUserId) { this.createdByUserId = createdByUserId; }

    public String getCreatedByUserName() { return createdByUserName; }
    public void setCreatedByUserName(String createdByUserName) { this.createdByUserName = createdByUserName; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }

    public OffsetDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }

    public Boolean getIsActive() { return isActive; }
    public void setIsActive(Boolean isActive) { this.isActive = isActive; }
}
