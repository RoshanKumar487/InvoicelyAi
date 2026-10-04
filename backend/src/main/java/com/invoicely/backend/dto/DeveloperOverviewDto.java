package com.invoicely.backend.dto;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

public class DeveloperOverviewDto {

    private long totalCompanies;
    private long totalUsers;
    private long totalInvoices;
    private long totalExpenses;
    private BigDecimal totalPlatformRevenue = BigDecimal.ZERO;
    private BigDecimal totalPlatformExpenses = BigDecimal.ZERO;
    private List<CompanyPlatformStatsDto> companies = new ArrayList<>();

    public DeveloperOverviewDto() {}

    public long getTotalCompanies() { return totalCompanies; }
    public void setTotalCompanies(long totalCompanies) { this.totalCompanies = totalCompanies; }

    public long getTotalUsers() { return totalUsers; }
    public void setTotalUsers(long totalUsers) { this.totalUsers = totalUsers; }

    public long getTotalInvoices() { return totalInvoices; }
    public void setTotalInvoices(long totalInvoices) { this.totalInvoices = totalInvoices; }

    public long getTotalExpenses() { return totalExpenses; }
    public void setTotalExpenses(long totalExpenses) { this.totalExpenses = totalExpenses; }

    public BigDecimal getTotalPlatformRevenue() { return totalPlatformRevenue; }
    public void setTotalPlatformRevenue(BigDecimal totalPlatformRevenue) { this.totalPlatformRevenue = totalPlatformRevenue; }

    public BigDecimal getTotalPlatformExpenses() { return totalPlatformExpenses; }
    public void setTotalPlatformExpenses(BigDecimal totalPlatformExpenses) { this.totalPlatformExpenses = totalPlatformExpenses; }

    public List<CompanyPlatformStatsDto> getCompanies() { return companies; }
    public void setCompanies(List<CompanyPlatformStatsDto> companies) { this.companies = companies; }

    public static class CompanyPlatformStatsDto {
        private Long companyId;
        private String companyCode;
        private String companyName;
        private String email;
        private String location;
        private long userCount;
        private long invoiceCount;
        private long expenseCount;
        private BigDecimal totalRevenue = BigDecimal.ZERO;
        private BigDecimal totalExpenses = BigDecimal.ZERO;

        public CompanyPlatformStatsDto() {}

        public Long getCompanyId() { return companyId; }
        public void setCompanyId(Long companyId) { this.companyId = companyId; }

        public String getCompanyCode() { return companyCode; }
        public void setCompanyCode(String companyCode) { this.companyCode = companyCode; }

        public String getCompanyName() { return companyName; }
        public void setCompanyName(String companyName) { this.companyName = companyName; }

        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }

        public String getLocation() { return location; }
        public void setLocation(String location) { this.location = location; }

        public long getUserCount() { return userCount; }
        public void setUserCount(long userCount) { this.userCount = userCount; }

        public long getInvoiceCount() { return invoiceCount; }
        public void setInvoiceCount(long invoiceCount) { this.invoiceCount = invoiceCount; }

        public long getExpenseCount() { return expenseCount; }
        public void setExpenseCount(long expenseCount) { this.expenseCount = expenseCount; }

        public BigDecimal getTotalRevenue() { return totalRevenue; }
        public void setTotalRevenue(BigDecimal totalRevenue) { this.totalRevenue = totalRevenue; }

        public BigDecimal getTotalExpenses() { return totalExpenses; }
        public void setTotalExpenses(BigDecimal totalExpenses) { this.totalExpenses = totalExpenses; }
    }
}
