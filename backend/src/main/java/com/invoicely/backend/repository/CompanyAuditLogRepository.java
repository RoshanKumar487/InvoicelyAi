package com.invoicely.backend.repository;

import com.invoicely.backend.model.CompanyAuditLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CompanyAuditLogRepository extends JpaRepository<CompanyAuditLog, Long> {

    List<CompanyAuditLog> findByCompanyIdOrderByCreatedAtDesc(Long companyId);

    List<CompanyAuditLog> findByCompanyIdAndUserIdOrderByCreatedAtDesc(Long companyId, Long userId);

    List<CompanyAuditLog> findAllByOrderByCreatedAtDesc();

    long countByCompanyId(Long companyId);
}
