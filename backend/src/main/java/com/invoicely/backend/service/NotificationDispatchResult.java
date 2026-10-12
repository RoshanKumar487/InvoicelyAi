package com.invoicely.backend.service;

public class NotificationDispatchResult {

    private final boolean success;
    private final String providerResponseCode;
    private final String errorMessage;
    private final long durationMs;

    public NotificationDispatchResult(boolean success, String providerResponseCode, String errorMessage, long durationMs) {
        this.success = success;
        this.providerResponseCode = providerResponseCode;
        this.errorMessage = errorMessage;
        this.durationMs = durationMs;
    }

    public static NotificationDispatchResult success(String responseCode, long durationMs) {
        return new NotificationDispatchResult(true, responseCode, null, durationMs);
    }

    public static NotificationDispatchResult failure(String responseCode, String errorMessage, long durationMs) {
        return new NotificationDispatchResult(false, responseCode, errorMessage, durationMs);
    }

    public boolean isSuccess() { return success; }
    public String getProviderResponseCode() { return providerResponseCode; }
    public String getErrorMessage() { return errorMessage; }
    public long getDurationMs() { return durationMs; }
}
