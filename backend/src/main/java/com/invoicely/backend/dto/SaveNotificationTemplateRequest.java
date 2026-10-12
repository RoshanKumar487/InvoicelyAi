package com.invoicely.backend.dto;

import com.invoicely.backend.model.NotificationChannel;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public class SaveNotificationTemplateRequest {

    @NotBlank(message = "templateName is required")
    private String templateName;

    @NotNull(message = "channel is required")
    private NotificationChannel channel = NotificationChannel.EMAIL;

    private String subject;

    private String title;

    @NotBlank(message = "body is required")
    private String body;

    private String metadataJson = "{}";

    public SaveNotificationTemplateRequest() {}

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
}
