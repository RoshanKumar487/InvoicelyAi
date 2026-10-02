package com.example.data.model

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountBalance
import androidx.compose.material.icons.filled.Build
import androidx.compose.material.icons.filled.Business
import androidx.compose.material.icons.filled.Code
import androidx.compose.material.icons.filled.LocalHospital
import androidx.compose.material.icons.filled.LocalShipping
import androidx.compose.material.icons.filled.Restaurant
import androidx.compose.material.icons.filled.School
import androidx.compose.material.icons.filled.ShoppingBag
import androidx.compose.material.icons.filled.ShoppingCart
import androidx.compose.material.icons.filled.Tune
import androidx.compose.material.icons.filled.Work
import androidx.compose.ui.graphics.vector.ImageVector

data class IndustryTemplatePreset(
    val id: String,
    val name: String,
    val industryCategory: String,
    val description: String,
    val icon: ImageVector,
    val defaultColumns: List<ItemColumnDef>,
    val defaultNotes: String = "",
    val defaultTerms: String = "",
    val recommendedSectionTitle: String = "Shipping Details",
    val recommendedTemplateId: String = "minimalist",
    val sampleItem: InvoiceItem? = null
)

object IndustryTemplates {

    val allPresets: List<IndustryTemplatePreset> = listOf(
        IndustryTemplatePreset(
            id = "general",
            name = "General Business",
            industryCategory = "Standard",
            description = "Description, HSN/SAC, Quantity, Unit, Rate, Discount, Tax, Amount",
            icon = Icons.Default.Business,
            recommendedTemplateId = "minimalist",
            sampleItem = InvoiceItem(
                description = "Professional Commercial Services & Consulting",
                quantity = 1.0,
                unitPrice = 500.0,
                unit = "unit"
            ),
            defaultColumns = listOf(
                ItemColumnDef(id = "col_desc", label = "Description / Service", key = "description", dataType = "text", isVisible = true, order = 0, widthWeight = 2.2f, isRequired = true),
                ItemColumnDef(id = "col_hsn", label = "HSN/SAC", key = "hsn", dataType = "hsn", isVisible = true, order = 1, widthWeight = 0.9f),
                ItemColumnDef(id = "col_qty", label = "Qty", key = "quantity", dataType = "quantity", isVisible = true, order = 2, widthWeight = 0.7f),
                ItemColumnDef(id = "col_unit", label = "Unit", key = "unit", dataType = "unit", isVisible = true, order = 3, widthWeight = 0.7f),
                ItemColumnDef(id = "col_rate", label = "Rate", key = "unitPrice", dataType = "currency", isVisible = true, order = 4, widthWeight = 1.1f),
                ItemColumnDef(id = "col_discount", label = "Disc (%)", key = "discountRate", dataType = "percentage", isVisible = true, order = 5, widthWeight = 0.8f),
                ItemColumnDef(id = "col_tax", label = "Tax (%)", key = "taxRate", dataType = "tax", isVisible = false, order = 6, widthWeight = 0.8f),
                ItemColumnDef(id = "col_total", label = "Amount", key = "total", dataType = "formula", isVisible = true, order = 7, widthWeight = 1.3f, calculationType = "formula", formula = "Quantity * Rate - Discount")
            ),
            defaultNotes = "Thank you for your business! Please remit payment according to agreed terms.",
            defaultTerms = "Payment due within 30 days of invoice date.",
            recommendedSectionTitle = "Shipping Details"
        ),

        IndustryTemplatePreset(
            id = "ecommerce",
            name = "E-Commerce",
            industryCategory = "Retail & Online",
            description = "Product, SKU, Variant, Qty, Unit Price, Discount, Tax, Total",
            icon = Icons.Default.ShoppingCart,
            recommendedTemplateId = "ecommerce",
            sampleItem = InvoiceItem(
                description = "Wireless Active Noise-Canceling Over-Ear Headphones",
                quantity = 2.0,
                unitPrice = 79.99,
                unit = "pcs",
                customFields = mapOf("sku" to "ANC-900-BLK", "variant" to "Matte Black")
            ),
            defaultColumns = listOf(
                ItemColumnDef(id = "col_product", label = "Product", key = "description", dataType = "text", isVisible = true, order = 0, widthWeight = 2.0f, isRequired = true),
                ItemColumnDef(id = "col_sku", label = "SKU", key = "sku", dataType = "sku", isVisible = true, order = 1, widthWeight = 1.0f),
                ItemColumnDef(id = "col_variant", label = "Variant / Size", key = "variant", dataType = "text", isVisible = true, order = 2, widthWeight = 1.0f),
                ItemColumnDef(id = "col_qty", label = "Qty", key = "quantity", dataType = "quantity", isVisible = true, order = 3, widthWeight = 0.7f),
                ItemColumnDef(id = "col_unit_price", label = "Unit Price", key = "unitPrice", dataType = "currency", isVisible = true, order = 4, widthWeight = 1.1f),
                ItemColumnDef(id = "col_discount", label = "Discount", key = "discountRate", dataType = "percentage", isVisible = true, order = 5, widthWeight = 0.8f),
                ItemColumnDef(id = "col_tax", label = "Tax", key = "taxRate", dataType = "tax", isVisible = true, order = 6, widthWeight = 0.8f),
                ItemColumnDef(id = "col_total", label = "Total", key = "total", dataType = "formula", isVisible = true, order = 7, widthWeight = 1.2f, calculationType = "formula", formula = "Quantity * Unit Price - Discount + Tax")
            ),
            defaultNotes = "Thank you for shopping with us! Tracking link will be sent upon dispatch.",
            defaultTerms = "Returns accepted within 14 days in original unopened packaging.",
            recommendedSectionTitle = "Delivery & Tracking"
        ),

        IndustryTemplatePreset(
            id = "retail",
            name = "Retail & POS",
            industryCategory = "Store & Commerce",
            description = "Product, Barcode, Qty, Unit, Rate, Discount, Tax, Total",
            icon = Icons.Default.ShoppingBag,
            recommendedTemplateId = "compact_ledger",
            sampleItem = InvoiceItem(
                description = "Artisan Roasted Single-Origin Coffee Beans (1kg)",
                quantity = 3.0,
                unitPrice = 18.50,
                unit = "pack",
                customFields = mapOf("barcode" to "8901234567890")
            ),
            defaultColumns = listOf(
                ItemColumnDef(id = "col_product", label = "Product", key = "description", dataType = "text", isVisible = true, order = 0, widthWeight = 2.0f, isRequired = true),
                ItemColumnDef(id = "col_barcode", label = "Barcode", key = "barcode", dataType = "barcode", isVisible = true, order = 1, widthWeight = 1.0f),
                ItemColumnDef(id = "col_qty", label = "Qty", key = "quantity", dataType = "quantity", isVisible = true, order = 2, widthWeight = 0.7f),
                ItemColumnDef(id = "col_unit", label = "Unit", key = "unit", dataType = "unit", isVisible = true, order = 3, widthWeight = 0.7f),
                ItemColumnDef(id = "col_rate", label = "Rate", key = "unitPrice", dataType = "currency", isVisible = true, order = 4, widthWeight = 1.1f),
                ItemColumnDef(id = "col_discount", label = "Discount", key = "discountRate", dataType = "percentage", isVisible = true, order = 5, widthWeight = 0.8f),
                ItemColumnDef(id = "col_tax", label = "Tax", key = "taxRate", dataType = "tax", isVisible = true, order = 6, widthWeight = 0.8f),
                ItemColumnDef(id = "col_total", label = "Total", key = "total", dataType = "formula", isVisible = true, order = 7, widthWeight = 1.2f, calculationType = "formula", formula = "Quantity * Rate - Discount")
            ),
            defaultNotes = "Items received in good condition. Thank you for your visit!",
            defaultTerms = "Please retain this invoice for exchange or warranty claims.",
            recommendedSectionTitle = "Delivery Details"
        ),

        IndustryTemplatePreset(
            id = "manufacturing",
            name = "Manufacturing",
            industryCategory = "Industrial",
            description = "Material, Batch No., Quantity, Unit, Rate, Tax, Total",
            icon = Icons.Default.Build,
            recommendedTemplateId = "corporate",
            sampleItem = InvoiceItem(
                description = "High-Tensile Precision Machined Fasteners (Grade 8)",
                quantity = 400.0,
                unitPrice = 6.25,
                unit = "pcs",
                customFields = mapOf("batch_no" to "LOT-2026-MFG-44B")
            ),
            defaultColumns = listOf(
                ItemColumnDef(id = "col_material", label = "Material / Part", key = "description", dataType = "text", isVisible = true, order = 0, widthWeight = 2.0f, isRequired = true),
                ItemColumnDef(id = "col_batch", label = "Batch No.", key = "batch_no", dataType = "batch_number", isVisible = true, order = 1, widthWeight = 1.0f),
                ItemColumnDef(id = "col_qty", label = "Quantity", key = "quantity", dataType = "quantity", isVisible = true, order = 2, widthWeight = 0.8f),
                ItemColumnDef(id = "col_unit", label = "Unit", key = "unit", dataType = "unit", isVisible = true, order = 3, widthWeight = 0.7f),
                ItemColumnDef(id = "col_rate", label = "Rate", key = "unitPrice", dataType = "currency", isVisible = true, order = 4, widthWeight = 1.1f),
                ItemColumnDef(id = "col_tax", label = "Tax", key = "taxRate", dataType = "tax", isVisible = true, order = 5, widthWeight = 0.8f),
                ItemColumnDef(id = "col_total", label = "Total", key = "total", dataType = "formula", isVisible = true, order = 6, widthWeight = 1.2f, calculationType = "formula", formula = "Quantity * Rate")
            ),
            defaultNotes = "Certificate of Analysis (COA) attached with batch consignment.",
            defaultTerms = "Goods manufactured per approved specs. Inspection within 7 days.",
            recommendedSectionTitle = "Dispatch & Logistics"
        ),

        IndustryTemplatePreset(
            id = "it_software",
            name = "IT & Software Services",
            industryCategory = "Technology",
            description = "Service, Project, Hours, Rate/Hour, Discount, Tax, Total",
            icon = Icons.Default.Code,
            recommendedTemplateId = "tech_clean",
            sampleItem = InvoiceItem(
                description = "Cloud Architecture & Microservices API Modernization",
                quantity = 40.0,
                unitPrice = 125.0,
                unit = "hrs",
                customFields = mapOf("project" to "Sprint 14 - Platform API")
            ),
            defaultColumns = listOf(
                ItemColumnDef(id = "col_service", label = "Service", key = "description", dataType = "text", isVisible = true, order = 0, widthWeight = 2.0f, isRequired = true),
                ItemColumnDef(id = "col_project", label = "Project", key = "project", dataType = "text", isVisible = true, order = 1, widthWeight = 1.1f),
                ItemColumnDef(id = "col_hours", label = "Hours", key = "quantity", dataType = "duration", isVisible = true, order = 2, widthWeight = 0.8f),
                ItemColumnDef(id = "col_hourly_rate", label = "Rate / Hr", key = "unitPrice", dataType = "currency", isVisible = true, order = 3, widthWeight = 1.1f),
                ItemColumnDef(id = "col_discount", label = "Discount", key = "discountRate", dataType = "percentage", isVisible = true, order = 4, widthWeight = 0.8f),
                ItemColumnDef(id = "col_tax", label = "Tax", key = "taxRate", dataType = "tax", isVisible = true, order = 5, widthWeight = 0.8f),
                ItemColumnDef(id = "col_total", label = "Total", key = "total", dataType = "formula", isVisible = true, order = 6, widthWeight = 1.2f, calculationType = "formula", formula = "Hours * Rate/Hour - Discount")
            ),
            defaultNotes = "Timesheets and sprint deliverables signed off by client lead.",
            defaultTerms = "Source code and IP transfer upon receipt of full payment.",
            recommendedSectionTitle = "Digital Delivery"
        ),

        IndustryTemplatePreset(
            id = "consulting",
            name = "Consulting",
            industryCategory = "Professional Services",
            description = "Consultant, Service, Hours, Rate, Expense, Tax, Total",
            icon = Icons.Default.Work,
            recommendedTemplateId = "classic_letterhead",
            sampleItem = InvoiceItem(
                description = "Strategic Market Expansion & Operating Model Review",
                quantity = 25.0,
                unitPrice = 180.0,
                unit = "hrs",
                customFields = mapOf("consultant" to "Managing Director", "expense" to "0.0")
            ),
            defaultColumns = listOf(
                ItemColumnDef(id = "col_consultant", label = "Consultant", key = "consultant", dataType = "text", isVisible = true, order = 0, widthWeight = 1.2f),
                ItemColumnDef(id = "col_service", label = "Service Scope", key = "description", dataType = "text", isVisible = true, order = 1, widthWeight = 1.8f, isRequired = true),
                ItemColumnDef(id = "col_hours", label = "Hours", key = "quantity", dataType = "duration", isVisible = true, order = 2, widthWeight = 0.8f),
                ItemColumnDef(id = "col_rate", label = "Rate", key = "unitPrice", dataType = "currency", isVisible = true, order = 3, widthWeight = 1.1f),
                ItemColumnDef(id = "col_expense", label = "Reimbursable Exp", key = "expense", dataType = "currency", isVisible = true, order = 4, widthWeight = 1.0f),
                ItemColumnDef(id = "col_tax", label = "Tax", key = "taxRate", dataType = "tax", isVisible = true, order = 5, widthWeight = 0.8f),
                ItemColumnDef(id = "col_total", label = "Total", key = "total", dataType = "formula", isVisible = true, order = 6, widthWeight = 1.2f, calculationType = "formula", formula = "Hours * Rate + Expense")
            ),
            defaultNotes = "Monthly advisory & strategic consulting retainer.",
            defaultTerms = "Confidentiality and non-disclosure obligations apply to all work.",
            recommendedSectionTitle = "Delivery Details"
        ),

        IndustryTemplatePreset(
            id = "healthcare",
            name = "Healthcare & Clinic",
            industryCategory = "Medical",
            description = "Service, Doctor, Appointment, Qty, Rate, Insurance, Tax, Total",
            icon = Icons.Default.LocalHospital,
            recommendedTemplateId = "healthcare",
            sampleItem = InvoiceItem(
                description = "Comprehensive Diagnostic Consultation & Pathology Panel",
                quantity = 1.0,
                unitPrice = 280.0,
                unit = "sess",
                customFields = mapOf("doctor" to "Dr. Robert Vance, MD", "appointment_date" to "2026-10-02", "insurance" to "50.0")
            ),
            defaultColumns = listOf(
                ItemColumnDef(id = "col_service", label = "Service / Procedure", key = "description", dataType = "text", isVisible = true, order = 0, widthWeight = 2.0f, isRequired = true),
                ItemColumnDef(id = "col_doctor", label = "Attending Doctor", key = "doctor", dataType = "text", isVisible = true, order = 1, widthWeight = 1.2f),
                ItemColumnDef(id = "col_appointment", label = "Appointment Date", key = "appointment_date", dataType = "date", isVisible = true, order = 2, widthWeight = 1.0f),
                ItemColumnDef(id = "col_qty", label = "Qty / Sessions", key = "quantity", dataType = "quantity", isVisible = true, order = 3, widthWeight = 0.8f),
                ItemColumnDef(id = "col_rate", label = "Rate", key = "unitPrice", dataType = "currency", isVisible = true, order = 4, widthWeight = 1.1f),
                ItemColumnDef(id = "col_insurance", label = "Insurance Copay", key = "insurance", dataType = "currency", isVisible = true, order = 5, widthWeight = 1.0f),
                ItemColumnDef(id = "col_tax", label = "Tax", key = "taxRate", dataType = "tax", isVisible = false, order = 6, widthWeight = 0.8f),
                ItemColumnDef(id = "col_total", label = "Patient Due", key = "total", dataType = "formula", isVisible = true, order = 7, widthWeight = 1.2f, calculationType = "formula", formula = "Qty * Rate - Insurance")
            ),
            defaultNotes = "Medical claim forms attached for third-party insurance reimbursement.",
            defaultTerms = "Payment due on date of consultation / treatment.",
            recommendedSectionTitle = "Dispatch Details"
        ),

        IndustryTemplatePreset(
            id = "logistics",
            name = "Logistics & Freight",
            industryCategory = "Transportation",
            description = "Shipment, Origin, Destination, Weight, Distance, Rate, Charges, Total",
            icon = Icons.Default.LocalShipping,
            recommendedTemplateId = "corporate",
            sampleItem = InvoiceItem(
                description = "Express Air Freight Consignment (Priority Hub Dispatch)",
                quantity = 50.0,
                unitPrice = 11.50,
                unit = "kg",
                customFields = mapOf("origin" to "Chicago ORD", "destination" to "New York JFK", "charges" to "45.0")
            ),
            defaultColumns = listOf(
                ItemColumnDef(id = "col_shipment", label = "Shipment / Waybill", key = "description", dataType = "text", isVisible = true, order = 0, widthWeight = 1.6f, isRequired = true),
                ItemColumnDef(id = "col_origin", label = "Origin", key = "origin", dataType = "text", isVisible = true, order = 1, widthWeight = 1.0f),
                ItemColumnDef(id = "col_destination", label = "Destination", key = "destination", dataType = "text", isVisible = true, order = 2, widthWeight = 1.0f),
                ItemColumnDef(id = "col_weight", label = "Weight (kg)", key = "quantity", dataType = "number", isVisible = true, order = 3, widthWeight = 0.8f),
                ItemColumnDef(id = "col_rate", label = "Rate / kg", key = "unitPrice", dataType = "currency", isVisible = true, order = 4, widthWeight = 1.0f),
                ItemColumnDef(id = "col_charges", label = "Handling Fee", key = "charges", dataType = "currency", isVisible = true, order = 5, widthWeight = 0.9f),
                ItemColumnDef(id = "col_total", label = "Total", key = "total", dataType = "formula", isVisible = true, order = 6, widthWeight = 1.2f, calculationType = "formula", formula = "Weight * Rate + Charges")
            ),
            defaultNotes = "Cargo inspected and released per consignment note.",
            defaultTerms = "Carrier liability limited to terms specified on the Air Waybill / Lorry Receipt.",
            recommendedSectionTitle = "Logistics & Fleet Details"
        ),

        IndustryTemplatePreset(
            id = "restaurant",
            name = "Restaurant & Catering",
            industryCategory = "Food & Hospitality",
            description = "Item, Category, Qty, Unit Price, Discount, Tax, Total",
            icon = Icons.Default.Restaurant,
            recommendedTemplateId = "compact_ledger",
            sampleItem = InvoiceItem(
                description = "Chef's 5-Course Tasting Menu & Pairing Experience",
                quantity = 8.0,
                unitPrice = 85.00,
                unit = "cover",
                customFields = mapOf("category" to "Dining / Private Room")
            ),
            defaultColumns = listOf(
                ItemColumnDef(id = "col_item", label = "Menu Item", key = "description", dataType = "text", isVisible = true, order = 0, widthWeight = 2.0f, isRequired = true),
                ItemColumnDef(id = "col_category", label = "Category", key = "category", dataType = "text", isVisible = true, order = 1, widthWeight = 1.1f),
                ItemColumnDef(id = "col_qty", label = "Qty / Plates", key = "quantity", dataType = "quantity", isVisible = true, order = 2, widthWeight = 0.8f),
                ItemColumnDef(id = "col_unit_price", label = "Price", key = "unitPrice", dataType = "currency", isVisible = true, order = 3, widthWeight = 1.1f),
                ItemColumnDef(id = "col_discount", label = "Discount", key = "discountRate", dataType = "percentage", isVisible = true, order = 4, widthWeight = 0.8f),
                ItemColumnDef(id = "col_tax", label = "GST (5%)", key = "taxRate", dataType = "tax", isVisible = true, order = 5, widthWeight = 0.8f),
                ItemColumnDef(id = "col_total", label = "Total", key = "total", dataType = "formula", isVisible = true, order = 6, widthWeight = 1.2f, calculationType = "formula", formula = "Qty * Price - Discount")
            ),
            defaultNotes = "Thank you for dining with us! We look forward to serving you again.",
            defaultTerms = "All prices include service and standard culinary preparation.",
            recommendedSectionTitle = "Delivery / Table Details"
        ),

        IndustryTemplatePreset(
            id = "education",
            name = "Education & Courses",
            industryCategory = "Academic & Training",
            description = "Course, Student, Duration, Qty, Fee, Discount, Tax, Total",
            icon = Icons.Default.School,
            recommendedTemplateId = "classic_letterhead",
            sampleItem = InvoiceItem(
                description = "Full Stack Cloud Application Development Cohort",
                quantity = 1.0,
                unitPrice = 1450.0,
                unit = "enrollment",
                customFields = mapOf("student" to "Alex Rivera", "duration" to "12 Weeks")
            ),
            defaultColumns = listOf(
                ItemColumnDef(id = "col_course", label = "Course / Program", key = "description", dataType = "text", isVisible = true, order = 0, widthWeight = 2.0f, isRequired = true),
                ItemColumnDef(id = "col_student", label = "Student Name", key = "student", dataType = "text", isVisible = true, order = 1, widthWeight = 1.2f),
                ItemColumnDef(id = "col_duration", label = "Duration", key = "duration", dataType = "duration", isVisible = true, order = 2, widthWeight = 0.9f),
                ItemColumnDef(id = "col_qty", label = "Enrollments", key = "quantity", dataType = "quantity", isVisible = true, order = 3, widthWeight = 0.8f),
                ItemColumnDef(id = "col_fee", label = "Tuition Fee", key = "unitPrice", dataType = "currency", isVisible = true, order = 4, widthWeight = 1.1f),
                ItemColumnDef(id = "col_discount", label = "Scholarship", key = "discountRate", dataType = "percentage", isVisible = true, order = 5, widthWeight = 0.9f),
                ItemColumnDef(id = "col_tax", label = "Tax", key = "taxRate", dataType = "tax", isVisible = false, order = 6, widthWeight = 0.8f),
                ItemColumnDef(id = "col_total", label = "Total Due", key = "total", dataType = "formula", isVisible = true, order = 7, widthWeight = 1.2f, calculationType = "formula", formula = "Enrollments * Fee - Scholarship")
            ),
            defaultNotes = "Welcome to the cohort! Course portal login credentials sent via email.",
            defaultTerms = "Tuition fees are non-refundable once the course start date commences.",
            recommendedSectionTitle = "Dispatch Details"
        ),

        IndustryTemplatePreset(
            id = "construction",
            name = "Construction & Contracting",
            industryCategory = "Engineering",
            description = "Scope / Work Item, Labor/Material, Units, Unit Cost, Retainage %, Tax, Total",
            icon = Icons.Default.AccountBalance,
            recommendedTemplateId = "corporate",
            sampleItem = InvoiceItem(
                description = "Commercial Steel Framing & Gypsum Wallboard Installation",
                quantity = 650.0,
                unitPrice = 5.50,
                unit = "sqft",
                customFields = mapOf("item_type" to "Labor & Material")
            ),
            defaultColumns = listOf(
                ItemColumnDef(id = "col_scope", label = "Scope of Work", key = "description", dataType = "text", isVisible = true, order = 0, widthWeight = 2.0f, isRequired = true),
                ItemColumnDef(id = "col_type", label = "Labor / Material", key = "item_type", dataType = "text", isVisible = true, order = 1, widthWeight = 1.1f),
                ItemColumnDef(id = "col_units", label = "Units / SqFt", key = "quantity", dataType = "quantity", isVisible = true, order = 2, widthWeight = 0.8f),
                ItemColumnDef(id = "col_unit_cost", label = "Unit Cost", key = "unitPrice", dataType = "currency", isVisible = true, order = 3, widthWeight = 1.1f),
                ItemColumnDef(id = "col_retainage", label = "Retainage (%)", key = "discountRate", dataType = "percentage", isVisible = true, order = 4, widthWeight = 0.9f),
                ItemColumnDef(id = "col_tax", label = "Tax", key = "taxRate", dataType = "tax", isVisible = true, order = 5, widthWeight = 0.8f),
                ItemColumnDef(id = "col_total", label = "Total", key = "total", dataType = "formula", isVisible = true, order = 6, widthWeight = 1.2f, calculationType = "formula", formula = "Units * Unit Cost - Retainage")
            ),
            defaultNotes = "Progress billing for Milestone 2. Site inspection report certified.",
            defaultTerms = "Retainage balance payable upon final certificate of completion.",
            recommendedSectionTitle = "Job Site & Delivery"
        ),

        IndustryTemplatePreset(
            id = "custom",
            name = "Custom / Blank Template",
            industryCategory = "Tailored",
            description = "Start with a flexible, clean itemization and build your own table",
            icon = Icons.Default.Tune,
            recommendedTemplateId = "minimalist",
            sampleItem = InvoiceItem(
                description = "Custom Professional Service",
                quantity = 1.0,
                unitPrice = 100.0,
                unit = "unit"
            ),
            defaultColumns = listOf(
                ItemColumnDef(id = "col_custom_1", label = "Item Name", key = "description", dataType = "text", isVisible = true, order = 0, widthWeight = 2.2f, isRequired = true),
                ItemColumnDef(id = "col_custom_2", label = "Quantity", key = "quantity", dataType = "quantity", isVisible = true, order = 1, widthWeight = 0.8f),
                ItemColumnDef(id = "col_custom_3", label = "Unit Price", key = "unitPrice", dataType = "currency", isVisible = true, order = 2, widthWeight = 1.1f),
                ItemColumnDef(id = "col_custom_4", label = "Amount", key = "total", dataType = "formula", isVisible = true, order = 3, widthWeight = 1.3f, calculationType = "formula", formula = "Quantity * Unit Price")
            ),
            defaultNotes = "Thank you for your business!",
            defaultTerms = "Payment due upon receipt of invoice.",
            recommendedSectionTitle = "Shipping Details"
        )
    )

    fun getPresetById(id: String): IndustryTemplatePreset {
        return allPresets.find { it.id.equals(id, ignoreCase = true) } ?: allPresets.first()
    }
}

