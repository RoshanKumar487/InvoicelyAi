package com.example.docx

import com.example.data.model.TemplateConfig

object DocxTemplatePreset {

    val gstTax = TemplateConfig(
        templateId = "gst_tax",
        templateName = "GST Standard Tax Invoice (Indian Biz)",
        docxTitle = "TAX INVOICE",
        showLogo = true,
        showTaxBreakdown = true,
        showPaymentInstructions = true,
        showSignature = true,
        primaryColorHex = "#1E3A8A",
        secondaryColorHex = "#0D9488",
        fontStyle = "Calibri",
        colHeaderItem = "Description of Goods / Services",
        colHeaderQty = "Qty",
        colHeaderUnit = "Unit",
        colHeaderRate = "Rate / Item",
        colHeaderAmount = "Taxable Amount",
        customFooterNote = "Goods once sold cannot be returned. Subject to Mumbai Jurisdiction.",
        categoryBadge = "Indian Biz"
    )

    val zohoElegance = TemplateConfig(
        templateId = "zoho_elegance",
        templateName = "Zoho Invoice Clean",
        docxTitle = "INVOICE",
        showLogo = true,
        showTaxBreakdown = true,
        showPaymentInstructions = true,
        showSignature = true,
        primaryColorHex = "#0284C7",
        secondaryColorHex = "#0369A1",
        fontStyle = "Arial",
        colHeaderItem = "Item & Description",
        colHeaderQty = "Quantity",
        colHeaderUnit = "UOM",
        colHeaderRate = "Price",
        colHeaderAmount = "Amount",
        customFooterNote = "Thank you for your business. Fast payment via UPI / Netbanking accepted.",
        categoryBadge = "Zoho Style"
    )

    val vyaparClassic = TemplateConfig(
        templateId = "vyapar_classic",
        templateName = "Vyapar / Tally Boxed",
        docxTitle = "TAX INVOICE / BILL OF SUPPLY",
        showLogo = true,
        showTaxBreakdown = true,
        showPaymentInstructions = true,
        showSignature = true,
        primaryColorHex = "#0F766E",
        secondaryColorHex = "#134E4A",
        fontStyle = "Times New Roman",
        colHeaderItem = "Particulars / Item Name",
        colHeaderQty = "Qty / Units",
        colHeaderUnit = "Unit",
        colHeaderRate = "Rate (₹)",
        colHeaderAmount = "Total (₹)",
        customFooterNote = "Certified that the particulars given above are true and correct. Subject to local jurisdiction.",
        categoryBadge = "Indian Biz"
    )

    val modern = TemplateConfig(
        templateId = "modern",
        templateName = "Modern Minimalist",
        docxTitle = "INVOICE",
        showLogo = true,
        showTaxBreakdown = true,
        showPaymentInstructions = true,
        showSignature = true,
        primaryColorHex = "#2563EB",
        secondaryColorHex = "#3B82F6",
        fontStyle = "Calibri",
        colHeaderItem = "Description / Service",
        colHeaderQty = "Qty",
        colHeaderUnit = "Unit",
        colHeaderRate = "Rate",
        colHeaderAmount = "Amount",
        customFooterNote = "Thank you for your business!",
        categoryBadge = "Modern"
    )

    val corporate = TemplateConfig(
        templateId = "corporate",
        templateName = "Corporate Executive",
        docxTitle = "COMMERCIAL INVOICE",
        showLogo = true,
        showTaxBreakdown = true,
        showPaymentInstructions = true,
        showSignature = true,
        primaryColorHex = "#0F172A",
        secondaryColorHex = "#334155",
        fontStyle = "Arial",
        colHeaderItem = "Item & Scope of Work",
        colHeaderQty = "Quantity",
        colHeaderUnit = "Unit",
        colHeaderRate = "Unit Price",
        colHeaderAmount = "Line Total",
        customFooterNote = "Authorized commercial billing document. All rights reserved.",
        categoryBadge = "Corporate"
    )

    val creative = TemplateConfig(
        templateId = "creative",
        templateName = "Creative Studio & Agency",
        docxTitle = "CREATIVE INVOICE",
        showLogo = true,
        showTaxBreakdown = true,
        showPaymentInstructions = true,
        showSignature = true,
        primaryColorHex = "#4F46E5",
        secondaryColorHex = "#EC4899",
        fontStyle = "Calibri",
        colHeaderItem = "Project Deliverable",
        colHeaderQty = "Hrs / Units",
        colHeaderUnit = "Hrs",
        colHeaderRate = "Price",
        colHeaderAmount = "Total",
        customFooterNote = "Crafted with care. Looking forward to our next collaboration!",
        categoryBadge = "Creative"
    )

    val itConsulting = TemplateConfig(
        templateId = "it_consulting",
        templateName = "IT & Tech Consulting",
        docxTitle = "SERVICES & SPRINT INVOICE",
        showLogo = true,
        showTaxBreakdown = true,
        showPaymentInstructions = true,
        showSignature = true,
        primaryColorHex = "#0891B2",
        secondaryColorHex = "#155E75",
        fontStyle = "Consolas",
        colHeaderItem = "Sprint / Task Description",
        colHeaderQty = "Hours",
        colHeaderUnit = "Hrs",
        colHeaderRate = "Hourly Rate",
        colHeaderAmount = "Net Total",
        customFooterNote = "Sprint deliverables & milestone signoff approved. Net 30 payment.",
        categoryBadge = "Services"
    )

    val retailWholesale = TemplateConfig(
        templateId = "retail_wholesale",
        templateName = "Retail & Wholesale Traders",
        docxTitle = "RETAIL INVOICE",
        showLogo = false,
        showTaxBreakdown = true,
        showPaymentInstructions = true,
        showSignature = true,
        primaryColorHex = "#DC2626",
        secondaryColorHex = "#991B1B",
        fontStyle = "Arial",
        colHeaderItem = "Item / SKU Details",
        colHeaderQty = "Qty",
        colHeaderUnit = "Pcs",
        colHeaderRate = "MRP / Price",
        colHeaderAmount = "Net Amount",
        customFooterNote = "E. & O.E. All disputes subject to local jurisdiction.",
        categoryBadge = "Indian Biz"
    )

    val luxuryEnterprise = TemplateConfig(
        templateId = "luxury_enterprise",
        templateName = "Luxury Enterprise & Legal",
        docxTitle = "STATEMENT OF ACCOUNT",
        showLogo = true,
        showTaxBreakdown = true,
        showPaymentInstructions = true,
        showSignature = true,
        primaryColorHex = "#78350F",
        secondaryColorHex = "#D97706",
        fontStyle = "Times New Roman",
        colHeaderItem = "Matter / Professional Service",
        colHeaderQty = "Units",
        colHeaderUnit = "Unit",
        colHeaderRate = "Fee Rate",
        colHeaderAmount = "Total Fee",
        customFooterNote = "Confidential billing statement. Retain for financial records.",
        categoryBadge = "Executive"
    )

    val healthcareProf = TemplateConfig(
        templateId = "healthcare_prof",
        templateName = "Healthcare & Professional",
        docxTitle = "PROFESSIONAL FEE BILL",
        showLogo = true,
        showTaxBreakdown = true,
        showPaymentInstructions = true,
        showSignature = true,
        primaryColorHex = "#059669",
        secondaryColorHex = "#047857",
        fontStyle = "Calibri",
        colHeaderItem = "Service / Consultation / Procedure",
        colHeaderQty = "Sessions",
        colHeaderUnit = "Sess",
        colHeaderRate = "Charges",
        colHeaderAmount = "Total Due",
        customFooterNote = "Professional consultation fees & medical services invoice.",
        categoryBadge = "Professional"
    )

    val minimalist = TemplateConfig(
        templateId = "minimalist",
        templateName = "Clean Minimalist Letterhead",
        docxTitle = "INVOICE",
        showLogo = true,
        showTaxBreakdown = true,
        showPaymentInstructions = true,
        showSignature = true,
        primaryColorHex = "#1E293B",
        secondaryColorHex = "#475569",
        fontStyle = "Calibri",
        colHeaderItem = "Description / Service",
        colHeaderQty = "Qty",
        colHeaderUnit = "Unit",
        colHeaderRate = "Rate",
        colHeaderAmount = "Amount",
        customFooterNote = "Thank you for your business! Please remit payment according to agreed terms.",
        categoryBadge = "Minimalist"
    )

    val classicLetterhead = TemplateConfig(
        templateId = "classic_letterhead",
        templateName = "Classic Formal Business Letterhead",
        docxTitle = "TAX INVOICE & STATEMENT OF ACCOUNT",
        showLogo = true,
        showTaxBreakdown = true,
        showPaymentInstructions = true,
        showSignature = true,
        primaryColorHex = "#0F172A",
        secondaryColorHex = "#334155",
        fontStyle = "Times New Roman",
        colHeaderItem = "Particulars / Service Scope",
        colHeaderQty = "Hours / Qty",
        colHeaderUnit = "Unit",
        colHeaderRate = "Rate",
        colHeaderAmount = "Line Total",
        customFooterNote = "Certified that this invoice represents genuine commercial services rendered.",
        categoryBadge = "Formal"
    )

    val techClean = TemplateConfig(
        templateId = "tech_clean",
        templateName = "Tech & SaaS Modern Strip Letterhead",
        docxTitle = "SERVICES & DELIVERABLES INVOICE",
        showLogo = true,
        showTaxBreakdown = true,
        showPaymentInstructions = true,
        showSignature = true,
        primaryColorHex = "#2563EB",
        secondaryColorHex = "#1D4ED8",
        fontStyle = "Consolas",
        colHeaderItem = "Sprint / Architecture Deliverable",
        colHeaderQty = "Hours",
        colHeaderUnit = "Hrs",
        colHeaderRate = "Rate / Hr",
        colHeaderAmount = "Total",
        customFooterNote = "Milestone deliverables signed off. Digital payment via Wire / Netbanking.",
        categoryBadge = "Technology"
    )

    val compactLedger = TemplateConfig(
        templateId = "compact_ledger",
        templateName = "Compact Ledger / Retail Bill",
        docxTitle = "RETAIL INVOICE",
        showLogo = false,
        showTaxBreakdown = true,
        showPaymentInstructions = true,
        showSignature = true,
        primaryColorHex = "#0F172A",
        secondaryColorHex = "#334155",
        fontStyle = "Arial",
        colHeaderItem = "Item / Barcode",
        colHeaderQty = "Qty",
        colHeaderUnit = "Unit",
        colHeaderRate = "Rate",
        colHeaderAmount = "Net Total",
        customFooterNote = "Items received in good condition. Keep invoice for claims.",
        categoryBadge = "Retail"
    )

    val ecommerce = TemplateConfig(
        templateId = "ecommerce",
        templateName = "E-Commerce Dispatch Letterhead",
        docxTitle = "ORDER TAX INVOICE",
        showLogo = true,
        showTaxBreakdown = true,
        showPaymentInstructions = true,
        showSignature = true,
        primaryColorHex = "#1E3A8A",
        secondaryColorHex = "#2563EB",
        fontStyle = "Calibri",
        colHeaderItem = "Product Details",
        colHeaderQty = "Qty",
        colHeaderUnit = "Pcs",
        colHeaderRate = "Unit Price",
        colHeaderAmount = "Total",
        customFooterNote = "Thank you for shopping with us! Tracking link sent upon dispatch.",
        categoryBadge = "E-Commerce"
    )

    val healthcare = TemplateConfig(
        templateId = "healthcare",
        templateName = "Healthcare & Clinic Letterhead",
        docxTitle = "MEDICAL CONSULTATION & FEE BILL",
        showLogo = true,
        showTaxBreakdown = true,
        showPaymentInstructions = true,
        showSignature = true,
        primaryColorHex = "#0D9488",
        secondaryColorHex = "#0F766E",
        fontStyle = "Calibri",
        colHeaderItem = "Procedure / Consultation",
        colHeaderQty = "Sessions",
        colHeaderUnit = "Sess",
        colHeaderRate = "Fee Rate",
        colHeaderAmount = "Patient Due",
        customFooterNote = "Medical invoice provided for patient records and insurance claims.",
        categoryBadge = "Healthcare"
    )

    val allTemplates = listOf(
        minimalist,
        classicLetterhead,
        techClean,
        compactLedger,
        ecommerce,
        healthcare,
        corporate,
        gstTax,
        zohoElegance,
        vyaparClassic,
        modern,
        creative,
        itConsulting,
        retailWholesale,
        luxuryEnterprise,
        healthcareProf
    )

    fun getById(id: String): TemplateConfig {
        return allTemplates.find { it.templateId.equals(id, ignoreCase = true) }
            ?: when (id.lowercase()) {
                "general", "modern" -> minimalist
                "consulting", "education" -> classicLetterhead
                "it_software", "it" -> techClean
                "retail", "restaurant" -> compactLedger
                "ecommerce", "e-commerce" -> ecommerce
                "healthcare", "medical" -> healthcare
                "manufacturing", "logistics", "construction" -> corporate
                else -> minimalist
            }
    }
}
