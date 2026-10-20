package com.invoicely.backend.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.OffsetDateTime;

@Entity
@Table(name = "expenses", indexes = {
    @Index(name = "idx_expenses_company_id", columnList = "company_id"),
    @Index(name = "idx_expenses_company_user", columnList = "company_id, created_by_user_id"),
    @Index(name = "idx_expenses_company_category", columnList = "company_id, category"),
    @Index(name = "idx_expenses_company_status", columnList = "company_id, status")
})
public class Expense {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "company_id")
    private Long companyId;

    @Column(name = "created_by_user_id")
    private Long createdByUserId;

    @Column(name = "created_by_user_name")
    private String createdByUserName = "";

    @Column(nullable = false)
    private String title;

    private String category = "General";

    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal amount = BigDecimal.ZERO;

    private String currency = "USD";

    @Column(name = "currency_symbol")
    private String currencySymbol = "$";

    private String date = "";
    private String vendor = "";

    @Column(name = "payment_method")
    private String paymentMethod = "Credit Card";

    @Column(name = "tax_deductible")
    private Boolean taxDeductible = true;

    @Column(name = "tax_amount", precision = 12, scale = 2)
    private BigDecimal taxAmount = BigDecimal.ZERO;

    @Column(name = "receipt_image_uri", columnDefinition = "TEXT")
    private String receiptImageUri;

    @Column(name = "status")
    private String status = "Paid";

    @Column(name = "due_date")
    private String dueDate = "";

    @Column(columnDefinition = "TEXT")
    private String notes = "";

    @Column(name = "employee_id")
    private Long employeeId;

    @Column(name = "employee_name")
    private String employeeName;

    @Column(name = "is_salary_advance")
    private Boolean isSalaryAdvance = false;

    @Column(name = "advance_settled")
    private Boolean advanceSettled = false;

    @Column(name = "settled_payroll_run_id")
    private Long settledPayrollRunId;

    @Column(name = "created_at")
    private OffsetDateTime createdAt = OffsetDateTime.now();

    public Expense() {}

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }

    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }

    public String getCurrencySymbol() { return currencySymbol; }
    public void setCurrencySymbol(String currencySymbol) { this.currencySymbol = currencySymbol; }

    public String getDate() { return date; }
    public void setDate(String date) { this.date = date; }

    public String getVendor() { return vendor; }
    public void setVendor(String vendor) { this.vendor = vendor; }

    public String getPaymentMethod() { return paymentMethod; }
    public void setPaymentMethod(String paymentMethod) { this.paymentMethod = paymentMethod; }

    public Boolean getTaxDeductible() { return taxDeductible; }
    public void setTaxDeductible(Boolean taxDeductible) { this.taxDeductible = taxDeductible; }

    public BigDecimal getTaxAmount() { return taxAmount; }
    public void setTaxAmount(BigDecimal taxAmount) { this.taxAmount = taxAmount; }

    public String getReceiptImageUri() { return receiptImageUri; }
    public void setReceiptImageUri(String receiptImageUri) { this.receiptImageUri = receiptImageUri; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }

    public Long getCompanyId() { return companyId; }
    public void setCompanyId(Long companyId) { this.companyId = companyId; }

    public Long getCreatedByUserId() { return createdByUserId; }
    public void setCreatedByUserId(Long createdByUserId) { this.createdByUserId = createdByUserId; }

    public String getCreatedByUserName() { return createdByUserName; }
    public void setCreatedByUserName(String createdByUserName) { this.createdByUserName = createdByUserName; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getDueDate() { return dueDate; }
    public void setDueDate(String dueDate) { this.dueDate = dueDate; }

    public Long getEmployeeId() { return employeeId; }
    public void setEmployeeId(Long employeeId) { this.employeeId = employeeId; }

    public String getEmployeeName() { return employeeName; }
    public void setEmployeeName(String employeeName) { this.employeeName = employeeName; }

    public Boolean getIsSalaryAdvance() { return isSalaryAdvance != null ? isSalaryAdvance : false; }
    public void setIsSalaryAdvance(Boolean isSalaryAdvance) { this.isSalaryAdvance = isSalaryAdvance; }

    public Boolean getAdvanceSettled() { return advanceSettled != null ? advanceSettled : false; }
    public void setAdvanceSettled(Boolean advanceSettled) { this.advanceSettled = advanceSettled; }

    public Long getSettledPayrollRunId() { return settledPayrollRunId; }
    public void setSettledPayrollRunId(Long settledPayrollRunId) { this.settledPayrollRunId = settledPayrollRunId; }
}
