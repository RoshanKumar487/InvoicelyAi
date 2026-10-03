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

    public List<Expense> getExpenses(Long companyId, String category) {
        if (companyId != null) {
            if (category != null && !category.trim().isEmpty()) {
                return expenseRepository.findByCompanyIdAndCategoryIgnoreCaseOrderByCreatedAtDesc(companyId, category.trim());
            }
            return expenseRepository.findByCompanyIdOrderByCreatedAtDesc(companyId);
        }

        if (category != null && !category.trim().isEmpty()) {
            return expenseRepository.findByCategoryIgnoreCaseOrderByCreatedAtDesc(category.trim());
        }
        return expenseRepository.findAllByOrderByCreatedAtDesc();
    }

    public List<Expense> getExpensesByCategory(String category) {
        return expenseRepository.findByCategoryIgnoreCaseOrderByCreatedAtDesc(category);
    }

    public Expense getExpenseById(Long id) {
        return expenseRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Expense", "id", id));
    }

    public Expense getExpenseById(Long id, Long companyId) {
        if (companyId != null) {
            return expenseRepository.findByIdAndCompanyId(id, companyId)
                    .orElseThrow(() -> new ResourceNotFoundException("Expense", "id", id));
        }
        return getExpenseById(id);
    }

    @Transactional
    public Expense createExpense(Expense expense) {
        return createExpense(expense, expense.getCompanyId());
    }

    @Transactional
    public Expense createExpense(Expense expense, Long companyId) {
        if (companyId != null && expense.getCompanyId() == null) {
            expense.setCompanyId(companyId);
        }
        if (expense.getCreatedAt() == null) {
            expense.setCreatedAt(OffsetDateTime.now());
        }
        return expenseRepository.save(expense);
    }

    @Transactional
    public Expense updateExpense(Long id, Expense updated) {
        return updateExpense(id, updated, updated.getCompanyId());
    }

    @Transactional
    public Expense updateExpense(Long id, Expense updated, Long companyId) {
        Expense existing = getExpenseById(id, companyId);
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
        deleteExpense(id, null);
    }

    @Transactional
    public void deleteExpense(Long id, Long companyId) {
        Expense existing = getExpenseById(id, companyId);
        expenseRepository.delete(existing);
    }
}
