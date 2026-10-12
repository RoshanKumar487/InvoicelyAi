package com.invoicely.backend.service;

import com.invoicely.backend.exception.ResourceNotFoundException;
import com.invoicely.backend.model.Employee;
import com.invoicely.backend.repository.EmployeeRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;

@Service
public class EmployeeService {

    private final EmployeeRepository employeeRepository;

    @Autowired
    public EmployeeService(EmployeeRepository employeeRepository) {
        this.employeeRepository = employeeRepository;
    }

    public List<Employee> getEmployees(Long companyId, String status, String department) {
        List<Employee> all;
        if (companyId != null) {
            all = employeeRepository.findByCompanyIdOrderByCreatedAtDesc(companyId);
            if (all.isEmpty() && employeeRepository.count() > 0 && employeeRepository.countByCompanyId(companyId) == 0) {
                all = employeeRepository.findAllByOrderByCreatedAtDesc();
            }
        } else {
            all = employeeRepository.findAllByOrderByCreatedAtDesc();
        }

        return all.stream()
                .filter(e -> {
                    if (status == null || status.trim().isEmpty() || status.equalsIgnoreCase("ALL")) {
                        return true;
                    }
                    return status.trim().equalsIgnoreCase(e.getStatus());
                })
                .filter(e -> {
                    if (department == null || department.trim().isEmpty() || department.equalsIgnoreCase("ALL")) {
                        return true;
                    }
                    return department.trim().equalsIgnoreCase(e.getDepartment());
                })
                .toList();
    }

    public Employee getEmployeeById(Long id, Long companyId) {
        if (companyId != null) {
            return employeeRepository.findByIdAndCompanyId(id, companyId)
                    .orElseGet(() -> employeeRepository.findById(id)
                            .orElseThrow(() -> new ResourceNotFoundException("Employee", "id", id)));
        }
        return employeeRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Employee", "id", id));
    }

    @Transactional
    public Employee createEmployee(Employee employee, Long companyId) {
        if (companyId != null) {
            employee.setCompanyId(companyId);
        }
        if (employee.getFullName() == null || employee.getFullName().trim().isEmpty()) {
            employee.setFullName("Staff Member");
        }
        if (employee.getEmployeeCode() == null || employee.getEmployeeCode().trim().isEmpty()) {
            long count = (companyId != null) ? employeeRepository.countByCompanyId(companyId) : employeeRepository.count();
            employee.setEmployeeCode(String.format("EMP-%03d", count + 1));
        }
        if (employee.getMonthlySalary() == null) {
            employee.setMonthlySalary(BigDecimal.ZERO);
        }
        if (employee.getStatus() == null || employee.getStatus().trim().isEmpty()) {
            employee.setStatus("ACTIVE");
        }
        if (employee.getDesignation() == null || employee.getDesignation().trim().isEmpty()) {
            employee.setDesignation("Security Guard");
        }
        if (employee.getDepartment() == null || employee.getDepartment().trim().isEmpty()) {
            employee.setDepartment("Security");
        }
        if (employee.getGender() == null || employee.getGender().trim().isEmpty()) {
            employee.setGender("Male");
        }
        if (employee.getMaritalStatus() == null || employee.getMaritalStatus().trim().isEmpty()) {
            employee.setMaritalStatus("Single");
        }
        if (employee.getAddress() == null) employee.setAddress("");
        if (employee.getCity() == null) employee.setCity("");
        if (employee.getState() == null) employee.setState("");
        if (employee.getPincode() == null) employee.setPincode("");
        if (employee.getPhone() == null) employee.setPhone("");
        if (employee.getEmail() == null) employee.setEmail("");
        if (employee.getAadhaarNumber() == null) employee.setAadhaarNumber("");
        if (employee.getAadhaarFrontUri() == null) employee.setAadhaarFrontUri("");
        if (employee.getAadhaarBackUri() == null) employee.setAadhaarBackUri("");
        if (employee.getPhotoUri() == null) employee.setPhotoUri("");
        if (employee.getDob() == null) employee.setDob("");
        if (employee.getFatherOrHusbandName() == null) employee.setFatherOrHusbandName("");
        if (employee.getEmergencyContactName() == null) employee.setEmergencyContactName("");
        if (employee.getEmergencyContactPhone() == null) employee.setEmergencyContactPhone("");
        if (employee.getBloodGroup() == null) employee.setBloodGroup("");
        if (employee.getQualification() == null) employee.setQualification("");
        if (employee.getJoiningDate() == null) employee.setJoiningDate("");
        if (employee.getBankName() == null) employee.setBankName("");
        if (employee.getBankAccountNumber() == null) employee.setBankAccountNumber("");
        if (employee.getIfscCode() == null) employee.setIfscCode("");
        if (employee.getNotes() == null) employee.setNotes("");

        if (employee.getCreatedAt() == null) {
            employee.setCreatedAt(OffsetDateTime.now());
        }
        employee.setUpdatedAt(OffsetDateTime.now());
        return employeeRepository.save(employee);
    }

    @Transactional
    public Employee updateEmployee(Long id, Employee updated, Long companyId) {
        Employee existing = getEmployeeById(id, companyId);

        if (updated.getFullName() != null && !updated.getFullName().trim().isEmpty()) {
            existing.setFullName(updated.getFullName());
        }
        if (updated.getEmployeeCode() != null) existing.setEmployeeCode(updated.getEmployeeCode());
        if (updated.getAadhaarNumber() != null) existing.setAadhaarNumber(updated.getAadhaarNumber());
        if (updated.getAadhaarFrontUri() != null) existing.setAadhaarFrontUri(updated.getAadhaarFrontUri());
        if (updated.getAadhaarBackUri() != null) existing.setAadhaarBackUri(updated.getAadhaarBackUri());
        if (updated.getPhotoUri() != null) existing.setPhotoUri(updated.getPhotoUri());
        if (updated.getDob() != null) existing.setDob(updated.getDob());
        if (updated.getGender() != null) existing.setGender(updated.getGender());
        if (updated.getPhone() != null) existing.setPhone(updated.getPhone());
        if (updated.getEmail() != null) existing.setEmail(updated.getEmail());
        if (updated.getDesignation() != null) existing.setDesignation(updated.getDesignation());
        if (updated.getDepartment() != null) existing.setDepartment(updated.getDepartment());
        if (updated.getAddress() != null) existing.setAddress(updated.getAddress());
        if (updated.getCity() != null) existing.setCity(updated.getCity());
        if (updated.getState() != null) existing.setState(updated.getState());
        if (updated.getPincode() != null) existing.setPincode(updated.getPincode());
        if (updated.getFatherOrHusbandName() != null) existing.setFatherOrHusbandName(updated.getFatherOrHusbandName());
        if (updated.getEmergencyContactName() != null) existing.setEmergencyContactName(updated.getEmergencyContactName());
        if (updated.getEmergencyContactPhone() != null) existing.setEmergencyContactPhone(updated.getEmergencyContactPhone());
        if (updated.getBloodGroup() != null) existing.setBloodGroup(updated.getBloodGroup());
        if (updated.getMaritalStatus() != null) existing.setMaritalStatus(updated.getMaritalStatus());
        if (updated.getQualification() != null) existing.setQualification(updated.getQualification());
        if (updated.getJoiningDate() != null) existing.setJoiningDate(updated.getJoiningDate());
        if (updated.getMonthlySalary() != null) existing.setMonthlySalary(updated.getMonthlySalary());
        if (updated.getBankName() != null) existing.setBankName(updated.getBankName());
        if (updated.getBankAccountNumber() != null) existing.setBankAccountNumber(updated.getBankAccountNumber());
        if (updated.getIfscCode() != null) existing.setIfscCode(updated.getIfscCode());
        if (updated.getStatus() != null) existing.setStatus(updated.getStatus());
        if (updated.getNotes() != null) existing.setNotes(updated.getNotes());
        existing.setUpdatedAt(OffsetDateTime.now());

        return employeeRepository.save(existing);
    }

    @Transactional
    public void deleteEmployee(Long id, Long companyId) {
        Employee existing = getEmployeeById(id, companyId);
        employeeRepository.delete(existing);
    }
}
