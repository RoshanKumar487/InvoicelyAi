package com.invoicely.backend.repository;

import com.invoicely.backend.model.NotificationChannel;
import com.invoicely.backend.model.NotificationTemplate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface NotificationTemplateRepository extends JpaRepository<NotificationTemplate, Long> {

    List<NotificationTemplate> findByCompanyId(Long companyId);

    List<NotificationTemplate> findByCompanyIdAndIsActiveTrue(Long companyId);

    Optional<NotificationTemplate> findByCompanyIdAndTemplateName(Long companyId, String templateName);

    Optional<NotificationTemplate> findByCompanyIdIsNullAndTemplateName(String templateName);

    List<NotificationTemplate> findByCompanyIdIsNull();

    @Query("SELECT t FROM NotificationTemplate t WHERE (t.companyId = :companyId OR t.companyId IS NULL) AND t.isActive = true ORDER BY t.templateName ASC")
    List<NotificationTemplate> findAllForCompany(@Param("companyId") Long companyId);

    Optional<NotificationTemplate> findByCompanyIdAndTemplateNameAndChannel(Long companyId, String templateName, NotificationChannel channel);

    Optional<NotificationTemplate> findByCompanyIdIsNullAndTemplateNameAndChannel(String templateName, NotificationChannel channel);
}
