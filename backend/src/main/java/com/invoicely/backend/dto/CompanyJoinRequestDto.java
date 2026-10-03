package com.invoicely.backend.dto;

import com.invoicely.backend.model.CompanyJoinRequest;
import com.invoicely.backend.model.JoinRequestStatus;

import java.time.OffsetDateTime;

public class CompanyJoinRequestDto {
    private Long id;
    private Long userId;
    private Long companyId;
    private String userFullName;
    private String userEmail;
    private String userMobile;
    private String companyName;
    private String companyCode;
    private JoinRequestStatus status;
    private String requestMessage;
    private OffsetDateTime requestedAt;
    private OffsetDateTime reviewedAt;
    private Long reviewedByUserId;

    public CompanyJoinRequestDto() {}

    public CompanyJoinRequestDto(CompanyJoinRequest req) {
        this.id = req.getId();
        this.userId = req.getUserId();
        this.companyId = req.getCompanyId();
        this.userFullName = req.getUserFullName();
        this.userEmail = req.getUserEmail();
        this.userMobile = req.getUserMobile();
        this.companyName = req.getCompanyName();
        this.companyCode = req.getCompanyCode();
        this.status = req.getStatus();
        this.requestMessage = req.getRequestMessage();
        this.requestedAt = req.getRequestedAt();
        this.reviewedAt = req.getReviewedAt();
        this.reviewedByUserId = req.getReviewedByUserId();
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public Long getCompanyId() { return companyId; }
    public void setCompanyId(Long companyId) { this.companyId = companyId; }

    public String getUserFullName() { return userFullName; }
    public void setUserFullName(String userFullName) { this.userFullName = userFullName; }

    public String getUserEmail() { return userEmail; }
    public void setUserEmail(String userEmail) { this.userEmail = userEmail; }

    public String getUserMobile() { return userMobile; }
    public void setUserMobile(String userMobile) { this.userMobile = userMobile; }

    public String getCompanyName() { return companyName; }
    public void setCompanyName(String companyName) { this.companyName = companyName; }

    public String getCompanyCode() { return companyCode; }
    public void setCompanyCode(String companyCode) { this.companyCode = companyCode; }

    public JoinRequestStatus getStatus() { return status; }
    public void setStatus(JoinRequestStatus status) { this.status = status; }

    public String getRequestMessage() { return requestMessage; }
    public void setRequestMessage(String requestMessage) { this.requestMessage = requestMessage; }

    public OffsetDateTime getRequestedAt() { return requestedAt; }
    public void setRequestedAt(OffsetDateTime requestedAt) { this.requestedAt = requestedAt; }

    public OffsetDateTime getReviewedAt() { return reviewedAt; }
    public void setReviewedAt(OffsetDateTime reviewedAt) { this.reviewedAt = reviewedAt; }

    public Long getReviewedByUserId() { return reviewedByUserId; }
    public void setReviewedByUserId(Long reviewedByUserId) { this.reviewedByUserId = reviewedByUserId; }
}
