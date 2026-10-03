package com.invoicely.backend.model;

import jakarta.persistence.*;
import java.time.OffsetDateTime;

@Entity
@Table(name = "company_join_requests")
public class CompanyJoinRequest {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "company_id", nullable = false)
    private Long companyId;

    @Column(name = "user_full_name")
    private String userFullName;

    @Column(name = "user_email")
    private String userEmail;

    @Column(name = "user_mobile")
    private String userMobile;

    @Column(name = "company_name")
    private String companyName;

    @Column(name = "company_code")
    private String companyCode;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private JoinRequestStatus status = JoinRequestStatus.PENDING;

    @Column(name = "request_message", columnDefinition = "TEXT")
    private String requestMessage;

    @Column(name = "requested_at")
    private OffsetDateTime requestedAt = OffsetDateTime.now();

    @Column(name = "reviewed_at")
    private OffsetDateTime reviewedAt;

    @Column(name = "reviewed_by_user_id")
    private Long reviewedByUserId;

    public CompanyJoinRequest() {}

    public CompanyJoinRequest(Long userId, Long companyId, String userFullName, String userEmail, String userMobile,
                              String companyName, String companyCode, String requestMessage) {
        this.userId = userId;
        this.companyId = companyId;
        this.userFullName = userFullName;
        this.userEmail = userEmail;
        this.userMobile = userMobile;
        this.companyName = companyName;
        this.companyCode = companyCode;
        this.requestMessage = requestMessage;
        this.status = JoinRequestStatus.PENDING;
        this.requestedAt = OffsetDateTime.now();
    }

    // Getters and Setters
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

    public String getUserFullName() {
        return userFullName;
    }

    public void setUserFullName(String userFullName) {
        this.userFullName = userFullName;
    }

    public String getUserEmail() {
        return userEmail;
    }

    public void setUserEmail(String userEmail) {
        this.userEmail = userEmail;
    }

    public String getUserMobile() {
        return userMobile;
    }

    public void setUserMobile(String userMobile) {
        this.userMobile = userMobile;
    }

    public String getCompanyName() {
        return companyName;
    }

    public void setCompanyName(String companyName) {
        this.companyName = companyName;
    }

    public String getCompanyCode() {
        return companyCode;
    }

    public void setCompanyCode(String companyCode) {
        this.companyCode = companyCode;
    }

    public JoinRequestStatus getStatus() {
        return status;
    }

    public void setStatus(JoinRequestStatus status) {
        this.status = status;
    }

    public String getRequestMessage() {
        return requestMessage;
    }

    public void setRequestMessage(String requestMessage) {
        this.requestMessage = requestMessage;
    }

    public OffsetDateTime getRequestedAt() {
        return requestedAt;
    }

    public void setRequestedAt(OffsetDateTime requestedAt) {
        this.requestedAt = requestedAt;
    }

    public OffsetDateTime getReviewedAt() {
        return reviewedAt;
    }

    public void setReviewedAt(OffsetDateTime reviewedAt) {
        this.reviewedAt = reviewedAt;
    }

    public Long getReviewedByUserId() {
        return reviewedByUserId;
    }

    public void setReviewedByUserId(Long reviewedByUserId) {
        this.reviewedByUserId = reviewedByUserId;
    }
}
