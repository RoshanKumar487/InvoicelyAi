package com.invoicely.backend.dto;

import com.invoicely.backend.model.Invoice;

public class AiInvoiceDraftResponse {

    private final String message;
    private final Invoice invoice;

    public AiInvoiceDraftResponse(String message, Invoice invoice) {
        this.message = message;
        this.invoice = invoice;
    }

    public String getMessage() { return message; }
    public Invoice getInvoice() { return invoice; }
}
