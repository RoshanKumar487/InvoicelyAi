package com.example.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "business_profile")
data class BusinessProfile(
    @PrimaryKey val id: Int = 1,
    // Business Identity
    val businessName: String = "Apex Nova Dynamics",
    val legalName: String = "Apex Nova Dynamics LLC",
    val email: String = "billing@apexnova.io",
    val phone: String = "+91 98201 54321",
    val website: String = "www.apexnova.io",
    val address: String = "Plot 42, Bandra-Kurla Complex (BKC)\nMumbai, Maharashtra 400051",
    val taxId: String = "27AABCU9603R1ZN",
    val brandColorHex: String = "#1E3A8A",

    // Indian Business & Zoho Invoicing specifics
    val gstin: String = "27AABCU9603R1ZN",
    val panNumber: String = "AABCU9603R",
    val placeOfSupply: String = "27-Maharashtra",
    val upiId: String = "apexnova@icici",
    val ifscCode: String = "HDFC0000240",
    val branchName: String = "BKC Branch, Mumbai",
    val showGstBreakdown: Boolean = true,
    val showAmountInWords: Boolean = true,

    // Custom Icon Builder Fields
    val customIconType: String = "symbol", // "symbol", "initials", "badge"
    val customIconSymbol: String = "receipt", // "receipt", "business", "store", "star", "diamond", "trending", "account_balance", "verified"
    val customIconShape: String = "rounded", // "rounded", "circle", "square"
    val customIconText: String = "AN",
    val customIconBgColorHex: String = "#1E3A8A",
    val customIconFgColorHex: String = "#FFFFFF",

    // Bank & Wire details
    val bankName: String = "HDFC Commercial Bank Ltd",
    val accountHolder: String = "Apex Nova Dynamics LLC",
    val accountNumber: String = "50200084920491",
    val routingNumber: String = "400240012",
    val swiftBic: String = "HDFCINBB",
    val paymentLink: String = "https://pay.apexnova.io/inv",

    // Currency Settings (configured in Settings only)
    val defaultCurrency: String = "INR",
    val defaultCurrencySymbol: String = "₹",
    val defaultCurrencyFormat: String = "before", // "before" (₹100) or "after" (100 ₹)

    // Default Template selection
    val defaultTemplateId: String = "gst_tax", // "gst_tax", "zoho_elegance", "vyapar_classic", "modern", "corporate", etc.

    // Configurable Item Column Headers (editable for all businesses, e.g., Salary vs Price, Hours vs Qty)
    val colHeaderItem: String = "Description / Service",
    val colHeaderQty: String = "Qty",
    val colHeaderUnit: String = "Unit",
    val colHeaderRate: String = "Rate",
    val colHeaderAmount: String = "Amount",
    val colHeaderTax: String = "Tax (%)",
    val colHeaderDiscount: String = "Disc (%)",

    // Invoice Field Visibility Customization (toggle on/off per business requirement)
    val showStatus: Boolean = true,
    val showIssueDate: Boolean = true,
    val showDueDate: Boolean = true,
    val showPoNumber: Boolean = false,
    val showPaymentTerms: Boolean = true,
    val showClientCompany: Boolean = true,
    val showClientEmail: Boolean = true,
    val showClientPhone: Boolean = true,
    val showClientAddress: Boolean = true,
    val showClientTaxId: Boolean = true,
    val showItemUnit: Boolean = true,
    val showItemQty: Boolean = true,
    val showItemRate: Boolean = true,
    val showItemDiscount: Boolean = true,
    val showItemTax: Boolean = true,
    val showShippingFee: Boolean = true,
    val showShippingSection: Boolean = false,
    val showNotesSection: Boolean = false,
    val showPaymentInstructions: Boolean = true,
    val showNotes: Boolean = true,
    val showTerms: Boolean = true,
    val showSignature: Boolean = true,

    // Tax & Invoicing defaults
    val isTaxApplicable: Boolean = true,
    val defaultTaxRate: Double = 18.0,
    val defaultTaxLabel: String = "GST (18%)",
    val defaultDiscountType: String = "percentage", // "percentage" or "flat"
    val defaultDiscountValue: Double = 0.0,
    val additionalChargeLabel: String = "Additional Charges",
    val defaultAdditionalCharge: Double = 0.0,
    val defaultPaymentTerms: String = "Net 30",
    val defaultNotes: String = "Thank you for partnering with Apex Nova! We appreciate your business.",
    val defaultTerms: String = "Payment is due according to the specified terms. Outstanding balances are subject to 1.5% interest per month.",
    val signeeName: String = "Jordan Vance",
    val signeeTitle: String = "Authorized Signatory",

    // Logo, Signature & Stamp in one section (Default on invoice, optional)
    val showLogo: Boolean = true,
    val showStamp: Boolean = true,
    val stampText: String = "APEX NOVA • OFFICIAL SEAL • VERIFIED",
    val stampShape: String = "circle", // "circle", "rectangle"
    val stampColorHex: String = "#1E3A8A",

    // Dynamic Custom Columns (user can add columns, change labels, change positions)
    val customColumnsJson: String = ""
)

data class ItemColumnDef(
    val id: String,
    val label: String,
    val key: String,
    val isVisible: Boolean = true,
    val order: Int = 0,
    val isCustom: Boolean = false,
    val widthWeight: Float = 1.0f,
    val dataType: String = "text",       // "text", "number", "currency", "percentage", "date", "dropdown", "checkbox", "image", "sku", "barcode", "hsn", "tax", "formula", "quantity", "unit", "duration", "serial_number", "batch_number"
    val isRequired: Boolean = false,
    val calculationType: String = "none",// "none", "multiply", "percentage", "formula", "total"
    val formula: String = "",            // e.g. "Quantity * Unit Price - Discount + Tax"
    val alignment: String = "start",     // "start", "center", "end"
    val dropdownOptions: String = ""     // Comma separated options for dropdown data type
)

data class ShippingDetails(
    val isEnabled: Boolean = false,
    val sameAsBilling: Boolean = false,
    val sectionTitle: String = "Shipping Details", // Customizable: "Shipping Details", "Delivery Details", "Dispatch Details", "Logistics Details"
    val shippingAddress: String = "",
    val deliveryAddress: String = "",
    val shippingMethod: String = "",
    val courier: String = "",
    val trackingNumber: String = "",
    val expectedDelivery: String = "",
    val warehouse: String = "",
    val deliveryContact: String = "",
    val vehicleNumber: String = "",
    val dispatchDate: String = ""
)

data class CustomClientField(
    val id: String = java.util.UUID.randomUUID().toString(),
    val label: String = "Custom Field",
    val value: String = "",
    val isRequired: Boolean = false
)

data class TemplateConfig(
    val templateId: String = "gst_tax",
    val templateName: String = "GST Tax Invoice (Indian Biz)",
    val docxTitle: String = "TAX INVOICE",
    val showLogo: Boolean = true,
    val showTaxBreakdown: Boolean = true,
    val showPaymentInstructions: Boolean = true,
    val showSignature: Boolean = true,
    val primaryColorHex: String = "#1E3A8A",
    val secondaryColorHex: String = "#0D9488",
    val fontStyle: String = "Calibri", // Calibri, Arial, Times New Roman, Consolas
    val colHeaderItem: String = "Description / Service",
    val colHeaderQty: String = "Qty",
    val colHeaderUnit: String = "Unit",
    val colHeaderRate: String = "Rate",
    val colHeaderAmount: String = "Amount",
    val customFooterNote: String = "This is a computer generated invoice and does not require physical signature unless specified.",
    val categoryBadge: String = "Indian Biz" // "Indian Biz", "Zoho Style", "Corporate", "Creative", etc.
)
