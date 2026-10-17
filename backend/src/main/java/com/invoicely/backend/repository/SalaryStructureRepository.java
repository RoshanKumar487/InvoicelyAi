package com.invoicely.backend.repository;

import com.invoicely.backend.model.SalaryStructure;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface SalaryStructureRepository extends JpaRepository<SalaryStructure, Long> {
    Optional<SalaryStructure> findByEmployeeId(Long employeeId);
    Optional<SalaryStructure> findByCompanyIdAndEmployeeId(Long companyId, Long employeeId);
}
