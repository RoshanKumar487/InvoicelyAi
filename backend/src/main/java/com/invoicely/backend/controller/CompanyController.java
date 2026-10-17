package com.invoicely.backend.controller;

import com.invoicely.backend.dto.*;
import com.invoicely.backend.security.UserPrincipal;
import com.invoicely.backend.service.CompanyService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/companies")
@Tag(name = "Companies & Workspaces", description = "Multi-tenant company setup, workspace switching, and member role management")
public class CompanyController {

    private final CompanyService companyService;

    public CompanyController(CompanyService companyService) {
        this.companyService = companyService;
    }

    @GetMapping("/my-company")
    @Operation(summary = "Get the company profile and unique company code for the current authenticated user")
    public ResponseEntity<ApiResponse<CompanySummaryDto>> getMyCompany(@AuthenticationPrincipal UserPrincipal principal) {
        CompanySummaryDto company = companyService.getMyCompany(principal);
        return ResponseEntity.ok(ApiResponse.ok(company));
    }

    @PutMapping("/my-company")
    @PreAuthorize("hasAnyRole('ADMIN', 'DEVELOPER')")
    @Operation(summary = "Update current company workspace profile & branding settings (Admin / Developer)")
    public ResponseEntity<ApiResponse<CompanySummaryDto>> updateMyCompany(
            @Valid @RequestBody UpdateCompanyRequest request,
            @AuthenticationPrincipal UserPrincipal principal) {
        CompanySummaryDto updated = companyService.updateMyCompany(request, principal);
        return ResponseEntity.ok(ApiResponse.ok("Company profile updated successfully", updated));
    }

    @GetMapping("/my-companies")
    @Operation(summary = "List all company workspaces accessible to the authenticated user for multi-company switching")
    public ResponseEntity<ApiResponse<List<CompanySummaryDto>>> getMyCompanies(@AuthenticationPrincipal UserPrincipal principal) {
        List<CompanySummaryDto> companies = companyService.getMyCompanies(principal);
        return ResponseEntity.ok(ApiResponse.ok(companies));
    }

    @PostMapping
    @Operation(summary = "Create an additional company workspace under the authenticated account")
    public ResponseEntity<ApiResponse<AuthResponse>> createCompanyWorkspace(
            @Valid @RequestBody CreateWorkspaceRequest request,
            @AuthenticationPrincipal UserPrincipal principal) {
        AuthResponse response = companyService.createCompanyWorkspace(request, principal);
        return new ResponseEntity<>(ApiResponse.ok("Company workspace created successfully", response), HttpStatus.CREATED);
    }

    @GetMapping("/join-requests")
    @PreAuthorize("hasAnyRole('ADMIN', 'DEVELOPER')")
    @Operation(summary = "Get pending or historical join requests from employees (Admin / Developer)")
    public ResponseEntity<ApiResponse<List<CompanyJoinRequestDto>>> getJoinRequests(
            @RequestParam(required = false) String status,
            @AuthenticationPrincipal UserPrincipal principal) {
        List<CompanyJoinRequestDto> requests = companyService.getJoinRequests(principal, status);
        return ResponseEntity.ok(ApiResponse.ok(requests));
    }

    @PostMapping("/join-requests/{id}/action")
    @PreAuthorize("hasAnyRole('ADMIN', 'DEVELOPER')")
    @Operation(summary = "Approve or Reject an employee join request (Admin / Developer)")
    public ResponseEntity<ApiResponse<CompanyJoinRequestDto>> processJoinRequest(
            @PathVariable Long id,
            @Valid @RequestBody JoinRequestActionRequest actionRequest,
            @AuthenticationPrincipal UserPrincipal principal) {
        CompanyJoinRequestDto result = companyService.processJoinRequest(id, actionRequest, principal);
        return ResponseEntity.ok(ApiResponse.ok("Join request " + actionRequest.getAction().toLowerCase() + "d successfully", result));
    }

    @GetMapping("/employees")
    @PreAuthorize("hasAnyRole('ADMIN', 'DEVELOPER')")
    @Operation(summary = "Get all registered and pending employees for the current company (Admin / Developer)")
    public ResponseEntity<ApiResponse<List<UserSummaryDto>>> getEmployees(@AuthenticationPrincipal UserPrincipal principal) {
        List<UserSummaryDto> employees = companyService.getCompanyEmployees(principal);
        return ResponseEntity.ok(ApiResponse.ok(employees));
    }

    @PutMapping("/employees/{id}/permissions")
    @PreAuthorize("hasAnyRole('ADMIN', 'DEVELOPER')")
    @Operation(summary = "Update employee tool permissions / feature access (Admin / Developer)")
    public ResponseEntity<ApiResponse<UserSummaryDto>> updateEmployeePermissions(
            @PathVariable Long id,
            @Valid @RequestBody com.invoicely.backend.dto.UpdateEmployeePermissionsRequest request,
            @AuthenticationPrincipal UserPrincipal principal) {
        UserSummaryDto updated = companyService.updateEmployeePermissions(id, request.getPermissions(), principal);
        return ResponseEntity.ok(ApiResponse.ok("Employee tool access updated successfully", updated));
    }

    @PutMapping("/employees/{id}/role")
    @PreAuthorize("hasAnyRole('ADMIN', 'DEVELOPER')")
    @Operation(summary = "Update employee role (Promote to Admin / Staff) and feature permissions (Admin / Developer)")
    public ResponseEntity<ApiResponse<UserSummaryDto>> updateEmployeeRole(
            @PathVariable Long id,
            @RequestBody com.invoicely.backend.dto.UpdateEmployeeRoleRequest request,
            @AuthenticationPrincipal UserPrincipal principal) {
        UserSummaryDto updated = companyService.updateEmployeeRole(id, request.getRole(), request.getPermissions(), principal);
        return ResponseEntity.ok(ApiResponse.ok("Employee role updated successfully", updated));
    }

    @GetMapping("/all")
    @PreAuthorize("hasRole('DEVELOPER')")
    @Operation(summary = "Get all registered companies across the platform (Developer only)")
    public ResponseEntity<ApiResponse<List<CompanySummaryDto>>> getAllCompanies(@AuthenticationPrincipal UserPrincipal principal) {
        List<CompanySummaryDto> companies = companyService.getAllCompanies(principal);
        return ResponseEntity.ok(ApiResponse.ok(companies));
    }
}
