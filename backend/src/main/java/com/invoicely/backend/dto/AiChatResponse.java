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
    private final List<SummaryCard> summaryCards;
    private final InsightCard insightCard;
    private final List<RecordCard> recordCards;

    public record SummaryCard(String id, String title, String value, String subtitle, String icon, String color) {}
    public record InsightCard(String title, String message, String actionLabel, String actionType, String actionTarget) {}
    public record RecordCard(String id, String recordType, String title, String subtitle, String amount, String status, String statusColor, String updatedAt) {}

    public AiChatResponse(String answer, List<String> groundedSources, boolean readOnly) {
        this(answer, groundedSources, readOnly, null, null, null, null, null, null, null);
    }

    public AiChatResponse(String answer, List<String> groundedSources, boolean readOnly,
                          String pendingCommandId, String actionType, String resourceType, Long resourceId) {
        this(answer, groundedSources, readOnly, pendingCommandId, actionType, resourceType, resourceId, null, null, null);
    }

    public AiChatResponse(String answer, List<String> groundedSources, boolean readOnly,
                          String pendingCommandId, String actionType, String resourceType, Long resourceId,
                          List<SummaryCard> summaryCards, InsightCard insightCard, List<RecordCard> recordCards) {
        this.answer = answer;
        this.groundedSources = groundedSources != null ? groundedSources : List.of();
        this.readOnly = readOnly;
        this.pendingCommandId = pendingCommandId;
        this.actionType = actionType;
        this.resourceType = resourceType;
        this.resourceId = resourceId;
        this.summaryCards = summaryCards != null ? summaryCards : List.of();
        this.insightCard = insightCard;
        this.recordCards = recordCards != null ? recordCards : List.of();
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

    public List<SummaryCard> getSummaryCards() {
        return summaryCards;
    }

    public InsightCard getInsightCard() {
        return insightCard;
    }

    public List<RecordCard> getRecordCards() {
        return recordCards;
    }
}
