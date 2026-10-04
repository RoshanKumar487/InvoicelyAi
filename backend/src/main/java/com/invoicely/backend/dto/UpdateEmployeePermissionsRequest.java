package com.invoicely.backend.dto;

import jakarta.validation.constraints.NotBlank;

public class UpdateEmployeePermissionsRequest {

    @NotBlank(message = "Permissions string must not be empty")
    private String permissions;

    public UpdateEmployeePermissionsRequest() {}

    public UpdateEmployeePermissionsRequest(String permissions) {
        this.permissions = permissions;
    }

    public String getPermissions() {
        return permissions;
    }

    public void setPermissions(String permissions) {
        this.permissions = permissions;
    }
}
