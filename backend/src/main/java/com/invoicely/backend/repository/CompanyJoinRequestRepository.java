package com.invoicely.backend.repository;

import com.invoicely.backend.model.CompanyJoinRequest;
import com.invoicely.backend.model.JoinRequestStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CompanyJoinRequestRepository extends JpaRepository<CompanyJoinRequest, Long> {
    List<CompanyJoinRequest> findByCompanyIdOrderByRequestedAtDesc(Long companyId);
    List<CompanyJoinRequest> findByCompanyIdAndStatusOrderByRequestedAtDesc(Long companyId, JoinRequestStatus status);
    List<CompanyJoinRequest> findByUserIdOrderByRequestedAtDesc(Long userId);
    Optional<CompanyJoinRequest> findByUserIdAndCompanyIdAndStatus(Long userId, Long companyId, JoinRequestStatus status);
    List<CompanyJoinRequest> findAllByOrderByRequestedAtDesc();
}
