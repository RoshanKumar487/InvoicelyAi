package com.invoicely.backend.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.OffsetDateTime;

@Entity
@Table(name = "employees")
public class Employee {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "company_id")
    private Long companyId;

    @Column(name = "employee_code")
    private String employeeCode = "";

    @Column(name = "full_name", nullable = false)
    private String fullName = "";

    @Column(name = "aadhaar_number", length = 30)
    private String aadhaarNumber = "";

    @Column(name = "aadhaar_front_uri", columnDefinition = "TEXT")
    private String aadhaarFrontUri = "";

    @Column(name = "aadhaar_back_uri", columnDefinition = "TEXT")
    private String aadhaarBackUri = "";

    @Column(name = "photo_uri", columnDefinition = "TEXT")
    private String photoUri = "";

    @Column(name = "dob", length = 30)
    private String dob = "";

    @Column(name = "gender", length = 20)
    private String gender = "Male";

    @Column(name = "phone", length = 50)
    private String phone = "";

    @Column(name = "email", length = 120)
    private String email = "";

    @Column(name = "designation", length = 100)
    private String designation = "Security Guard";

    @Column(name = "department", length = 100)
    private String department = "Security";

    @Column(columnDefinition = "TEXT")
    private String address = "";

    @Column(length = 100)
    private String city = "";

    @Column(length = 100)
    private String state = "";

    @Column(length = 20)
    private String pincode = "";

    @Column(name = "father_or_husband_name", length = 150)
    private String fatherOrHusbandName = "";

    @Column(name = "emergency_contact_name", length = 150)
    private String emergencyContactName = "";

    @Column(name = "emergency_contact_phone", length = 50)
    private String emergencyContactPhone = "";

    @Column(name = "blood_group", length = 10)
    private String bloodGroup = "";

    @Column(name = "marital_status", length = 30)
    private String maritalStatus = "Single";

    @Column(name = "qualification", length = 100)
    private String qualification = "";

    @Column(name = "joining_date", length = 30)
    private String joiningDate = "";

    @Column(name = "monthly_salary", precision = 12, scale = 2)
    private BigDecimal monthlySalary = BigDecimal.ZERO;

    @Column(name = "bank_name", length = 100)
    private String bankName = "";

    @Column(name = "bank_account_number", length = 50)
    private String bankAccountNumber = "";

    @Column(name = "ifsc_code", length = 30)
    private String ifscCode = "";

    @Column(name = "status", length = 30)
    private String status = "ACTIVE"; // ACTIVE, INACTIVE, ON_LEAVE

    @Column(columnDefinition = "TEXT")
    private String notes = "";

    @Column(name = "created_at")
    private OffsetDateTime createdAt = OffsetDateTime.now();

    @Column(name = "updated_at")
    private OffsetDateTime updatedAt = OffsetDateTime.now();

    public Employee() {}

    @PrePersist
    public void prePersist() {
        if (createdAt == null) createdAt = OffsetDateTime.now();
        if (updatedAt == null) updatedAt = OffsetDateTime.now();
    }

    @PreUpdate
    public void preUpdate() {
        updatedAt = OffsetDateTime.now();
    }

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getCompanyId() { return companyId; }
    public void setCompanyId(Long companyId) { this.companyId = companyId; }

    public String getEmployeeCode() { return employeeCode; }
    public void setEmployeeCode(String employeeCode) { this.employeeCode = employeeCode; }

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public String getAadhaarNumber() { return aadhaarNumber; }
    public void setAadhaarNumber(String aadhaarNumber) { this.aadhaarNumber = aadhaarNumber; }

    public String getAadhaarFrontUri() { return aadhaarFrontUri; }
    public void setAadhaarFrontUri(String aadhaarFrontUri) { this.aadhaarFrontUri = aadhaarFrontUri; }

    public String getAadhaarBackUri() { return aadhaarBackUri; }
    public void setAadhaarBackUri(String aadhaarBackUri) { this.aadhaarBackUri = aadhaarBackUri; }

    public String getPhotoUri() { return photoUri; }
    public void setPhotoUri(String photoUri) { this.photoUri = photoUri; }

    public String getDob() { return dob; }
    public void setDob(String dob) { this.dob = dob; }

    public String getGender() { return gender; }
    public void setGender(String gender) { this.gender = gender; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getDesignation() { return designation; }
    public void setDesignation(String designation) { this.designation = designation; }

    public String getDepartment() { return department; }
    public void setDepartment(String department) { this.department = department; }

    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }

    public String getCity() { return city; }
    public void setCity(String city) { this.city = city; }

    public String getState() { return state; }
    public void setState(String state) { this.state = state; }

    public String getPincode() { return pincode; }
    public void setPincode(String pincode) { this.pincode = pincode; }

    public String getFatherOrHusbandName() { return fatherOrHusbandName; }
    public void setFatherOrHusbandName(String fatherOrHusbandName) { this.fatherOrHusbandName = fatherOrHusbandName; }

    public String getEmergencyContactName() { return emergencyContactName; }
    public void setEmergencyContactName(String emergencyContactName) { this.emergencyContactName = emergencyContactName; }

    public String getEmergencyContactPhone() { return emergencyContactPhone; }
    public void setEmergencyContactPhone(String emergencyContactPhone) { this.emergencyContactPhone = emergencyContactPhone; }

    public String getBloodGroup() { return bloodGroup; }
    public void setBloodGroup(String bloodGroup) { this.bloodGroup = bloodGroup; }

    public String getMaritalStatus() { return maritalStatus; }
    public void setMaritalStatus(String maritalStatus) { this.maritalStatus = maritalStatus; }

    public String getQualification() { return qualification; }
    public void setQualification(String qualification) { this.qualification = qualification; }

    public String getJoiningDate() { return joiningDate; }
    public void setJoiningDate(String joiningDate) { this.joiningDate = joiningDate; }

    public BigDecimal getMonthlySalary() { return monthlySalary; }
    public void setMonthlySalary(BigDecimal monthlySalary) { this.monthlySalary = monthlySalary; }

    public String getBankName() { return bankName; }
    public void setBankName(String bankName) { this.bankName = bankName; }

    public String getBankAccountNumber() { return bankAccountNumber; }
    public void setBankAccountNumber(String bankAccountNumber) { this.bankAccountNumber = bankAccountNumber; }

    public String getIfscCode() { return ifscCode; }
    public void setIfscCode(String ifscCode) { this.ifscCode = ifscCode; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }

    public OffsetDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }
}
