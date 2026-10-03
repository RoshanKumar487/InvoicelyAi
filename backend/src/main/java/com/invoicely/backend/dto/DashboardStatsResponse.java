package com.invoicely.backend.dto;

import java.math.BigDecimal;

public class DashboardStatsResponse {

    private long totalInvoices;
    private long paidInvoices;
    private long overdueInvoices;
    private long draftInvoices;
    private BigDecimal totalRevenue = BigDecimal.ZERO;
    private BigDecimal outstandingAmount = BigDecimal.ZERO;
    private BigDecimal totalExpenses = BigDecimal.ZERO;
    private long totalClients;

    public DashboardStatsResponse() {}

    public long getTotalInvoices() { return totalInvoices; }
    public void setTotalInvoices(long totalInvoices) { this.totalInvoices = totalInvoices; }

    public long getPaidInvoices() { return paidInvoices; }
    public void setPaidInvoices(long paidInvoices) { this.paidInvoices = paidInvoices; }

    public long getOverdueInvoices() { return overdueInvoices; }
    public void setOverdueInvoices(long overdueInvoices) { this.overdueInvoices = overdueInvoices; }

    public long getDraftInvoices() { return draftInvoices; }
    public void setDraftInvoices(long draftInvoices) { this.draftInvoices = draftInvoices; }

    public BigDecimal getTotalRevenue() { return totalRevenue; }
    public void setTotalRevenue(BigDecimal totalRevenue) { this.totalRevenue = totalRevenue; }

    public BigDecimal getOutstandingAmount() { return outstandingAmount; }
    public void setOutstandingAmount(BigDecimal outstandingAmount) { this.outstandingAmount = outstandingAmount; }

    public BigDecimal getTotalExpenses() { return totalExpenses; }
    public void setTotalExpenses(BigDecimal totalExpenses) { this.totalExpenses = totalExpenses; }

    public long getTotalClients() { return totalClients; }
    public void setTotalClients(long totalClients) { this.totalClients = totalClients; }
}
