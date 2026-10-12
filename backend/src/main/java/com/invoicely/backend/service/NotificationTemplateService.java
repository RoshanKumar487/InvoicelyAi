package com.invoicely.backend.service;

import com.invoicely.backend.dto.NotificationTemplateDto;
import com.invoicely.backend.dto.SaveNotificationTemplateRequest;
import com.invoicely.backend.dto.TemplatePreviewRequest;
import com.invoicely.backend.dto.TemplatePreviewResponse;
import com.invoicely.backend.exception.ResourceNotFoundException;
import com.invoicely.backend.model.Company;
import com.invoicely.backend.model.Invoice;
import com.invoicely.backend.model.NotificationChannel;
import com.invoicely.backend.model.NotificationTemplate;
import com.invoicely.backend.repository.CompanyRepository;
import com.invoicely.backend.repository.InvoiceRepository;
import com.invoicely.backend.repository.NotificationTemplateRepository;
import com.invoicely.backend.security.UserPrincipal;
import jakarta.annotation.PostConstruct;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

@Service
public class NotificationTemplateService {

    private final NotificationTemplateRepository templateRepository;
    private final CompanyRepository companyRepository;
    private final InvoiceRepository invoiceRepository;
    private final TemplateRenderer templateRenderer;

    public NotificationTemplateService(NotificationTemplateRepository templateRepository,
                                       CompanyRepository companyRepository,
                                       InvoiceRepository invoiceRepository,
                                       TemplateRenderer templateRenderer) {
        this.templateRepository = templateRepository;
        this.companyRepository = companyRepository;
        this.invoiceRepository = invoiceRepository;
        this.templateRenderer = templateRenderer;
    }

    @PostConstruct
    public void seedDefaultTemplates() {
        if (templateRepository.findByCompanyIdIsNull().isEmpty()) {
            List<NotificationTemplate> defaults = List.of(
                new NotificationTemplate(
                    null,
                    "PAYMENT_REMINDER",
                    NotificationChannel.EMAIL,
                    "Payment Reminder: Invoice {{invoiceNumber}} from {{companyName}}",
                    "Invoice Payment Reminder (Email)",
                    "Dear {{clientName}},\n\nThis is a friendly reminder that payment for Invoice {{invoiceNumber}} is due on {{dueDate}}.\n\nAmount Due: {{amountDue}}\n\nPlease arrange for payment at your earliest convenience.\nIf payment has already been sent, please disregard this reminder.\n\nThank you for your business!\n{{companyName}}\n{{companyEmail}}",
                    "{\"category\":\"Billing\",\"tags\":[\"invoice\",\"reminder\"]}",
                    null,
                    "System Default"
                ),
                new NotificationTemplate(
                    null,
                    "WHATSAPP_PAYMENT_REMINDER",
                    NotificationChannel.WHATSAPP,
                    "Invoice Payment Reminder",
                    "Invoice Payment Reminder (WhatsApp)",
                    "Hello {{clientName}}, this is a friendly reminder from {{companyName}} regarding Invoice *{{invoiceNumber}}* for *{{amountDue}}*, due on *{{dueDate}}*. Please let us know if you need any assistance or have questions. Thank you!",
                    "{\"category\":\"Billing\",\"tags\":[\"whatsapp\",\"reminder\"]}",
                    null,
                    "System Default"
                ),
                new NotificationTemplate(
                    null,
                    "INVOICE_SEND",
                    NotificationChannel.EMAIL,
                    "Invoice {{invoiceNumber}} from {{companyName}}",
                    "New Invoice Dispatch (Email)",
                    "Dear {{clientName}},\n\nPlease find your invoice {{invoiceNumber}} for {{amountDue}}.\nIssue Date: {{issueDate}}\nDue Date: {{dueDate}}\n\nThank you for choosing {{companyName}}!\n{{companyEmail}}",
                    "{\"category\":\"Billing\",\"tags\":[\"invoice\",\"dispatch\"]}",
                    null,
                    "System Default"
                ),
                new NotificationTemplate(
                    null,
                    "COMPANY_INVITE",
                    NotificationChannel.EMAIL,
                    "Invitation to join {{companyName}} on Invoicely",
                    "Workspace Team Invitation",
                    "Hello {{inviteeName}},\n\n{{inviterName}} has invited you to join the workspace for {{companyName}} as a {{role}} on Invoicely.\n\nCompany Code: {{companyCode}}\nAccept Invitation: {{inviteLink}}\n\nWelcome aboard!\nTeam {{companyName}}",
                    "{\"category\":\"Team\",\"tags\":[\"invite\",\"team\"]}",
                    null,
                    "System Default"
                ),
                new NotificationTemplate(
                    null,
                    "JOIN_REQUEST_APPROVED",
                    NotificationChannel.EMAIL,
                    "Your join request for {{companyName}} has been Approved!",
                    "Join Request Approval Notice",
                    "Hello {{userFullName}},\n\nGreat news! Your request to join {{companyName}} (Company Code: {{companyCode}}) has been APPROVED.\n\nYou now have access to company invoicing tools. Log in to your Invoicely account to get started.\n\nFeedback from Admin:\n{{adminFeedback}}\n\nBest regards,\n{{companyName}} Admin Team",
                    "{\"category\":\"Join Requests\",\"tags\":[\"approval\"]}",
                    null,
                    "System Default"
                ),
                new NotificationTemplate(
                    null,
                    "JOIN_REQUEST_REJECTED",
                    NotificationChannel.EMAIL,
                    "Update regarding your request to join {{companyName}}",
                    "Join Request Decision",
                    "Hello {{userFullName}},\n\nYour request to join {{companyName}} has been reviewed.\nStatus: Declined\n\nAdmin Note:\n{{adminFeedback}}\n\nIf you believe this is in error, please contact your company administrator.",
                    "{\"category\":\"Join Requests\",\"tags\":[\"rejection\"]}",
                    null,
                    "System Default"
                ),
                new NotificationTemplate(
                    null,
                    "OVERDUE_NOTICE",
                    NotificationChannel.EMAIL,
                    "URGENT: Overdue Payment Notice - Invoice {{invoiceNumber}}",
                    "Overdue Payment Notice (Email)",
                    "Dear {{clientName}},\n\nOur records show that Invoice {{invoiceNumber}} for {{amountDue}} was due on {{dueDate}} and remains unpaid.\n\nPlease remit payment at your earliest convenience to maintain an active account.\n\nThank you,\n{{companyName}}\n{{companyEmail}}",
                    "{\"category\":\"Billing\",\"tags\":[\"overdue\",\"notice\"]}",
                    null,
                    "System Default"
                )
            );
            templateRepository.saveAll(defaults);
        }
    }

    /**
     * Returns all templates active for a company (merging company-specific overrides over global defaults).
     */
    public List<NotificationTemplateDto> getTemplatesForCompany(Long companyId) {
        List<NotificationTemplate> allAvailable = templateRepository.findAllForCompany(companyId);

        // Deduplicate by templateName: if company has customized one, prefer company version over global default
        Map<String, NotificationTemplate> map = new LinkedHashMap<>();

        // First add company-specific templates
        for (NotificationTemplate t : allAvailable) {
            if (t.getCompanyId() != null && t.getCompanyId().equals(companyId)) {
                map.put(t.getTemplateName() + "_" + t.getChannel().name(), t);
            }
        }

        // Then add system defaults if not overridden
        for (NotificationTemplate t : allAvailable) {
            if (t.getCompanyId() == null) {
                map.putIfAbsent(t.getTemplateName() + "_" + t.getChannel().name(), t);
            }
        }

        return map.values().stream()
                .map(NotificationTemplateDto::fromEntity)
                .toList();
    }

    /**
     * Resolves a template by name and channel for a company (company-specific override or fallback default).
     */
    public NotificationTemplate getEffectiveTemplate(Long companyId, String templateName, NotificationChannel channel) {
        if (companyId != null) {
            if (channel != null) {
                Optional<NotificationTemplate> custom = templateRepository.findByCompanyIdAndTemplateNameAndChannel(companyId, templateName, channel);
                if (custom.isPresent()) return custom.get();
            }
            Optional<NotificationTemplate> customGeneral = templateRepository.findByCompanyIdAndTemplateName(companyId, templateName);
            if (customGeneral.isPresent()) return customGeneral.get();
        }

        if (channel != null) {
            Optional<NotificationTemplate> defaultTemplate = templateRepository.findByCompanyIdIsNullAndTemplateNameAndChannel(templateName, channel);
            if (defaultTemplate.isPresent()) return defaultTemplate.get();
        }

        return templateRepository.findByCompanyIdIsNullAndTemplateName(templateName)
                .orElseThrow(() -> new ResourceNotFoundException("Notification template '" + templateName + "' not found"));
    }

    public NotificationTemplateDto getTemplateById(Long id, Long companyId) {
        NotificationTemplate template = templateRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Template not found with ID " + id));

        if (template.getCompanyId() != null && companyId != null && !template.getCompanyId().equals(companyId)) {
            throw new ResourceNotFoundException("Template not found for current company");
        }
        return NotificationTemplateDto.fromEntity(template);
    }

    /**
     * Saves or updates a template from the Settings UI.
     */
    @Transactional
    public NotificationTemplateDto saveOrUpdateTemplate(Long companyId, SaveNotificationTemplateRequest request, UserPrincipal principal) {
        String templateName = request.getTemplateName().trim();
        NotificationChannel channel = request.getChannel() != null ? request.getChannel() : NotificationChannel.EMAIL;

        Optional<NotificationTemplate> existingOpt = templateRepository.findByCompanyIdAndTemplateNameAndChannel(companyId, templateName, channel);
        if (existingOpt.isEmpty()) {
            existingOpt = templateRepository.findByCompanyIdAndTemplateName(companyId, templateName);
        }

        NotificationTemplate entity;
        if (existingOpt.isPresent()) {
            entity = existingOpt.get();
            entity.setSubject(request.getSubject());
            entity.setTitle(request.getTitle());
            entity.setBody(request.getBody());
            entity.setChannel(channel);
            if (request.getMetadataJson() != null) {
                entity.setMetadataJson(request.getMetadataJson());
            }
            if (principal != null) {
                entity.setCreatedByUserId(principal.getId());
                entity.setCreatedByUserName(principal.getFullName());
            }
        } else {
            entity = new NotificationTemplate(
                companyId,
                templateName,
                channel,
                request.getSubject(),
                request.getTitle(),
                request.getBody(),
                request.getMetadataJson(),
                principal != null ? principal.getId() : null,
                principal != null ? principal.getFullName() : "Admin"
            );
        }

        NotificationTemplate saved = templateRepository.save(entity);
        return NotificationTemplateDto.fromEntity(saved);
    }

    /**
     * Updates an existing template by ID.
     */
    @Transactional
    public NotificationTemplateDto updateTemplateById(Long id, Long companyId, SaveNotificationTemplateRequest request, UserPrincipal principal) {
        NotificationTemplate entity = templateRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Template not found with id " + id));

        // If trying to modify a system default, create a company clone instead of modifying the global default
        if (entity.getCompanyId() == null) {
            return saveOrUpdateTemplate(companyId, request, principal);
        }

        if (companyId != null && !companyId.equals(entity.getCompanyId())) {
            throw new ResourceNotFoundException("Template does not belong to current company");
        }

        entity.setSubject(request.getSubject());
        entity.setTitle(request.getTitle());
        entity.setBody(request.getBody());
        if (request.getChannel() != null) {
            entity.setChannel(request.getChannel());
        }
        if (request.getMetadataJson() != null) {
            entity.setMetadataJson(request.getMetadataJson());
        }
        if (principal != null) {
            entity.setCreatedByUserId(principal.getId());
            entity.setCreatedByUserName(principal.getFullName());
        }

        NotificationTemplate saved = templateRepository.save(entity);
        return NotificationTemplateDto.fromEntity(saved);
    }

    /**
     * Resets or deletes a company custom template (reverting to system default).
     */
    @Transactional
    public void deleteOrResetTemplate(Long id, Long companyId) {
        NotificationTemplate entity = templateRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Template not found with id " + id));

        if (entity.getCompanyId() != null && companyId != null && entity.getCompanyId().equals(companyId)) {
            templateRepository.delete(entity);
        }
    }

    /**
     * Previews a template with mock or live invoice data for UI testing.
     */
    public TemplatePreviewResponse previewTemplate(Long companyId, TemplatePreviewRequest request) {
        String subjectToRender = request.getSubject();
        String bodyToRender = request.getBody();
        NotificationChannel channel = request.getChannel() != null ? request.getChannel() : NotificationChannel.EMAIL;

        if (bodyToRender == null || bodyToRender.isBlank()) {
            if (request.getTemplateName() != null) {
                NotificationTemplate template = getEffectiveTemplate(companyId, request.getTemplateName(), channel);
                subjectToRender = template.getSubject();
                bodyToRender = template.getBody();
                channel = template.getChannel();
            }
        }

        Map<String, Object> variables = new HashMap<>();
        Company company = companyId != null ? companyRepository.findById(companyId).orElse(null) : null;

        if (request.getInvoiceId() != null) {
            Invoice invoice = invoiceRepository.findById(request.getInvoiceId()).orElse(null);
            if (invoice != null) {
                variables.putAll(templateRenderer.extractInvoiceVariables(invoice, company));
            }
        }

        if (variables.isEmpty()) {
            // Populate realistic mock preview values
            variables.put("clientName", "Acme Global Solutions");
            variables.put("clientEmail", "billing@acme.com");
            variables.put("clientPhone", "+1 (555) 234-5678");
            variables.put("invoiceNumber", "INV-2026-089");
            variables.put("dueDate", "2026-10-25");
            variables.put("issueDate", "2026-10-10");
            variables.put("amountDue", "$ 2,450.00");
            variables.put("currencySymbol", "$");
            variables.put("paymentTerms", "Net 15");
            variables.put("companyName", company != null ? company.getCompanyName() : "Apex Nova Dynamics");
            variables.put("companyCode", company != null ? company.getCompanyCode() : "APEX-2026");
            variables.put("companyEmail", company != null ? company.getEmail() : "billing@apexnova.io");
            variables.put("inviteeName", "Sarah Jenkins");
            variables.put("inviteeEmail", "sarah@acme.com");
            variables.put("inviterName", "Roshan Kumar");
            variables.put("role", "ACCOUNTANT");
            variables.put("inviteLink", "https://invoicelyai.onrender.com/join?code=" + (company != null ? company.getCompanyCode() : "APEX-2026"));
            variables.put("userFullName", "Alex Carter");
            variables.put("adminFeedback", "Welcome to the team! Invoicing & Reports access granted.");
        }

        if (request.getVariables() != null) {
            variables.putAll(request.getVariables());
        }

        String renderedSubject = templateRenderer.render(subjectToRender, variables);
        String renderedBody = templateRenderer.render(bodyToRender, variables);

        return new TemplatePreviewResponse(renderedSubject, renderedBody, channel, variables);
    }
}
