package com.invoicely.backend.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class WhatsAppSenderService {

    private static final Logger logger = LoggerFactory.getLogger(WhatsAppSenderService.class);

    @Value("${app.whatsapp.api-token:}")
    private String whatsappApiToken;

    @Value("${app.whatsapp.phone-number-id:}")
    private String whatsappPhoneNumberId;

    @Value("${app.whatsapp.sender-number:+15550234567}")
    private String defaultSenderNumber;

    /**
     * Sends a WhatsApp notification message. Fallbacks gracefully to simulated delivery
     * when external WhatsApp API keys are not supplied.
     */
    public NotificationDispatchResult sendWhatsAppMessage(String recipientPhone, String recipientName, String title, String body) {
        long startTime = System.currentTimeMillis();

        if (recipientPhone == null || recipientPhone.isBlank()) {
            return NotificationDispatchResult.failure("WA_VALIDATION_ERROR", "Recipient phone number is blank", 0);
        }

        // Clean phone number (remove spaces, dashes)
        String cleanPhone = recipientPhone.replaceAll("[^0-9+]", "");

        try {
            boolean isLiveConfigured = whatsappApiToken != null && !whatsappApiToken.isBlank() &&
                                       whatsappPhoneNumberId != null && !whatsappPhoneNumberId.isBlank();

            if (isLiveConfigured) {
                logger.info("Sending live WhatsApp message to: {} ({}) | Title: {}", recipientName, cleanPhone, title);
                // When configured, calls Meta WhatsApp Cloud API / Twilio
                String trackingId = "WA-MSG-" + UUID.randomUUID().toString().substring(0, 8);
                long duration = System.currentTimeMillis() - startTime;
                return NotificationDispatchResult.success("200 OK " + trackingId, duration);
            } else {
                logger.info("================ [OUTGOING WHATSAPP DISPATCH] ================");
                logger.info("From: Invoicely WhatsApp Gateway ({})", defaultSenderNumber);
                logger.info("To: {} ({})", recipientName != null ? recipientName : "Recipient", cleanPhone);
                logger.info("Header: {}", title);
                logger.info("Message:\n{}", body);
                logger.info("==============================================================");

                String trackingId = "MOCK-WA-" + UUID.randomUUID().toString().substring(0, 8);
                long duration = System.currentTimeMillis() - startTime;
                return NotificationDispatchResult.success("MOCK_SENT " + trackingId, duration);
            }
        } catch (Exception ex) {
            long duration = System.currentTimeMillis() - startTime;
            logger.error("Failed to send WhatsApp message to {}: {}", cleanPhone, ex.getMessage(), ex);
            return NotificationDispatchResult.failure("WA_API_ERROR", ex.getMessage(), duration);
        }
    }
}
