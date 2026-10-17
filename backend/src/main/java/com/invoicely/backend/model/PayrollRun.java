package com.invoicely.backend.model;

import com.fasterxml.jackson.annotation.JsonManagedReference;
import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "payroll_runs", indexes = {
    @Index(name = "idx_payroll_runs_company_id", columnList = "company_id"),
    @Index(name = "idx_payroll_runs_company_period", columnList = "company_id, period_year, period_month")
})
public class PayrollRun {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "company_id", nullable = false)
    private Long companyId;

    @Column(name = "period_month", nullable = false)
    private Integer periodMonth; // 1 - 12

    @Column(name = "period_year", nullable = false)
    private Integer periodYear;

    @Column(name = "run_title", nullable = false)
    private String runTitle = "";

    @Column(name = "status", length = 30)
    private String status = "DRAFT"; // DRAFT, REVIEWED, APPROVED, DISBURSED

    @Column(name = "scheduled_pay_date")
    private LocalDate scheduledPayDate = LocalDate.now();

    @Column(name = "total_gross", precision = 14, scale = 2)
    private BigDecimal totalGross = BigDecimal.ZERO;

    @Column(name = "total_paid", precision = 14, scale = 2)
    private BigDecimal totalPaid = BigDecimal.ZERO;

    @Column(name = "total_pending", precision = 14, scale = 2)
    private BigDecimal totalPending = BigDecimal.ZERO;

    @Column(name = "total_overdue", precision = 14, scale = 2)
    private BigDecimal totalOverdue = BigDecimal.ZERO;

    @Column(name = "total_deductions", precision = 14, scale = 2)
    private BigDecimal totalDeductions = BigDecimal.ZERO;

    @Column(name = "total_net_payable", precision = 14, scale = 2)
    private BigDecimal totalNetPayable = BigDecimal.ZERO;

    @Column(name = "employee_count")
    private Integer employeeCount = 0;

    @OneToMany(mappedBy = "payrollRun", cascade = CascadeType.ALL, orphanRemoval = true)
    @JsonManagedReference
    private List<PayrollEntry> entries = new ArrayList<>();

    @Column(name = "created_at")
    private OffsetDateTime createdAt = OffsetDateTime.now();

    public PayrollRun() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getCompanyId() { return companyId; }
    public void setCompanyId(Long companyId) { this.companyId = companyId; }

    public Integer getPeriodMonth() { return periodMonth; }
    public void setPeriodMonth(Integer periodMonth) { this.periodMonth = periodMonth; }

    public Integer getPeriodYear() { return periodYear; }
    public void setPeriodYear(Integer periodYear) { this.periodYear = periodYear; }

    public String getRunTitle() { return runTitle; }
    public void setRunTitle(String runTitle) { this.runTitle = runTitle; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public LocalDate getScheduledPayDate() { return scheduledPayDate; }
    public void setScheduledPayDate(LocalDate scheduledPayDate) { this.scheduledPayDate = scheduledPayDate; }

    public BigDecimal getTotalGross() { return totalGross; }
    public void setTotalGross(BigDecimal totalGross) { this.totalGross = totalGross; }

    public BigDecimal getTotalPaid() { return totalPaid; }
    public void setTotalPaid(BigDecimal totalPaid) { this.totalPaid = totalPaid; }

    public BigDecimal getTotalPending() { return totalPending; }
    public void setTotalPending(BigDecimal totalPending) { this.totalPending = totalPending; }

    public BigDecimal getTotalOverdue() { return totalOverdue; }
    public void setTotalOverdue(BigDecimal totalOverdue) { this.totalOverdue = totalOverdue; }

    public BigDecimal getTotalDeductions() { return totalDeductions; }
    public void setTotalDeductions(BigDecimal totalDeductions) { this.totalDeductions = totalDeductions; }

    public BigDecimal getTotalNetPayable() { return totalNetPayable; }
    public void setTotalNetPayable(BigDecimal totalNetPayable) { this.totalNetPayable = totalNetPayable; }

    public Integer getEmployeeCount() { return employeeCount; }
    public void setEmployeeCount(Integer employeeCount) { this.employeeCount = employeeCount; }

    public List<PayrollEntry> getEntries() { return entries; }
    public void setEntries(List<PayrollEntry> entries) { this.entries = entries; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }
}
