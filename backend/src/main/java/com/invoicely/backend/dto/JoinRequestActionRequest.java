package com.invoicely.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public class JoinRequestActionRequest {

    @NotBlank(message = "Action is required")
    @Pattern(regexp = "APPROVE|REJECT", message = "Action must be APPROVE or REJECT")
    private String action; // APPROVE or REJECT

    public JoinRequestActionRequest() {}

    public JoinRequestActionRequest(String action) {
        this.action = action;
    }

    public String getAction() { return action; }
    public void setAction(String action) { this.action = action; }
}
