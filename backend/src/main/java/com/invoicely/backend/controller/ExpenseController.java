package com.invoicely.backend.controller;

import com.invoicely.backend.dto.ApiResponse;
import com.invoicely.backend.model.Expense;
import com.invoicely.backend.model.Role;
import com.invoicely.backend.security.UserPrincipal;
import com.invoicely.backend.service.ExpenseService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/expenses")
@Tag(name = "Expenses", description = "Track business expenses and tax deductions (Multi-tenant & Role-Scoped)")
public class ExpenseController {

    private final ExpenseService expenseService;

    @Autowired
    public ExpenseController(ExpenseService expenseService) {
        this.expenseService = expenseService;
    }

    @GetMapping
    @Operation(summary = "Get all expenses or filter by category (Scoped to staff for Employee, company for Admin, global/filtered for Developer)")
    public ResponseEntity<ApiResponse<List<Expense>>> getAllExpenses(
            @RequestParam(required = false) String category,
            @RequestParam(required = false) Long companyId,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long resolvedCompanyId = resolveCompanyId(principal, companyId);
        Long createdByUserId = (principal != null && principal.getRole() == Role.EMPLOYEE) ? principal.getId() : null;
        List<Expense> expenses = expenseService.getExpenses(resolvedCompanyId, createdByUserId, category);
        return ResponseEntity.ok(ApiResponse.ok(expenses));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get expense by ID")
    public ResponseEntity<ApiResponse<Expense>> getExpenseById(
            @PathVariable Long id,
            @RequestParam(required = false) Long companyId,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long resolvedCompanyId = resolveCompanyId(principal, companyId);
        Long createdByUserId = (principal != null && principal.getRole() == Role.EMPLOYEE) ? principal.getId() : null;
        return ResponseEntity.ok(ApiResponse.ok(expenseService.getExpenseById(id, resolvedCompanyId, createdByUserId)));
    }

    @PostMapping
    @Operation(summary = "Log a new business expense")
    public ResponseEntity<ApiResponse<Expense>> createExpense(
            @RequestBody Expense expense,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = (principal != null && principal.getRole() != Role.DEVELOPER) ? principal.getCompanyId() : expense.getCompanyId();
        Long createdByUserId = (principal != null) ? principal.getId() : null;
        String createdByUserName = (principal != null) ? principal.getFullName() : "";
        Expense created = expenseService.createExpense(expense, companyId, createdByUserId, createdByUserName);
        return new ResponseEntity<>(ApiResponse.ok("Expense created successfully", created), HttpStatus.CREATED);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update an existing expense")
    public ResponseEntity<ApiResponse<Expense>> updateExpense(
            @PathVariable Long id,
            @RequestBody Expense expense,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = resolveCompanyId(principal, expense.getCompanyId());
        Long createdByUserId = (principal != null && principal.getRole() == Role.EMPLOYEE) ? principal.getId() : null;
        Expense updated = expenseService.updateExpense(id, expense, companyId, createdByUserId);
        return ResponseEntity.ok(ApiResponse.ok("Expense updated successfully", updated));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete expense by ID")
    public ResponseEntity<ApiResponse<Void>> deleteExpense(
            @PathVariable Long id,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = resolveCompanyId(principal, null);
        Long createdByUserId = (principal != null && principal.getRole() == Role.EMPLOYEE) ? principal.getId() : null;
        expenseService.deleteExpense(id, companyId, createdByUserId);
        return ResponseEntity.ok(ApiResponse.ok("Expense deleted successfully", null));
    }

    private Long resolveCompanyId(UserPrincipal principal, Long requestedCompanyId) {
        if (principal == null) return requestedCompanyId;
        if (principal.getRole() == Role.DEVELOPER) return requestedCompanyId;
        return principal.getCompanyId();
    }
}
