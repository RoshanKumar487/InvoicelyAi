package com.invoicely.backend.repository;

import com.invoicely.backend.model.AuditStatus;
import com.invoicely.backend.model.NotificationAuditLog;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface NotificationAuditLogRepository extends JpaRepository<NotificationAuditLog, Long> {

    List<NotificationAuditLog> findByNotificationIdOrderByCreatedAtDesc(Long notificationId);

    Page<NotificationAuditLog> findByCompanyIdOrderByCreatedAtDesc(Long companyId, Pageable pageable);

    Page<NotificationAuditLog> findByCompanyIdAndStatusOrderByCreatedAtDesc(Long companyId, AuditStatus status, Pageable pageable);

    long countByCompanyIdAndStatus(Long companyId, AuditStatus status);
}
