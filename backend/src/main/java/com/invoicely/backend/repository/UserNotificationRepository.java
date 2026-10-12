package com.invoicely.backend.repository;

import com.invoicely.backend.model.NotificationChannel;
import com.invoicely.backend.model.NotificationStatus;
import com.invoicely.backend.model.UserNotification;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.OffsetDateTime;
import java.util.List;

@Repository
public interface UserNotificationRepository extends JpaRepository<UserNotification, Long> {

    @Query("SELECT n FROM UserNotification n WHERE n.status = 'PENDING' AND n.scheduledAt <= :now ORDER BY n.scheduledAt ASC, n.createdAt ASC")
    List<UserNotification> findReadyForDispatch(@Param("now") OffsetDateTime now, Pageable pageable);

    Page<UserNotification> findByCompanyId(Long companyId, Pageable pageable);

    Page<UserNotification> findByCompanyIdAndStatus(Long companyId, NotificationStatus status, Pageable pageable);

    Page<UserNotification> findByCompanyIdAndChannel(Long companyId, NotificationChannel channel, Pageable pageable);

    Page<UserNotification> findByCompanyIdAndStatusAndChannel(Long companyId, NotificationStatus status, NotificationChannel channel, Pageable pageable);

    long countByCompanyIdAndStatus(Long companyId, NotificationStatus status);

    long countByCompanyId(Long companyId);

    @Query("SELECT n FROM UserNotification n WHERE n.status = 'FAILED' OR (n.status = 'PROCESSING' AND n.updatedAt <= :stuckThreshold)")
    List<UserNotification> findStuckNotifications(@Param("stuckThreshold") OffsetDateTime stuckThreshold);
}
