package com.invoicely.backend.dto;

public class NotificationMetricsDto {

    private long total;
    private long pending;
    private long processing;
    private long sent;
    private long failed;
    private long stuck;
    private double successRatePercent;

    public NotificationMetricsDto() {}

    public NotificationMetricsDto(long total, long pending, long processing, long sent, long failed, long stuck) {
        this.total = total;
        this.pending = pending;
        this.processing = processing;
        this.sent = sent;
        this.failed = failed;
        this.stuck = stuck;
        long finished = sent + failed;
        this.successRatePercent = finished > 0 ? ((double) sent / finished) * 100.0 : 100.0;
    }

    public long getTotal() { return total; }
    public void setTotal(long total) { this.total = total; }

    public long getPending() { return pending; }
    public void setPending(long pending) { this.pending = pending; }

    public long getProcessing() { return processing; }
    public void setProcessing(long processing) { this.processing = processing; }

    public long getSent() { return sent; }
    public void setSent(long sent) { this.sent = sent; }

    public long getFailed() { return failed; }
    public void setFailed(long failed) { this.failed = failed; }

    public long getStuck() { return stuck; }
    public void setStuck(long stuck) { this.stuck = stuck; }

    public double getSuccessRatePercent() { return successRatePercent; }
    public void setSuccessRatePercent(double successRatePercent) { this.successRatePercent = successRatePercent; }
}
