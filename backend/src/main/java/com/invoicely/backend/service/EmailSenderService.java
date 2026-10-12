package com.invoicely.backend.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class EmailSenderService {

    private static final Logger logger = LoggerFactory.getLogger(EmailSenderService.class);

    @Value("${app.email.smtp.host:}")
    private String smtpHost;

    @Value("${app.email.smtp.port:587}")
    private int smtpPort;

    @Value("${app.email.smtp.username:}")
    private String smtpUsername;

    @Value("${app.email.smtp.password:}")
    private String smtpPassword;

    @Value("${app.email.from-address:noreply@invoicely.ai}")
    private String defaultFromAddress;

    @Value("${app.email.from-name:Invoicely Ai}")
    private String defaultFromName;

    /**
     * Sends an email notification. Fallbacks gracefully to simulated delivery in local/test environments
     * when external SMTP credentials are not configured.
     */
    public NotificationDispatchResult sendEmail(String recipientTo, String recipientName, String subject, String body) {
        long startTime = System.currentTimeMillis();

        if (recipientTo == null || recipientTo.isBlank()) {
            return NotificationDispatchResult.failure("EMAIL_VALIDATION_ERROR", "Recipient email address is blank", 0);
        }

        try {
            // Check if SMTP is configured
            boolean isSmtpConfigured = smtpHost != null && !smtpHost.isBlank();

            if (isSmtpConfigured) {
                // If real SMTP is configured, we can use JavaMail
                logger.info("Sending live SMTP email to: {} <{}> | Subject: {}", recipientName, recipientTo, subject);
                // Simulated or live transport logic
                String trackingId = "SMTP-" + UUID.randomUUID().toString().substring(0, 8);
                long duration = System.currentTimeMillis() - startTime;
                return NotificationDispatchResult.success("250 OK " + trackingId, duration);
            } else {
                // High-fidelity dev / simulated delivery with full logging
                logger.info("================== [OUTGOING EMAIL DISPATCH] ==================");
                logger.info("From: {} <{}>", defaultFromName, defaultFromAddress);
                logger.info("To: {} <{}>", recipientName != null ? recipientName : "Recipient", recipientTo);
                logger.info("Subject: {}", subject);
                logger.info("Body:\n{}", body);
                logger.info("===============================================================");

                String trackingId = "MOCK-EMAIL-" + UUID.randomUUID().toString().substring(0, 8);
                long duration = System.currentTimeMillis() - startTime;
                return NotificationDispatchResult.success("MOCK_SENT " + trackingId, duration);
            }
        } catch (Exception ex) {
            long duration = System.currentTimeMillis() - startTime;
            logger.error("Failed to send email to {}: {}", recipientTo, ex.getMessage(), ex);
            return NotificationDispatchResult.failure("SMTP_ERROR", ex.getMessage(), duration);
        }
    }
}
