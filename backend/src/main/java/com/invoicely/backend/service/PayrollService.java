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
    private final ExpenseRepository expenseRepo;

    public PayrollService(PayrollRunRepository payrollRunRepo,
                          PayrollEntryRepository payrollEntryRepo,
                          EmployeeRepository employeeRepo,
                          SalaryStructureRepository salaryRepo,
                          ExpenseRepository expenseRepo) {
        this.payrollRunRepo = payrollRunRepo;
        this.payrollEntryRepo = payrollEntryRepo;
        this.employeeRepo = employeeRepo;
        this.salaryRepo = salaryRepo;
        this.expenseRepo = expenseRepo;
    }

    @Transactional
    public List<PayrollRun> listRuns(Long companyId) {
        LocalDate now = LocalDate.now();
        int curMonth = now.getMonthValue();
        int curYear = now.getYear();

        List<Employee> allEmployees = getEmployeesForCompany(companyId);
        Long effectiveCompanyId = companyId != null ? companyId : 1L;

        List<PayrollRun> existingRuns = payrollRunRepo.findByCompanyIdOrderByPeriodYearDescPeriodMonthDesc(effectiveCompanyId);
        if (existingRuns.isEmpty() && companyId != null && !effectiveCompanyId.equals(companyId)) {
            existingRuns = payrollRunRepo.findByCompanyIdOrderByPeriodYearDescPeriodMonthDesc(companyId);
        }

        var currentRunOpt = existingRuns.stream()
                .filter(r -> r.getPeriodMonth() == curMonth && r.getPeriodYear() == curYear)
                .findFirst();

        if (currentRunOpt.isEmpty() && !allEmployees.isEmpty()) {
            try {
                generatePayrollRun(effectiveCompanyId, curMonth, curYear, now.withDayOfMonth(now.lengthOfMonth()), "Monthly Payroll Run - " + curMonth + "/" + curYear);
                existingRuns = payrollRunRepo.findByCompanyIdOrderByPeriodYearDescPeriodMonthDesc(effectiveCompanyId);
            } catch (Exception ignored) {}
        } else if (currentRunOpt.isPresent() && !allEmployees.isEmpty()) {
            syncRunEmployees(currentRunOpt.get(), allEmployees, effectiveCompanyId);
        }

        return existingRuns;
    }

    public List<Employee> getEmployeesForCompany(Long companyId) {
        List<Employee> emps = null;
        if (companyId != null) {
            emps = employeeRepo.findByCompanyIdOrderByCreatedAtDesc(companyId);
        }
        if ((emps == null || emps.isEmpty()) && employeeRepo.count() > 0) {
            emps = employeeRepo.findAllByOrderByCreatedAtDesc();
        }
        return emps != null ? emps : List.of();
    }

    @Transactional
    public void syncRunEmployees(PayrollRun run, List<Employee> employees, Long companyId) {
        if (run == null || employees == null || employees.isEmpty()) return;

        List<PayrollEntry> existingEntries = payrollEntryRepo.findByPayrollRunIdOrderByEmployeeNameAsc(run.getId());
        java.util.Set<Long> existingEmpIds = existingEntries.stream()
                .map(PayrollEntry::getEmployeeId)
                .filter(id -> id != null)
                .collect(Collectors.toSet());

        java.util.Set<String> existingEmpNames = existingEntries.stream()
                .map(e -> e.getEmployeeName() != null ? e.getEmployeeName().trim().toLowerCase() : "")
                .filter(s -> !s.isEmpty())
                .collect(Collectors.toSet());

        boolean changed = false;
        LocalDate payDate = run.getScheduledPayDate() != null ? run.getScheduledPayDate() : LocalDate.now().plusDays(5);

        for (Employee emp : employees) {
            boolean alreadyInRun = (emp.getId() != null && existingEmpIds.contains(emp.getId()))
                    || (emp.getFullName() != null && existingEmpNames.contains(emp.getFullName().trim().toLowerCase()));

            if (!alreadyInRun) {
                PayrollEntry entry = buildEntryForEmployee(run, emp, companyId, payDate, run.getPeriodMonth(), run.getPeriodYear());
                payrollEntryRepo.save(entry);
                changed = true;
            }
        }

        if (changed) {
            recalculateRunTotals(run);
        }
    }

    @Transactional(readOnly = true)
    public PayrollRun getRun(Long runId, Long companyId) {
        return payrollRunRepo.findByIdAndCompanyId(runId, companyId)
                .orElseGet(() -> payrollRunRepo.findById(runId)
                        .orElseThrow(() -> new ResourceNotFoundException("PayrollRun", "id", runId)));
    }

    @Transactional
    public List<PayrollEntry> listEntries(Long companyId, Long runId, String status, String search) {
        Long effectiveCompanyId = companyId != null ? companyId : 1L;

        // If runId is provided, sync any missing active employees into this run
        if (runId != null && runId > 0) {
            payrollRunRepo.findById(runId).ifPresent(r -> {
                List<Employee> emps = getEmployeesForCompany(effectiveCompanyId);
                syncRunEmployees(r, emps, effectiveCompanyId);
            });
        }

        List<PayrollEntry> entries = (runId != null && runId > 0)
                ? payrollEntryRepo.findByPayrollRunIdOrderByEmployeeNameAsc(runId)
                : payrollEntryRepo.findByCompanyIdOrderByEmployeeNameAsc(effectiveCompanyId);

        if (entries.isEmpty() && (runId == null || runId == 0)) {
            // Check if there are entries across all company runs
            entries = payrollEntryRepo.findAll();
        }

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
        BigDecimal totalAdvances = BigDecimal.ZERO;
        int pendingCount = 0;
        int paidCount = 0;
        int overdueCount = 0;

        for (PayrollEntry e : entries) {
            BigDecimal net = e.getNetSalary() != null ? e.getNetSalary() : BigDecimal.ZERO;
            BigDecimal gross = e.getGrossEarnings() != null ? e.getGrossEarnings() : BigDecimal.ZERO;
            BigDecimal adv = e.getAdvanceAmount() != null ? e.getAdvanceAmount() : BigDecimal.ZERO;
            totalGross = totalGross.add(gross);
            totalAdvances = totalAdvances.add(adv);

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
        kpi.setTotalAdvances(totalAdvances);
        kpi.setTotalEmployees(entries.size());
        kpi.setPendingCount(pendingCount);
        kpi.setPaidCount(paidCount);
        kpi.setOverdueCount(overdueCount);
        return kpi;
    @Transactional
    public PayrollRun generatePayrollRun(Long companyId, int month, int year, LocalDate scheduledPayDate, String title) {
        LocalDate payDate = scheduledPayDate != null ? scheduledPayDate : LocalDate.now().plusDays(5);
        String runTitle = (title != null && !title.isBlank()) ? title : "Payroll " + month + "/" + year;

        Long effectiveCompanyId = companyId != null ? companyId : 1L;

        PayrollRun run = payrollRunRepo.findByCompanyIdAndPeriodMonthAndPeriodYear(effectiveCompanyId, month, year)
                .orElseGet(() -> {
                    PayrollRun r = new PayrollRun();
                    r.setCompanyId(effectiveCompanyId);
                    r.setPeriodMonth(month);
                    r.setPeriodYear(year);
                    return r;
                });

        run.setRunTitle(runTitle);
        run.setScheduledPayDate(payDate);
        run.setStatus("REVIEWED");
        run.getEntries().clear();

        List<Employee> employees = getEmployeesForCompany(effectiveCompanyId);

        BigDecimal totalGross = BigDecimal.ZERO;
        BigDecimal totalDeductions = BigDecimal.ZERO;
        BigDecimal totalNet = BigDecimal.ZERO;
        BigDecimal totalAdvances = BigDecimal.ZERO;

        for (Employee emp : employees) {
            PayrollEntry entry = buildEntryForEmployee(run, emp, effectiveCompanyId, payDate, month, year);
            run.getEntries().add(entry);

            BigDecimal gross = entry.getGrossEarnings() != null ? entry.getGrossEarnings() : BigDecimal.ZERO;
            BigDecimal ded = entry.getTotalDeductions() != null ? entry.getTotalDeductions() : BigDecimal.ZERO;
            BigDecimal net = entry.getNetSalary() != null ? entry.getNetSalary() : BigDecimal.ZERO;
            BigDecimal adv = entry.getAdvanceAmount() != null ? entry.getAdvanceAmount() : BigDecimal.ZERO;

            totalGross = totalGross.add(gross);
            totalDeductions = totalDeductions.add(ded);
            totalNet = totalNet.add(net);
            totalAdvances = totalAdvances.add(adv);
        }

        run.setTotalGross(totalGross);
        run.setTotalPending(totalNet);
        run.setTotalPaid(BigDecimal.ZERO);
        run.setTotalOverdue(BigDecimal.ZERO);
        run.setTotalDeductions(totalDeductions);
        run.setTotalNetPayable(totalNet);
        run.setTotalAdvances(totalAdvances);
        run.setEmployeeCount(employees.size());

        return payrollRunRepo.save(run);
    }

    public PayrollEntry buildEntryForEmployee(PayrollRun run, Employee emp, Long companyId, LocalDate payDate, int month, int year) {
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
        BigDecimal gross = (emp.getMonthlySalary() != null && emp.getMonthlySalary().compareTo(BigDecimal.ZERO) > 0)
                ? emp.getMonthlySalary()
                : (structure.getMonthlyGross() != null ? structure.getMonthlyGross() : BigDecimal.valueOf(18000.00));

        BigDecimal basic = gross.multiply(BigDecimal.valueOf(0.50)).setScale(2, RoundingMode.HALF_UP);
        BigDecimal hra = gross.multiply(BigDecimal.valueOf(0.30)).setScale(2, RoundingMode.HALF_UP);
        BigDecimal allowances = gross.subtract(basic).subtract(hra);

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
        BigDecimal statutoryDeductions = pf.add(esi).add(pt);

        // Advance taken via Expenses screen
        BigDecimal unrecoveredAdvance = expenseRepo.sumUnsettledAdvances(companyId, emp.getId(), emp.getFullName());
        if (unrecoveredAdvance == null) unrecoveredAdvance = BigDecimal.ZERO;

        BigDecimal netBeforeAdvance = gross.subtract(statutoryDeductions).max(BigDecimal.ZERO);
        BigDecimal advanceDeduction = unrecoveredAdvance.min(netBeforeAdvance);
        BigDecimal allDeductions = statutoryDeductions.add(advanceDeduction);
        BigDecimal net = gross.subtract(allDeductions).max(BigDecimal.ZERO);

        entry.setPfEmployee(pf);
        entry.setEsiEmployee(esi);
        entry.setProfessionalTax(pt);
        entry.setAdvanceAmount(unrecoveredAdvance);
        entry.setAdvanceDeduction(advanceDeduction);
        entry.setTotalDeductions(allDeductions);
        entry.setNetSalary(net);

        // Backlog / multi-month pending salary calculation
        List<PayrollEntry> historicalEntries = payrollEntryRepo.findByCompanyIdAndEmployeeId(companyId, emp.getId());
        int pastPendingMonths = 0;
        BigDecimal pastPendingSalary = BigDecimal.ZERO;
        StringBuilder pendingMonthsStr = new StringBuilder();

        for (PayrollEntry past : historicalEntries) {
            if (past.getPayrollRun() != null && (run == null || !past.getPayrollRun().getId().equals(run.getId()))
                    && !"PAID".equalsIgnoreCase(past.getPaymentStatus())) {
                pastPendingMonths++;
                pastPendingSalary = pastPendingSalary.add(past.getNetSalary() != null ? past.getNetSalary() : BigDecimal.ZERO);
                if (pendingMonthsStr.length() > 0) pendingMonthsStr.append(", ");
                pendingMonthsStr.append(past.getPayrollRun().getPeriodMonth()).append("/").append(past.getPayrollRun().getPeriodYear());
            }
        }

        int totalPendingMonths = pastPendingMonths + 1;
        entry.setPendingMonthsCount(totalPendingMonths);
        if (pendingMonthsStr.length() > 0) {
            entry.setPendingMonthsDetails(totalPendingMonths + " Months Pending (" + pendingMonthsStr.toString() + ", " + month + "/" + year + ")");
        } else {
            entry.setPendingMonthsDetails("Current Month (" + month + "/" + year + ")");
        }
        entry.setCumulativePayable(net.add(pastPendingSalary));

        return entry;
    }

    @Transactional
    public void recalculateRunTotals(PayrollRun run) {
        if (run == null || run.getId() == null) return;
        List<PayrollEntry> entries = payrollEntryRepo.findByPayrollRunIdOrderByEmployeeNameAsc(run.getId());
        BigDecimal totalGross = BigDecimal.ZERO;
        BigDecimal totalPaid = BigDecimal.ZERO;
        BigDecimal totalPending = BigDecimal.ZERO;
        BigDecimal totalOverdue = BigDecimal.ZERO;
        BigDecimal totalDeductions = BigDecimal.ZERO;
        BigDecimal totalNet = BigDecimal.ZERO;
        BigDecimal totalAdvances = BigDecimal.ZERO;

        for (PayrollEntry e : entries) {
            BigDecimal gross = e.getGrossEarnings() != null ? e.getGrossEarnings() : BigDecimal.ZERO;
            BigDecimal ded = e.getTotalDeductions() != null ? e.getTotalDeductions() : BigDecimal.ZERO;
            BigDecimal net = e.getNetSalary() != null ? e.getNetSalary() : BigDecimal.ZERO;
            BigDecimal adv = e.getAdvanceAmount() != null ? e.getAdvanceAmount() : BigDecimal.ZERO;

            totalGross = totalGross.add(gross);
            totalDeductions = totalDeductions.add(ded);
            totalNet = totalNet.add(net);
            totalAdvances = totalAdvances.add(adv);

            if ("PAID".equalsIgnoreCase(e.getPaymentStatus())) {
                totalPaid = totalPaid.add(net);
            } else if ("OVERDUE".equalsIgnoreCase(e.getPaymentStatus())) {
                totalOverdue = totalOverdue.add(net);
            } else {
                totalPending = totalPending.add(net);
            }
        }

        run.setTotalGross(totalGross);
        run.setTotalPaid(totalPaid);
        run.setTotalPending(totalPending);
        run.setTotalOverdue(totalOverdue);
        run.setTotalDeductions(totalDeductions);
        run.setTotalNetPayable(totalNet);
        run.setTotalAdvances(totalAdvances);
        run.setEmployeeCount(entries.size());
        payrollRunRepo.save(run);
    }

    @Transactional
    public PayrollEntry updateEntry(Long entryId, PayrollEntry updated, Long companyId) {
        PayrollEntry entry = payrollEntryRepo.findByIdAndCompanyId(entryId, companyId)
                .orElseGet(() -> payrollEntryRepo.findById(entryId)
                        .orElseThrow(() -> new ResourceNotFoundException("PayrollEntry", "id", entryId)));

        if (updated.getGrossEarnings() != null) {
            entry.setGrossEarnings(updated.getGrossEarnings());
            // Pro-rate basic and HRA if gross changed
            BigDecimal basic = updated.getGrossEarnings().multiply(BigDecimal.valueOf(0.50)).setScale(2, RoundingMode.HALF_UP);
            BigDecimal hra = updated.getGrossEarnings().multiply(BigDecimal.valueOf(0.30)).setScale(2, RoundingMode.HALF_UP);
            BigDecimal allowances = updated.getGrossEarnings().subtract(basic).subtract(hra);
            entry.setBasicPay(basic);
            entry.setHra(hra);
            entry.setAllowances(allowances);
        } else {
            if (updated.getBasicPay() != null) entry.setBasicPay(updated.getBasicPay());
            if (updated.getHra() != null) entry.setHra(updated.getHra());
            if (updated.getAllowances() != null) entry.setAllowances(updated.getAllowances());
            if (updated.getBasicPay() != null || updated.getHra() != null || updated.getAllowances() != null) {
                BigDecimal b = entry.getBasicPay() != null ? entry.getBasicPay() : BigDecimal.ZERO;
                BigDecimal h = entry.getHra() != null ? entry.getHra() : BigDecimal.ZERO;
                BigDecimal a = entry.getAllowances() != null ? entry.getAllowances() : BigDecimal.ZERO;
                entry.setGrossEarnings(b.add(h).add(a));
            }
        }

        if (updated.getPfEmployee() != null) entry.setPfEmployee(updated.getPfEmployee());
        if (updated.getEsiEmployee() != null) entry.setEsiEmployee(updated.getEsiEmployee());
        if (updated.getProfessionalTax() != null) entry.setProfessionalTax(updated.getProfessionalTax());
        if (updated.getAdvanceAmount() != null) entry.setAdvanceAmount(updated.getAdvanceAmount());
        if (updated.getAdvanceDeduction() != null) entry.setAdvanceDeduction(updated.getAdvanceDeduction());

        BigDecimal statutory = (entry.getPfEmployee() != null ? entry.getPfEmployee() : BigDecimal.ZERO)
                .add(entry.getEsiEmployee() != null ? entry.getEsiEmployee() : BigDecimal.ZERO)
                .add(entry.getProfessionalTax() != null ? entry.getProfessionalTax() : BigDecimal.ZERO);
        BigDecimal advCut = entry.getAdvanceDeduction() != null ? entry.getAdvanceDeduction() : BigDecimal.ZERO;
        BigDecimal totalDeductions = statutory.add(advCut);
        entry.setTotalDeductions(totalDeductions);

        if (updated.getNetSalary() != null) {
            entry.setNetSalary(updated.getNetSalary());
        } else {
            BigDecimal gross = entry.getGrossEarnings() != null ? entry.getGrossEarnings() : BigDecimal.ZERO;
            entry.setNetSalary(gross.subtract(totalDeductions).max(BigDecimal.ZERO));
        }

        if (updated.getCumulativePayable() != null) {
            entry.setCumulativePayable(updated.getCumulativePayable());
        } else {
            entry.setCumulativePayable(entry.getNetSalary());
        }

        if (updated.getPaymentStatus() != null && !updated.getPaymentStatus().isBlank()) {
            entry.setPaymentStatus(updated.getPaymentStatus().toUpperCase());
            if ("PAID".equalsIgnoreCase(updated.getPaymentStatus()) && entry.getDisbursedAt() == null) {
                entry.setDisbursedAt(OffsetDateTime.now());
                settleAdvancesForEntry(entry, companyId);
            }
        }

        if (updated.getNotes() != null) entry.setNotes(updated.getNotes());
        if (updated.getBankAccountMask() != null) entry.setBankAccountMask(updated.getBankAccountMask());

        PayrollEntry saved = payrollEntryRepo.save(entry);

        if (saved.getPayrollRun() != null) {
            recalculateRunTotals(saved.getPayrollRun());
        }

        return saved;
    }

    private void settleAdvancesForEntry(PayrollEntry entry, Long companyId) {
        if (entry.getAdvanceDeduction() != null && entry.getAdvanceDeduction().compareTo(BigDecimal.ZERO) > 0) {
            List<Expense> unsettled = expenseRepo.findUnsettledAdvancesByEmployee(companyId, entry.getEmployeeId(), entry.getEmployeeName());
            BigDecimal remainingToSettle = entry.getAdvanceDeduction();
            for (Expense exp : unsettled) {
                if (remainingToSettle.compareTo(BigDecimal.ZERO) <= 0) break;
                exp.setAdvanceSettled(true);
                if (entry.getPayrollRun() != null) {
                    exp.setSettledPayrollRunId(entry.getPayrollRun().getId());
                }
                expenseRepo.save(exp);
                remainingToSettle = remainingToSettle.subtract(exp.getAmount());
            }
        }
    }

    @Transactional
    public PayrollEntry updateEntryStatus(Long entryId, String status, Long companyId) {
        PayrollEntry entry = payrollEntryRepo.findByIdAndCompanyId(entryId, companyId)
                .orElseGet(() -> payrollEntryRepo.findById(entryId)
                        .orElseThrow(() -> new ResourceNotFoundException("PayrollEntry", "id", entryId)));

        entry.setPaymentStatus(status.toUpperCase());
        if ("PAID".equalsIgnoreCase(status)) {
            entry.setDisbursedAt(OffsetDateTime.now());
            settleAdvancesForEntry(entry, companyId);
        }

        PayrollEntry saved = payrollEntryRepo.save(entry);
        if (saved.getPayrollRun() != null) {
            recalculateRunTotals(saved.getPayrollRun());
        }
        return saved;
    }

    @Transactional
    public List<PayrollEntry> batchUpdateStatus(List<Long> entryIds, String status, Long companyId) {
        return entryIds.stream()
                .map(id -> updateEntryStatus(id, status, companyId))
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<Expense> getEmployeeAdvanceHistory(Long companyId, Long employeeId, String employeeName) {
        return expenseRepo.findAdvanceHistoryByEmployee(companyId, employeeId, employeeName);
    }

    private String maskAccountNumber(String acc) {
        if (acc == null || acc.length() < 4) return "XXXX";
        return "XXXX-" + acc.substring(acc.length() - 4);
    }

    private SalaryStructure createDefaultStructure(Employee emp) {
        SalaryStructure s = new SalaryStructure();
        s.setCompanyId(emp.getCompanyId());
        s.setEmployeeId(emp.getId());
        BigDecimal gross = emp.getMonthlySalary() != null && emp.getMonthlySalary().compareTo(BigDecimal.ZERO) > 0
                ? emp.getMonthlySalary()
                : BigDecimal.valueOf(18000.00);
        s.setMonthlyGross(gross);
        s.setBasicSalary(gross.multiply(BigDecimal.valueOf(0.50)).setScale(2, RoundingMode.HALF_UP));
        s.setHra(gross.multiply(BigDecimal.valueOf(0.30)).setScale(2, RoundingMode.HALF_UP));
        s.setSpecialAllowance(gross.subtract(s.getBasicSalary()).subtract(s.getHra()));
        return s;
    }
}
