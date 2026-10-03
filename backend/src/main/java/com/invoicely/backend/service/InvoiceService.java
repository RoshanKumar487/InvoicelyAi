package com.invoicely.backend.service;

import com.invoicely.backend.exception.ResourceNotFoundException;
import com.invoicely.backend.model.Invoice;
import com.invoicely.backend.repository.InvoiceRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Year;
import java.util.List;

@Service
public class InvoiceService {

    private final InvoiceRepository invoiceRepository;

    @Autowired
    public InvoiceService(InvoiceRepository invoiceRepository) {
        this.invoiceRepository = invoiceRepository;
    }

    public List<Invoice> getAllInvoices() {
        return invoiceRepository.findAllByOrderByCreatedAtDesc();
    }

    public List<Invoice> getInvoices(Long companyId, String status, Long clientId) {
        if (companyId != null) {
            if (status != null && !status.trim().isEmpty()) {
                return invoiceRepository.findByCompanyIdAndStatusIgnoreCaseOrderByCreatedAtDesc(companyId, status.trim());
            } else if (clientId != null) {
                return invoiceRepository.findByCompanyIdAndClientIdOrderByCreatedAtDesc(companyId, clientId);
            } else {
                return invoiceRepository.findByCompanyIdOrderByCreatedAtDesc(companyId);
            }
        }

        if (status != null && !status.trim().isEmpty()) {
            return invoiceRepository.findByStatusIgnoreCaseOrderByCreatedAtDesc(status.trim());
        } else if (clientId != null) {
            return invoiceRepository.findByClientIdOrderByCreatedAtDesc(clientId);
        } else {
            return invoiceRepository.findAllByOrderByCreatedAtDesc();
        }
    }

    public List<Invoice> getInvoicesByStatus(String status) {
        return invoiceRepository.findByStatusIgnoreCaseOrderByCreatedAtDesc(status);
    }

    public List<Invoice> getInvoicesByClientId(Long clientId) {
        return invoiceRepository.findByClientIdOrderByCreatedAtDesc(clientId);
    }

    public Invoice getInvoiceById(Long id) {
        return invoiceRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Invoice", "id", id));
    }

    public Invoice getInvoiceById(Long id, Long companyId) {
        if (companyId != null) {
            return invoiceRepository.findByIdAndCompanyId(id, companyId)
                    .orElseThrow(() -> new ResourceNotFoundException("Invoice", "id", id));
        }
        return getInvoiceById(id);
    }

    public Invoice getInvoiceByNumber(String number) {
        return invoiceRepository.findByInvoiceNumber(number)
                .orElseThrow(() -> new ResourceNotFoundException("Invoice", "invoiceNumber", number));
    }

    public Invoice getInvoiceByNumber(String number, Long companyId) {
        if (companyId != null) {
            return invoiceRepository.findByInvoiceNumberAndCompanyId(number, companyId)
                    .orElseThrow(() -> new ResourceNotFoundException("Invoice", "invoiceNumber", number));
        }
        return getInvoiceByNumber(number);
    }

    @Transactional
    public Invoice createInvoice(Invoice invoice) {
        return createInvoice(invoice, invoice.getCompanyId());
    }

    @Transactional
    public Invoice createInvoice(Invoice invoice, Long companyId) {
        if (companyId != null && invoice.getCompanyId() == null) {
            invoice.setCompanyId(companyId);
        }
        if (invoice.getInvoiceNumber() == null || invoice.getInvoiceNumber().trim().isEmpty()) {
            invoice.setInvoiceNumber(generateNextInvoiceNumber(invoice.getCompanyId()));
        }
        if (invoice.getCreatedAt() == null) {
            invoice.setCreatedAt(System.currentTimeMillis());
        }
        return invoiceRepository.save(invoice);
    }

    @Transactional
    public Invoice updateInvoice(Long id, Invoice updated) {
        return updateInvoice(id, updated, updated.getCompanyId());
    }

    @Transactional
    public Invoice updateInvoice(Long id, Invoice updated, Long companyId) {
        Invoice existing = getInvoiceById(id, companyId);

        if (companyId != null) {
            existing.setCompanyId(companyId);
        } else if (updated.getCompanyId() != null) {
            existing.setCompanyId(updated.getCompanyId());
        }

        existing.setClientName(updated.getClientName());
        existing.setClientCompany(updated.getClientCompany());
        existing.setClientEmail(updated.getClientEmail());
        existing.setClientPhone(updated.getClientPhone());
        existing.setClientAddress(updated.getClientAddress());
        existing.setClientTaxId(updated.getClientTaxId());
        existing.setClientId(updated.getClientId());
        existing.setIssueDate(updated.getIssueDate());
        existing.setDueDate(updated.getDueDate());
        existing.setPoNumber(updated.getPoNumber());
        existing.setPaymentTerms(updated.getPaymentTerms());
        existing.setCurrencyCode(updated.getCurrencyCode());
        existing.setCurrencySymbol(updated.getCurrencySymbol());
        existing.setItemsJson(updated.getItemsJson());
        existing.setNotes(updated.getNotes());
        existing.setTerms(updated.getTerms());
        existing.setPaymentInstructions(updated.getPaymentInstructions());
        existing.setTaxRate(updated.getTaxRate());
        existing.setTaxLabel(updated.getTaxLabel());
        existing.setTaxType(updated.getTaxType());
        existing.setIsTaxInclusive(updated.getIsTaxInclusive());
        existing.setDiscountPercent(updated.getDiscountPercent());
        existing.setDiscountAmount(updated.getDiscountAmount());
        existing.setShippingFee(updated.getShippingFee());
        existing.setAdditionalCharges(updated.getAdditionalCharges());
        existing.setRoundOff(updated.getRoundOff());
        existing.setAmountPaid(updated.getAmountPaid());
        existing.setStatus(updated.getStatus());
        existing.setTemplateId(updated.getTemplateId());
        existing.setDocxTemplateTitle(updated.getDocxTemplateTitle());
        existing.setPaidDate(updated.getPaidDate());
        existing.setShippingDetailsJson(updated.getShippingDetailsJson());
        existing.setCustomFieldsJson(updated.getCustomFieldsJson());
        existing.setItemColumnsJson(updated.getItemColumnsJson());

        return invoiceRepository.save(existing);
    }

    @Transactional
    public Invoice updateStatus(Long id, String newStatus) {
        return updateStatus(id, newStatus, null);
    }

    @Transactional
    public Invoice updateStatus(Long id, String newStatus, Long companyId) {
        Invoice existing = getInvoiceById(id, companyId);
        existing.setStatus(newStatus);
        if ("Paid".equalsIgnoreCase(newStatus) && existing.getPaidDate() == null) {
            existing.setPaidDate(System.currentTimeMillis());
        }
        return invoiceRepository.save(existing);
    }

    @Transactional
    public void deleteInvoice(Long id) {
        deleteInvoice(id, null);
    }

    @Transactional
    public void deleteInvoice(Long id, Long companyId) {
        Invoice existing = getInvoiceById(id, companyId);
        invoiceRepository.delete(existing);
    }

    private String generateNextInvoiceNumber(Long companyId) {
        int currentYear = Year.now().getValue();
        long count = (companyId != null)
                ? invoiceRepository.countByCompanyId(companyId) + 1
                : invoiceRepository.count() + 1;
        return String.format("INV-%d-%04d", currentYear, count);
    }
}
