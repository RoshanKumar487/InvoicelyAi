package com.invoicely.backend.repository;

import com.invoicely.backend.model.Employee;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface EmployeeRepository extends JpaRepository<Employee, Long> {

    List<Employee> findAllByOrderByCreatedAtDesc();

    List<Employee> findByCompanyIdOrderByCreatedAtDesc(Long companyId);

    List<Employee> findByCompanyIdAndStatusIgnoreCaseOrderByCreatedAtDesc(Long companyId, String status);

    List<Employee> findByCompanyIdAndDepartmentIgnoreCaseOrderByCreatedAtDesc(Long companyId, String department);

    Optional<Employee> findByIdAndCompanyId(Long id, Long companyId);

    Optional<Employee> findByCompanyIdAndAadhaarNumber(Long companyId, String aadhaarNumber);

    long countByCompanyId(Long companyId);

    long countByCompanyIdAndStatusIgnoreCase(Long companyId, String status);
}
