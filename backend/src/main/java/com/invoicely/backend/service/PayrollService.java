package com.invoicely.backend.service;

import com.invoicely.backend.dto.PayrollSummaryKpiDto;
import com.invoicely.backend.exception.ResourceNotFoundException;
import com.invoicely.backend.model.*;
import com.invoicely.backend.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class PayrollService {

    private final PayrollRunRepository payrollRunRepo;
    private final PayrollEntryRepository payrollEntryRepo;
    private final EmployeeRepository employeeRepo;
    private final SalaryStructureRepository salaryRepo;

    public PayrollService(PayrollRunRepository payrollRunRepo,
                          PayrollEntryRepository payrollEntryRepo,
                          EmployeeRepository employeeRepo,
                          SalaryStructureRepository salaryRepo) {
        this.payrollRunRepo = payrollRunRepo;
        this.payrollEntryRepo = payrollEntryRepo;
        this.employeeRepo = employeeRepo;
        this.salaryRepo = salaryRepo;
    }

    @Transactional(readOnly = true)
    public List<PayrollRun> listRuns(Long companyId) {
        return payrollRunRepo.findByCompanyIdOrderByPeriodYearDescPeriodMonthDesc(companyId);
    }

    @Transactional(readOnly = true)
    public PayrollRun getRun(Long runId, Long companyId) {
        return payrollRunRepo.findByIdAndCompanyId(runId, companyId)
                .orElseThrow(() -> new ResourceNotFoundException("PayrollRun", "id", runId));
    }

    @Transactional(readOnly = true)
    public List<PayrollEntry> listEntries(Long companyId, Long runId, String status, String search) {
        List<PayrollEntry> entries = (runId != null && runId > 0)
                ? payrollEntryRepo.findByPayrollRunIdOrderByEmployeeNameAsc(runId)
                : payrollEntryRepo.findByCompanyIdOrderByEmployeeNameAsc(companyId);

        LocalDate today = LocalDate.now();

        // Dynamically flag overdue items if scheduledPayDate is past and still pending
        entries.forEach(e -> {
            if ("PENDING".equalsIgnoreCase(e.getPaymentStatus()) && e.getScheduledPayDate() != null && e.getScheduledPayDate().isBefore(today)) {
                e.setPaymentStatus("OVERDUE");
            }
        });

        if (status != null && !status.isBlank() && !"ALL".equalsIgnoreCase(status.trim())) {
            String target = status.trim().toUpperCase();
            entries = entries.stream()
                    .filter(e -> e.getPaymentStatus().equalsIgnoreCase(target))
                    .collect(Collectors.toList());
        }

        if (search != null && !search.isBlank()) {
            String q = search.trim().toLowerCase();
            entries = entries.stream()
                    .filter(e -> (e.getEmployeeName() != null && e.getEmployeeName().toLowerCase().contains(q))
                            || (e.getEmployeeCode() != null && e.getEmployeeCode().toLowerCase().contains(q))
                            || (e.getDepartment() != null && e.getDepartment().toLowerCase().contains(q))
                            || (e.getDesignation() != null && e.getDesignation().toLowerCase().contains(q)))
                    .collect(Collectors.toList());
        }

        return entries;
    }

    @Transactional(readOnly = true)
    public PayrollSummaryKpiDto getPayrollKpis(Long companyId, Long runId) {
        List<PayrollEntry> entries = listEntries(companyId, runId, null, null);

        PayrollSummaryKpiDto kpi = new PayrollSummaryKpiDto();
        BigDecimal totalGross = BigDecimal.ZERO;
        BigDecimal totalPaid = BigDecimal.ZERO;
        BigDecimal totalPending = BigDecimal.ZERO;
        BigDecimal totalOverdue = BigDecimal.ZERO;
        int pendingCount = 0;
        int paidCount = 0;
        int overdueCount = 0;

        for (PayrollEntry e : entries) {
            BigDecimal net = e.getNetSalary() != null ? e.getNetSalary() : BigDecimal.ZERO;
            BigDecimal gross = e.getGrossEarnings() != null ? e.getGrossEarnings() : BigDecimal.ZERO;
            totalGross = totalGross.add(gross);

            if ("PAID".equalsIgnoreCase(e.getPaymentStatus())) {
                totalPaid = totalPaid.add(net);
                paidCount++;
            } else if ("OVERDUE".equalsIgnoreCase(e.getPaymentStatus())) {
                totalOverdue = totalOverdue.add(net);
                overdueCount++;
            } else {
                totalPending = totalPending.add(net);
                pendingCount++;
            }
        }

        kpi.setTotalGross(totalGross);
        kpi.setTotalPaid(totalPaid);
        kpi.setTotalPending(totalPending);
        kpi.setTotalOverdue(totalOverdue);
        kpi.setTotalEmployees(entries.size());
        kpi.setPendingCount(pendingCount);
        kpi.setPaidCount(paidCount);
        kpi.setOverdueCount(overdueCount);
        return kpi;
    }

    @Transactional
    public PayrollRun generatePayrollRun(Long companyId, int month, int year, LocalDate scheduledPayDate, String title) {
        LocalDate payDate = scheduledPayDate != null ? scheduledPayDate : LocalDate.now().plusDays(5);
        String runTitle = (title != null && !title.isBlank()) ? title : "Payroll " + month + "/" + year;

        PayrollRun run = payrollRunRepo.findByCompanyIdAndPeriodMonthAndPeriodYear(companyId, month, year)
                .orElseGet(() -> {
                    PayrollRun r = new PayrollRun();
                    r.setCompanyId(companyId);
                    r.setPeriodMonth(month);
                    r.setPeriodYear(year);
                    return r;
                });

        run.setRunTitle(runTitle);
        run.setScheduledPayDate(payDate);
        run.setStatus("REVIEWED");
        run.getEntries().clear();

        List<Employee> employees = employeeRepo.findByCompanyIdAndStatusIgnoreCaseOrderByCreatedAtDesc(companyId, "ACTIVE");
        if (employees.isEmpty()) {
            employees = employeeRepo.findByCompanyIdOrderByCreatedAtDesc(companyId);
        }

        BigDecimal totalGross = BigDecimal.ZERO;
        BigDecimal totalDeductions = BigDecimal.ZERO;
        BigDecimal totalNet = BigDecimal.ZERO;

        for (Employee emp : employees) {
            SalaryStructure structure = salaryRepo.findByEmployeeId(emp.getId())
                    .orElseGet(() -> createDefaultStructure(emp));

            PayrollEntry entry = new PayrollEntry();
            entry.setPayrollRun(run);
            entry.setCompanyId(companyId);
            entry.setEmployeeId(emp.getId());
            entry.setEmployeeName(emp.getFullName());
            entry.setEmployeeCode(emp.getEmployeeCode());
            entry.setDesignation(emp.getDesignation());
            entry.setDepartment(emp.getDepartment());
            entry.setScheduledPayDate(payDate);
            entry.setPaymentStatus("PENDING");
            entry.setBankAccountMask(maskAccountNumber(emp.getBankAccountNumber()));

            // Earnings
            BigDecimal basic = structure.getBasicSalary();
            BigDecimal hra = structure.getHra();
            BigDecimal allowances = structure.getSpecialAllowance().add(structure.getConveyanceAllowance());
            BigDecimal gross = basic.add(hra).add(allowances);

            entry.setBasicPay(basic);
            entry.setHra(hra);
            entry.setAllowances(allowances);
            entry.setGrossEarnings(gross);

            // Statutory Deductions
            BigDecimal pf = BigDecimal.ZERO;
            if (Boolean.TRUE.equals(structure.getIsPfEligible())) {
                BigDecimal pfWageBase = basic.min(BigDecimal.valueOf(15000));
                pf = pfWageBase.multiply(BigDecimal.valueOf(0.12)).setScale(2, RoundingMode.HALF_UP);
            }

            BigDecimal esi = BigDecimal.ZERO;
            if (Boolean.TRUE.equals(structure.getIsEsiEligible()) && gross.compareTo(BigDecimal.valueOf(21000)) <= 0) {
                esi = gross.multiply(BigDecimal.valueOf(0.0075)).setScale(2, RoundingMode.HALF_UP);
            }

            BigDecimal pt = Boolean.TRUE.equals(structure.getIsPtEligible()) ? BigDecimal.valueOf(200.00) : BigDecimal.ZERO;
            BigDecimal deductions = pf.add(esi).add(pt);
            BigDecimal net = gross.subtract(deductions).max(BigDecimal.ZERO);

            entry.setPfEmployee(pf);
            entry.setEsiEmployee(esi);
            entry.setProfessionalTax(pt);
            entry.setTotalDeductions(deductions);
            entry.setNetSalary(net);

            run.getEntries().add(entry);

            totalGross = totalGross.add(gross);
            totalDeductions = totalDeductions.add(deductions);
            totalNet = totalNet.add(net);
        }

        run.setTotalGross(totalGross);
        run.setTotalPending(totalNet);
        run.setTotalPaid(BigDecimal.ZERO);
        run.setTotalOverdue(BigDecimal.ZERO);
        run.setTotalDeductions(totalDeductions);
        run.setTotalNetPayable(totalNet);
        run.setEmployeeCount(employees.size());

        return payrollRunRepo.save(run);
    }

    @Transactional
    public PayrollEntry updateEntryStatus(Long entryId, String status, Long companyId) {
        PayrollEntry entry = payrollEntryRepo.findByIdAndCompanyId(entryId, companyId)
                .orElseThrow(() -> new ResourceNotFoundException("PayrollEntry", "id", entryId));

        entry.setPaymentStatus(status.toUpperCase());
        if ("PAID".equalsIgnoreCase(status)) {
            entry.setDisbursedAt(OffsetDateTime.now());
        }
        return payrollEntryRepo.save(entry);
    }

    @Transactional
    public List<PayrollEntry> batchUpdateStatus(List<Long> entryIds, String status, Long companyId) {
        return entryIds.stream()
                .map(id -> updateEntryStatus(id, status, companyId))
                .collect(Collectors.toList());
    }

    private String maskAccountNumber(String acc) {
        if (acc == null || acc.length() < 4) return "XXXX";
        return "XXXX-" + acc.substring(acc.length() - 4);
    }

    private SalaryStructure createDefaultStructure(Employee emp) {
        SalaryStructure s = new SalaryStructure();
        s.setCompanyId(emp.getCompanyId());
        s.setEmployeeId(emp.getId());
        BigDecimal gross = emp.getMonthlySalary() != null ? emp.getMonthlySalary() : BigDecimal.valueOf(18000.00);
        s.setMonthlyGross(gross);
        s.setBasicSalary(gross.multiply(BigDecimal.valueOf(0.50)).setScale(2, RoundingMode.HALF_UP));
        s.setHra(gross.multiply(BigDecimal.valueOf(0.30)).setScale(2, RoundingMode.HALF_UP));
        s.setSpecialAllowance(gross.subtract(s.getBasicSalary()).subtract(s.getHra()));
        return s;
    }
}
