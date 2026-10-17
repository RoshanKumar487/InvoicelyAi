package com.invoicely.backend.model;

import jakarta.persistence.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.OffsetDateTime;

@Entity
@Table(name = "invoice_templates", indexes = {
    @Index(name = "idx_invoice_templates_company_id", columnList = "company_id"),
    @Index(name = "idx_invoice_templates_org_code", columnList = "org_code"),
    @Index(name = "idx_invoice_templates_company_default", columnList = "company_id, is_default")
})
public class InvoiceTemplate {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "company_id")
    private Long companyId;

    @Column(name = "org_code")
    private String orgCode;

    @Column(name = "template_name", nullable = false)
    private String templateName = "Security Services — GST Invoice";

    @Column(name = "industry_preset")
    private String industryPreset = "security_agency";

    @Column(name = "status")
    private String status = "DRAFT"; // DRAFT, PUBLISHED, ARCHIVED

    @Column(name = "version")
    private Integer version = 1;

    @Column(name = "is_default")
    private Boolean isDefault = false;

    // Explicit boolean toggles for each template section
    @Column(name = "sec_branding_enabled")
    private Boolean secBrandingEnabled = true;

    @Column(name = "sec_invoice_details_enabled")
    private Boolean secInvoiceDetailsEnabled = true;

    @Column(name = "sec_bill_to_enabled")
    private Boolean secBillToEnabled = true;

    @Column(name = "sec_ship_to_enabled")
    private Boolean secShipToEnabled = false;

    @Column(name = "sec_services_enabled")
    private Boolean secServicesEnabled = true;

    @Column(name = "sec_tax_totals_enabled")
    private Boolean secTaxTotalsEnabled = true;

    @Column(name = "sec_bank_payment_enabled")
    private Boolean secBankPaymentEnabled = true;

    @Column(name = "sec_adjustments_enabled")
    private Boolean secAdjustmentsEnabled = false;

    @Column(name = "sec_terms_notes_enabled")
    private Boolean secTermsNotesEnabled = true;

    @Column(name = "sec_signature_enabled")
    private Boolean secSignatureEnabled = true;

    @Column(name = "letterhead_enabled")
    private Boolean letterheadEnabled = true;

    @Column(name = "show_qr_code")
    private Boolean showQrCode = true;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "configuration_json", columnDefinition = "JSONB")
    private String configurationJson = "{}";

    @Column(name = "settings_json", columnDefinition = "TEXT")
    private String settingsJson = "{}";

    @Column(name = "created_by_user_id")
    private Long createdByUserId;

    @Column(name = "updated_by_user_id")
    private Long updatedByUserId;

    @Column(name = "created_by")
    private String createdBy;

    @Column(name = "updated_by")
    private String updatedBy;

    @Column(name = "created_at")
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @Column(name = "updated_at")
    private OffsetDateTime updatedAt = OffsetDateTime.now();

    public InvoiceTemplate() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getCompanyId() { return companyId; }
    public void setCompanyId(Long companyId) { this.companyId = companyId; }

    public String getOrgCode() { return orgCode; }
    public void setOrgCode(String orgCode) { this.orgCode = orgCode; }

    public String getTemplateName() { return templateName; }
    public void setTemplateName(String templateName) { this.templateName = templateName; }

    public String getIndustryPreset() { return industryPreset; }
    public void setIndustryPreset(String industryPreset) { this.industryPreset = industryPreset; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Integer getVersion() { return version; }
    public void setVersion(Integer version) { this.version = version; }

    public Boolean getIsDefault() { return isDefault; }
    public void setIsDefault(Boolean isDefault) { this.isDefault = isDefault; }

    public Boolean getSecBrandingEnabled() { return secBrandingEnabled; }
    public void setSecBrandingEnabled(Boolean secBrandingEnabled) { this.secBrandingEnabled = secBrandingEnabled; }

    public Boolean getSecInvoiceDetailsEnabled() { return secInvoiceDetailsEnabled; }
    public void setSecInvoiceDetailsEnabled(Boolean secInvoiceDetailsEnabled) { this.secInvoiceDetailsEnabled = secInvoiceDetailsEnabled; }

    public Boolean getSecBillToEnabled() { return secBillToEnabled; }
    public void setSecBillToEnabled(Boolean secBillToEnabled) { this.secBillToEnabled = secBillToEnabled; }

    public Boolean getSecShipToEnabled() { return secShipToEnabled; }
    public void setSecShipToEnabled(Boolean secShipToEnabled) { this.secShipToEnabled = secShipToEnabled; }

    public Boolean getSecServicesEnabled() { return secServicesEnabled; }
    public void setSecServicesEnabled(Boolean secServicesEnabled) { this.secServicesEnabled = secServicesEnabled; }

    public Boolean getSecTaxTotalsEnabled() { return secTaxTotalsEnabled; }
    public void setSecTaxTotalsEnabled(Boolean secTaxTotalsEnabled) { this.secTaxTotalsEnabled = secTaxTotalsEnabled; }

    public Boolean getSecBankPaymentEnabled() { return secBankPaymentEnabled; }
    public void setSecBankPaymentEnabled(Boolean secBankPaymentEnabled) { this.secBankPaymentEnabled = secBankPaymentEnabled; }

    public Boolean getSecAdjustmentsEnabled() { return secAdjustmentsEnabled; }
    public void setSecAdjustmentsEnabled(Boolean secAdjustmentsEnabled) { this.secAdjustmentsEnabled = secAdjustmentsEnabled; }

    public Boolean getSecTermsNotesEnabled() { return secTermsNotesEnabled; }
    public void setSecTermsNotesEnabled(Boolean secTermsNotesEnabled) { this.secTermsNotesEnabled = secTermsNotesEnabled; }

    public Boolean getSecSignatureEnabled() { return secSignatureEnabled; }
    public void setSecSignatureEnabled(Boolean secSignatureEnabled) { this.secSignatureEnabled = secSignatureEnabled; }

    public Boolean getLetterheadEnabled() { return letterheadEnabled; }
    public void setLetterheadEnabled(Boolean letterheadEnabled) { this.letterheadEnabled = letterheadEnabled; }

    public Boolean getShowQrCode() { return showQrCode; }
    public void setShowQrCode(Boolean showQrCode) { this.showQrCode = showQrCode; }

    public String getConfigurationJson() { return configurationJson; }
    public void setConfigurationJson(String configurationJson) { this.configurationJson = configurationJson; }

    public String getSettingsJson() { return settingsJson; }
    public void setSettingsJson(String settingsJson) { this.settingsJson = settingsJson; }

    public Long getCreatedByUserId() { return createdByUserId; }
    public void setCreatedByUserId(Long createdByUserId) { this.createdByUserId = createdByUserId; }

    public Long getUpdatedByUserId() { return updatedByUserId; }
    public void setUpdatedByUserId(Long updatedByUserId) { this.updatedByUserId = updatedByUserId; }

    public String getCreatedBy() { return createdBy; }
    public void setCreatedBy(String createdBy) { this.createdBy = createdBy; }

    public String getUpdatedBy() { return updatedBy; }
    public void setUpdatedBy(String updatedBy) { this.updatedBy = updatedBy; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }

    public OffsetDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }
}
