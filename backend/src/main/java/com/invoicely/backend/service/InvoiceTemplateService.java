package com.invoicely.backend.service;

import com.invoicely.backend.model.InvoiceTemplate;
import com.invoicely.backend.repository.InvoiceTemplateRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;

@Service
public class InvoiceTemplateService {

    private final InvoiceTemplateRepository templateRepository;

    @Autowired
    public InvoiceTemplateService(InvoiceTemplateRepository templateRepository) {
        this.templateRepository = templateRepository;
    }

    public List<InvoiceTemplate> getTemplates(Long companyId) {
        return templateRepository.findByCompanyIdOrderByUpdatedAtDesc(companyId);
    }

    public InvoiceTemplate getTemplateById(Long id, Long companyId) {
        return templateRepository.findByIdAndCompanyId(id, companyId)
                .orElseThrow(() -> new RuntimeException("Invoice template not found with ID: " + id));
    }

    public InvoiceTemplate getActiveOrDefaultTemplate(Long companyId) {
        return templateRepository.findFirstByCompanyIdAndIsDefaultTrue(companyId)
                .or(() -> templateRepository.findFirstByCompanyIdAndStatus(companyId, "PUBLISHED"))
                .or(() -> templateRepository.findByCompanyIdOrderByUpdatedAtDesc(companyId).stream().findFirst())
                .orElse(null);
    }

    @Transactional
    public InvoiceTemplate saveDraft(InvoiceTemplate template, Long companyId, Long userId) {
        if (template.getId() != null) {
            InvoiceTemplate existing = getTemplateById(template.getId(), companyId);
            existing.setTemplateName(template.getTemplateName());
            existing.setIndustryPreset(template.getIndustryPreset());
            existing.setConfigurationJson(template.getConfigurationJson());
            existing.setVersion(existing.getVersion() != null ? existing.getVersion() + 1 : 1);
            existing.setUpdatedAt(OffsetDateTime.now());
            return templateRepository.save(existing);
        } else {
            template.setCompanyId(companyId);
            template.setCreatedByUserId(userId);
            template.setStatus("DRAFT");
            template.setVersion(1);
            template.setCreatedAt(OffsetDateTime.now());
            template.setUpdatedAt(OffsetDateTime.now());
            return templateRepository.save(template);
        }
    }

    @Transactional
    public InvoiceTemplate publishTemplate(Long id, Long companyId, Long userId) {
        InvoiceTemplate template = getTemplateById(id, companyId);
        template.setStatus("PUBLISHED");
        template.setIsDefault(true);
        template.setVersion(template.getVersion() != null ? template.getVersion() + 1 : 1);
        template.setUpdatedAt(OffsetDateTime.now());

        // Reset previous default if any
        templateRepository.findFirstByCompanyIdAndIsDefaultTrue(companyId)
                .filter(other -> !other.getId().equals(template.getId()))
                .ifPresent(other -> {
                    other.setIsDefault(false);
                    templateRepository.save(other);
                });

        return templateRepository.save(template);
    }

    @Transactional
    public void deleteTemplate(Long id, Long companyId) {
        InvoiceTemplate template = getTemplateById(id, companyId);
        templateRepository.delete(template);
    }
}
