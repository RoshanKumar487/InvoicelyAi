package com.invoicely.backend.service;

import com.invoicely.backend.model.CompanyAuditLog;
import com.invoicely.backend.repository.CompanyAuditLogRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;

@Service
public class AuditLogService {

    private final CompanyAuditLogRepository auditLogRepository;

    @Autowired
    public AuditLogService(CompanyAuditLogRepository auditLogRepository) {
        this.auditLogRepository = auditLogRepository;
    }

    public List<CompanyAuditLog> getAuditLogs(Long companyId, Long userId, String module, String action) {
        List<CompanyAuditLog> logs;
        if (companyId != null && userId != null) {
            logs = auditLogRepository.findByCompanyIdAndUserIdOrderByCreatedAtDesc(companyId, userId);
        } else if (companyId != null) {
            logs = auditLogRepository.findByCompanyIdOrderByCreatedAtDesc(companyId);
        } else {
            logs = auditLogRepository.findAllByOrderByCreatedAtDesc();
        }

        return logs.stream()
                .filter(log -> {
                    if (module == null || module.trim().isEmpty() || module.equalsIgnoreCase("ALL")) {
                        return true;
                    }
                    return module.trim().equalsIgnoreCase(log.getModule());
                })
                .filter(log -> {
                    if (action == null || action.trim().isEmpty() || action.equalsIgnoreCase("ALL")) {
                        return true;
                    }
                    return action.trim().equalsIgnoreCase(log.getAction());
                })
                .toList();
    }

    @Transactional
    public CompanyAuditLog recordLog(CompanyAuditLog log) {
        if (log.getCreatedAt() == null) {
            log.setCreatedAt(OffsetDateTime.now());
        }
        if (log.getTitle() == null || log.getTitle().trim().isEmpty()) {
            log.setTitle(String.format("%s %s", log.getModule(), log.getAction()));
        }
        return auditLogRepository.save(log);
    }

    @Transactional
    public CompanyAuditLog recordActivity(Long companyId, Long userId, String userName, String userRole,
                                          String module, String action, String entityId,
                                          String title, String description, String metadataJson) {
        CompanyAuditLog log = new CompanyAuditLog(
                companyId, userId, userName, userRole, module, action, entityId, title, description, metadataJson
        );
        return auditLogRepository.save(log);
    }
}
