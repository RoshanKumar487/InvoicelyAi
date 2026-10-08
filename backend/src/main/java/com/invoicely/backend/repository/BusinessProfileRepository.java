package com.invoicely.backend.repository;

import com.invoicely.backend.model.BusinessProfile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface BusinessProfileRepository extends JpaRepository<BusinessProfile, Integer> {
    Optional<BusinessProfile> findFirstByOrderByIdAsc();
    Optional<BusinessProfile> findFirstByCompanyId(Long companyId);
}
