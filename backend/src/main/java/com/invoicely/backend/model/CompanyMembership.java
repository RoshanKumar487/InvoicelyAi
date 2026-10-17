package com.invoicely.backend.model;

import jakarta.persistence.*;
import java.time.OffsetDateTime;

/**
 * Tracks a user's role and membership in a specific company workspace.
 * Enables true multi-tenant, multi-company support where a single user
 * can own or work across multiple companies and switch between them.
 */
@Entity
@Table(name = "company_memberships", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"user_id", "company_id"})
})
public class CompanyMembership {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "company_id", nullable = false)
    private Long companyId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private Role role = Role.ADMIN;

    @Column(name = "is_default")
    private Boolean isDefault = false;

    @Column(name = "created_at")
    private OffsetDateTime createdAt = OffsetDateTime.now();

    public CompanyMembership() {}

    public CompanyMembership(Long userId, Long companyId, Role role, Boolean isDefault) {
        this.userId = userId;
        this.companyId = companyId;
        this.role = role != null ? role : Role.ADMIN;
        this.isDefault = isDefault != null ? isDefault : false;
        this.createdAt = OffsetDateTime.now();
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public Long getCompanyId() {
        return companyId;
    }

    public void setCompanyId(Long companyId) {
        this.companyId = companyId;
    }

    public Role getRole() {
        return role;
    }

    public void setRole(Role role) {
        this.role = role;
    }

    public Boolean getIsDefault() {
        return isDefault;
    }

    public void setIsDefault(Boolean isDefault) {
        this.isDefault = isDefault;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(OffsetDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
