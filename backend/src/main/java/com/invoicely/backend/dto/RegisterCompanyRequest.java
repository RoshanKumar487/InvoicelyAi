package com.invoicely.backend.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class RegisterCompanyRequest {

    // User Details
    @NotBlank(message = "Full name is required")
    private String fullName;

    @NotBlank(message = "Email is required")
    @Email(message = "Email must be valid")
    private String email;

    @NotBlank(message = "Mobile number is required")
    private String mobile;

    @NotBlank(message = "Password is required")
    @Size(min = 6, message = "Password must be at least 6 characters")
    private String password;

    // Company Details
    @NotBlank(message = "Company name is required")
    private String companyName;

    private String details;
    private String gstin;
    private String location;
    private String signatureStampUrl;

    public RegisterCompanyRequest() {}

    // Getters and Setters
    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getMobile() { return mobile; }
    public void setMobile(String mobile) { this.mobile = mobile; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }

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
}
