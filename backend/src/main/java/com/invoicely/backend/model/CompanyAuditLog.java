package com.invoicely.backend.model;

import jakarta.persistence.*;
import java.time.OffsetDateTime;

@Entity
@Table(name = "company_audit_logs", indexes = {
    @Index(name = "idx_audit_logs_company_id", columnList = "company_id"),
    @Index(name = "idx_audit_logs_company_module", columnList = "company_id, module")
})
public class CompanyAuditLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "company_id")
    private Long companyId;

    @Column(name = "user_id")
    private Long userId;

    @Column(name = "user_name")
    private String userName = "";

    @Column(name = "user_role")
    private String userRole = "STAFF";

    @Column(nullable = false, length = 50)
    private String module = "GENERAL"; // INVOICE, EXPENSE, CLIENT, EMPLOYEE, TEAM, SETTINGS, AUTH

    @Column(nullable = false, length = 50)
    private String action = "VIEW"; // CREATE, UPDATE, DELETE, STATUS_CHANGE, EXPORT_PDF, SCAN_OCR, ROLE_CHANGE

    @Column(name = "entity_id", length = 100)
    private String entityId = "";

    @Column(nullable = false)
    private String title = "";

    @Column(columnDefinition = "TEXT")
    private String description = "";

    @Column(name = "metadata_json", columnDefinition = "TEXT")
    private String metadataJson = "{}";

    @Column(name = "created_at")
    private OffsetDateTime createdAt = OffsetDateTime.now();

    public CompanyAuditLog() {}

    public CompanyAuditLog(Long companyId, Long userId, String userName, String userRole,
                           String module, String action, String entityId,
                           String title, String description, String metadataJson) {
        this.companyId = companyId;
        this.userId = userId;
        this.userName = userName != null ? userName : "";
        this.userRole = userRole != null ? userRole : "STAFF";
        this.module = module != null ? module : "GENERAL";
        this.action = action != null ? action : "VIEW";
        this.entityId = entityId != null ? entityId : "";
        this.title = title != null ? title : "";
        this.description = description != null ? description : "";
        this.metadataJson = metadataJson != null ? metadataJson : "{}";
        this.createdAt = OffsetDateTime.now();
    }

    @PrePersist
    public void prePersist() {
        if (createdAt == null) createdAt = OffsetDateTime.now();
    }

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getCompanyId() { return companyId; }
    public void setCompanyId(Long companyId) { this.companyId = companyId; }

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public String getUserName() { return userName; }
    public void setUserName(String userName) { this.userName = userName; }

    public String getUserRole() { return userRole; }
    public void setUserRole(String userRole) { this.userRole = userRole; }

    public String getModule() { return module; }
    public void setModule(String module) { this.module = module; }

    public String getAction() { return action; }
    public void setAction(String action) { this.action = action; }

    public String getEntityId() { return entityId; }
    public void setEntityId(String entityId) { this.entityId = entityId; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getMetadataJson() { return metadataJson; }
    public void setMetadataJson(String metadataJson) { this.metadataJson = metadataJson; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }
}
