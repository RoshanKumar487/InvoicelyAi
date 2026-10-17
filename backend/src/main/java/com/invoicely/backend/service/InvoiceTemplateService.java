package com.invoicely.backend.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.invoicely.backend.model.BusinessProfile;
import com.invoicely.backend.model.Company;
import com.invoicely.backend.model.InvoiceTemplate;
import com.invoicely.backend.repository.BusinessProfileRepository;
import com.invoicely.backend.repository.CompanyRepository;
import com.invoicely.backend.repository.InvoiceTemplateRepository;
import com.invoicely.backend.security.UserPrincipal;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
public class InvoiceTemplateService {

    private final InvoiceTemplateRepository templateRepository;
    private final CompanyRepository companyRepository;
    private final BusinessProfileRepository businessProfileRepository;
    private final ObjectMapper objectMapper;

    @Autowired
    public InvoiceTemplateService(
            InvoiceTemplateRepository templateRepository,
            CompanyRepository companyRepository,
            BusinessProfileRepository businessProfileRepository,
            ObjectMapper objectMapper) {
        this.templateRepository = templateRepository;
        this.companyRepository = companyRepository;
        this.businessProfileRepository = businessProfileRepository;
        this.objectMapper = objectMapper;
    }

    public List<InvoiceTemplate> getTemplates(Long companyId) {
        return templateRepository.findByCompanyIdOrderByUpdatedAtDesc(companyId);
    }

    public InvoiceTemplate getTemplateById(Long id, Long companyId) {
        return templateRepository.findByIdAndCompanyId(id, companyId)
                .orElseThrow(() -> new RuntimeException("Invoice template not found with ID: " + id));
    }

    public InvoiceTemplate getActiveOrDefaultTemplate(Long companyId) {
        String orgCode = resolveOrgCode(companyId, null);
        if (orgCode != null && !orgCode.isBlank()) {
            Optional<InvoiceTemplate> byOrg = templateRepository.findFirstByOrgCodeOrderByUpdatedAtDesc(orgCode);
            if (byOrg.isPresent()) {
                return byOrg.get();
            }
        }
        return templateRepository.findFirstByCompanyIdAndIsDefaultTrue(companyId)
                .or(() -> templateRepository.findFirstByCompanyIdAndStatus(companyId, "PUBLISHED"))
                .or(() -> templateRepository.findFirstByCompanyIdOrderByUpdatedAtDesc(companyId))
                .orElse(null);
    }

    @Transactional
    public InvoiceTemplate getOrCreateSettings(Long companyId, String requestedOrgCode, UserPrincipal principal) {
        String orgCode = resolveOrgCode(companyId, requestedOrgCode);
        Optional<InvoiceTemplate> existing = Optional.empty();
        if (orgCode != null && !orgCode.isBlank()) {
            existing = templateRepository.findFirstByOrgCodeOrderByUpdatedAtDesc(orgCode);
        }
        if (existing.isEmpty() && companyId != null) {
            existing = templateRepository.findFirstByCompanyIdOrderByUpdatedAtDesc(companyId);
        }
        if (existing.isPresent()) {
            InvoiceTemplate found = existing.get();
            if ((found.getOrgCode() == null || found.getOrgCode().isBlank()) && orgCode != null) {
                found.setOrgCode(orgCode);
                templateRepository.save(found);
            }
            return found;
        }

        InvoiceTemplate created = new InvoiceTemplate();
        created.setCompanyId(companyId);
        created.setOrgCode(orgCode);
        created.setTemplateName("Organization Default Template");
        created.setIndustryPreset("SECURITY_SERVICES");
        created.setStatus("PUBLISHED");
        created.setIsDefault(true);
        created.setVersion(1);
        String actor = formatActor(principal);
        Long userId = principal != null ? principal.getId() : null;
        created.setCreatedBy(actor);
        created.setUpdatedBy(actor);
        created.setCreatedByUserId(userId);
        created.setUpdatedByUserId(userId);
        created.setCreatedAt(OffsetDateTime.now());
        created.setUpdatedAt(OffsetDateTime.now());

        if (companyId != null) {
            businessProfileRepository.findFirstByCompanyId(companyId).ifPresent(bp -> {
                if (bp.getInvoiceSettingsJson() != null && !bp.getInvoiceSettingsJson().isBlank()) {
                    created.setSettingsJson(bp.getInvoiceSettingsJson());
                    created.setConfigurationJson(bp.getInvoiceSettingsJson());
                }
            });
        }

        return templateRepository.save(created);
    }

    @Transactional
    @SuppressWarnings("unchecked")
    public InvoiceTemplate upsertSettings(Map<String, Object> payload, Long companyId, UserPrincipal principal) {
        String requestedOrgCode = payload.get("orgCode") != null ? String.valueOf(payload.get("orgCode")) : null;
        String orgCode = resolveOrgCode(companyId, requestedOrgCode);
        String actor = formatActor(principal);
        Long userId = principal != null ? principal.getId() : null;

        Optional<InvoiceTemplate> existingOpt = Optional.empty();
        if (orgCode != null && !orgCode.isBlank()) {
            existingOpt = templateRepository.findFirstByOrgCodeOrderByUpdatedAtDesc(orgCode);
        }
        if (existingOpt.isEmpty() && companyId != null) {
            existingOpt = templateRepository.findFirstByCompanyIdOrderByUpdatedAtDesc(companyId);
        }

        InvoiceTemplate template = existingOpt.orElseGet(() -> {
            InvoiceTemplate fresh = new InvoiceTemplate();
            fresh.setCompanyId(companyId);
            fresh.setOrgCode(orgCode);
            fresh.setCreatedBy(actor);
            fresh.setCreatedByUserId(userId);
            fresh.setCreatedAt(OffsetDateTime.now());
            fresh.setVersion(1);
            fresh.setIsDefault(true);
            fresh.setStatus("PUBLISHED");
            return fresh;
        });

        if (template.getCompanyId() == null && companyId != null) {
            template.setCompanyId(companyId);
        }
        if (orgCode != null && !orgCode.isBlank()) {
            template.setOrgCode(orgCode);
        }
        if (template.getCreatedBy() == null || template.getCreatedBy().isBlank()) {
            template.setCreatedBy(actor);
        }
        if (template.getCreatedByUserId() == null && userId != null) {
            template.setCreatedByUserId(userId);
        }
        template.setUpdatedBy(actor);
        template.setUpdatedByUserId(userId);
        template.setUpdatedAt(OffsetDateTime.now());
        template.setVersion(template.getVersion() != null ? template.getVersion() + 1 : 1);

        String name = payload.get("templateName") != null
                ? String.valueOf(payload.get("templateName"))
                : (payload.get("name") != null ? String.valueOf(payload.get("name")) : template.getTemplateName());
        if (name != null && !name.isBlank()) {
            template.setTemplateName(name);
        } else if (template.getTemplateName() == null || template.getTemplateName().isBlank()) {
            template.setTemplateName("Organization Default Template");
        }

        if (payload.get("industryPreset") != null) {
            template.setIndustryPreset(String.valueOf(payload.get("industryPreset")));
        }
        if (payload.get("status") != null) {
            template.setStatus(String.valueOf(payload.get("status")));
        } else if (template.getStatus() == null) {
            template.setStatus("PUBLISHED");
        }
        template.setIsDefault(true);

        // Extract section boolean flags from top-level payload, sectionBooleans map, and sections array
        applySectionBooleans(template, payload);

        try {
            if (payload.get("configurationJson") instanceof String configStr && !configStr.isBlank()) {
                template.setConfigurationJson(configStr);
            } else if (payload.get("sections") != null) {
                template.setConfigurationJson(objectMapper.writeValueAsString(payload.get("sections")));
            }

            if (payload.get("settingsJson") instanceof String settingsStr && !settingsStr.isBlank()) {
                template.setSettingsJson(settingsStr);
            } else {
                // Exclude any binary document fields while preserving full user customization JSON
                Map<String, Object> sanitized = new java.util.LinkedHashMap<>(payload);
                sanitized.remove("fileBytes");
                sanitized.remove("docxBytes");
                sanitized.remove("templateDocument");
                sanitized.put("orgCode", template.getOrgCode());
                sanitized.put("createdBy", template.getCreatedBy());
                sanitized.put("updatedBy", template.getUpdatedBy());
                template.setSettingsJson(objectMapper.writeValueAsString(sanitized));
            }
        } catch (Exception ignored) {
        }

        InvoiceTemplate saved = templateRepository.save(template);

        // Sync BusinessProfile.invoiceSettingsJson for this company so both sources stay identical
        if (companyId != null && saved.getSettingsJson() != null) {
            businessProfileRepository.findFirstByCompanyId(companyId).ifPresent(bp -> {
                bp.setInvoiceSettingsJson(saved.getSettingsJson());
                bp.setUpdatedAt(OffsetDateTime.now());
                businessProfileRepository.save(bp);
            });
        }

        return saved;
    }

    @SuppressWarnings("unchecked")
    private void applySectionBooleans(InvoiceTemplate template, Map<String, Object> payload) {
        Map<String, Object> sectionMap = null;
        if (payload.get("sectionBooleans") instanceof Map<?, ?> m) {
            sectionMap = (Map<String, Object>) m;
        }

        // First inspect sections list if provided
        if (payload.get("sections") instanceof List<?> sectionsList) {
            for (Object item : sectionsList) {
                if (item instanceof Map<?, ?> sec) {
                    String id = sec.get("id") != null ? String.valueOf(sec.get("id")) : "";
                    boolean enabled = parseBool(sec.get("isEnabled"), true);
                    setSectionFlagById(template, id, enabled);
                }
            }
        }

        // Next check explicit sectionBooleans map
        if (sectionMap != null) {
            for (Map.Entry<String, Object> entry : sectionMap.entrySet()) {
                setSectionFlagById(template, entry.getKey(), parseBool(entry.getValue(), true));
            }
        }

        // Also check top-level boolean properties
        checkTopLevelBool(payload, "secBrandingEnabled", "sec_branding", v -> template.setSecBrandingEnabled(v));
        checkTopLevelBool(payload, "secInvoiceDetailsEnabled", "sec_invoice_details", v -> template.setSecInvoiceDetailsEnabled(v));
        checkTopLevelBool(payload, "secBillToEnabled", "sec_bill_to", v -> template.setSecBillToEnabled(v));
        checkTopLevelBool(payload, "secShipToEnabled", "sec_ship_to", v -> template.setSecShipToEnabled(v));
        checkTopLevelBool(payload, "secServicesEnabled", "sec_services", v -> template.setSecServicesEnabled(v));
        checkTopLevelBool(payload, "secTaxTotalsEnabled", "sec_tax_totals", v -> template.setSecTaxTotalsEnabled(v));
        checkTopLevelBool(payload, "secBankPaymentEnabled", "sec_bank_payment", v -> template.setSecBankPaymentEnabled(v));
        checkTopLevelBool(payload, "secAdjustmentsEnabled", "sec_adjustments", v -> template.setSecAdjustmentsEnabled(v));
        checkTopLevelBool(payload, "secTermsNotesEnabled", "sec_terms_notes", v -> template.setSecTermsNotesEnabled(v));
        checkTopLevelBool(payload, "secSignatureEnabled", "sec_signature", v -> template.setSecSignatureEnabled(v));
        checkTopLevelBool(payload, "letterheadEnabled", "letterhead_enabled", v -> template.setLetterheadEnabled(v));
        checkTopLevelBool(payload, "showQrCode", "show_qr_code", v -> template.setShowQrCode(v));
    }

    private void checkTopLevelBool(
            Map<String, Object> payload,
            String camelKey,
            String snakeKey,
            java.util.function.Consumer<Boolean> setter) {
        if (payload.containsKey(camelKey) && payload.get(camelKey) != null) {
            setter.accept(parseBool(payload.get(camelKey), true));
        } else if (payload.containsKey(snakeKey) && payload.get(snakeKey) != null) {
            setter.accept(parseBool(payload.get(snakeKey), true));
        }
    }

    private void setSectionFlagById(InvoiceTemplate template, String id, boolean enabled) {
        if (id == null) return;
        switch (id.trim()) {
            case "sec_branding", "secBrandingEnabled" -> template.setSecBrandingEnabled(enabled);
            case "sec_invoice_details", "secInvoiceDetailsEnabled" -> template.setSecInvoiceDetailsEnabled(enabled);
            case "sec_bill_to", "secBillToEnabled" -> template.setSecBillToEnabled(enabled);
            case "sec_ship_to", "secShipToEnabled" -> template.setSecShipToEnabled(enabled);
            case "sec_services", "secServicesEnabled" -> template.setSecServicesEnabled(enabled);
            case "sec_tax_totals", "secTaxTotalsEnabled" -> template.setSecTaxTotalsEnabled(enabled);
            case "sec_bank_payment", "secBankPaymentEnabled" -> template.setSecBankPaymentEnabled(enabled);
            case "sec_adjustments", "secAdjustmentsEnabled" -> template.setSecAdjustmentsEnabled(enabled);
            case "sec_terms_notes", "secTermsNotesEnabled" -> template.setSecTermsNotesEnabled(enabled);
            case "sec_signature", "secSignatureEnabled" -> template.setSecSignatureEnabled(enabled);
            case "letterhead_enabled", "letterheadEnabled" -> template.setLetterheadEnabled(enabled);
            case "showQrCode", "show_qr_code" -> template.setShowQrCode(enabled);
        }
    }

    private boolean parseBool(Object val, boolean fallback) {
        if (val instanceof Boolean b) return b;
        if (val instanceof String s) return Boolean.parseBoolean(s);
        if (val instanceof Number n) return n.intValue() != 0;
        return fallback;
    }

    private String resolveOrgCode(Long companyId, String fallbackOrgCode) {
        if (companyId != null) {
            Optional<Company> companyOpt = companyRepository.findById(companyId);
            if (companyOpt.isPresent() && companyOpt.get().getCompanyCode() != null && !companyOpt.get().getCompanyCode().isBlank()) {
                return companyOpt.get().getCompanyCode();
            }
        }
        if (fallbackOrgCode != null && !fallbackOrgCode.isBlank()) {
            return fallbackOrgCode;
        }
        return companyId != null ? "ORG-" + companyId : "ORG-DEFAULT";
    }

    private String formatActor(UserPrincipal principal) {
        if (principal == null) return "System";
        String name = principal.getFullName() != null ? principal.getFullName().trim() : "";
        String email = principal.getEmail() != null ? principal.getEmail().trim() : "";
        if (!name.isEmpty() && !email.isEmpty()) {
            return name + " (" + email + ")";
        }
        return !name.isEmpty() ? name : (!email.isEmpty() ? email : "User#" + principal.getId());
    }

    @Transactional
    public InvoiceTemplate saveDraft(InvoiceTemplate template, Long companyId, Long userId) {
        String orgCode = resolveOrgCode(companyId, template.getOrgCode());
        if (template.getId() != null) {
            InvoiceTemplate existing = getTemplateById(template.getId(), companyId);
            if (template.getTemplateName() != null && !template.getTemplateName().isBlank()) {
                existing.setTemplateName(template.getTemplateName());
            }
            existing.setIndustryPreset(template.getIndustryPreset());
            existing.setConfigurationJson(template.getConfigurationJson());
            if (template.getSettingsJson() != null) {
                existing.setSettingsJson(template.getSettingsJson());
            }
            existing.setOrgCode(orgCode);
            existing.setUpdatedByUserId(userId);
            if (template.getUpdatedBy() != null) {
                existing.setUpdatedBy(template.getUpdatedBy());
            }
            existing.setVersion(existing.getVersion() != null ? existing.getVersion() + 1 : 1);
            existing.setUpdatedAt(OffsetDateTime.now());
            return templateRepository.save(existing);
        } else {
            if (template.getTemplateName() == null || template.getTemplateName().isBlank()) {
                template.setTemplateName("Organization Default Template");
            }
            template.setCompanyId(companyId);
            template.setOrgCode(orgCode);
            template.setCreatedByUserId(userId);
            template.setUpdatedByUserId(userId);
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
        template.setUpdatedByUserId(userId);
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
