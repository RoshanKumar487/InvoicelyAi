package com.invoicely.backend.repository;

import com.invoicely.backend.model.Invoice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

@Repository
public interface InvoiceRepository extends JpaRepository<Invoice, Long> {

    Optional<Invoice> findByInvoiceNumber(String invoiceNumber);

    List<Invoice> findAllByOrderByCreatedAtDesc();

    List<Invoice> findByStatusIgnoreCaseOrderByCreatedAtDesc(String status);

    List<Invoice> findByClientIdOrderByCreatedAtDesc(Long clientId);

    long countByStatusIgnoreCase(String status);

    @Query("SELECT COALESCE(SUM(i.amountPaid), 0) FROM Invoice i")
    BigDecimal sumTotalRevenue();

    @Query("SELECT COALESCE(SUM(i.discountAmount), 0) FROM Invoice i")
    BigDecimal sumTotalDiscount();

    // Multi-tenant company queries
    List<Invoice> findByCompanyIdOrderByCreatedAtDesc(Long companyId);

    List<Invoice> findByCompanyIdAndStatusIgnoreCaseOrderByCreatedAtDesc(Long companyId, String status);

    List<Invoice> findByCompanyIdAndClientIdOrderByCreatedAtDesc(Long companyId, Long clientId);

    Optional<Invoice> findByIdAndCompanyId(Long id, Long companyId);

    Optional<Invoice> findByInvoiceNumberAndCompanyId(String invoiceNumber, Long companyId);

    long countByCompanyId(Long companyId);

    long countByCompanyIdAndStatusIgnoreCase(Long companyId, String status);

    @Query("SELECT COALESCE(SUM(i.amountPaid), 0) FROM Invoice i WHERE i.companyId = :companyId")
    BigDecimal sumTotalRevenueByCompanyId(@org.springframework.data.repository.query.Param("companyId") Long companyId);

    @Query("SELECT COALESCE(SUM(i.discountAmount), 0) FROM Invoice i WHERE i.companyId = :companyId")
    BigDecimal sumTotalDiscountByCompanyId(@org.springframework.data.repository.query.Param("companyId") Long companyId);

    // Staff-scoped queries (mapped by companyId and createdByUserId)
    List<Invoice> findByCompanyIdAndCreatedByUserIdOrderByCreatedAtDesc(Long companyId, Long createdByUserId);

    List<Invoice> findByCompanyIdAndCreatedByUserIdAndStatusIgnoreCaseOrderByCreatedAtDesc(Long companyId, Long createdByUserId, String status);

    List<Invoice> findByCompanyIdAndCreatedByUserIdAndClientIdOrderByCreatedAtDesc(Long companyId, Long createdByUserId, Long clientId);

    Optional<Invoice> findByIdAndCompanyIdAndCreatedByUserId(Long id, Long companyId, Long createdByUserId);

    long countByCompanyIdAndCreatedByUserId(Long companyId, Long createdByUserId);

    long countByCompanyIdAndCreatedByUserIdAndStatusIgnoreCase(Long companyId, Long createdByUserId, String status);

    @Query("SELECT COALESCE(SUM(i.amountPaid), 0) FROM Invoice i WHERE i.companyId = :companyId AND i.createdByUserId = :createdByUserId")
    BigDecimal sumTotalRevenueByCompanyIdAndCreatedByUserId(@org.springframework.data.repository.query.Param("companyId") Long companyId,
                                                             @org.springframework.data.repository.query.Param("createdByUserId") Long createdByUserId);
}
