package com.invoicely.backend.repository;

import com.invoicely.backend.model.PayrollEntry;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PayrollEntryRepository extends JpaRepository<PayrollEntry, Long> {
    List<PayrollEntry> findByCompanyIdOrderByEmployeeNameAsc(Long companyId);
    List<PayrollEntry> findByPayrollRunIdOrderByEmployeeNameAsc(Long payrollRunId);
    List<PayrollEntry> findByCompanyIdAndPaymentStatus(Long companyId, String paymentStatus);
    Optional<PayrollEntry> findByIdAndCompanyId(Long id, Long companyId);
}
