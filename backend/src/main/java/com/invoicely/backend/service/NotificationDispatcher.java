package com.invoicely.backend.service;

import com.invoicely.backend.model.NotificationChannel;
import com.invoicely.backend.model.UserNotification;
import org.springframework.stereotype.Service;

@Service
public class NotificationDispatcher {

    private final EmailSenderService emailSenderService;
    private final WhatsAppSenderService whatsAppSenderService;

    public NotificationDispatcher(EmailSenderService emailSenderService, WhatsAppSenderService whatsAppSenderService) {
        this.emailSenderService = emailSenderService;
        this.whatsAppSenderService = whatsAppSenderService;
    }

    /**
     * Dispatches a notification through the appropriate channel sender.
     */
    public NotificationDispatchResult dispatch(UserNotification notification) {
        if (notification == null) {
            return NotificationDispatchResult.failure("NULL_NOTIFICATION", "Notification payload is null", 0);
        }

        NotificationChannel channel = notification.getChannel();
        if (channel == NotificationChannel.WHATSAPP) {
            return whatsAppSenderService.sendWhatsAppMessage(
                    notification.getRecipientTo(),
                    notification.getRecipientName(),
                    notification.getTitle(),
                    notification.getBody()
            );
        } else {
            // Default to Email
            return emailSenderService.sendEmail(
                    notification.getRecipientTo(),
                    notification.getRecipientName(),
                    notification.getTitle(),
                    notification.getBody()
            );
        }
    }
}
