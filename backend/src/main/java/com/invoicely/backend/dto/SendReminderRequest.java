package com.invoicely.backend.dto;

import com.invoicely.backend.model.NotificationChannel;
import jakarta.validation.constraints.NotNull;
import java.time.OffsetDateTime;

public class SendReminderRequest {

    @NotNull(message = "invoiceId is required")
    private Long invoiceId;

    private NotificationChannel channel = NotificationChannel.EMAIL;

    private String templateName;

    private String overrideRecipient;

    private String customMessage;

    private OffsetDateTime scheduledAt;

    public SendReminderRequest() {}

    public Long getInvoiceId() { return invoiceId; }
    public void setInvoiceId(Long invoiceId) { this.invoiceId = invoiceId; }

    public NotificationChannel getChannel() { return channel; }
    public void setChannel(NotificationChannel channel) { this.channel = channel; }

    public String getTemplateName() { return templateName; }
    public void setTemplateName(String templateName) { this.templateName = templateName; }

    public String getOverrideRecipient() { return overrideRecipient; }
    public void setOverrideRecipient(String overrideRecipient) { this.overrideRecipient = overrideRecipient; }

    public String getCustomMessage() { return customMessage; }
    public void setCustomMessage(String customMessage) { this.customMessage = customMessage; }

    public OffsetDateTime getScheduledAt() { return scheduledAt; }
    public void setScheduledAt(OffsetDateTime scheduledAt) { this.scheduledAt = scheduledAt; }
}
