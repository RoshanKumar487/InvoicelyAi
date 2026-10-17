package com.invoicely.backend.controller;

import com.invoicely.backend.dto.ApiResponse;
import com.invoicely.backend.model.Employee;
import com.invoicely.backend.model.Role;
import com.invoicely.backend.security.UserPrincipal;
import com.invoicely.backend.service.EmployeeService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/employees")
@Tag(name = "Employees", description = "Manage workforce, Aadhaar verification, and Biodata profiles (Multi-tenant & Role-Scoped)")
public class EmployeeController {

    private final EmployeeService employeeService;

    @Autowired
    public EmployeeController(EmployeeService employeeService) {
        this.employeeService = employeeService;
    }

    @GetMapping
    @Operation(summary = "Get all employees or filter by status or department")
    public ResponseEntity<ApiResponse<List<Employee>>> getEmployees(
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String department,
            @RequestParam(required = false) Long companyId,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long resolvedCompanyId = resolveCompanyId(principal, companyId);
        List<Employee> employees = employeeService.getEmployees(resolvedCompanyId, status, department);
        return ResponseEntity.ok(ApiResponse.ok(employees));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get employee profile by ID")
    public ResponseEntity<ApiResponse<Employee>> getEmployeeById(
            @PathVariable Long id,
            @RequestParam(required = false) Long companyId,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long resolvedCompanyId = resolveCompanyId(principal, companyId);
        return ResponseEntity.ok(ApiResponse.ok(employeeService.getEmployeeById(id, resolvedCompanyId)));
    }

    @PostMapping
    @Operation(summary = "Register a new employee")
    public ResponseEntity<ApiResponse<Employee>> createEmployee(
            @RequestBody Employee employee,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = (principal != null && principal.getRole() != Role.DEVELOPER && principal.getCompanyId() != null)
                ? principal.getCompanyId()
                : employee.getCompanyId();
        Employee created = employeeService.createEmployee(employee, companyId);
        return new ResponseEntity<>(ApiResponse.ok("Employee registered successfully", created), HttpStatus.CREATED);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update employee profile & biodata")
    public ResponseEntity<ApiResponse<Employee>> updateEmployee(
            @PathVariable Long id,
            @RequestBody Employee employee,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = resolveCompanyId(principal, employee.getCompanyId());
        Employee updated = employeeService.updateEmployee(id, employee, companyId);
        return ResponseEntity.ok(ApiResponse.ok("Employee profile updated successfully", updated));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete employee record by ID")
    public ResponseEntity<ApiResponse<Void>> deleteEmployee(
            @PathVariable Long id,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long companyId = resolveCompanyId(principal, null);
        employeeService.deleteEmployee(id, companyId);
        return ResponseEntity.ok(ApiResponse.ok("Employee removed successfully", null));
    }

    private Long resolveCompanyId(UserPrincipal principal, Long requestedCompanyId) {
        if (principal == null) return requestedCompanyId;
        if (principal.getRole() == Role.DEVELOPER) return requestedCompanyId;
        return principal.getCompanyId() != null ? principal.getCompanyId() : requestedCompanyId;
    }
}
