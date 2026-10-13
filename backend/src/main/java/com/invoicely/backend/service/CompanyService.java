package com.invoicely.backend.service;

import com.invoicely.backend.dto.*;
import com.invoicely.backend.exception.ResourceNotFoundException;
import com.invoicely.backend.model.*;
import com.invoicely.backend.repository.*;
import com.invoicely.backend.security.JwtTokenProvider;
import com.invoicely.backend.security.UserPrincipal;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class CompanyService {

    private final CompanyRepository companyRepository;
    private final CompanyJoinRequestRepository joinRequestRepository;
    private final UserRepository userRepository;
    private final CompanyMembershipRepository companyMembershipRepository;
    private final BusinessProfileRepository businessProfileRepository;
    private final JwtTokenProvider tokenProvider;

    public CompanyService(CompanyRepository companyRepository,
                          CompanyJoinRequestRepository joinRequestRepository,
                          UserRepository userRepository,
                          CompanyMembershipRepository companyMembershipRepository,
                          BusinessProfileRepository businessProfileRepository,
                          JwtTokenProvider tokenProvider) {
        this.companyRepository = companyRepository;
        this.joinRequestRepository = joinRequestRepository;
        this.userRepository = userRepository;
        this.companyMembershipRepository = companyMembershipRepository;
        this.businessProfileRepository = businessProfileRepository;
        this.tokenProvider = tokenProvider;
    }

    @Transactional(readOnly = true)
    public CompanySummaryDto getMyCompany(UserPrincipal principal) {
        if (principal.getCompanyId() == null) {
            throw new ResourceNotFoundException("Company", "userId", principal.getId());
        }
        Company company = companyRepository.findById(principal.getCompanyId())
                .orElseThrow(() -> new ResourceNotFoundException("Company", "id", principal.getCompanyId()));
        return new CompanySummaryDto(company, principal.getRole() != null ? principal.getRole().name() : "ADMIN", true);
    }

    @Transactional
    public CompanySummaryDto updateMyCompany(UpdateCompanyRequest request, UserPrincipal principal) {
        if (principal.getCompanyId() == null) {
            throw new ResourceNotFoundException("Company", "userId", principal.getId());
        }
        ensureAdminOrDeveloper(principal);

        Company company = companyRepository.findById(principal.getCompanyId())
                .orElseThrow(() -> new ResourceNotFoundException("Company", "id", principal.getCompanyId()));

        if (request.getCompanyName() != null && !request.getCompanyName().isBlank()) {
            company.setCompanyName(request.getCompanyName().trim());
        }
        if (request.getDetails() != null) company.setDetails(request.getDetails());
        if (request.getGstin() != null) company.setGstin(request.getGstin().trim());
        if (request.getLocation() != null) company.setLocation(request.getLocation().trim());
        if (request.getSignatureStampUrl() != null) company.setSignatureStampUrl(request.getSignatureStampUrl());
        if (request.getEmail() != null) company.setEmail(request.getEmail().trim().toLowerCase(Locale.ROOT));
        if (request.getPhone() != null) company.setPhone(request.getPhone().trim());
        if (request.getWebsite() != null) company.setWebsite(request.getWebsite().trim());

        Company savedCompany = companyRepository.save(company);

        // Sync corresponding BusinessProfile so invoice & PDF templates immediately reflect branding
        BusinessProfile profile = businessProfileRepository.findFirstByCompanyId(savedCompany.getId())
                .orElseGet(() -> {
                    BusinessProfile bp = new BusinessProfile();
                    bp.setCompanyId(savedCompany.getId());
                    return bp;
                });
        profile.setBusinessName(savedCompany.getCompanyName());
        profile.setLegalName(savedCompany.getCompanyName());
        if (savedCompany.getGstin() != null) profile.setGstin(savedCompany.getGstin());
        if (savedCompany.getEmail() != null) profile.setEmail(savedCompany.getEmail());
        if (savedCompany.getPhone() != null) profile.setPhone(savedCompany.getPhone());
        if (savedCompany.getLocation() != null) profile.setAddress(savedCompany.getLocation());
        if (savedCompany.getWebsite() != null) profile.setWebsite(savedCompany.getWebsite());
        businessProfileRepository.save(profile);

        return new CompanySummaryDto(savedCompany, principal.getRole() != null ? principal.getRole().name() : "ADMIN", true);
    }

    @Transactional
    public List<CompanySummaryDto> getMyCompanies(UserPrincipal principal) {
        if (principal.getRole() == Role.DEVELOPER && principal.getCompanyId() == null) {
            return companyRepository.findAll().stream()
                    .map(c -> new CompanySummaryDto(c, "DEVELOPER", false))
                    .collect(Collectors.toList());
        }

        List<CompanyMembership> memberships = companyMembershipRepository.findByUserId(principal.getId());

        // Backwards compatibility for users created prior to membership tracking:
        if (memberships.isEmpty() && principal.getCompanyId() != null) {
            CompanyMembership legacyMembership = new CompanyMembership(
                    principal.getId(),
                    principal.getCompanyId(),
                    principal.getRole() != null ? principal.getRole() : Role.ADMIN,
                    true
            );
            legacyMembership = companyMembershipRepository.save(legacyMembership);
            memberships = List.of(legacyMembership);
        }

        return memberships.stream().map(m -> {
            Company c = companyRepository.findById(m.getCompanyId()).orElse(null);
            if (c == null) return null;
            boolean isActive = c.getId().equals(principal.getCompanyId());
            return new CompanySummaryDto(c, m.getRole().name(), isActive);
        }).filter(dto -> dto != null).collect(Collectors.toList());
    }

    @Transactional
    public AuthResponse createCompanyWorkspace(CreateWorkspaceRequest request, UserPrincipal principal) {
        User user = userRepository.findById(principal.getId())
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", principal.getId()));

        String companyCode = generateUniqueCompanyCode(request.getCompanyName());
        Company company = new Company(
                companyCode,
                request.getCompanyName().trim(),
                request.getDetails(),
                request.getGstin(),
                request.getLocation(),
                request.getSignatureStampUrl()
        );
        if (request.getEmail() != null) company.setEmail(request.getEmail().trim().toLowerCase(Locale.ROOT));
        if (request.getPhone() != null) company.setPhone(request.getPhone().trim());
        if (request.getWebsite() != null) company.setWebsite(request.getWebsite().trim());
        company = companyRepository.save(company);

        // Record membership
        CompanyMembership membership = new CompanyMembership(user.getId(), company.getId(), Role.ADMIN, false);
        companyMembershipRepository.save(membership);

        // Switch active workspace to newly created company
        user.setCompanyId(company.getId());
        user.setRole(Role.ADMIN);
        user = userRepository.save(user);

        // Initialize default BusinessProfile for invoicing
        BusinessProfile profile = new BusinessProfile();
        profile.setCompanyId(company.getId());
        profile.setBusinessName(company.getCompanyName());
        profile.setLegalName(company.getCompanyName());
        if (company.getGstin() != null) profile.setGstin(company.getGstin());
        if (company.getEmail() != null) profile.setEmail(company.getEmail());
        if (company.getPhone() != null) profile.setPhone(company.getPhone());
        if (company.getLocation() != null) profile.setAddress(company.getLocation());
        if (company.getWebsite() != null) profile.setWebsite(company.getWebsite());
        businessProfileRepository.save(profile);

        String token = tokenProvider.generateToken(user);
        return new AuthResponse(
                token,
                new UserSummaryDto(user),
                new CompanySummaryDto(company, "ADMIN", true),
                "New company workspace '" + company.getCompanyName() + "' created and activated successfully."
        );
    }

    @Transactional(readOnly = true)
    public List<CompanyJoinRequestDto> getJoinRequests(UserPrincipal principal, String statusStr) {
        ensureAdminOrDeveloper(principal);

        List<CompanyJoinRequest> list;
        JoinRequestStatus parsedStatus = null;
        if (statusStr != null && !statusStr.trim().isEmpty()) {
            try {
                parsedStatus = JoinRequestStatus.valueOf(statusStr.trim().toUpperCase(Locale.ROOT));
            } catch (IllegalArgumentException ignored) {}
        }
        final JoinRequestStatus targetStatus = parsedStatus;

        if (principal.getRole() == Role.DEVELOPER && principal.getCompanyId() == null) {
            list = (targetStatus != null)
                    ? joinRequestRepository.findAllByOrderByRequestedAtDesc().stream()
                        .filter(r -> r.getStatus() == targetStatus)
                        .collect(Collectors.toList())
                    : joinRequestRepository.findAllByOrderByRequestedAtDesc();
        } else {
            Long companyId = principal.getCompanyId();
            if (companyId == null) {
                return List.of();
            }
            list = (targetStatus != null)
                    ? joinRequestRepository.findByCompanyIdAndStatusOrderByRequestedAtDesc(companyId, targetStatus)
                    : joinRequestRepository.findByCompanyIdOrderByRequestedAtDesc(companyId);
        }

        return list.stream().map(CompanyJoinRequestDto::new).collect(Collectors.toList());
    }

    @Transactional
    public CompanyJoinRequestDto processJoinRequest(Long requestId, JoinRequestActionRequest actionRequest, UserPrincipal principal) {
        ensureAdminOrDeveloper(principal);

        CompanyJoinRequest request = joinRequestRepository.findById(requestId)
                .orElseThrow(() -> new ResourceNotFoundException("CompanyJoinRequest", "id", requestId));

        if (principal.getRole() != Role.DEVELOPER) {
            if (principal.getCompanyId() == null || !principal.getCompanyId().equals(request.getCompanyId())) {
                throw new AccessDeniedException("You do not have permission to review join requests for this company.");
            }
        }

        User user = userRepository.findById(request.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", request.getUserId()));

        String action = actionRequest.getAction().trim().toUpperCase(Locale.ROOT);
        if ("APPROVE".equals(action)) {
            request.setStatus(JoinRequestStatus.APPROVED);
            user.setStatus(UserStatus.ACTIVE);
            if (!companyMembershipRepository.existsByUserIdAndCompanyId(user.getId(), request.getCompanyId())) {
                companyMembershipRepository.save(new CompanyMembership(user.getId(), request.getCompanyId(), user.getRole(), true));
            }
        } else if ("REJECT".equals(action)) {
            request.setStatus(JoinRequestStatus.REJECTED);
            user.setStatus(UserStatus.REJECTED);
        } else {
            throw new IllegalArgumentException("Action must be APPROVE or REJECT");
        }

        request.setReviewedAt(OffsetDateTime.now());
        request.setReviewedByUserId(principal.getId());

        userRepository.save(user);
        CompanyJoinRequest saved = joinRequestRepository.save(request);

        return new CompanyJoinRequestDto(saved);
    }

    @Transactional(readOnly = true)
    public List<UserSummaryDto> getCompanyEmployees(UserPrincipal principal) {
        ensureAdminOrDeveloper(principal);

        Long companyId = principal.getCompanyId();
        if (companyId == null && principal.getRole() == Role.DEVELOPER) {
            return userRepository.findAll().stream().map(UserSummaryDto::new).collect(Collectors.toList());
        }

        if (companyId == null) {
            return List.of();
        }

        return userRepository.findByCompanyId(companyId).stream()
                .map(UserSummaryDto::new)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<CompanySummaryDto> getAllCompanies(UserPrincipal principal) {
        if (principal.getRole() != Role.DEVELOPER) {
            throw new AccessDeniedException("Only platform DEVELOPERs can view all registered companies.");
        }
        return companyRepository.findAll().stream()
                .map(CompanySummaryDto::new)
                .collect(Collectors.toList());
    }

    @Transactional
    public UserSummaryDto updateEmployeePermissions(Long userId, String permissions, UserPrincipal principal) {
        ensureAdminOrDeveloper(principal);

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));

        if (principal.getRole() != Role.DEVELOPER) {
            if (principal.getCompanyId() == null || !principal.getCompanyId().equals(user.getCompanyId())) {
                throw new AccessDeniedException("You do not have permission to manage employees outside your organization.");
            }
        }

        user.setPermissions(permissions != null && !permissions.isBlank() ? permissions : "INVOICES,EXPENSES,CLIENTS,REPORTS");
        User saved = userRepository.save(user);
        return new UserSummaryDto(saved);
    }

    @Transactional
    public UserSummaryDto updateEmployeeRole(Long userId, String roleStr, String permissions, UserPrincipal principal) {
        ensureAdminOrDeveloper(principal);

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));

        if (principal.getRole() != Role.DEVELOPER) {
            if (principal.getCompanyId() == null || !principal.getCompanyId().equals(user.getCompanyId())) {
                throw new AccessDeniedException("You do not have permission to manage employees outside your organization.");
            }
        }

        if (roleStr != null && !roleStr.isBlank()) {
            try {
                Role newRole = Role.valueOf(roleStr.trim().toUpperCase());
                user.setRole(newRole);
            } catch (IllegalArgumentException ignored) {}
        }

        if (permissions != null && !permissions.isBlank()) {
            user.setPermissions(permissions);
        } else if (user.getRole() == Role.ADMIN) {
            user.setPermissions("INVOICES,EXPENSES,CLIENTS,REPORTS,EMPLOYEES,AUDIT_LOGS,SETTINGS");
        }

        User saved = userRepository.save(user);
        return new UserSummaryDto(saved);
    }

    private void ensureAdminOrDeveloper(UserPrincipal principal) {
        if (principal.getRole() != Role.ADMIN && principal.getRole() != Role.DEVELOPER) {
            throw new AccessDeniedException("Only ADMIN or DEVELOPER roles can perform this action.");
        }
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
