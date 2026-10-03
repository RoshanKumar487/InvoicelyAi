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
    @Operation(summary = "Get all expenses or filter by category (Scoped to company or global for Developer)")
    public ResponseEntity<ApiResponse<List<Expense>>> getAllExpenses(
            @RequestParam(required = false) String category,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = resolveCompanyId(principal);
        List<Expense> expenses = expenseService.getExpenses(companyId, category);
        return ResponseEntity.ok(ApiResponse.ok(expenses));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get expense by ID")
    public ResponseEntity<ApiResponse<Expense>> getExpenseById(
            @PathVariable Long id,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = resolveCompanyId(principal);
        return ResponseEntity.ok(ApiResponse.ok(expenseService.getExpenseById(id, companyId)));
    }

    @PostMapping
    @Operation(summary = "Log a new business expense")
    public ResponseEntity<ApiResponse<Expense>> createExpense(
            @RequestBody Expense expense,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = resolveCompanyId(principal);
        Expense created = expenseService.createExpense(expense, companyId);
        return new ResponseEntity<>(ApiResponse.ok("Expense created successfully", created), HttpStatus.CREATED);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update an existing expense")
    public ResponseEntity<ApiResponse<Expense>> updateExpense(
            @PathVariable Long id,
            @RequestBody Expense expense,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = resolveCompanyId(principal);
        Expense updated = expenseService.updateExpense(id, expense, companyId);
        return ResponseEntity.ok(ApiResponse.ok("Expense updated successfully", updated));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete expense by ID")
    public ResponseEntity<ApiResponse<Void>> deleteExpense(
            @PathVariable Long id,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = resolveCompanyId(principal);
        expenseService.deleteExpense(id, companyId);
        return ResponseEntity.ok(ApiResponse.ok("Expense deleted successfully", null));
    }

    private Long resolveCompanyId(UserPrincipal principal) {
        if (principal == null) return null;
        if (principal.getRole() == Role.DEVELOPER) return null;
        return principal.getCompanyId();
    }
}
