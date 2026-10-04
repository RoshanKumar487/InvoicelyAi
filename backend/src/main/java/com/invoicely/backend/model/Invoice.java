package com.invoicely.backend.model;

import jakarta.persistence.*;
import java.math.BigDecimal;

@Entity
@Table(name = "invoices")
public class Invoice {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "company_id")
    private Long companyId;

    @Column(name = "created_by_user_id")
    private Long createdByUserId;

    @Column(name = "created_by_user_name")
    private String createdByUserName = "";

    @Column(name = "invoice_number", nullable = false, unique = true)
    private String invoiceNumber;

    @Column(name = "client_id")
    private Long clientId;

    @Column(name = "client_name", nullable = false)
    private String clientName;

    @Column(name = "client_company")
    private String clientCompany = "";

    @Column(name = "client_email")
    private String clientEmail = "";

    @Column(name = "client_phone")
    private String clientPhone = "";

    @Column(name = "client_address", columnDefinition = "TEXT")
    private String clientAddress = "";

    @Column(name = "client_tax_id")
    private String clientTaxId = "";

    @Column(name = "issue_date", nullable = false)
    private String issueDate; // YYYY-MM-DD

    @Column(name = "due_date", nullable = false)
    private String dueDate;   // YYYY-MM-DD

    @Column(name = "po_number")
    private String poNumber = "";

    @Column(name = "payment_terms")
    private String paymentTerms = "Net 30";

    @Column(name = "currency_code")
    private String currencyCode = "USD";

    @Column(name = "currency_symbol")
    private String currencySymbol = "$";

    @Column(name = "items_json", columnDefinition = "JSONB")
    private String itemsJson = "[]";

    @Column(columnDefinition = "TEXT")
    private String notes = "";

    @Column(columnDefinition = "TEXT")
    private String terms = "";

    @Column(name = "payment_instructions", columnDefinition = "TEXT")
    private String paymentInstructions = "";

    @Column(name = "tax_rate", precision = 5, scale = 2)
    private BigDecimal taxRate = BigDecimal.ZERO;

    @Column(name = "tax_label")
    private String taxLabel = "Tax";

    @Column(name = "tax_type")
    private String taxType = "GST";

    @Column(name = "is_tax_inclusive")
    private Boolean isTaxInclusive = false;

    @Column(name = "discount_percent", precision = 5, scale = 2)
    private BigDecimal discountPercent = BigDecimal.ZERO;

    @Column(name = "discount_amount", precision = 12, scale = 2)
    private BigDecimal discountAmount = BigDecimal.ZERO;

    @Column(name = "shipping_fee", precision = 12, scale = 2)
    private BigDecimal shippingFee = BigDecimal.ZERO;

    @Column(name = "additional_charges", precision = 12, scale = 2)
    private BigDecimal additionalCharges = BigDecimal.ZERO;

    @Column(name = "round_off", precision = 12, scale = 2)
    private BigDecimal roundOff = BigDecimal.ZERO;

    @Column(name = "amount_paid", precision = 12, scale = 2)
    private BigDecimal amountPaid = BigDecimal.ZERO;

    @Column(nullable = false)
    private String status = "Draft"; // Draft, Sent, Paid, Overdue, Cancelled

    @Column(name = "template_id")
    private String templateId = "modern";

    @Column(name = "docx_template_title")
    private String docxTemplateTitle = "INVOICE";

    @Column(name = "paid_date")
    private Long paidDate;

    @Column(name = "reminder_last_sent")
    private Long reminderLastSent;

    @Column(name = "shipping_details_json", columnDefinition = "JSONB")
    private String shippingDetailsJson = "{}";

    @Column(name = "custom_fields_json", columnDefinition = "JSONB")
    private String customFieldsJson = "{}";

    @Column(name = "item_columns_json", columnDefinition = "TEXT")
    private String itemColumnsJson = "";

    @Column(name = "created_at")
    private Long createdAt = System.currentTimeMillis();

    public Invoice() {}

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getInvoiceNumber() { return invoiceNumber; }
    public void setInvoiceNumber(String invoiceNumber) { this.invoiceNumber = invoiceNumber; }

    public Long getClientId() { return clientId; }
    public void setClientId(Long clientId) { this.clientId = clientId; }

    public String getClientName() { return clientName; }
    public void setClientName(String clientName) { this.clientName = clientName; }

    public String getClientCompany() { return clientCompany; }
    public void setClientCompany(String clientCompany) { this.clientCompany = clientCompany; }

    public String getClientEmail() { return clientEmail; }
    public void setClientEmail(String clientEmail) { this.clientEmail = clientEmail; }

    public String getClientPhone() { return clientPhone; }
    public void setClientPhone(String clientPhone) { this.clientPhone = clientPhone; }

    public String getClientAddress() { return clientAddress; }
    public void setClientAddress(String clientAddress) { this.clientAddress = clientAddress; }

    public String getClientTaxId() { return clientTaxId; }
    public void setClientTaxId(String clientTaxId) { this.clientTaxId = clientTaxId; }

    public String getIssueDate() { return issueDate; }
    public void setIssueDate(String issueDate) { this.issueDate = issueDate; }

    public String getDueDate() { return dueDate; }
    public void setDueDate(String dueDate) { this.dueDate = dueDate; }

    public String getPoNumber() { return poNumber; }
    public void setPoNumber(String poNumber) { this.poNumber = poNumber; }

    public String getPaymentTerms() { return paymentTerms; }
    public void setPaymentTerms(String paymentTerms) { this.paymentTerms = paymentTerms; }

    public String getCurrencyCode() { return currencyCode; }
    public void setCurrencyCode(String currencyCode) { this.currencyCode = currencyCode; }

    public String getCurrencySymbol() { return currencySymbol; }
    public void setCurrencySymbol(String currencySymbol) { this.currencySymbol = currencySymbol; }

    public String getItemsJson() { return itemsJson; }
    public void setItemsJson(String itemsJson) { this.itemsJson = itemsJson; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }

    public String getTerms() { return terms; }
    public void setTerms(String terms) { this.terms = terms; }

    public String getPaymentInstructions() { return paymentInstructions; }
    public void setPaymentInstructions(String paymentInstructions) { this.paymentInstructions = paymentInstructions; }

    public BigDecimal getTaxRate() { return taxRate; }
    public void setTaxRate(BigDecimal taxRate) { this.taxRate = taxRate; }

    public String getTaxLabel() { return taxLabel; }
    public void setTaxLabel(String taxLabel) { this.taxLabel = taxLabel; }

    public String getTaxType() { return taxType; }
    public void setTaxType(String taxType) { this.taxType = taxType; }

    public Boolean getIsTaxInclusive() { return isTaxInclusive; }
    public void setIsTaxInclusive(Boolean taxInclusive) { isTaxInclusive = taxInclusive; }

    public BigDecimal getDiscountPercent() { return discountPercent; }
    public void setDiscountPercent(BigDecimal discountPercent) { this.discountPercent = discountPercent; }

    public BigDecimal getDiscountAmount() { return discountAmount; }
    public void setDiscountAmount(BigDecimal discountAmount) { this.discountAmount = discountAmount; }

    public BigDecimal getShippingFee() { return shippingFee; }
    public void setShippingFee(BigDecimal shippingFee) { this.shippingFee = shippingFee; }

    public BigDecimal getAdditionalCharges() { return additionalCharges; }
    public void setAdditionalCharges(BigDecimal additionalCharges) { this.additionalCharges = additionalCharges; }

    public BigDecimal getRoundOff() { return roundOff; }
    public void setRoundOff(BigDecimal roundOff) { this.roundOff = roundOff; }

    public BigDecimal getAmountPaid() { return amountPaid; }
    public void setAmountPaid(BigDecimal amountPaid) { this.amountPaid = amountPaid; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getTemplateId() { return templateId; }
    public void setTemplateId(String templateId) { this.templateId = templateId; }

    public String getDocxTemplateTitle() { return docxTemplateTitle; }
    public void setDocxTemplateTitle(String docxTemplateTitle) { this.docxTemplateTitle = docxTemplateTitle; }

    public Long getPaidDate() { return paidDate; }
    public void setPaidDate(Long paidDate) { this.paidDate = paidDate; }

    public Long getReminderLastSent() { return reminderLastSent; }
    public void setReminderLastSent(Long reminderLastSent) { this.reminderLastSent = reminderLastSent; }

    public String getShippingDetailsJson() { return shippingDetailsJson; }
    public void setShippingDetailsJson(String shippingDetailsJson) { this.shippingDetailsJson = shippingDetailsJson; }

    public String getCustomFieldsJson() { return customFieldsJson; }
    public void setCustomFieldsJson(String customFieldsJson) { this.customFieldsJson = customFieldsJson; }

    public String getItemColumnsJson() { return itemColumnsJson; }
    public void setItemColumnsJson(String itemColumnsJson) { this.itemColumnsJson = itemColumnsJson; }

    public Long getCreatedAt() { return createdAt; }
    public void setCreatedAt(Long createdAt) { this.createdAt = createdAt; }

    public Long getCompanyId() { return companyId; }
    public void setCompanyId(Long companyId) { this.companyId = companyId; }

    public Long getCreatedByUserId() { return createdByUserId; }
    public void setCreatedByUserId(Long createdByUserId) { this.createdByUserId = createdByUserId; }

    public String getCreatedByUserName() { return createdByUserName; }
    public void setCreatedByUserName(String createdByUserName) { this.createdByUserName = createdByUserName; }
}
