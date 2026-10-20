package com.invoicely.backend.model;

import com.fasterxml.jackson.annotation.JsonBackReference;
import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.OffsetDateTime;

@Entity
@Table(name = "payroll_entries", indexes = {
    @Index(name = "idx_payroll_entries_company_id", columnList = "company_id"),
    @Index(name = "idx_payroll_entries_run_id", columnList = "payroll_run_id")
})
public class PayrollEntry {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "payroll_run_id", nullable = false)
    @JsonBackReference
    private PayrollRun payrollRun;

    @Column(name = "company_id", nullable = false)
    private Long companyId;

    @Column(name = "employee_id", nullable = false)
    private Long employeeId;

    @Column(name = "employee_name", nullable = false)
    private String employeeName = "";

    @Column(name = "employee_code")
    private String employeeCode = "";

    @Column(name = "designation")
    private String designation = "";

    @Column(name = "department")
    private String department = "";

    @Column(name = "working_days")
    private Integer workingDays = 30;

    @Column(name = "paid_days")
    private BigDecimal paidDays = BigDecimal.valueOf(30);

    @Column(name = "basic_pay", precision = 12, scale = 2)
    private BigDecimal basicPay = BigDecimal.ZERO;

    @Column(name = "hra", precision = 12, scale = 2)
    private BigDecimal hra = BigDecimal.ZERO;

    @Column(name = "allowances", precision = 12, scale = 2)
    private BigDecimal allowances = BigDecimal.ZERO;

    @Column(name = "gross_earnings", precision = 12, scale = 2)
    private BigDecimal grossEarnings = BigDecimal.ZERO;

    @Column(name = "pf_employee", precision = 12, scale = 2)
    private BigDecimal pfEmployee = BigDecimal.ZERO;

    @Column(name = "esi_employee", precision = 12, scale = 2)
    private BigDecimal esiEmployee = BigDecimal.ZERO;

    @Column(name = "professional_tax", precision = 12, scale = 2)
    private BigDecimal professionalTax = BigDecimal.ZERO;

    @Column(name = "tds_tax", precision = 12, scale = 2)
    private BigDecimal tdsTax = BigDecimal.ZERO;

    @Column(name = "other_deductions", precision = 12, scale = 2)
    private BigDecimal otherDeductions = BigDecimal.ZERO;

    @Column(name = "total_deductions", precision = 12, scale = 2)
    private BigDecimal totalDeductions = BigDecimal.ZERO;

    @Column(name = "net_salary", precision = 12, scale = 2)
    private BigDecimal netSalary = BigDecimal.ZERO;

    @Column(name = "payment_status", length = 30)
    private String paymentStatus = "PENDING"; // PENDING, PAID, OVERDUE, ON_HOLD

    @Column(name = "scheduled_pay_date")
    private LocalDate scheduledPayDate = LocalDate.now();

    @Column(name = "disbursed_at")
    private OffsetDateTime disbursedAt;

    @Column(name = "bank_account_mask", length = 30)
    private String bankAccountMask = "";

    @Column(name = "advance_amount", precision = 12, scale = 2)
    private BigDecimal advanceAmount = BigDecimal.ZERO;

    @Column(name = "advance_deduction", precision = 12, scale = 2)
    private BigDecimal advanceDeduction = BigDecimal.ZERO;

    @Column(name = "pending_months_count")
    private Integer pendingMonthsCount = 1;

    @Column(name = "pending_months_details")
    private String pendingMonthsDetails = "";

    @Column(name = "cumulative_payable", precision = 12, scale = 2)
    private BigDecimal cumulativePayable = BigDecimal.ZERO;

    public PayrollEntry() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public PayrollRun getPayrollRun() { return payrollRun; }
    public void setPayrollRun(PayrollRun payrollRun) { this.payrollRun = payrollRun; }

    public Long getCompanyId() { return companyId; }
    public void setCompanyId(Long companyId) { this.companyId = companyId; }

    public Long getEmployeeId() { return employeeId; }
    public void setEmployeeId(Long employeeId) { this.employeeId = employeeId; }

    public String getEmployeeName() { return employeeName; }
    public void setEmployeeName(String employeeName) { this.employeeName = employeeName; }

    public String getEmployeeCode() { return employeeCode; }
    public void setEmployeeCode(String employeeCode) { this.employeeCode = employeeCode; }

    public String getDesignation() { return designation; }
    public void setDesignation(String designation) { this.designation = designation; }

    public String getDepartment() { return department; }
    public void setDepartment(String department) { this.department = department; }

    public Integer getWorkingDays() { return workingDays; }
    public void setWorkingDays(Integer workingDays) { this.workingDays = workingDays; }

    public BigDecimal getPaidDays() { return paidDays; }
    public void setPaidDays(BigDecimal paidDays) { this.paidDays = paidDays; }

    public BigDecimal getBasicPay() { return basicPay; }
    public void setBasicPay(BigDecimal basicPay) { this.basicPay = basicPay; }

    public BigDecimal getHra() { return hra; }
    public void setHra(BigDecimal hra) { this.hra = hra; }

    public BigDecimal getAllowances() { return allowances; }
    public void setAllowances(BigDecimal allowances) { this.allowances = allowances; }

    public BigDecimal getGrossEarnings() { return grossEarnings; }
    public void setGrossEarnings(BigDecimal grossEarnings) { this.grossEarnings = grossEarnings; }

    public BigDecimal getPfEmployee() { return pfEmployee; }
    public void setPfEmployee(BigDecimal pfEmployee) { this.pfEmployee = pfEmployee; }

    public BigDecimal getEsiEmployee() { return esiEmployee; }
    public void setEsiEmployee(BigDecimal esiEmployee) { this.esiEmployee = esiEmployee; }

    public BigDecimal getProfessionalTax() { return professionalTax; }
    public void setProfessionalTax(BigDecimal professionalTax) { this.professionalTax = professionalTax; }

    public BigDecimal getTdsTax() { return tdsTax; }
    public void setTdsTax(BigDecimal tdsTax) { this.tdsTax = tdsTax; }

    public BigDecimal getOtherDeductions() { return otherDeductions; }
    public void setOtherDeductions(BigDecimal otherDeductions) { this.otherDeductions = otherDeductions; }

    public BigDecimal getTotalDeductions() { return totalDeductions; }
    public void setTotalDeductions(BigDecimal totalDeductions) { this.totalDeductions = totalDeductions; }

    public BigDecimal getNetSalary() { return netSalary; }
    public void setNetSalary(BigDecimal netSalary) { this.netSalary = netSalary; }

    public String getPaymentStatus() { return paymentStatus; }
    public void setPaymentStatus(String paymentStatus) { this.paymentStatus = paymentStatus; }

    public LocalDate getScheduledPayDate() { return scheduledPayDate; }
    public void setScheduledPayDate(LocalDate scheduledPayDate) { this.scheduledPayDate = scheduledPayDate; }

    public OffsetDateTime getDisbursedAt() { return disbursedAt; }
    public void setDisbursedAt(OffsetDateTime disbursedAt) { this.disbursedAt = disbursedAt; }

    public String getBankAccountMask() { return bankAccountMask; }
    public void setBankAccountMask(String bankAccountMask) { this.bankAccountMask = bankAccountMask; }

    public BigDecimal getAdvanceAmount() { return advanceAmount != null ? advanceAmount : BigDecimal.ZERO; }
    public void setAdvanceAmount(BigDecimal advanceAmount) { this.advanceAmount = advanceAmount; }

    public BigDecimal getAdvanceDeduction() { return advanceDeduction != null ? advanceDeduction : BigDecimal.ZERO; }
    public void setAdvanceDeduction(BigDecimal advanceDeduction) { this.advanceDeduction = advanceDeduction; }

    public Integer getPendingMonthsCount() { return pendingMonthsCount != null ? pendingMonthsCount : 1; }
    public void setPendingMonthsCount(Integer pendingMonthsCount) { this.pendingMonthsCount = pendingMonthsCount; }

    public String getPendingMonthsDetails() { return pendingMonthsDetails != null ? pendingMonthsDetails : ""; }
    public void setPendingMonthsDetails(String pendingMonthsDetails) { this.pendingMonthsDetails = pendingMonthsDetails; }

    public BigDecimal getCumulativePayable() { return cumulativePayable != null ? cumulativePayable : BigDecimal.ZERO; }
    public void setCumulativePayable(BigDecimal cumulativePayable) { this.cumulativePayable = cumulativePayable; }
}
