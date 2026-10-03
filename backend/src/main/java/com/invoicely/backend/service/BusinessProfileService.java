package com.invoicely.backend.service;

import com.invoicely.backend.model.BusinessProfile;
import com.invoicely.backend.repository.BusinessProfileRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;

@Service
public class BusinessProfileService {

    private final BusinessProfileRepository profileRepository;

    @Autowired
    public BusinessProfileService(BusinessProfileRepository profileRepository) {
        this.profileRepository = profileRepository;
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
        
        existing.setBusinessName(incoming.getBusinessName());
        existing.setLegalName(incoming.getLegalName());
        existing.setEmail(incoming.getEmail());
        existing.setPhone(incoming.getPhone());
        existing.setWebsite(incoming.getWebsite());
        existing.setAddress(incoming.getAddress());
        existing.setTaxId(incoming.getTaxId());
        existing.setGstin(incoming.getGstin());
        existing.setPanNumber(incoming.getPanNumber());
        existing.setPlaceOfSupply(incoming.getPlaceOfSupply());
        existing.setUpiId(incoming.getUpiId());
        existing.setBankName(incoming.getBankName());
        existing.setAccountHolder(incoming.getAccountHolder());
        existing.setAccountNumber(incoming.getAccountNumber());
        existing.setIfscCode(incoming.getIfscCode());
        existing.setRoutingNumber(incoming.getRoutingNumber());
        existing.setSwiftBic(incoming.getSwiftBic());
        existing.setPaymentLink(incoming.getPaymentLink());
        existing.setDefaultCurrency(incoming.getDefaultCurrency());
        existing.setDefaultCurrencySymbol(incoming.getDefaultCurrencySymbol());
        existing.setDefaultCurrencyFormat(incoming.getDefaultCurrencyFormat());
        existing.setDefaultTaxRate(incoming.getDefaultTaxRate());
        existing.setDefaultTaxLabel(incoming.getDefaultTaxLabel());
        existing.setDefaultPaymentTerms(incoming.getDefaultPaymentTerms());
        existing.setDefaultNotes(incoming.getDefaultNotes());
        existing.setDefaultTerms(incoming.getDefaultTerms());
        existing.setSigneeName(incoming.getSigneeName());
        existing.setSigneeTitle(incoming.getSigneeTitle());
        existing.setBrandColorHex(incoming.getBrandColorHex());
        existing.setUpdatedAt(OffsetDateTime.now());

        return profileRepository.save(existing);
    }
}
