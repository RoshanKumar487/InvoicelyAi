package com.invoicely.backend.repository;

import com.invoicely.backend.model.Company;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface CompanyRepository extends JpaRepository<Company, Long> {
    Optional<Company> findByCompanyCode(String companyCode);
    Optional<Company> findByCompanyNameIgnoreCase(String companyName);
    boolean existsByCompanyCode(String companyCode);
}
