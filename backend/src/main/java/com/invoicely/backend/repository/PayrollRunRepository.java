package com.invoicely.backend.repository;

import com.invoicely.backend.model.PayrollRun;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PayrollRunRepository extends JpaRepository<PayrollRun, Long> {
    List<PayrollRun> findByCompanyIdOrderByPeriodYearDescPeriodMonthDesc(Long companyId);
    Optional<PayrollRun> findByIdAndCompanyId(Long id, Long companyId);
    Optional<PayrollRun> findByCompanyIdAndPeriodMonthAndPeriodYear(Long companyId, Integer month, Integer year);
}
