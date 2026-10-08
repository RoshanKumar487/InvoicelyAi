package com.invoicely.backend.dto;

import java.math.BigDecimal;

public class ReceiptScanResponse {

    private final String vendor;
    private final String title;
    private final BigDecimal amount;
    private final BigDecimal taxAmount;
    private final String category;
    private final String paymentMethod;
    private final String date;
    private final String currency;
    private final String notes;

    public ReceiptScanResponse(String vendor, String title, BigDecimal amount, BigDecimal taxAmount,
                               String category, String paymentMethod, String date,
                               String currency, String notes) {
        this.vendor = vendor;
        this.title = title;
        this.amount = amount;
        this.taxAmount = taxAmount;
        this.category = category;
        this.paymentMethod = paymentMethod;
        this.date = date;
        this.currency = currency;
        this.notes = notes;
    }

    public String getVendor() { return vendor; }
    public String getTitle() { return title; }
    public BigDecimal getAmount() { return amount; }
    public BigDecimal getTaxAmount() { return taxAmount; }
    public String getCategory() { return category; }
    public String getPaymentMethod() { return paymentMethod; }
    public String getDate() { return date; }
    public String getCurrency() { return currency; }
    public String getNotes() { return notes; }
}
