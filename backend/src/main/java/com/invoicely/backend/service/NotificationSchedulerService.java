package com.invoicely.backend.service;

import com.invoicely.backend.model.*;
import com.invoicely.backend.repository.NotificationAuditLogRepository;
import com.invoicely.backend.repository.UserNotificationRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.PageRequest;
import org.springframework.scheduling.annotation.Async;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;

@Service
public class NotificationSchedulerService {

    private static final Logger logger = LoggerFactory.getLogger(NotificationSchedulerService.class);

    private final UserNotificationRepository notificationRepository;
    private final NotificationAuditLogRepository auditLogRepository;
    private final NotificationDispatcher notificationDispatcher;

    public NotificationSchedulerService(UserNotificationRepository notificationRepository,
                                        NotificationAuditLogRepository auditLogRepository,
                                        NotificationDispatcher notificationDispatcher) {
        this.notificationRepository = notificationRepository;
        this.auditLogRepository = auditLogRepository;
        this.notificationDispatcher = notificationDispatcher;
    }

    /**
     * Periodic scheduler to pick ready-to-process records and dispatch asynchronously one by one.
     */
    @Scheduled(fixedDelayString = "${app.notification.scheduler.fixed-delay-ms:5000}")
    public void processPendingNotifications() {
        OffsetDateTime now = OffsetDateTime.now();
        List<UserNotification> readyRecords = notificationRepository.findReadyForDispatch(now, PageRequest.of(0, 10));

        if (readyRecords.isEmpty()) {
            return;
        }

        logger.debug("Scheduler picked {} ready notification(s) for async dispatch", readyRecords.size());

        for (UserNotification record : readyRecords) {
            try {
                // Mark as processing to avoid duplicate pickups
                record.setStatus(NotificationStatus.PROCESSING);
                record.setUpdatedAt(OffsetDateTime.now());
                notificationRepository.save(record);

                // Dispatch asynchronously one by one
                dispatchSingleRecordAsync(record.getId());
            } catch (Exception ex) {
                logger.error("Failed to transition notification #{} to PROCESSING: {}", record.getId(), ex.getMessage());
            }
        }
    }

    /**
     * Asynchronous execution worker for an individual notification.
     */
    @Async("notificationExecutor")
    @Transactional
    public void dispatchSingleRecordAsync(Long notificationId) {
        UserNotification notification = notificationRepository.findById(notificationId).orElse(null);
        if (notification == null) return;

        int currentAttempt = notification.getRetryCount() + 1;
        NotificationDispatchResult result;

        try {
            logger.info("Dispatching notification #{} (Attempt {}/{}) via {} to {}",
                    notification.getId(), currentAttempt, notification.getMaxRetries(),
                    notification.getChannel(), notification.getRecipientTo());

            result = notificationDispatcher.dispatch(notification);
        } catch (Exception ex) {
            result = NotificationDispatchResult.failure("UNHANDLED_EXCEPTION", ex.getMessage(), 0);
        }

        if (result.isSuccess()) {
            // Mark as SENT with delivery timestamp and details
            notification.setStatus(NotificationStatus.SENT);
            notification.setSentAt(OffsetDateTime.now());
            notification.setErrorMessage(null);
            notification.setUpdatedAt(OffsetDateTime.now());
            notificationRepository.save(notification);

            // Record audit log
            NotificationAuditLog auditLog = new NotificationAuditLog(
                    notification.getId(),
                    notification.getCompanyId(),
                    notification.getChannel(),
                    notification.getRecipientTo(),
                    currentAttempt,
                    AuditStatus.SUCCESS,
                    result.getProviderResponseCode(),
                    null,
                    result.getDurationMs()
            );
            auditLogRepository.save(auditLog);

            logger.info("✓ Successfully sent notification #{} via {} to {}",
                    notification.getId(), notification.getChannel(), notification.getRecipientTo());
        } else {
            // Failed attempt
            int updatedRetries = notification.getRetryCount() + 1;
            notification.setRetryCount(updatedRetries);
            notification.setErrorMessage(result.getErrorMessage());
            notification.setUpdatedAt(OffsetDateTime.now());

            boolean isPermanentlyStuck = updatedRetries >= notification.getMaxRetries();

            if (isPermanentlyStuck) {
                // Exhausted max retries -> Mark as FAILED / STUCK
                notification.setStatus(NotificationStatus.FAILED);
                notificationRepository.save(notification);

                NotificationAuditLog auditLog = new NotificationAuditLog(
                        notification.getId(),
                        notification.getCompanyId(),
                        notification.getChannel(),
                        notification.getRecipientTo(),
                        updatedRetries,
                        AuditStatus.STUCK,
                        result.getProviderResponseCode(),
                        result.getErrorMessage(),
                        result.getDurationMs()
                );
                auditLogRepository.save(auditLog);

                logger.warn("✗ Notification #{} exhausted retries and is marked as STUCK/FAILED: {}",
                        notification.getId(), result.getErrorMessage());
            } else {
                // Schedule backoff retry
                notification.setStatus(NotificationStatus.PENDING);
                long backoffSeconds = 30L * updatedRetries; // 30s, 60s, 90s...
                notification.setScheduledAt(OffsetDateTime.now().plusSeconds(backoffSeconds));
                notificationRepository.save(notification);

                NotificationAuditLog auditLog = new NotificationAuditLog(
                        notification.getId(),
                        notification.getCompanyId(),
                        notification.getChannel(),
                        notification.getRecipientTo(),
                        updatedRetries,
                        AuditStatus.RETRYING,
                        result.getProviderResponseCode(),
                        result.getErrorMessage(),
                        result.getDurationMs()
                );
                auditLogRepository.save(auditLog);

                logger.warn("Notification #{} attempt {} failed. Retrying in {}s. Reason: {}",
                        notification.getId(), updatedRetries, backoffSeconds, result.getErrorMessage());
            }
        }
    }
}
