package com.invoicely.backend.service;

import com.invoicely.backend.model.Company;
import com.invoicely.backend.model.CompanyJoinRequest;
import com.invoicely.backend.model.Invoice;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
public class TemplateRenderer {

    private static final Pattern PLACEHOLDER_PATTERN = Pattern.compile("\\{\\{\\s*([a-zA-Z0-9_.-]+)\\s*}}");

    /**
     * Renders a template string by replacing {{placeholder}} tokens with values from variables map.
     */
    public String render(String template, Map<String, Object> variables) {
        if (template == null) return "";
        if (variables == null || variables.isEmpty()) return template;

        Matcher matcher = PLACEHOLDER_PATTERN.matcher(template);
        StringBuilder sb = new StringBuilder();

        while (matcher.find()) {
            String key = matcher.group(1);
            Object value = variables.get(key);
            String replacement = value != null ? Matcher.quoteReplacement(value.toString()) : "";
            matcher.appendReplacement(sb, replacement);
        }
        matcher.appendTail(sb);
        return sb.toString();
    }

    /**
     * Extracts standard template variables from an Invoice and optional Company.
     */
    public Map<String, Object> extractInvoiceVariables(Invoice invoice, Company company) {
        Map<String, Object> vars = new HashMap<>();
        if (invoice == null) return vars;

        vars.put("invoiceNumber", invoice.getInvoiceNumber() != null ? invoice.getInvoiceNumber() : "");
        vars.put("clientName", invoice.getClientName() != null ? invoice.getClientName() : "");
        vars.put("clientCompany", invoice.getClientCompany() != null ? invoice.getClientCompany() : "");
        vars.put("clientEmail", invoice.getClientEmail() != null ? invoice.getClientEmail() : "");
        vars.put("clientPhone", invoice.getClientPhone() != null ? invoice.getClientPhone() : "");
        vars.put("issueDate", invoice.getIssueDate() != null ? invoice.getIssueDate() : "");
        vars.put("dueDate", invoice.getDueDate() != null ? invoice.getDueDate() : "");
        vars.put("paymentTerms", invoice.getPaymentTerms() != null ? invoice.getPaymentTerms() : "Net 30");
        vars.put("currencySymbol", invoice.getCurrencySymbol() != null ? invoice.getCurrencySymbol() : "$");
        vars.put("currencyCode", invoice.getCurrencyCode() != null ? invoice.getCurrencyCode() : "USD");
        vars.put("status", invoice.getStatus() != null ? invoice.getStatus() : "Draft");

        BigDecimal amountPaid = invoice.getAmountPaid() != null ? invoice.getAmountPaid() : BigDecimal.ZERO;
        vars.put("amountPaid", amountPaid.toPlainString());

        BigDecimal total = invoice.getTotal();
        BigDecimal balanceDue = invoice.getBalanceDue();
        vars.put("total", total.toPlainString());
        vars.put("balanceDue", balanceDue.toPlainString());
        vars.put("amountDue", vars.get("currencySymbol") + " " + balanceDue.toPlainString());

        if (company != null) {
            vars.put("companyName", company.getCompanyName() != null ? company.getCompanyName() : "Invoicely");
            vars.put("companyCode", company.getCompanyCode() != null ? company.getCompanyCode() : "");
            vars.put("companyEmail", company.getEmail() != null ? company.getEmail() : "");
            vars.put("companyPhone", company.getPhone() != null ? company.getPhone() : "");
            vars.put("companyWebsite", company.getWebsite() != null ? company.getWebsite() : "");
            vars.put("companyGstin", company.getGstin() != null ? company.getGstin() : "");
        } else {
            vars.put("companyName", "Invoicely Ai");
            vars.put("companyCode", "");
            vars.put("companyEmail", "billing@invoicely.ai");
            vars.put("companyPhone", "");
        }

        return vars;
    }

    /**
     * Extracts variables for a Join Request.
     */
    public Map<String, Object> extractJoinRequestVariables(CompanyJoinRequest request, Company company, String adminMessage) {
        Map<String, Object> vars = new HashMap<>();
        if (request == null) return vars;

        vars.put("userFullName", request.getUserFullName() != null ? request.getUserFullName() : "Team Member");
        vars.put("userEmail", request.getUserEmail() != null ? request.getUserEmail() : "");
        vars.put("userMobile", request.getUserMobile() != null ? request.getUserMobile() : "");
        vars.put("companyName", request.getCompanyName() != null ? request.getCompanyName() : (company != null ? company.getCompanyName() : "Invoicely"));
        vars.put("companyCode", request.getCompanyCode() != null ? request.getCompanyCode() : (company != null ? company.getCompanyCode() : ""));
        vars.put("status", request.getStatus() != null ? request.getStatus().name() : "PENDING");
        vars.put("requestMessage", request.getRequestMessage() != null ? request.getRequestMessage() : "");
        vars.put("adminFeedback", adminMessage != null ? adminMessage : "");
        vars.put("actionDate", java.time.LocalDate.now().toString());

        return vars;
    }

    /**
     * Extracts variables for Company Invitation.
     */
    public Map<String, Object> extractInviteVariables(Company company, String inviteeName, String inviteeEmail, String inviterName, String role, String inviteLink) {
        Map<String, Object> vars = new HashMap<>();
        vars.put("inviteeName", inviteeName != null && !inviteeName.isBlank() ? inviteeName : "Team Member");
        vars.put("inviteeEmail", inviteeEmail != null ? inviteeEmail : "");
        vars.put("inviterName", inviterName != null ? inviterName : "Administrator");
        vars.put("companyName", company != null ? company.getCompanyName() : "Our Company");
        vars.put("companyCode", company != null ? company.getCompanyCode() : "");
        vars.put("role", role != null ? role : "EMPLOYEE");
        vars.put("inviteLink", inviteLink != null ? inviteLink : "https://invoicelyai.onrender.com/join");
        return vars;
    }
}
