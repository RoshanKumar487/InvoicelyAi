package com.invoicely.backend.repository;

import com.invoicely.backend.model.Expense;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;

@Repository
public interface ExpenseRepository extends JpaRepository<Expense, Long> {

    List<Expense> findAllByOrderByCreatedAtDesc();

    List<Expense> findByCategoryIgnoreCaseOrderByCreatedAtDesc(String category);

    @Query("SELECT COALESCE(SUM(e.amount), 0) FROM Expense e")
    BigDecimal sumTotalExpenses();

    @Query("SELECT COALESCE(SUM(e.taxAmount), 0) FROM Expense e WHERE e.taxDeductible = true")
    BigDecimal sumTotalTaxDeductible();

    // Multi-tenant company queries
    List<Expense> findByCompanyIdOrderByCreatedAtDesc(Long companyId);

    List<Expense> findByCompanyIdAndCategoryIgnoreCaseOrderByCreatedAtDesc(Long companyId, String category);

    java.util.Optional<Expense> findByIdAndCompanyId(Long id, Long companyId);

    long countByCompanyId(Long companyId);

    @Query("SELECT COALESCE(SUM(e.amount), 0) FROM Expense e WHERE e.companyId = :companyId")
    BigDecimal sumTotalExpensesByCompanyId(@org.springframework.data.repository.query.Param("companyId") Long companyId);

    @Query("SELECT COALESCE(SUM(e.taxAmount), 0) FROM Expense e WHERE e.companyId = :companyId AND e.taxDeductible = true")
    BigDecimal sumTotalTaxDeductibleByCompanyId(@org.springframework.data.repository.query.Param("companyId") Long companyId);

    // Staff-scoped queries (mapped by companyId and createdByUserId)
    List<Expense> findByCompanyIdAndCreatedByUserIdOrderByCreatedAtDesc(Long companyId, Long createdByUserId);

    List<Expense> findByCompanyIdAndCreatedByUserIdAndCategoryIgnoreCaseOrderByCreatedAtDesc(Long companyId, Long createdByUserId, String category);

    java.util.Optional<Expense> findByIdAndCompanyIdAndCreatedByUserId(Long id, Long companyId, Long createdByUserId);

    long countByCompanyIdAndCreatedByUserId(Long companyId, Long createdByUserId);

    @Query("SELECT COALESCE(SUM(e.amount), 0) FROM Expense e WHERE e.companyId = :companyId AND e.createdByUserId = :createdByUserId")
    BigDecimal sumTotalExpensesByCompanyIdAndCreatedByUserId(@org.springframework.data.repository.query.Param("companyId") Long companyId,
                                                             @org.springframework.data.repository.query.Param("createdByUserId") Long createdByUserId);
}
