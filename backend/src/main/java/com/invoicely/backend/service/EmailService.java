package com.invoicely.backend.service;

import com.invoicely.backend.model.BusinessProfile;
import com.invoicely.backend.model.Expense;
import com.invoicely.backend.model.Invoice;
import com.invoicely.backend.repository.BusinessProfileRepository;
import com.invoicely.backend.repository.ExpenseRepository;
import com.invoicely.backend.repository.InvoiceRepository;
import jakarta.mail.internet.MimeMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.JavaMailSenderImpl;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

import java.time.OffsetDateTime;
import java.util.*;

@Service
public class EmailService {

    private static final Logger logger = LoggerFactory.getLogger(EmailService.class);

    private final JavaMailSender defaultMailSender;
    private final InvoiceRepository invoiceRepository;
    private final ExpenseRepository expenseRepository;
    private final BusinessProfileRepository profileRepository;

    @Value("${spring.mail.host:smtp.gmail.com}")
    private String defaultHost;

    @Value("${spring.mail.port:587}")
    private int defaultPort;

    @Value("${spring.mail.username:}")
    private String defaultUsername;

    @Value("${spring.mail.password:}")
    private String defaultPassword;

    @Value("${app.mail.from-email:billing@invoicelyai.com}")
    private String defaultFromEmail;

    @Value("${app.mail.from-name:Invoicely AI Billing}")
    private String defaultFromName;

    public EmailService(
            JavaMailSender defaultMailSender,
            InvoiceRepository invoiceRepository,
            ExpenseRepository expenseRepository,
            BusinessProfileRepository profileRepository) {
        this.defaultMailSender = defaultMailSender;
        this.invoiceRepository = invoiceRepository;
        this.expenseRepository = expenseRepository;
        this.profileRepository = profileRepository;
    }

    public Map<String, Object> testSmtp(String toEmail, String host, Integer port, String username, String password, Boolean startTls) {
        Map<String, Object> result = new LinkedHashMap<>();
        try {
            JavaMailSender sender;
            if (host != null && !host.isBlank() && username != null && !username.isBlank()) {
                JavaMailSenderImpl dynamicSender = new JavaMailSenderImpl();
                dynamicSender.setHost(host.trim());
                dynamicSender.setPort(port != null ? port : 587);
                dynamicSender.setUsername(username.trim());
                dynamicSender.setPassword(password != null ? password.trim() : "");

                Properties props = dynamicSender.getJavaMailProperties();
                props.put("mail.transport.protocol", "smtp");
                props.put("mail.smtp.auth", "true");
                props.put("mail.smtp.starttls.enable", startTls != null ? String.valueOf(startTls) : "true");
                props.put("mail.smtp.connectiontimeout", "8000");
                props.put("mail.smtp.timeout", "8000");
                sender = dynamicSender;
            } else {
                sender = defaultMailSender;
            }

            String target = (toEmail != null && !toEmail.isBlank()) ? toEmail.trim() : defaultFromEmail;
            MimeMessage message = sender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
            helper.setFrom(defaultFromEmail, defaultFromName);
            helper.setTo(target);
            helper.setSubject("Invoicely AI — SMTP Connection Verified");

            String html = """
                <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 580px; margin: 0 auto; border: 1px solid #e2e8f0; border-radius: 12px; overflow: hidden; background: #ffffff;">
                    <div style="background: linear-gradient(135deg, #1e3a8a, #0284c7); padding: 28px 24px; text-align: center;">
                        <h1 style="color: #ffffff; margin: 0; font-size: 22px; font-weight: 700;">Invoicely AI</h1>
                        <p style="color: #e0f2fe; margin: 6px 0 0; font-size: 13px;">SMTP Gateway &amp; Automated Delivery Status</p>
                    </div>
                    <div style="padding: 28px 24px;">
                        <div style="background: #f0fdf4; border: 1px solid #bbf7d0; border-radius: 8px; padding: 14px; margin-bottom: 20px;">
                            <p style="color: #166534; font-weight: 600; margin: 0; font-size: 14px;">SMTP Connection Successful</p>
                            <p style="color: #15803d; font-size: 12px; margin: 4px 0 0;">Your email dispatch service is online and verified to deliver automated payment reminders.</p>
                        </div>
                        <p style="color: #475569; font-size: 13px; line-height: 1.6;">
                            This test email confirms your SMTP server host and credentials can dispatch scheduled payment reminders, invoice receipts, and expense alerts directly to clients and vendors.
                        </p>
                        <hr style="border: none; border-top: 1px solid #f1f5f9; margin: 20px 0;" />
                        <p style="color: #94a3b8; font-size: 11px; margin: 0;">Verified on %s via Invoicely AI Mail Engine</p>
                    </div>
                </div>
            """.formatted(OffsetDateTime.now());

            helper.setText(html, true);
            sender.send(message);

            result.put("success", true);
            result.put("message", "Test email sent successfully to " + target);
            result.put("timestamp", OffsetDateTime.now().toString());
            return result;
        } catch (Exception ex) {
            logger.warn("SMTP test connection failed: {}", ex.getMessage());
            result.put("success", false);
            result.put("message", "SMTP delivery failed: " + ex.getMessage());
            result.put("timestamp", OffsetDateTime.now().toString());
            return result;
        }
    }

    public Map<String, Object> sendInvoiceReminder(Long invoiceId, String recipientEmail, String customNote, Long companyId) {
        Map<String, Object> result = new LinkedHashMap<>();
        Invoice invoice = invoiceRepository.findById(invoiceId)
                .orElseThrow(() -> new IllegalArgumentException("Invoice not found with ID: " + invoiceId));

        String target = (recipientEmail != null && !recipientEmail.isBlank())
                ? recipientEmail.trim()
                : invoice.getClientEmail();

        if (target == null || target.isBlank()) {
            throw new IllegalArgumentException("Recipient email not found for invoice #" + invoice.getInvoiceNumber());
        }

        BusinessProfile profile = companyId != null
                ? profileRepository.findFirstByCompanyId(companyId).orElseGet(BusinessProfile::new)
                : profileRepository.findFirstByOrderByIdAsc().orElseGet(BusinessProfile::new);

        try {
            MimeMessage message = defaultMailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
            helper.setFrom(defaultFromEmail, profile.getBusinessName() != null && !profile.getBusinessName().isEmpty() ? profile.getBusinessName() : defaultFromName);
            helper.setTo(target);
            helper.setSubject("Payment Reminder: Invoice #" + (invoice.getInvoiceNumber() != null ? invoice.getInvoiceNumber() : "") + " (Due: " + (invoice.getDueDate() != null && !invoice.getDueDate().isEmpty() ? invoice.getDueDate() : "Upon receipt") + ")");

            String noteBlock = (customNote != null && !customNote.isBlank())
                    ? "<div style='background:#f8fafc; border-left:4px solid #0284c7; padding:12px; margin:16px 0; font-size:13px; color:#334155;'>" + customNote + "</div>"
                    : "";

            String upiBlock = (!profile.getUpiId().isEmpty())
                    ? "<div style='margin-top:14px; padding:12px; background:#eff6ff; border-radius:8px; font-size:12px; color:#1e40af;'><strong>Instant UPI Pay:</strong> " + profile.getUpiId() + "</div>"
                    : "";

            String html = """
                <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 580px; margin: 0 auto; border: 1px solid #e2e8f0; border-radius: 12px; overflow: hidden; background: #ffffff;">
                    <div style="background: linear-gradient(135deg, #1e3a8a, #0284c7); padding: 24px; text-align: left; color: #ffffff;">
                        <h2 style="margin: 0; font-size: 20px; font-weight: 700;">%s</h2>
                        <p style="margin: 4px 0 0; font-size: 13px; color: #bae6fd;">Payment Reminder &amp; Account Summary</p>
                    </div>
                    <div style="padding: 24px;">
                        <p style="color: #334155; font-size: 14px; margin-top: 0;">Dear <strong>%s</strong>,</p>
                        <p style="color: #475569; font-size: 13px; line-height: 1.5;">
                            This is a friendly reminder that payment for <strong>Invoice #%s</strong> is due on <strong>%s</strong>.
                        </p>
                        <div style="background: #f8fafc; border: 1px solid #e2e8f0; border-radius: 8px; padding: 16px; margin: 16px 0;">
                            <div style="display: flex; justify-content: space-between; margin-bottom: 8px;">
                                <span style="color: #64748b; font-size: 12px;">Total Invoice Amount:</span>
                                <strong style="color: #0f172a; font-size: 14px;">%s%s</strong>
                            </div>
                            <div style="display: flex; justify-content: space-between;">
                                <span style="color: #64748b; font-size: 12px;">Payment Status:</span>
                                <span style="color: #d97706; font-weight: 700; font-size: 12px;">%s</span>
                            </div>
                        </div>
                        %s
                        %s
                        <p style="color: #64748b; font-size: 12px; margin-top: 20px; line-height: 1.5;">
                            If you have already processed this transaction, please disregard this reminder. For queries, reply directly to this email.
                        </p>
                    </div>
                </div>
            """.formatted(
                    profile.getBusinessName() != null && !profile.getBusinessName().isEmpty() ? profile.getBusinessName() : "Invoicely AI",
                    invoice.getClientName() != null && !invoice.getClientName().isEmpty() ? invoice.getClientName() : "Customer",
                    invoice.getInvoiceNumber() != null ? invoice.getInvoiceNumber() : "",
                    invoice.getDueDate() != null && !invoice.getDueDate().isEmpty() ? invoice.getDueDate() : "Upon receipt",
                    invoice.getCurrencySymbol() != null && !invoice.getCurrencySymbol().isEmpty() ? invoice.getCurrencySymbol() : "₹",
                    invoice.getTotal() != null ? invoice.getTotal().toPlainString() : "0.00",
                    invoice.getStatus() != null ? invoice.getStatus().toUpperCase() : "PENDING",
                    noteBlock,
                    upiBlock
            );

            helper.setText(html, true);
            defaultMailSender.send(message);

            result.put("success", true);
            result.put("recipient", target);
            result.put("invoiceNumber", invoice.getInvoiceNumber());
            result.put("sentAt", OffsetDateTime.now().toString());
            return result;
        } catch (Exception ex) {
            logger.warn("Failed to dispatch invoice reminder: {}", ex.getMessage());
            result.put("success", false);
            result.put("error", ex.getMessage());
            result.put("invoiceNumber", invoice.getInvoiceNumber());
            return result;
        }
    }

    public Map<String, Object> sendExpenseReminder(Long expenseId, String recipientEmail, String customNote, Long companyId) {
        Map<String, Object> result = new LinkedHashMap<>();
        Expense expense = expenseRepository.findById(expenseId)
                .orElseThrow(() -> new IllegalArgumentException("Expense not found with ID: " + expenseId));

        BusinessProfile profile = companyId != null
                ? profileRepository.findFirstByCompanyId(companyId).orElseGet(BusinessProfile::new)
                : profileRepository.findFirstByOrderByIdAsc().orElseGet(BusinessProfile::new);

        String target = (recipientEmail != null && !recipientEmail.isBlank())
                ? recipientEmail.trim()
                : (profile.getEmail().isEmpty() ? defaultFromEmail : profile.getEmail());

        try {
            MimeMessage message = defaultMailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
            helper.setFrom(defaultFromEmail, profile.getBusinessName() != null && !profile.getBusinessName().isEmpty() ? profile.getBusinessName() : defaultFromName);
            helper.setTo(target);
            helper.setSubject("Expense Due Alert: " + (expense.getTitle() != null ? expense.getTitle() : "Expense") + " (" + (expense.getDueDate() != null && !expense.getDueDate().isEmpty() ? "Due: " + expense.getDueDate() : "Action Required") + ")");

            String html = """
                <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 580px; margin: 0 auto; border: 1px solid #e2e8f0; border-radius: 12px; overflow: hidden; background: #ffffff;">
                    <div style="background: linear-gradient(135deg, #b45309, #d97706); padding: 24px; text-align: left; color: #ffffff;">
                        <h2 style="margin: 0; font-size: 20px; font-weight: 700;">Expense Payment Due</h2>
                        <p style="margin: 4px 0 0; font-size: 13px; color: #fef3c7;">Vendor / Outward Liability Reminder</p>
                    </div>
                    <div style="padding: 24px;">
                        <p style="color: #334155; font-size: 14px; margin-top: 0;">Attention: Accounts &amp; Finance</p>
                        <p style="color: #475569; font-size: 13px; line-height: 1.5;">
                            An expense record is marked <strong>DUE / PENDING</strong> for settlement.
                        </p>
                        <div style="background: #fffbeb; border: 1px solid #fde68a; border-radius: 8px; padding: 16px; margin: 16px 0;">
                            <p style="margin: 0 0 6px; font-size: 14px; font-weight: 700; color: #92400e;">%s</p>
                            <p style="margin: 0 0 6px; font-size: 12px; color: #78350f;">Vendor: <strong>%s</strong> | Category: <strong>%s</strong></p>
                            <p style="margin: 0 0 6px; font-size: 14px; color: #b45309; font-weight: 800;">Amount: %s%s</p>
                            <p style="margin: 0; font-size: 12px; color: #92400e;">Due Date: <strong>%s</strong></p>
                        </div>
                    </div>
                </div>
            """.formatted(
                    expense.getTitle() != null ? expense.getTitle() : "Expense",
                    expense.getVendor() != null && !expense.getVendor().isEmpty() ? expense.getVendor() : "General Merchant",
                    expense.getCategory() != null ? expense.getCategory() : "General",
                    expense.getCurrencySymbol() != null && !expense.getCurrencySymbol().isEmpty() ? expense.getCurrencySymbol() : "₹",
                    expense.getAmount() != null ? expense.getAmount().toPlainString() : "0.00",
                    expense.getDueDate() != null && !expense.getDueDate().isEmpty() ? expense.getDueDate() : "Immediate"
            );

            helper.setText(html, true);
            defaultMailSender.send(message);

            result.put("success", true);
            result.put("recipient", target);
            result.put("expenseId", expense.getId());
            result.put("sentAt", OffsetDateTime.now().toString());
            return result;
        } catch (Exception ex) {
            logger.warn("Failed to dispatch expense reminder: {}", ex.getMessage());
            result.put("success", false);
            result.put("error", ex.getMessage());
            return result;
        }
    }
}
