package com.invoicely.backend.dto;

import com.invoicely.backend.model.Role;
import com.invoicely.backend.model.User;
import com.invoicely.backend.model.UserStatus;

public class UserSummaryDto {
    private Long id;
    private String fullName;
    private String email;
    private String mobile;
    private Role role;
    private UserStatus status;
    private Long companyId;

    public UserSummaryDto() {}

    public UserSummaryDto(User user) {
        this.id = user.getId();
        this.fullName = user.getFullName();
        this.email = user.getEmail();
        this.mobile = user.getMobile();
        this.role = user.getRole();
        this.status = user.getStatus();
        this.companyId = user.getCompanyId();
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getMobile() { return mobile; }
    public void setMobile(String mobile) { this.mobile = mobile; }

    public Role getRole() { return role; }
    public void setRole(Role role) { this.role = role; }

    public UserStatus getStatus() { return status; }
    public void setStatus(UserStatus status) { this.status = status; }

    public Long getCompanyId() { return companyId; }
    public void setCompanyId(Long companyId) { this.companyId = companyId; }
}
