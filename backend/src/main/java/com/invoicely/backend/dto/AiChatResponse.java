package com.invoicely.backend.dto;

import java.util.List;

public class AiChatResponse {

    private final String answer;
    private final List<String> groundedSources;
    private final boolean readOnly;
    private final String pendingCommandId;
    private final String actionType;
    private final String resourceType;
    private final Long resourceId;

    public AiChatResponse(String answer, List<String> groundedSources, boolean readOnly) {
        this(answer, groundedSources, readOnly, null, null, null, null);
    }

    public AiChatResponse(String answer, List<String> groundedSources, boolean readOnly,
                          String pendingCommandId, String actionType, String resourceType, Long resourceId) {
        this.answer = answer;
        this.groundedSources = groundedSources;
        this.readOnly = readOnly;
        this.pendingCommandId = pendingCommandId;
        this.actionType = actionType;
        this.resourceType = resourceType;
        this.resourceId = resourceId;
    }

    public String getAnswer() {
        return answer;
    }

    public List<String> getGroundedSources() {
        return groundedSources;
    }

    public boolean isReadOnly() {
        return readOnly;
    }

    public String getPendingCommandId() {
        return pendingCommandId;
    }

    public String getActionType() {
        return actionType;
    }

    public String getResourceType() {
        return resourceType;
    }

    public Long getResourceId() {
        return resourceId;
    }
}
