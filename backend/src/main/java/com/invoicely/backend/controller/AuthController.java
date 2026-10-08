package com.invoicely.backend.controller;

import com.invoicely.backend.dto.*;
import com.invoicely.backend.security.UserPrincipal;
import com.invoicely.backend.service.AuthService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/auth")
@Tag(name = "Authentication", description = "Multi-tenant registration, RBAC login, and profile operations")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/register-company")
    @Operation(summary = "Register a new company and create the primary ADMIN user")
    public ResponseEntity<ApiResponse<AuthResponse>> registerCompany(@Valid @RequestBody RegisterCompanyRequest request) {
        AuthResponse response = authService.registerCompany(request);
        return new ResponseEntity<>(ApiResponse.ok("Company created successfully", response), HttpStatus.CREATED);
    }

    @PostMapping("/register-employee")
    @Operation(summary = "Register an employee requesting to join an existing company (Requires Admin approval)")
    public ResponseEntity<ApiResponse<AuthResponse>> registerEmployee(@Valid @RequestBody RegisterEmployeeRequest request) {
        AuthResponse response = authService.registerEmployee(request);
        return new ResponseEntity<>(ApiResponse.ok("Employee join request submitted", response), HttpStatus.CREATED);
    }

    @PostMapping("/register-developer")
    @Operation(summary = "Register a platform DEVELOPER with global system permissions")
    public ResponseEntity<ApiResponse<AuthResponse>> registerDeveloper(@Valid @RequestBody RegisterDeveloperRequest request) {
        AuthResponse response = authService.registerDeveloper(request);
        return new ResponseEntity<>(ApiResponse.ok("Developer registered successfully", response), HttpStatus.CREATED);
    }

    @PostMapping("/login")
    @Operation(summary = "Authenticate user (Developer, Admin, or approved Employee) and return JWT token")
    public ResponseEntity<ApiResponse<AuthResponse>> login(@Valid @RequestBody LoginRequest request) {
        AuthResponse response = authService.login(request);
        return ResponseEntity.ok(ApiResponse.ok("Login successful", response));
    }

    @PostMapping("/reset-password")
    @Operation(summary = "Reset or update user password by email or mobile identifier")
    public ResponseEntity<ApiResponse<AuthResponse>> resetPassword(@Valid @RequestBody ResetPasswordRequest request) {
        AuthResponse response = authService.resetPassword(request);
        return ResponseEntity.ok(ApiResponse.ok("Password updated successfully", response));
    }

    @GetMapping("/me")
    @Operation(summary = "Get current authenticated user profile and assigned company details")
    public ResponseEntity<ApiResponse<AuthResponse>> getMe(@AuthenticationPrincipal UserPrincipal principal) {
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(ApiResponse.error("Unauthorized"));
        }
        AuthResponse response = authService.getMe(principal);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }
}
