package com.invoicely.backend.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.OffsetDateTime;

@Entity
@Table(name = "business_profile")
public class BusinessProfile {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "company_id")
    private Long companyId;

    @Column(name = "business_name", nullable = false)
    private String businessName = "Apex Nova Dynamics";

    @Column(name = "legal_name")
    private String legalName = "Apex Nova Dynamics LLC";

    private String email = "billing@apexnova.io";
    private String phone = "";
    private String website = "";

    @Column(columnDefinition = "TEXT")
    private String address = "";

    @Column(name = "tax_id")
    private String taxId = "";

    private String gstin = "";

    @Column(name = "pan_number")
    private String panNumber = "";

    @Column(name = "place_of_supply")
    private String placeOfSupply = "";

    @Column(name = "upi_id")
    private String upiId = "";

    @Column(name = "bank_name")
    private String bankName = "";

    @Column(name = "account_holder")
    private String accountHolder = "";

    @Column(name = "account_number")
    private String accountNumber = "";

    @Column(name = "ifsc_code")
    private String ifscCode = "";

    @Column(name = "routing_number")
    private String routingNumber = "";

    @Column(name = "swift_bic")
    private String swiftBic = "";

    @Column(name = "payment_link", columnDefinition = "TEXT")
    private String paymentLink = "";

    @Column(name = "default_currency")
    private String defaultCurrency = "USD";

    @Column(name = "default_currency_symbol")
    private String defaultCurrencySymbol = "$";

    @Column(name = "default_currency_format")
    private String defaultCurrencyFormat = "before";

    @Column(name = "default_tax_rate", precision = 5, scale = 2)
    private BigDecimal defaultTaxRate = BigDecimal.ZERO;

    @Column(name = "default_tax_label")
    private String defaultTaxLabel = "Tax";

    @Column(name = "default_payment_terms")
    private String defaultPaymentTerms = "Net 30";

    @Column(name = "default_notes", columnDefinition = "TEXT")
    private String defaultNotes = "";

    @Column(name = "default_terms", columnDefinition = "TEXT")
    private String defaultTerms = "";

    @Column(name = "signee_name")
    private String signeeName = "";

    @Column(name = "signee_title")
    private String signeeTitle = "";

    @Column(name = "brand_color_hex")
    private String brandColorHex = "#1E3A8A";

    @Column(name = "updated_at")
    private OffsetDateTime updatedAt = OffsetDateTime.now();

    public BusinessProfile() {}

    // Getters and Setters
    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public String getBusinessName() { return businessName; }
    public void setBusinessName(String businessName) { this.businessName = businessName; }

    public String getLegalName() { return legalName; }
    public void setLegalName(String legalName) { this.legalName = legalName; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getWebsite() { return website; }
    public void setWebsite(String website) { this.website = website; }

    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }

    public String getTaxId() { return taxId; }
    public void setTaxId(String taxId) { this.taxId = taxId; }

    public String getGstin() { return gstin; }
    public void setGstin(String gstin) { this.gstin = gstin; }

    public String getPanNumber() { return panNumber; }
    public void setPanNumber(String panNumber) { this.panNumber = panNumber; }

    public String getPlaceOfSupply() { return placeOfSupply; }
    public void setPlaceOfSupply(String placeOfSupply) { this.placeOfSupply = placeOfSupply; }

    public String getUpiId() { return upiId; }
    public void setUpiId(String upiId) { this.upiId = upiId; }

    public String getBankName() { return bankName; }
    public void setBankName(String bankName) { this.bankName = bankName; }

    public String getAccountHolder() { return accountHolder; }
    public void setAccountHolder(String accountHolder) { this.accountHolder = accountHolder; }

    public String getAccountNumber() { return accountNumber; }
    public void setAccountNumber(String accountNumber) { this.accountNumber = accountNumber; }

    public String getIfscCode() { return ifscCode; }
    public void setIfscCode(String ifscCode) { this.ifscCode = ifscCode; }

    public String getRoutingNumber() { return routingNumber; }
    public void setRoutingNumber(String routingNumber) { this.routingNumber = routingNumber; }

    public String getSwiftBic() { return swiftBic; }
    public void setSwiftBic(String swiftBic) { this.swiftBic = swiftBic; }

    public String getPaymentLink() { return paymentLink; }
    public void setPaymentLink(String paymentLink) { this.paymentLink = paymentLink; }

    public String getDefaultCurrency() { return defaultCurrency; }
    public void setDefaultCurrency(String defaultCurrency) { this.defaultCurrency = defaultCurrency; }

    public String getDefaultCurrencySymbol() { return defaultCurrencySymbol; }
    public void setDefaultCurrencySymbol(String defaultCurrencySymbol) { this.defaultCurrencySymbol = defaultCurrencySymbol; }

    public String getDefaultCurrencyFormat() { return defaultCurrencyFormat; }
    public void setDefaultCurrencyFormat(String defaultCurrencyFormat) { this.defaultCurrencyFormat = defaultCurrencyFormat; }

    public BigDecimal getDefaultTaxRate() { return defaultTaxRate; }
    public void setDefaultTaxRate(BigDecimal defaultTaxRate) { this.defaultTaxRate = defaultTaxRate; }

    public String getDefaultTaxLabel() { return defaultTaxLabel; }
    public void setDefaultTaxLabel(String defaultTaxLabel) { this.defaultTaxLabel = defaultTaxLabel; }

    public String getDefaultPaymentTerms() { return defaultPaymentTerms; }
    public void setDefaultPaymentTerms(String defaultPaymentTerms) { this.defaultPaymentTerms = defaultPaymentTerms; }

    public String getDefaultNotes() { return defaultNotes; }
    public void setDefaultNotes(String defaultNotes) { this.defaultNotes = defaultNotes; }

    public String getDefaultTerms() { return defaultTerms; }
    public void setDefaultTerms(String defaultTerms) { this.defaultTerms = defaultTerms; }

    public String getSigneeName() { return signeeName; }
    public void setSigneeName(String signeeName) { this.signeeName = signeeName; }

    public String getSigneeTitle() { return signeeTitle; }
    public void setSigneeTitle(String signeeTitle) { this.signeeTitle = signeeTitle; }

    public String getBrandColorHex() { return brandColorHex; }
    public void setBrandColorHex(String brandColorHex) { this.brandColorHex = brandColorHex; }

    public OffsetDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }

    public Long getCompanyId() { return companyId; }
    public void setCompanyId(Long companyId) { this.companyId = companyId; }
}
