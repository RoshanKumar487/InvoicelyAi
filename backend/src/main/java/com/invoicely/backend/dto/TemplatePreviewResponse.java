package com.invoicely.backend.dto;

import com.invoicely.backend.model.NotificationChannel;
import java.util.Map;

public class TemplatePreviewResponse {

    private String subject;
    private String body;
    private NotificationChannel channel;
    private Map<String, Object> resolvedVariables;

    public TemplatePreviewResponse() {}

    public TemplatePreviewResponse(String subject, String body, NotificationChannel channel, Map<String, Object> resolvedVariables) {
        this.subject = subject;
        this.body = body;
        this.channel = channel;
        this.resolvedVariables = resolvedVariables;
    }

    public String getSubject() { return subject; }
    public void setSubject(String subject) { this.subject = subject; }

    public String getBody() { return body; }
    public void setBody(String body) { this.body = body; }

    public NotificationChannel getChannel() { return channel; }
    public void setChannel(NotificationChannel channel) { this.channel = channel; }

    public Map<String, Object> getResolvedVariables() { return resolvedVariables; }
    public void setResolvedVariables(Map<String, Object> resolvedVariables) { this.resolvedVariables = resolvedVariables; }
}
