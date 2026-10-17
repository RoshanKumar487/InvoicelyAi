package com.invoicely.backend.dto;

import java.math.BigDecimal;

public class PayrollSummaryKpiDto {
    private BigDecimal totalGross = BigDecimal.ZERO;
    private BigDecimal totalPaid = BigDecimal.ZERO;
    private BigDecimal totalPending = BigDecimal.ZERO;
    private BigDecimal totalOverdue = BigDecimal.ZERO;
    private Integer totalEmployees = 0;
    private Integer pendingCount = 0;
    private Integer paidCount = 0;
    private Integer overdueCount = 0;

    public PayrollSummaryKpiDto() {}

    public BigDecimal getTotalGross() { return totalGross; }
    public void setTotalGross(BigDecimal totalGross) { this.totalGross = totalGross; }

    public BigDecimal getTotalPaid() { return totalPaid; }
    public void setTotalPaid(BigDecimal totalPaid) { this.totalPaid = totalPaid; }

    public BigDecimal getTotalPending() { return totalPending; }
    public void setTotalPending(BigDecimal totalPending) { this.totalPending = totalPending; }

    public BigDecimal getTotalOverdue() { return totalOverdue; }
    public void setTotalOverdue(BigDecimal totalOverdue) { this.totalOverdue = totalOverdue; }

    public Integer getTotalEmployees() { return totalEmployees; }
    public void setTotalEmployees(Integer totalEmployees) { this.totalEmployees = totalEmployees; }

    public Integer getPendingCount() { return pendingCount; }
    public void setPendingCount(Integer pendingCount) { this.pendingCount = pendingCount; }

    public Integer getPaidCount() { return paidCount; }
    public void setPaidCount(Integer paidCount) { this.paidCount = paidCount; }

    public Integer getOverdueCount() { return overdueCount; }
    public void setOverdueCount(Integer overdueCount) { this.overdueCount = overdueCount; }
}
