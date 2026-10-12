package com.invoicely.backend.dto;

import com.invoicely.backend.model.NotificationChannel;
import jakarta.validation.constraints.NotNull;

public class SendJoinRequestNotificationRequest {

    @NotNull(message = "joinRequestId is required")
    private Long joinRequestId;

    private String action = "APPROVED"; // APPROVED, REJECTED, INFO_REQUESTED, CUSTOM

    private String customMessage;

    private NotificationChannel channel = NotificationChannel.EMAIL;

    private String templateName;

    public SendJoinRequestNotificationRequest() {}

    public Long getJoinRequestId() { return joinRequestId; }
    public void setJoinRequestId(Long joinRequestId) { this.joinRequestId = joinRequestId; }

    public String getAction() { return action; }
    public void setAction(String action) { this.action = action; }

    public String getCustomMessage() { return customMessage; }
    public void setCustomMessage(String customMessage) { this.customMessage = customMessage; }

    public NotificationChannel getChannel() { return channel; }
    public void setChannel(NotificationChannel channel) { this.channel = channel; }

    public String getTemplateName() { return templateName; }
    public void setTemplateName(String templateName) { this.templateName = templateName; }
}
