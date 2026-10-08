package com.invoicely.backend.controller;

import com.invoicely.backend.dto.ApiResponse;
import com.invoicely.backend.model.BusinessProfile;
import com.invoicely.backend.model.Role;
import com.invoicely.backend.security.UserPrincipal;
import com.invoicely.backend.service.BusinessProfileService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/profile")
@Tag(name = "Business Profile", description = "Company settings, legal info, banking, and branding (Multi-Tenant)")
public class BusinessProfileController {

    private final BusinessProfileService profileService;

    @Autowired
    public BusinessProfileController(BusinessProfileService profileService) {
        this.profileService = profileService;
    }

    @GetMapping
    @Operation(summary = "Get current business profile & settings for the authenticated company")
    public ResponseEntity<ApiResponse<BusinessProfile>> getProfile(@AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = resolveCompanyId(principal);
        return ResponseEntity.ok(ApiResponse.ok(profileService.getProfile(companyId)));
    }

    @PutMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'DEVELOPER')")
    @Operation(summary = "Update business profile & banking information (Admin / Developer)")
    public ResponseEntity<ApiResponse<BusinessProfile>> updateProfile(
            @RequestBody BusinessProfile profile,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = resolveCompanyId(principal);
        return ResponseEntity.ok(ApiResponse.ok("Business profile updated successfully", profileService.updateProfile(profile, companyId)));
    }

    private Long resolveCompanyId(UserPrincipal principal) {
        if (principal == null) return null;
        if (principal.getRole() == Role.DEVELOPER) return null;
        return principal.getCompanyId();
    }
}
