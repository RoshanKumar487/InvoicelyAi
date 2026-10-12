package com.invoicely.backend.dto;

import com.invoicely.backend.model.NotificationChannel;
import com.invoicely.backend.model.RecipientType;
import jakarta.validation.constraints.NotBlank;
import java.time.OffsetDateTime;
import java.util.Map;

public class SendCustomNotificationRequest {

    @NotBlank(message = "recipientTo is required")
    private String recipientTo;

    private String recipientName;

    private RecipientType recipientType = RecipientType.CLIENT;

    private NotificationChannel channel = NotificationChannel.EMAIL;

    private String templateName;

    private String title;

    private String body;

    private Map<String, Object> variables;

    private OffsetDateTime scheduledAt;

    public SendCustomNotificationRequest() {}

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

    public Map<String, Object> getVariables() { return variables; }
    public void setVariables(Map<String, Object> variables) { this.variables = variables; }

    public OffsetDateTime getScheduledAt() { return scheduledAt; }
    public void setScheduledAt(OffsetDateTime scheduledAt) { this.scheduledAt = scheduledAt; }
}
