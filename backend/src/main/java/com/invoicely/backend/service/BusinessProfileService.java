package com.invoicely.backend.service;

import com.invoicely.backend.model.BusinessProfile;
import com.invoicely.backend.model.Company;
import com.invoicely.backend.repository.BusinessProfileRepository;
import com.invoicely.backend.repository.CompanyRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;

@Service
public class BusinessProfileService {

    private final BusinessProfileRepository profileRepository;
    private final CompanyRepository companyRepository;

    @Autowired
    public BusinessProfileService(
            BusinessProfileRepository profileRepository,
            CompanyRepository companyRepository) {
        this.profileRepository = profileRepository;
        this.companyRepository = companyRepository;
    }

    public BusinessProfile getProfile() {
        return getProfile(null);
    }

    public BusinessProfile getProfile(Long companyId) {
        if (companyId != null) {
            return profileRepository.findFirstByCompanyId(companyId)
                    .orElseGet(() -> {
                        BusinessProfile defaultProfile = new BusinessProfile();
                        defaultProfile.setCompanyId(companyId);
                        companyRepository.findById(companyId).ifPresent(company -> {
                            if (company.getCompanyName() != null && !company.getCompanyName().isBlank()) {
                                defaultProfile.setBusinessName(company.getCompanyName());
                                defaultProfile.setLegalName(company.getCompanyName());
                            }
                            if (company.getEmail() != null) defaultProfile.setEmail(company.getEmail());
                            if (company.getPhone() != null) defaultProfile.setPhone(company.getPhone());
                            if (company.getWebsite() != null) defaultProfile.setWebsite(company.getWebsite());
                            if (company.getLocation() != null) defaultProfile.setAddress(company.getLocation());
                            if (company.getGstin() != null) defaultProfile.setGstin(company.getGstin());
                            if (company.getSignatureStampUrl() != null) defaultProfile.setStampUrl(company.getSignatureStampUrl());
                        });
                        return profileRepository.save(defaultProfile);
                    });
        }

        return profileRepository.findFirstByOrderByIdAsc()
                .orElseGet(() -> {
                    BusinessProfile defaultProfile = new BusinessProfile();
                    return profileRepository.save(defaultProfile);
                });
    }

    @Transactional
    public BusinessProfile updateProfile(BusinessProfile incoming) {
        return updateProfile(incoming, incoming.getCompanyId());
    }

    @Transactional
    public BusinessProfile updateProfile(BusinessProfile incoming, Long companyId) {
        BusinessProfile existing = getProfile(companyId);

        if (companyId != null) {
            existing.setCompanyId(companyId);
        }

        if (incoming.getBusinessName() != null && !incoming.getBusinessName().isBlank()) {
            existing.setBusinessName(incoming.getBusinessName().trim());
        }
        if (incoming.getLegalName() != null && !incoming.getLegalName().isBlank()) {
            existing.setLegalName(incoming.getLegalName().trim());
        } else if (existing.getBusinessName() != null) {
            existing.setLegalName(existing.getBusinessName());
        }
        if (incoming.getEmail() != null) existing.setEmail(incoming.getEmail());
        if (incoming.getPhone() != null) existing.setPhone(incoming.getPhone());
        if (incoming.getWebsite() != null) existing.setWebsite(incoming.getWebsite());
        if (incoming.getAddress() != null) existing.setAddress(incoming.getAddress());
        if (incoming.getTaxId() != null) existing.setTaxId(incoming.getTaxId());
        if (incoming.getGstin() != null) existing.setGstin(incoming.getGstin());
        if (incoming.getPanNumber() != null) existing.setPanNumber(incoming.getPanNumber());
        if (incoming.getPlaceOfSupply() != null) existing.setPlaceOfSupply(incoming.getPlaceOfSupply());
        if (incoming.getUpiId() != null) existing.setUpiId(incoming.getUpiId());
        if (incoming.getBankName() != null) existing.setBankName(incoming.getBankName());
        if (incoming.getAccountHolder() != null) existing.setAccountHolder(incoming.getAccountHolder());
        if (incoming.getAccountNumber() != null) existing.setAccountNumber(incoming.getAccountNumber());
        if (incoming.getIfscCode() != null) existing.setIfscCode(incoming.getIfscCode());
        if (incoming.getRoutingNumber() != null) existing.setRoutingNumber(incoming.getRoutingNumber());
        if (incoming.getSwiftBic() != null) existing.setSwiftBic(incoming.getSwiftBic());
        if (incoming.getPaymentLink() != null) existing.setPaymentLink(incoming.getPaymentLink());
        if (incoming.getDefaultCurrency() != null) existing.setDefaultCurrency(incoming.getDefaultCurrency());
        if (incoming.getDefaultCurrencySymbol() != null) existing.setDefaultCurrencySymbol(incoming.getDefaultCurrencySymbol());
        if (incoming.getDefaultCurrencyFormat() != null) existing.setDefaultCurrencyFormat(incoming.getDefaultCurrencyFormat());
        if (incoming.getDefaultTaxRate() != null) existing.setDefaultTaxRate(incoming.getDefaultTaxRate());
        if (incoming.getDefaultTaxLabel() != null) existing.setDefaultTaxLabel(incoming.getDefaultTaxLabel());
        if (incoming.getDefaultPaymentTerms() != null) existing.setDefaultPaymentTerms(incoming.getDefaultPaymentTerms());
        if (incoming.getDefaultNotes() != null) existing.setDefaultNotes(incoming.getDefaultNotes());
        if (incoming.getDefaultTerms() != null) existing.setDefaultTerms(incoming.getDefaultTerms());
        if (incoming.getSigneeName() != null) existing.setSigneeName(incoming.getSigneeName());
        if (incoming.getSigneeTitle() != null) existing.setSigneeTitle(incoming.getSigneeTitle());
        if (incoming.getBrandColorHex() != null) existing.setBrandColorHex(incoming.getBrandColorHex());
        if (incoming.getLogoUrl() != null) existing.setLogoUrl(incoming.getLogoUrl());
        if (incoming.getStampUrl() != null) existing.setStampUrl(incoming.getStampUrl());
        if (incoming.getSignatureUrl() != null) existing.setSignatureUrl(incoming.getSignatureUrl());
        if (incoming.getQrCodeUrl() != null) existing.setQrCodeUrl(incoming.getQrCodeUrl());
        if (incoming.getLetterheadJson() != null) existing.setLetterheadJson(incoming.getLetterheadJson());
        if (incoming.getInvoiceSettingsJson() != null) existing.setInvoiceSettingsJson(incoming.getInvoiceSettingsJson());
        existing.setUpdatedAt(OffsetDateTime.now());

        BusinessProfile saved = profileRepository.save(existing);

        // Sync Company entity name and contact info while preserving companyCode
        Long targetCompanyId = saved.getCompanyId();
        if (targetCompanyId != null) {
            companyRepository.findById(targetCompanyId).ifPresent(company -> {
                if (saved.getBusinessName() != null && !saved.getBusinessName().isBlank()
                        && !"Apex Nova Dynamics".equalsIgnoreCase(saved.getBusinessName().trim())) {
                    company.setCompanyName(saved.getBusinessName().trim());
                }
                if (saved.getGstin() != null) company.setGstin(saved.getGstin());
                if (saved.getAddress() != null) company.setLocation(saved.getAddress());
                if (saved.getEmail() != null) company.setEmail(saved.getEmail());
                if (saved.getPhone() != null) company.setPhone(saved.getPhone());
                if (saved.getWebsite() != null) company.setWebsite(saved.getWebsite());
                if (saved.getStampUrl() != null && !saved.getStampUrl().isBlank()) {
                    company.setSignatureStampUrl(saved.getStampUrl());
                }
                companyRepository.save(company);
            });
        }

        return saved;
    }
}
