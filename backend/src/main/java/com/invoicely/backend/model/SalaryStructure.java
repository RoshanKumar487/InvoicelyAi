package com.invoicely.backend.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.OffsetDateTime;

/**
 * Breakdown of an employee's monthly salary and statutory eligibility.
 */
@Entity
@Table(name = "salary_structures", uniqueConstraints = {
    @UniqueConstraint(columnNames = {"employee_id"})
})
public class SalaryStructure {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "company_id", nullable = false)
    private Long companyId;

    @Column(name = "employee_id", nullable = false)
    private Long employeeId;

    @Column(name = "monthly_gross", precision = 12, scale = 2, nullable = false)
    private BigDecimal monthlyGross = BigDecimal.ZERO;

    @Column(name = "basic_salary", precision = 12, scale = 2)
    private BigDecimal basicSalary = BigDecimal.ZERO;

    @Column(name = "hra", precision = 12, scale = 2)
    private BigDecimal hra = BigDecimal.ZERO;

    @Column(name = "conveyance_allowance", precision = 12, scale = 2)
    private BigDecimal conveyanceAllowance = BigDecimal.ZERO;

    @Column(name = "special_allowance", precision = 12, scale = 2)
    private BigDecimal specialAllowance = BigDecimal.ZERO;

    @Column(name = "is_pf_eligible")
    private Boolean isPfEligible = true;

    @Column(name = "is_esi_eligible")
    private Boolean isEsiEligible = true;

    @Column(name = "is_pt_eligible")
    private Boolean isPtEligible = true;

    @Column(name = "updated_at")
    private OffsetDateTime updatedAt = OffsetDateTime.now();

    public SalaryStructure() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getCompanyId() { return companyId; }
    public void setCompanyId(Long companyId) { this.companyId = companyId; }

    public Long getEmployeeId() { return employeeId; }
    public void setEmployeeId(Long employeeId) { this.employeeId = employeeId; }

    public BigDecimal getMonthlyGross() { return monthlyGross; }
    public void setMonthlyGross(BigDecimal monthlyGross) { this.monthlyGross = monthlyGross; }

    public BigDecimal getBasicSalary() { return basicSalary; }
    public void setBasicSalary(BigDecimal basicSalary) { this.basicSalary = basicSalary; }

    public BigDecimal getHra() { return hra; }
    public void setHra(BigDecimal hra) { this.hra = hra; }

    public BigDecimal getConveyanceAllowance() { return conveyanceAllowance; }
    public void setConveyanceAllowance(BigDecimal conveyanceAllowance) { this.conveyanceAllowance = conveyanceAllowance; }

    public BigDecimal getSpecialAllowance() { return specialAllowance; }
    public void setSpecialAllowance(BigDecimal specialAllowance) { this.specialAllowance = specialAllowance; }

    public Boolean getIsPfEligible() { return isPfEligible; }
    public void setIsPfEligible(Boolean isPfEligible) { this.isPfEligible = isPfEligible; }

    public Boolean getIsEsiEligible() { return isEsiEligible; }
    public void setIsEsiEligible(Boolean isEsiEligible) { this.isEsiEligible = isEsiEligible; }

    public Boolean getIsPtEligible() { return isPtEligible; }
    public void setIsPtEligible(Boolean isPtEligible) { this.isPtEligible = isPtEligible; }

    public OffsetDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }
}
