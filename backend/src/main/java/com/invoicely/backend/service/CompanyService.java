package com.invoicely.backend.service;

import com.invoicely.backend.dto.CompanyJoinRequestDto;
import com.invoicely.backend.dto.CompanySummaryDto;
import com.invoicely.backend.dto.JoinRequestActionRequest;
import com.invoicely.backend.dto.UserSummaryDto;
import com.invoicely.backend.exception.ResourceNotFoundException;
import com.invoicely.backend.model.*;
import com.invoicely.backend.repository.CompanyJoinRequestRepository;
import com.invoicely.backend.repository.CompanyRepository;
import com.invoicely.backend.repository.UserRepository;
import com.invoicely.backend.security.UserPrincipal;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Locale;
import java.util.stream.Collectors;

@Service
public class CompanyService {

    private final CompanyRepository companyRepository;
    private final CompanyJoinRequestRepository joinRequestRepository;
    private final UserRepository userRepository;

    public CompanyService(CompanyRepository companyRepository,
                          CompanyJoinRequestRepository joinRequestRepository,
                          UserRepository userRepository) {
        this.companyRepository = companyRepository;
        this.joinRequestRepository = joinRequestRepository;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public CompanySummaryDto getMyCompany(UserPrincipal principal) {
        if (principal.getCompanyId() == null) {
            throw new ResourceNotFoundException("Company", "userId", principal.getId());
        }
        Company company = companyRepository.findById(principal.getCompanyId())
                .orElseThrow(() -> new ResourceNotFoundException("Company", "id", principal.getCompanyId()));
        return new CompanySummaryDto(company);
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

    private void ensureAdminOrDeveloper(UserPrincipal principal) {
        if (principal.getRole() != Role.ADMIN && principal.getRole() != Role.DEVELOPER) {
            throw new AccessDeniedException("Only ADMIN or DEVELOPER roles can perform this action.");
        }
    }
}
