package com.invoicely.backend.dto;

public class UpdateEmployeeRoleRequest {

    private String role; // ADMIN, MANAGER, EMPLOYEE, ACCOUNTANT, VIEWER
    private String permissions; // INVOICES,EXPENSES,CLIENTS,REPORTS,EMPLOYEES,AUDIT_LOGS,SETTINGS

    public UpdateEmployeeRoleRequest() {}

    public UpdateEmployeeRoleRequest(String role, String permissions) {
        this.role = role;
        this.permissions = permissions;
    }

    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }

    public String getPermissions() { return permissions; }
    public void setPermissions(String permissions) { this.permissions = permissions; }
}
