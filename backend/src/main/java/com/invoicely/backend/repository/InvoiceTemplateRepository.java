package com.invoicely.backend.repository;

import com.invoicely.backend.model.InvoiceTemplate;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface InvoiceTemplateRepository extends JpaRepository<InvoiceTemplate, Long> {

    List<InvoiceTemplate> findByCompanyIdOrderByUpdatedAtDesc(Long companyId);

    Optional<InvoiceTemplate> findByIdAndCompanyId(Long id, Long companyId);

    Optional<InvoiceTemplate> findFirstByCompanyIdAndIsDefaultTrue(Long companyId);

    Optional<InvoiceTemplate> findFirstByCompanyIdAndStatus(Long companyId, String status);

    Optional<InvoiceTemplate> findFirstByOrgCodeOrderByUpdatedAtDesc(String orgCode);

    Optional<InvoiceTemplate> findFirstByCompanyIdOrderByUpdatedAtDesc(Long companyId);
}
