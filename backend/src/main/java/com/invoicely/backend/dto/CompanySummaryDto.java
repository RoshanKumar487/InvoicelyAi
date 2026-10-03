package com.invoicely.backend.dto;

import com.invoicely.backend.model.Company;

public class CompanySummaryDto {
    private Long id;
    private String companyCode;
    private String companyName;
    private String details;
    private String gstin;
    private String location;
    private String signatureStampUrl;
    private String email;
    private String phone;
    private String website;

    public CompanySummaryDto() {}

    public CompanySummaryDto(Company company) {
        if (company != null) {
            this.id = company.getId();
            this.companyCode = company.getCompanyCode();
            this.companyName = company.getCompanyName();
            this.details = company.getDetails();
            this.gstin = company.getGstin();
            this.location = company.getLocation();
            this.signatureStampUrl = company.getSignatureStampUrl();
            this.email = company.getEmail();
            this.phone = company.getPhone();
            this.website = company.getWebsite();
        }
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getCompanyCode() { return companyCode; }
    public void setCompanyCode(String companyCode) { this.companyCode = companyCode; }

    public String getCompanyName() { return companyName; }
    public void setCompanyName(String companyName) { this.companyName = companyName; }

    public String getDetails() { return details; }
    public void setDetails(String details) { this.details = details; }

    public String getGstin() { return gstin; }
    public void setGstin(String gstin) { this.gstin = gstin; }

    public String getLocation() { return location; }
    public void setLocation(String location) { this.location = location; }

    public String getSignatureStampUrl() { return signatureStampUrl; }
    public void setSignatureStampUrl(String signatureStampUrl) { this.signatureStampUrl = signatureStampUrl; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getWebsite() { return website; }
    public void setWebsite(String website) { this.website = website; }
}
