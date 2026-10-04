package com.invoicely.backend.service;

import com.invoicely.backend.exception.ResourceNotFoundException;
import com.invoicely.backend.model.Expense;
import com.invoicely.backend.repository.ExpenseRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;

@Service
public class ExpenseService {

    private final ExpenseRepository expenseRepository;

    @Autowired
    public ExpenseService(ExpenseRepository expenseRepository) {
        this.expenseRepository = expenseRepository;
    }

    public List<Expense> getAllExpenses() {
        return expenseRepository.findAllByOrderByCreatedAtDesc();
    }

    public List<Expense> getExpenses(Long companyId, Long createdByUserId, String category) {
        // Staff view: restricted to their company and their created expenses
        if (companyId != null && createdByUserId != null) {
            if (category != null && !category.trim().isEmpty()) {
                return expenseRepository.findByCompanyIdAndCreatedByUserIdAndCategoryIgnoreCaseOrderByCreatedAtDesc(companyId, createdByUserId, category.trim());
            }
            return expenseRepository.findByCompanyIdAndCreatedByUserIdOrderByCreatedAtDesc(companyId, createdByUserId);
        }

        // Admin view (or Developer filtered by companyId): sees all expenses in company
        if (companyId != null) {
            if (category != null && !category.trim().isEmpty()) {
                return expenseRepository.findByCompanyIdAndCategoryIgnoreCaseOrderByCreatedAtDesc(companyId, category.trim());
            }
            return expenseRepository.findByCompanyIdOrderByCreatedAtDesc(companyId);
        }

        // Developer global view across all companies
        if (category != null && !category.trim().isEmpty()) {
            return expenseRepository.findByCategoryIgnoreCaseOrderByCreatedAtDesc(category.trim());
        }
        return expenseRepository.findAllByOrderByCreatedAtDesc();
    }

    public List<Expense> getExpenses(Long companyId, String category) {
        return getExpenses(companyId, null, category);
    }

    public List<Expense> getExpensesByCategory(String category) {
        return expenseRepository.findByCategoryIgnoreCaseOrderByCreatedAtDesc(category);
    }

    public Expense getExpenseById(Long id) {
        return expenseRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Expense", "id", id));
    }

    public Expense getExpenseById(Long id, Long companyId) {
        return getExpenseById(id, companyId, null);
    }

    public Expense getExpenseById(Long id, Long companyId, Long createdByUserId) {
        Expense expense;
        if (companyId != null && createdByUserId != null) {
            expense = expenseRepository.findByIdAndCompanyIdAndCreatedByUserId(id, companyId, createdByUserId)
                    .orElseThrow(() -> new ResourceNotFoundException("Expense", "id", id));
        } else if (companyId != null) {
            expense = expenseRepository.findByIdAndCompanyId(id, companyId)
                    .orElseThrow(() -> new ResourceNotFoundException("Expense", "id", id));
        } else {
            expense = getExpenseById(id);
        }
        return expense;
    }

    @Transactional
    public Expense createExpense(Expense expense) {
        return createExpense(expense, expense.getCompanyId(), expense.getCreatedByUserId(), expense.getCreatedByUserName());
    }

    @Transactional
    public Expense createExpense(Expense expense, Long companyId) {
        return createExpense(expense, companyId, expense.getCreatedByUserId(), expense.getCreatedByUserName());
    }

    @Transactional
    public Expense createExpense(Expense expense, Long companyId, Long createdByUserId, String createdByUserName) {
        if (companyId != null && expense.getCompanyId() == null) {
            expense.setCompanyId(companyId);
        }
        if (createdByUserId != null && expense.getCreatedByUserId() == null) {
            expense.setCreatedByUserId(createdByUserId);
        }
        if (createdByUserName != null && (expense.getCreatedByUserName() == null || expense.getCreatedByUserName().isBlank())) {
            expense.setCreatedByUserName(createdByUserName);
        }
        if (expense.getCreatedAt() == null) {
            expense.setCreatedAt(OffsetDateTime.now());
        }
        return expenseRepository.save(expense);
    }

    @Transactional
    public Expense updateExpense(Long id, Expense updated) {
        return updateExpense(id, updated, updated.getCompanyId(), null);
    }

    @Transactional
    public Expense updateExpense(Long id, Expense updated, Long companyId) {
        return updateExpense(id, updated, companyId, null);
    }

    @Transactional
    public Expense updateExpense(Long id, Expense updated, Long companyId, Long createdByUserId) {
        Expense existing = getExpenseById(id, companyId, createdByUserId);
        if (companyId != null) {
            existing.setCompanyId(companyId);
        }
        existing.setTitle(updated.getTitle());
        existing.setCategory(updated.getCategory());
        existing.setAmount(updated.getAmount());
        existing.setCurrency(updated.getCurrency());
        existing.setCurrencySymbol(updated.getCurrencySymbol());
        existing.setDate(updated.getDate());
        existing.setVendor(updated.getVendor());
        existing.setPaymentMethod(updated.getPaymentMethod());
        existing.setTaxDeductible(updated.getTaxDeductible());
        existing.setTaxAmount(updated.getTaxAmount());
        existing.setReceiptImageUri(updated.getReceiptImageUri());
        existing.setNotes(updated.getNotes());
        return expenseRepository.save(existing);
    }

    @Transactional
    public void deleteExpense(Long id) {
        deleteExpense(id, null, null);
    }

    @Transactional
    public void deleteExpense(Long id, Long companyId) {
        deleteExpense(id, companyId, null);
    }

    @Transactional
    public void deleteExpense(Long id, Long companyId, Long createdByUserId) {
        Expense existing = getExpenseById(id, companyId, createdByUserId);
        expenseRepository.delete(existing);
    }
}
