package com.invoicely.backend.service;

import com.invoicely.backend.dto.*;
import com.invoicely.backend.exception.ResourceNotFoundException;
import com.invoicely.backend.model.*;
import com.invoicely.backend.repository.CompanyJoinRequestRepository;
import com.invoicely.backend.repository.CompanyRepository;
import com.invoicely.backend.repository.UserRepository;
import com.invoicely.backend.security.JwtTokenProvider;
import com.invoicely.backend.security.UserPrincipal;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Locale;
import java.util.UUID;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final CompanyRepository companyRepository;
    private final CompanyJoinRequestRepository joinRequestRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider tokenProvider;
    private final String developerSecretKey;

    public AuthService(
            UserRepository userRepository,
            CompanyRepository companyRepository,
            CompanyJoinRequestRepository joinRequestRepository,
            PasswordEncoder passwordEncoder,
            JwtTokenProvider tokenProvider,
            @Value("${app.developer.secret-key:invoicely_dev_secret_2026}") String developerSecretKey
    ) {
        this.userRepository = userRepository;
        this.companyRepository = companyRepository;
        this.joinRequestRepository = joinRequestRepository;
        this.passwordEncoder = passwordEncoder;
        this.tokenProvider = tokenProvider;
        this.developerSecretKey = developerSecretKey;
    }

    @Transactional
    public AuthResponse registerCompany(RegisterCompanyRequest request) {
        if (userRepository.existsByEmail(request.getEmail().trim().toLowerCase(Locale.ROOT))) {
            throw new IllegalArgumentException("Email is already registered: " + request.getEmail());
        }

        // Generate unique company code
        String companyCode = generateUniqueCompanyCode(request.getCompanyName());

        Company company = new Company(
                companyCode,
                request.getCompanyName().trim(),
                request.getDetails(),
                request.getGstin(),
                request.getLocation(),
                request.getSignatureStampUrl()
        );
        company.setEmail(request.getEmail().trim().toLowerCase(Locale.ROOT));
        company.setPhone(request.getMobile().trim());
        company = companyRepository.save(company);

        // Creator receives ADMIN role and ACTIVE status
        User adminUser = new User(
                request.getFullName().trim(),
                request.getEmail().trim().toLowerCase(Locale.ROOT),
                request.getMobile().trim(),
                passwordEncoder.encode(request.getPassword()),
                Role.ADMIN,
                UserStatus.ACTIVE,
                company.getId()
        );
        adminUser = userRepository.save(adminUser);

        String token = tokenProvider.generateToken(adminUser);
        return new AuthResponse(
                token,
                new UserSummaryDto(adminUser),
                new CompanySummaryDto(company),
                "Company and Admin registered successfully. Share Company Code '" + companyCode + "' with your employees."
        );
    }

    @Transactional
    public AuthResponse registerEmployee(RegisterEmployeeRequest request) {
        if (userRepository.existsByEmail(request.getEmail().trim().toLowerCase(Locale.ROOT))) {
            throw new IllegalArgumentException("Email is already registered: " + request.getEmail());
        }

        String searchCode = request.getCompanyCode().trim().toUpperCase(Locale.ROOT);
        Company company = companyRepository.findByCompanyCode(searchCode)
                .orElseGet(() -> companyRepository.findByCompanyNameIgnoreCase(request.getCompanyCode().trim())
                        .orElseThrow(() -> new ResourceNotFoundException("Company", "companyCode", request.getCompanyCode())));

        // Employee is registered with PENDING_APPROVAL status
        User employee = new User(
                request.getFullName().trim(),
                request.getEmail().trim().toLowerCase(Locale.ROOT),
                request.getMobile().trim(),
                passwordEncoder.encode(request.getPassword()),
                Role.EMPLOYEE,
                UserStatus.PENDING_APPROVAL,
                company.getId()
        );
        employee = userRepository.save(employee);

        CompanyJoinRequest joinRequest = new CompanyJoinRequest(
                employee.getId(),
                company.getId(),
                employee.getFullName(),
                employee.getEmail(),
                employee.getMobile(),
                company.getCompanyName(),
                company.getCompanyCode(),
                request.getRequestMessage() != null ? request.getRequestMessage() : "Employee join request"
        );
        joinRequestRepository.save(joinRequest);

        return new AuthResponse(
                null,
                new UserSummaryDto(employee),
                new CompanySummaryDto(company),
                "Join request submitted to " + company.getCompanyName() + ". An administrator must approve your account before you can log in."
        );
    }

    @Transactional
    public AuthResponse registerDeveloper(RegisterDeveloperRequest request) {
        if (!developerSecretKey.equals(request.getDeveloperSecretKey())) {
            throw new IllegalArgumentException("Invalid Developer secret registration key.");
        }

        if (userRepository.existsByEmail(request.getEmail().trim().toLowerCase(Locale.ROOT))) {
            throw new IllegalArgumentException("Email is already registered: " + request.getEmail());
        }

        User developer = new User(
                request.getFullName().trim(),
                request.getEmail().trim().toLowerCase(Locale.ROOT),
                request.getMobile().trim(),
                passwordEncoder.encode(request.getPassword()),
                Role.DEVELOPER,
                UserStatus.ACTIVE,
                null
        );
        developer = userRepository.save(developer);

        String token = tokenProvider.generateToken(developer);
        return new AuthResponse(
                token,
                new UserSummaryDto(developer),
                null,
                "Developer account activated with global access."
        );
    }

    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {
        String identifier = request.getIdentifier().trim().toLowerCase(Locale.ROOT);
        User user = userRepository.findByEmailOrMobile(identifier, identifier)
                .orElseThrow(() -> new IllegalArgumentException("Invalid email/mobile or password"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
            throw new IllegalArgumentException("Invalid email/mobile or password");
        }

        if (user.getStatus() == UserStatus.PENDING_APPROVAL) {
            throw new IllegalStateException("Your account registration is pending approval by your company administrator.");
        }

        if (user.getStatus() == UserStatus.REJECTED) {
            throw new IllegalStateException("Your account registration was rejected by the company administrator.");
        }

        if (user.getStatus() == UserStatus.INACTIVE) {
            throw new IllegalStateException("Your account is currently disabled. Please contact your company administrator.");
        }

        Company company = null;
        if (user.getCompanyId() != null) {
            company = companyRepository.findById(user.getCompanyId()).orElse(null);
        }

        String token = tokenProvider.generateToken(user);
        return new AuthResponse(
                token,
                new UserSummaryDto(user),
                company != null ? new CompanySummaryDto(company) : null,
                "Authentication successful"
        );
    }

    @Transactional(readOnly = true)
    public AuthResponse getMe(UserPrincipal principal) {
        User user = userRepository.findById(principal.getId())
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", principal.getId()));

        Company company = null;
        if (user.getCompanyId() != null) {
            company = companyRepository.findById(user.getCompanyId()).orElse(null);
        }

        return new AuthResponse(
                null,
                new UserSummaryDto(user),
                company != null ? new CompanySummaryDto(company) : null,
                "User profile retrieved"
        );
    }

    private String generateUniqueCompanyCode(String companyName) {
        String prefix = companyName.replaceAll("[^a-zA-Z]", "").toUpperCase(Locale.ROOT);
        if (prefix.length() > 4) {
            prefix = prefix.substring(0, 4);
        } else if (prefix.isEmpty()) {
            prefix = "COMP";
        }
        String randomSuffix = UUID.randomUUID().toString().substring(0, 5).toUpperCase(Locale.ROOT);
        String code = prefix + "-" + randomSuffix;

        while (companyRepository.existsByCompanyCode(code)) {
            randomSuffix = UUID.randomUUID().toString().substring(0, 5).toUpperCase(Locale.ROOT);
            code = prefix + "-" + randomSuffix;
        }
        return code;
    }
}
