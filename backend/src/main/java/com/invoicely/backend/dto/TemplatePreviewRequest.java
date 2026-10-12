package com.invoicely.backend.dto;

import com.invoicely.backend.model.NotificationChannel;
import java.util.Map;

public class TemplatePreviewRequest {

    private String templateName;
    private NotificationChannel channel = NotificationChannel.EMAIL;
    private String subject;
    private String body;
    private Long invoiceId;
    private Map<String, Object> variables;

    public TemplatePreviewRequest() {}

    public String getTemplateName() { return templateName; }
    public void setTemplateName(String templateName) { this.templateName = templateName; }

    public NotificationChannel getChannel() { return channel; }
    public void setChannel(NotificationChannel channel) { this.channel = channel; }

    public String getSubject() { return subject; }
    public void setSubject(String subject) { this.subject = subject; }

    public String getBody() { return body; }
    public void setBody(String body) { this.body = body; }

    public Long getInvoiceId() { return invoiceId; }
    public void setInvoiceId(Long invoiceId) { this.invoiceId = invoiceId; }

    public Map<String, Object> getVariables() { return variables; }
    public void setVariables(Map<String, Object> variables) { this.variables = variables; }
}
