package com.example.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.model.BusinessProfile
import com.example.data.model.CustomClientField
import com.example.data.model.InvoiceCalculations
import com.example.data.model.InvoiceItem
import com.example.data.model.InvoiceUtils
import com.example.data.model.ItemColumnDef
import com.example.data.model.ShippingDetails
import com.example.ui.theme.PrimaryNavy
import com.example.ui.theme.StatusPaidGreen
import java.util.Locale

/**
 * Renders an invoice document using one of 5 distinct, simple, professional letterhead designs:
 * 1. "minimalist" — Modern Minimalist Letterhead (ultra-clean, hairline rules, charcoal slate)
 * 2. "corporate" — Corporate Executive Letterhead (solid top bar, structured dual-framed cards)
 * 3. "classic_letterhead" — Classic Formal Business Letterhead (centered company title, double rules, ledger)
 * 4. "tech_clean" — Tech / SaaS Clean Letterhead (left accent bar, modern metadata chips)
 * 5. "compact_ledger" — Compact Ledger / Retail Bill (dense, space-saving, barcode & SKU ready)
 *
 * Dynamically displays all data filled by the user without garish or overwhelming colors.
 */
@Composable
fun InvoiceTemplateRenderer(
    templateId: String,
    invoiceNumber: String,
    issueDate: String,
    dueDate: String,
    poNumber: String,
    paymentTerms: String,
    currencySymbol: String,
    currencyCode: String,
    clientName: String,
    clientCompany: String,
    clientEmail: String,
    clientPhone: String,
    clientAddress: String,
    clientTaxId: String,
    customClientFields: List<CustomClientField>,
    shippingDetails: ShippingDetails,
    activeColumns: List<ItemColumnDef>,
    items: List<InvoiceItem>,
    taxRate: Double,
    taxLabel: String,
    taxType: String,
    isTaxInclusive: Boolean,
    calculations: InvoiceCalculations,
    notes: String,
    terms: String,
    paymentInstructions: String,
    notesLabel: String = "Notes",
    termsLabel: String = "Terms & Conditions",
    profile: BusinessProfile,
    status: String = "Draft",
    modifier: Modifier = Modifier
) {
    val visibleCols = activeColumns.filter { it.isVisible }

    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(18.dp)
            .testTag("invoice_template_renderer_$templateId")
    ) {
        when (templateId.lowercase()) {
            "corporate", "manufacturing", "logistics", "construction" -> {
                CorporateTemplateView(
                    invoiceNumber, issueDate, dueDate, poNumber, paymentTerms,
                    currencySymbol, currencyCode, clientName, clientCompany, clientEmail, clientPhone, clientAddress, clientTaxId,
                    customClientFields, shippingDetails, visibleCols, items, taxRate, taxLabel, isTaxInclusive, calculations,
                    notes, terms, paymentInstructions, notesLabel, termsLabel, profile, status
                )
            }
            "classic_letterhead", "consulting", "education" -> {
                ClassicLetterheadTemplateView(
                    invoiceNumber, issueDate, dueDate, poNumber, paymentTerms,
                    currencySymbol, currencyCode, clientName, clientCompany, clientEmail, clientPhone, clientAddress, clientTaxId,
                    customClientFields, shippingDetails, visibleCols, items, taxRate, taxLabel, isTaxInclusive, calculations,
                    notes, terms, paymentInstructions, notesLabel, termsLabel, profile, status
                )
            }
            "tech_clean", "it_software", "it" -> {
                TechCleanTemplateView(
                    invoiceNumber, issueDate, dueDate, poNumber, paymentTerms,
                    currencySymbol, currencyCode, clientName, clientCompany, clientEmail, clientPhone, clientAddress, clientTaxId,
                    customClientFields, shippingDetails, visibleCols, items, taxRate, taxLabel, isTaxInclusive, calculations,
                    notes, terms, paymentInstructions, notesLabel, termsLabel, profile, status
                )
            }
            "compact_ledger", "retail", "restaurant" -> {
                CompactLedgerTemplateView(
                    invoiceNumber, issueDate, dueDate, poNumber, paymentTerms,
                    currencySymbol, currencyCode, clientName, clientCompany, clientEmail, clientPhone, clientAddress, clientTaxId,
                    customClientFields, shippingDetails, visibleCols, items, taxRate, taxLabel, isTaxInclusive, calculations,
                    notes, terms, paymentInstructions, notesLabel, termsLabel, profile, status
                )
            }
            "ecommerce", "e-commerce" -> {
                EcommerceTemplateView(
                    invoiceNumber, issueDate, dueDate, poNumber, paymentTerms,
                    currencySymbol, currencyCode, clientName, clientCompany, clientEmail, clientPhone, clientAddress, clientTaxId,
                    customClientFields, shippingDetails, visibleCols, items, taxRate, taxLabel, isTaxInclusive, calculations,
                    notes, terms, paymentInstructions, notesLabel, termsLabel, profile, status
                )
            }
            "healthcare", "medical" -> {
                HealthcareTemplateView(
                    invoiceNumber, issueDate, dueDate, poNumber, paymentTerms,
                    currencySymbol, currencyCode, clientName, clientCompany, clientEmail, clientPhone, clientAddress, clientTaxId,
                    customClientFields, shippingDetails, visibleCols, items, taxRate, taxLabel, isTaxInclusive, calculations,
                    notes, terms, paymentInstructions, notesLabel, termsLabel, profile, status
                )
            }
            else -> {
                // Default: "minimalist" (Modern Minimalist Letterhead)
                MinimalistTemplateView(
                    invoiceNumber, issueDate, dueDate, poNumber, paymentTerms,
                    currencySymbol, currencyCode, clientName, clientCompany, clientEmail, clientPhone, clientAddress, clientTaxId,
                    customClientFields, shippingDetails, visibleCols, items, taxRate, taxLabel, isTaxInclusive, calculations,
                    notes, terms, paymentInstructions, notesLabel, termsLabel, profile, status
                )
            }
        }
    }
}

// =============================================================================
// 1. MINIMALIST TEMPLATE VIEW (Modern Minimalist Letterhead)
// =============================================================================
@Composable
private fun MinimalistTemplateView(
    invoiceNumber: String, issueDate: String, dueDate: String, poNumber: String, paymentTerms: String,
    currencySymbol: String, currencyCode: String, clientName: String, clientCompany: String, clientEmail: String, clientPhone: String, clientAddress: String, clientTaxId: String,
    customClientFields: List<CustomClientField>, shippingDetails: ShippingDetails, visibleCols: List<ItemColumnDef>, items: List<InvoiceItem>,
    taxRate: Double, taxLabel: String, isTaxInclusive: Boolean, calculations: InvoiceCalculations,
    notes: String, terms: String, paymentInstructions: String, notesLabel: String, termsLabel: String, profile: BusinessProfile, status: String
) {
    // Letterhead Row
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.Top
    ) {
        Column(modifier = Modifier.weight(1.3f)) {
            Text(
                text = profile.businessName.ifBlank { "Company Name" }.uppercase(),
                fontSize = 17.sp,
                fontWeight = FontWeight.ExtraBold,
                color = Color(0xFF0F172A),
                letterSpacing = 0.5.sp
            )
            if (profile.address.isNotBlank()) {
                Text(text = profile.address, fontSize = 10.sp, color = Color(0xFF64748B))
            }
            if (profile.phone.isNotBlank() || profile.email.isNotBlank()) {
                Text(text = "${profile.phone} • ${profile.email}".trim(' ', '•'), fontSize = 10.sp, color = Color(0xFF64748B))
            }
            if (profile.taxId.isNotBlank() || profile.gstin.isNotBlank()) {
                Text(text = "Tax ID: ${profile.taxId.ifBlank { profile.gstin }}", fontSize = 10.sp, color = Color(0xFF64748B), fontWeight = FontWeight.Medium)
            }
        }

        Column(horizontalAlignment = Alignment.End, modifier = Modifier.weight(0.9f)) {
            Text(
                text = "INVOICE",
                fontSize = 20.sp,
                fontWeight = FontWeight.Black,
                color = Color(0xFF0F172A),
                letterSpacing = 1.sp
            )
            Spacer(modifier = Modifier.height(2.dp))
            Text(text = "#$invoiceNumber", fontSize = 13.sp, fontWeight = FontWeight.Bold, color = Color(0xFF334155))
            Text(text = "Date: $issueDate", fontSize = 10.sp, color = Color(0xFF64748B))
            Text(text = "Due: $dueDate", fontSize = 10.sp, color = Color(0xFFDC2626), fontWeight = FontWeight.SemiBold)
            if (paymentTerms.isNotBlank()) {
                Text(text = "Terms: $paymentTerms", fontSize = 9.sp, color = Color(0xFF64748B))
            }
        }
    }

    Spacer(modifier = Modifier.height(14.dp))
    HorizontalDivider(color = Color(0xFFE2E8F0), thickness = 1.dp)
    Spacer(modifier = Modifier.height(12.dp))

    // Bill To & Ship To
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text("BILLED TO", fontSize = 9.sp, fontWeight = FontWeight.ExtraBold, color = Color(0xFF94A3B8), letterSpacing = 0.5.sp)
            Text(clientName.ifBlank { "Client Name" }, fontSize = 13.sp, fontWeight = FontWeight.Bold, color = Color(0xFF0F172A))
            if (clientCompany.isNotBlank()) Text(clientCompany, fontSize = 10.sp, color = Color(0xFF475569))
            if (clientAddress.isNotBlank()) Text(clientAddress, fontSize = 10.sp, color = Color(0xFF64748B))
            if (clientEmail.isNotBlank()) Text(clientEmail, fontSize = 10.sp, color = Color(0xFF64748B))
            if (clientTaxId.isNotBlank()) Text("Tax ID / GST: $clientTaxId", fontSize = 9.sp, color = Color(0xFF64748B))
            customClientFields.forEach {
                if (it.value.isNotBlank()) Text("${it.label}: ${it.value}", fontSize = 9.sp, color = Color(0xFF475569))
            }
        }

        if (shippingDetails.isEnabled) {
            Spacer(modifier = Modifier.width(14.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(shippingDetails.sectionTitle.uppercase(), fontSize = 9.sp, fontWeight = FontWeight.ExtraBold, color = Color(0xFF94A3B8), letterSpacing = 0.5.sp)
                val shipAddr = if (shippingDetails.sameAsBilling) clientAddress.ifBlank { "Same as billing address" } else shippingDetails.shippingAddress.ifBlank { "Delivery address" }
                Text(shipAddr, fontSize = 10.sp, color = Color(0xFF334155))
                if (shippingDetails.courier.isNotBlank()) Text("Courier: ${shippingDetails.courier}", fontSize = 9.sp, color = Color(0xFF64748B))
                if (shippingDetails.trackingNumber.isNotBlank()) Text("Tracking: ${shippingDetails.trackingNumber}", fontSize = 9.sp, color = Color(0xFF2563EB), fontWeight = FontWeight.Bold)
            }
        }
    }

    Spacer(modifier = Modifier.height(14.dp))

    // Minimalist Table (Hairline rules)
    RenderItemTable(visibleCols, items, currencySymbol, headerBg = Color(0xFFF8FAFC), headerText = Color(0xFF0F172A), isBordered = false)

    Spacer(modifier = Modifier.height(12.dp))

    // Totals Breakdown
    RenderTotalsSection(calculations, currencySymbol, currencyCode, taxLabel, taxRate, isTaxInclusive, paymentInstructions)

    Spacer(modifier = Modifier.height(14.dp))
    HorizontalDivider(color = Color(0xFFE2E8F0), thickness = 1.dp)
    Spacer(modifier = Modifier.height(10.dp))

    // Notes, Terms & Signatory
    RenderFooterSection(notes, terms, notesLabel, termsLabel, profile)
}

// =============================================================================
// 2. CORPORATE EXECUTIVE TEMPLATE VIEW
// =============================================================================
@Composable
private fun CorporateTemplateView(
    invoiceNumber: String, issueDate: String, dueDate: String, poNumber: String, paymentTerms: String,
    currencySymbol: String, currencyCode: String, clientName: String, clientCompany: String, clientEmail: String, clientPhone: String, clientAddress: String, clientTaxId: String,
    customClientFields: List<CustomClientField>, shippingDetails: ShippingDetails, visibleCols: List<ItemColumnDef>, items: List<InvoiceItem>,
    taxRate: Double, taxLabel: String, isTaxInclusive: Boolean, calculations: InvoiceCalculations,
    notes: String, terms: String, paymentInstructions: String, notesLabel: String, termsLabel: String, profile: BusinessProfile, status: String
) {
    // Solid Corporate Header Bar
    Surface(
        color = Color(0xFF1E293B),
        shape = RoundedCornerShape(6.dp),
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 14.dp, vertical = 10.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(
                    text = profile.businessName.ifBlank { "Corporate Supplier" }.uppercase(),
                    fontSize = 16.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.White
                )
                if (profile.taxId.isNotBlank() || profile.gstin.isNotBlank()) {
                    Text(
                        text = "GSTIN / TAX ID: ${profile.taxId.ifBlank { profile.gstin }}",
                        fontSize = 9.sp,
                        color = Color(0xFF94A3B8)
                    )
                }
            }

            Surface(
                color = Color(0xFF334155),
                shape = RoundedCornerShape(4.dp)
            ) {
                Text(
                    text = "COMMERCIAL INVOICE",
                    fontSize = 10.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color(0xFFE2E8F0),
                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                )
            }
        }
    }

    Spacer(modifier = Modifier.height(10.dp))

    // Dual Framed Particulars Boxes
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Surface(
            modifier = Modifier.weight(1f),
            color = Color(0xFFF8FAFC),
            shape = RoundedCornerShape(6.dp),
            border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFE2E8F0))
        ) {
            Column(modifier = Modifier.padding(10.dp)) {
                Text("BUYER / BILLED TO", fontSize = 9.sp, fontWeight = FontWeight.Bold, color = Color(0xFF64748B))
                Text(clientName.ifBlank { "Buyer Name" }, fontSize = 12.sp, fontWeight = FontWeight.Bold, color = Color(0xFF0F172A))
                if (clientCompany.isNotBlank()) Text(clientCompany, fontSize = 10.sp, color = Color(0xFF475569))
                if (clientAddress.isNotBlank()) Text(clientAddress, fontSize = 9.sp, color = Color(0xFF64748B))
                if (clientTaxId.isNotBlank()) Text("Tax ID: $clientTaxId", fontSize = 9.sp, color = Color(0xFF64748B))
            }
        }

        Surface(
            modifier = Modifier.weight(1f),
            color = Color(0xFFF8FAFC),
            shape = RoundedCornerShape(6.dp),
            border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFE2E8F0))
        ) {
            Column(modifier = Modifier.padding(10.dp)) {
                Text("INVOICE PARTICULARS", fontSize = 9.sp, fontWeight = FontWeight.Bold, color = Color(0xFF64748B))
                Text("Invoice #: $invoiceNumber", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Color(0xFF0F172A))
                Text("Issue Date: $issueDate", fontSize = 9.sp, color = Color(0xFF475569))
                Text("Due Date: $dueDate", fontSize = 9.sp, fontWeight = FontWeight.SemiBold, color = Color(0xFFDC2626))
                if (poNumber.isNotBlank()) Text("PO Ref: $poNumber", fontSize = 9.sp, color = Color(0xFF64748B))
            }
        }
    }

    if (shippingDetails.isEnabled) {
        Spacer(modifier = Modifier.height(6.dp))
        Surface(
            modifier = Modifier.fillMaxWidth(),
            color = Color(0xFFF8FAFC),
            shape = RoundedCornerShape(6.dp),
            border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFE2E8F0))
        ) {
            Row(modifier = Modifier.padding(8.dp), horizontalArrangement = Arrangement.SpaceBetween) {
                Text("${shippingDetails.sectionTitle}: ${if (shippingDetails.sameAsBilling) clientAddress else shippingDetails.shippingAddress}", fontSize = 9.sp, color = Color(0xFF475569), modifier = Modifier.weight(1f))
                if (shippingDetails.trackingNumber.isNotBlank()) Text("Track: ${shippingDetails.trackingNumber}", fontSize = 9.sp, fontWeight = FontWeight.Bold, color = Color(0xFF2563EB))
            }
        }
    }

    Spacer(modifier = Modifier.height(12.dp))

    // Structured Corporate Grid Table
    RenderItemTable(visibleCols, items, currencySymbol, headerBg = Color(0xFF334155), headerText = Color.White, isBordered = true)

    Spacer(modifier = Modifier.height(12.dp))

    // Corporate Totals
    RenderTotalsSection(calculations, currencySymbol, currencyCode, taxLabel, taxRate, isTaxInclusive, paymentInstructions)

    Spacer(modifier = Modifier.height(12.dp))
    HorizontalDivider(color = Color(0xFFCBD5E1), thickness = 1.dp)
    Spacer(modifier = Modifier.height(8.dp))

    RenderFooterSection(notes, terms, notesLabel, termsLabel, profile)
}

// =============================================================================
// 3. CLASSIC FORMAL LETTERHEAD TEMPLATE VIEW
// =============================================================================
@Composable
private fun ClassicLetterheadTemplateView(
    invoiceNumber: String, issueDate: String, dueDate: String, poNumber: String, paymentTerms: String,
    currencySymbol: String, currencyCode: String, clientName: String, clientCompany: String, clientEmail: String, clientPhone: String, clientAddress: String, clientTaxId: String,
    customClientFields: List<CustomClientField>, shippingDetails: ShippingDetails, visibleCols: List<ItemColumnDef>, items: List<InvoiceItem>,
    taxRate: Double, taxLabel: String, isTaxInclusive: Boolean, calculations: InvoiceCalculations,
    notes: String, terms: String, paymentInstructions: String, notesLabel: String, termsLabel: String, profile: BusinessProfile, status: String
) {
    // Centered Elegant Business Letterhead
    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = profile.businessName.ifBlank { "Business Name" }.uppercase(),
            fontSize = 19.sp,
            fontWeight = FontWeight.Bold,
            color = Color(0xFF0F172A),
            letterSpacing = 1.sp
        )
        if (profile.address.isNotBlank()) {
            Text(text = profile.address, fontSize = 9.sp, color = Color(0xFF475569))
        }
        val contactStr = listOf(profile.phone, profile.email).filter { it.isNotBlank() }.joinToString(" • ")
        if (contactStr.isNotBlank()) {
            Text(text = contactStr, fontSize = 9.sp, color = Color(0xFF64748B))
        }
        if (profile.taxId.isNotBlank() || profile.gstin.isNotBlank()) {
            Text(text = "Tax ID: ${profile.taxId.ifBlank { profile.gstin }}", fontSize = 9.sp, color = Color(0xFF64748B))
        }

        Spacer(modifier = Modifier.height(6.dp))

        // Formal Double-Line Divider
        HorizontalDivider(color = Color(0xFF0F172A), thickness = 1.5.dp)
        Spacer(modifier = Modifier.height(2.dp))
        HorizontalDivider(color = Color(0xFF94A3B8), thickness = 0.5.dp)
        Spacer(modifier = Modifier.height(6.dp))

        Text(
            text = "TAX INVOICE & STATEMENT OF ACCOUNT",
            fontSize = 11.sp,
            fontWeight = FontWeight.Bold,
            color = Color(0xFF1E293B),
            letterSpacing = 1.sp
        )
    }

    Spacer(modifier = Modifier.height(10.dp))

    // 3-Column Info Row
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Column(modifier = Modifier.weight(1.1f)) {
            Text("BILLED TO:", fontSize = 8.sp, fontWeight = FontWeight.Bold, color = Color(0xFF64748B))
            Text(clientName.ifBlank { "Client Name" }, fontSize = 12.sp, fontWeight = FontWeight.Bold, color = Color(0xFF0F172A))
            if (clientCompany.isNotBlank()) Text(clientCompany, fontSize = 9.sp, color = Color(0xFF475569))
            if (clientAddress.isNotBlank()) Text(clientAddress, fontSize = 9.sp, color = Color(0xFF64748B))
            if (clientTaxId.isNotBlank()) Text("Tax: $clientTaxId", fontSize = 8.sp, color = Color(0xFF64748B))
        }

        if (shippingDetails.isEnabled) {
            Column(modifier = Modifier.weight(1.1f)) {
                Text("DISPATCH TO:", fontSize = 8.sp, fontWeight = FontWeight.Bold, color = Color(0xFF64748B))
                val shipAddr = if (shippingDetails.sameAsBilling) clientAddress else shippingDetails.shippingAddress
                Text(shipAddr.ifBlank { "Same as billing" }, fontSize = 9.sp, color = Color(0xFF334155))
                if (shippingDetails.courier.isNotBlank()) Text("Carrier: ${shippingDetails.courier}", fontSize = 8.sp, color = Color(0xFF64748B))
            }
        }

        Column(modifier = Modifier.weight(0.9f), horizontalAlignment = Alignment.End) {
            Text("INVOICE NO:", fontSize = 8.sp, fontWeight = FontWeight.Bold, color = Color(0xFF64748B))
            Text("#$invoiceNumber", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = Color(0xFF0F172A))
            Text("Date: $issueDate", fontSize = 9.sp, color = Color(0xFF475569))
            Text("Due: $dueDate", fontSize = 9.sp, fontWeight = FontWeight.SemiBold, color = Color(0xFFDC2626))
            if (paymentTerms.isNotBlank()) Text("Terms: $paymentTerms", fontSize = 8.sp, color = Color(0xFF64748B))
        }
    }

    Spacer(modifier = Modifier.height(12.dp))

    // Ledger Bordered Table
    RenderItemTable(visibleCols, items, currencySymbol, headerBg = Color(0xFFF1F5F9), headerText = Color(0xFF0F172A), isBordered = true)

    Spacer(modifier = Modifier.height(12.dp))

    RenderTotalsSection(calculations, currencySymbol, currencyCode, taxLabel, taxRate, isTaxInclusive, paymentInstructions)

    Spacer(modifier = Modifier.height(12.dp))
    HorizontalDivider(color = Color(0xFFCBD5E1), thickness = 1.dp)
    Spacer(modifier = Modifier.height(8.dp))

    RenderFooterSection(notes, terms, notesLabel, termsLabel, profile)
}

// =============================================================================
// 4. TECH CLEAN TEMPLATE VIEW (Modern Left-Accent Bar)
// =============================================================================
@Composable
private fun TechCleanTemplateView(
    invoiceNumber: String, issueDate: String, dueDate: String, poNumber: String, paymentTerms: String,
    currencySymbol: String, currencyCode: String, clientName: String, clientCompany: String, clientEmail: String, clientPhone: String, clientAddress: String, clientTaxId: String,
    customClientFields: List<CustomClientField>, shippingDetails: ShippingDetails, visibleCols: List<ItemColumnDef>, items: List<InvoiceItem>,
    taxRate: Double, taxLabel: String, isTaxInclusive: Boolean, calculations: InvoiceCalculations,
    notes: String, terms: String, paymentInstructions: String, notesLabel: String, termsLabel: String, profile: BusinessProfile, status: String
) {
    // Left Accent Bar Header
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.Top
    ) {
        Row(
            modifier = Modifier.weight(1.2f),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            // 4dp vertical bar
            Box(
                modifier = Modifier
                    .width(4.dp)
                    .height(52.dp)
                    .clip(RoundedCornerShape(2.dp))
                    .background(Color(0xFF2563EB))
            )

            Column {
                Text(
                    text = profile.businessName.ifBlank { "Tech Agency" },
                    fontSize = 17.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color(0xFF0F172A)
                )
                if (profile.address.isNotBlank()) Text(profile.address, fontSize = 9.sp, color = Color(0xFF64748B))
                if (profile.email.isNotBlank()) Text(profile.email, fontSize = 9.sp, color = Color(0xFF64748B))
            }
        }

        Column(horizontalAlignment = Alignment.End, modifier = Modifier.weight(0.9f)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(
                    text = "INVOICE",
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Black,
                    color = Color(0xFF0F172A)
                )
                Surface(
                    color = Color(0xFFEFF6FF),
                    shape = RoundedCornerShape(4.dp),
                    border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFBFDBFE))
                ) {
                    Text(
                        text = status.uppercase(),
                        fontSize = 8.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color(0xFF1D4ED8),
                        modifier = Modifier.padding(horizontal = 4.dp, vertical = 2.dp)
                    )
                }
            }
            Text("#$invoiceNumber", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = Color(0xFF334155))
        }
    }

    Spacer(modifier = Modifier.height(10.dp))

    // Modern Metadata Chips Row
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(6.dp)
    ) {
        MetadataChip("Date", issueDate)
        MetadataChip("Due", dueDate, isAlert = true)
        if (poNumber.isNotBlank()) MetadataChip("PO #", poNumber)
        if (paymentTerms.isNotBlank()) MetadataChip("Terms", paymentTerms)
    }

    Spacer(modifier = Modifier.height(10.dp))

    // Client & Shipping Cards
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Surface(
            modifier = Modifier.weight(1f),
            color = Color(0xFFF8FAFC),
            shape = RoundedCornerShape(6.dp),
            border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFE2E8F0))
        ) {
            Column(modifier = Modifier.padding(8.dp)) {
                Text("CLIENT / BILL TO", fontSize = 8.sp, fontWeight = FontWeight.Bold, color = Color(0xFF94A3B8))
                Text(clientName.ifBlank { "Client Name" }, fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Color(0xFF0F172A))
                if (clientCompany.isNotBlank()) Text(clientCompany, fontSize = 9.sp, color = Color(0xFF475569))
                if (clientEmail.isNotBlank()) Text(clientEmail, fontSize = 9.sp, color = Color(0xFF64748B))
            }
        }

        if (shippingDetails.isEnabled) {
            Surface(
                modifier = Modifier.weight(1f),
                color = Color(0xFFF8FAFC),
                shape = RoundedCornerShape(6.dp),
                border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFE2E8F0))
            ) {
                Column(modifier = Modifier.padding(8.dp)) {
                    Text(shippingDetails.sectionTitle.uppercase(), fontSize = 8.sp, fontWeight = FontWeight.Bold, color = Color(0xFF94A3B8))
                    val shipAddr = if (shippingDetails.sameAsBilling) clientAddress else shippingDetails.shippingAddress
                    Text(shipAddr.ifBlank { "Same as billing" }, fontSize = 9.sp, color = Color(0xFF334155))
                    if (shippingDetails.trackingNumber.isNotBlank()) Text("Tracking: ${shippingDetails.trackingNumber}", fontSize = 8.sp, fontWeight = FontWeight.Bold, color = Color(0xFF2563EB))
                }
            }
        }
    }

    Spacer(modifier = Modifier.height(10.dp))

    // Tech Clean Table
    RenderItemTable(visibleCols, items, currencySymbol, headerBg = Color(0xFFF1F5F9), headerText = Color(0xFF1E293B), isBordered = false)

    Spacer(modifier = Modifier.height(10.dp))

    RenderTotalsSection(calculations, currencySymbol, currencyCode, taxLabel, taxRate, isTaxInclusive, paymentInstructions)

    Spacer(modifier = Modifier.height(10.dp))
    HorizontalDivider(color = Color(0xFFE2E8F0), thickness = 1.dp)
    Spacer(modifier = Modifier.height(8.dp))

    RenderFooterSection(notes, terms, notesLabel, termsLabel, profile)
}

// =============================================================================
// 5. COMPACT LEDGER / RETAIL BILL TEMPLATE VIEW
// =============================================================================
@Composable
private fun CompactLedgerTemplateView(
    invoiceNumber: String, issueDate: String, dueDate: String, poNumber: String, paymentTerms: String,
    currencySymbol: String, currencyCode: String, clientName: String, clientCompany: String, clientEmail: String, clientPhone: String, clientAddress: String, clientTaxId: String,
    customClientFields: List<CustomClientField>, shippingDetails: ShippingDetails, visibleCols: List<ItemColumnDef>, items: List<InvoiceItem>,
    taxRate: Double, taxLabel: String, isTaxInclusive: Boolean, calculations: InvoiceCalculations,
    notes: String, terms: String, paymentInstructions: String, notesLabel: String, termsLabel: String, profile: BusinessProfile, status: String
) {
    // Dense Single-Line Header
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column {
            Text(profile.businessName.ifBlank { "Store / POS" }, fontSize = 15.sp, fontWeight = FontWeight.ExtraBold, color = Color(0xFF0F172A))
            if (profile.taxId.isNotBlank() || profile.gstin.isNotBlank()) {
                Text("GST/Tax: ${profile.taxId.ifBlank { profile.gstin }}", fontSize = 8.sp, color = Color(0xFF64748B))
            }
        }

        Column(horizontalAlignment = Alignment.End) {
            Text("RETAIL INVOICE", fontSize = 12.sp, fontWeight = FontWeight.Black, color = Color(0xFF0F172A))
            Text("#$invoiceNumber • $issueDate", fontSize = 9.sp, fontWeight = FontWeight.SemiBold, color = Color(0xFF475569))
        }
    }

    Spacer(modifier = Modifier.height(6.dp))
    HorizontalDivider(color = Color(0xFFCBD5E1), thickness = 1.dp)
    Spacer(modifier = Modifier.height(6.dp))

    // Dense Client Line
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text("Customer: ${clientName.ifBlank { "Walk-in" }} ${if (clientPhone.isNotBlank()) "($clientPhone)" else ""}", fontSize = 9.sp, fontWeight = FontWeight.Medium, color = Color(0xFF334155))
        Text("Due: $dueDate", fontSize = 9.sp, color = Color(0xFF64748B))
    }

    Spacer(modifier = Modifier.height(8.dp))

    // Compact Dense Table
    RenderItemTable(visibleCols, items, currencySymbol, headerBg = Color(0xFF0F172A), headerText = Color.White, isBordered = true)

    Spacer(modifier = Modifier.height(8.dp))

    // Compact Totals
    RenderTotalsSection(calculations, currencySymbol, currencyCode, taxLabel, taxRate, isTaxInclusive, paymentInstructions)

    Spacer(modifier = Modifier.height(8.dp))
    HorizontalDivider(color = Color(0xFFCBD5E1), thickness = 1.dp)
    Spacer(modifier = Modifier.height(6.dp))

    RenderFooterSection(notes, terms, notesLabel, termsLabel, profile)
}

// =============================================================================
// 6. E-COMMERCE DISPATCH TEMPLATE VIEW
// =============================================================================
@Composable
private fun EcommerceTemplateView(
    invoiceNumber: String, issueDate: String, dueDate: String, poNumber: String, paymentTerms: String,
    currencySymbol: String, currencyCode: String, clientName: String, clientCompany: String, clientEmail: String, clientPhone: String, clientAddress: String, clientTaxId: String,
    customClientFields: List<CustomClientField>, shippingDetails: ShippingDetails, visibleCols: List<ItemColumnDef>, items: List<InvoiceItem>,
    taxRate: Double, taxLabel: String, isTaxInclusive: Boolean, calculations: InvoiceCalculations,
    notes: String, terms: String, paymentInstructions: String, notesLabel: String, termsLabel: String, profile: BusinessProfile, status: String
) {
    // E-Commerce Brand Letterhead Header
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.Top
    ) {
        Column(modifier = Modifier.weight(1.2f)) {
            Text(
                text = profile.businessName.ifBlank { "Online Store" },
                fontSize = 17.sp,
                fontWeight = FontWeight.ExtraBold,
                color = Color(0xFF0F172A)
            )
            if (profile.address.isNotBlank()) {
                Text(text = profile.address, fontSize = 9.sp, color = Color(0xFF64748B))
            }
            if (profile.email.isNotBlank() || profile.phone.isNotBlank()) {
                Text(
                    text = listOf(profile.email, profile.phone).filter { it.isNotBlank() }.joinToString(" • "),
                    fontSize = 9.sp,
                    color = Color(0xFF64748B)
                )
            }
            if (profile.taxId.isNotBlank() || profile.gstin.isNotBlank()) {
                Text(text = "Tax / GST: ${profile.taxId.ifBlank { profile.gstin }}", fontSize = 9.sp, color = Color(0xFF64748B))
            }
        }

        Column(horizontalAlignment = Alignment.End, modifier = Modifier.weight(0.9f)) {
            Surface(
                color = Color(0xFFF1F5F9),
                shape = RoundedCornerShape(4.dp),
                border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFCBD5E1))
            ) {
                Text(
                    text = "ORDER TAX INVOICE",
                    fontSize = 9.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color(0xFF1E293B),
                    modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                )
            }
            Spacer(modifier = Modifier.height(2.dp))
            Text(text = "#$invoiceNumber", fontSize = 13.sp, fontWeight = FontWeight.Bold, color = Color(0xFF0F172A))
            Text(text = "Order Date: $issueDate", fontSize = 9.sp, color = Color(0xFF64748B))
            if (poNumber.isNotBlank()) {
                Text(text = "Order Ref: $poNumber", fontSize = 9.sp, color = Color(0xFF475569))
            }
        }
    }

    Spacer(modifier = Modifier.height(8.dp))
    HorizontalDivider(color = Color(0xFFE2E8F0), thickness = 1.dp)
    Spacer(modifier = Modifier.height(8.dp))

    // Shipping & Dispatch Status Card
    if (shippingDetails.isEnabled) {
        Surface(
            modifier = Modifier.fillMaxWidth(),
            color = Color(0xFFF8FAFC),
            shape = RoundedCornerShape(6.dp),
            border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFE2E8F0))
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(8.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(modifier = Modifier.weight(1.2f)) {
                    Text(
                        text = "DELIVERY & TRACKING DETAILS",
                        fontSize = 8.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color(0xFF64748B)
                    )
                    val shipAddr = if (shippingDetails.sameAsBilling) clientAddress else shippingDetails.shippingAddress
                    Text(shipAddr.ifBlank { "Customer shipping address" }, fontSize = 9.sp, color = Color(0xFF1E293B))
                }

                Column(horizontalAlignment = Alignment.End, modifier = Modifier.weight(0.8f)) {
                    if (shippingDetails.courier.isNotBlank()) {
                        Text(text = "Carrier: ${shippingDetails.courier}", fontSize = 9.sp, color = Color(0xFF475569))
                    }
                    if (shippingDetails.trackingNumber.isNotBlank()) {
                        Text(
                            text = "Tracking: ${shippingDetails.trackingNumber}",
                            fontSize = 9.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color(0xFF2563EB)
                        )
                    }
                }
            }
        }
        Spacer(modifier = Modifier.height(8.dp))
    }

    // Bill To Customer Strip
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text("BILLED TO:", fontSize = 8.sp, fontWeight = FontWeight.Bold, color = Color(0xFF94A3B8))
            Text(clientName.ifBlank { "Customer Name" }, fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Color(0xFF0F172A))
            if (clientEmail.isNotBlank()) Text(clientEmail, fontSize = 9.sp, color = Color(0xFF64748B))
            if (clientPhone.isNotBlank()) Text(clientPhone, fontSize = 9.sp, color = Color(0xFF64748B))
        }
        Column(horizontalAlignment = Alignment.End, modifier = Modifier.weight(1f)) {
            Text("PAYMENT METHOD:", fontSize = 8.sp, fontWeight = FontWeight.Bold, color = Color(0xFF94A3B8))
            Text(paymentTerms.ifBlank { "Prepaid / COD" }, fontSize = 10.sp, fontWeight = FontWeight.Medium, color = Color(0xFF0F172A))
            Text("Currency: $currencyCode ($currencySymbol)", fontSize = 9.sp, color = Color(0xFF64748B))
        }
    }

    Spacer(modifier = Modifier.height(10.dp))

    // E-Commerce Product Table
    RenderItemTable(visibleCols, items, currencySymbol, headerBg = Color(0xFF1E293B), headerText = Color.White, isBordered = true)

    Spacer(modifier = Modifier.height(10.dp))

    // Financial Totals
    RenderTotalsSection(calculations, currencySymbol, currencyCode, taxLabel, taxRate, isTaxInclusive, paymentInstructions)

    Spacer(modifier = Modifier.height(10.dp))
    HorizontalDivider(color = Color(0xFFE2E8F0), thickness = 1.dp)
    Spacer(modifier = Modifier.height(8.dp))

    RenderFooterSection(notes, terms, notesLabel, termsLabel, profile)
}

// =============================================================================
// 7. HEALTHCARE & CLINICAL FEE BILL TEMPLATE VIEW
// =============================================================================
@Composable
private fun HealthcareTemplateView(
    invoiceNumber: String, issueDate: String, dueDate: String, poNumber: String, paymentTerms: String,
    currencySymbol: String, currencyCode: String, clientName: String, clientCompany: String, clientEmail: String, clientPhone: String, clientAddress: String, clientTaxId: String,
    customClientFields: List<CustomClientField>, shippingDetails: ShippingDetails, visibleCols: List<ItemColumnDef>, items: List<InvoiceItem>,
    taxRate: Double, taxLabel: String, isTaxInclusive: Boolean, calculations: InvoiceCalculations,
    notes: String, terms: String, paymentInstructions: String, notesLabel: String, termsLabel: String, profile: BusinessProfile, status: String
) {
    // Clinical Letterhead
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.Top
    ) {
        Column(modifier = Modifier.weight(1.3f)) {
            Text(
                text = profile.businessName.ifBlank { "Healthcare Clinic & Diagnostics" },
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold,
                color = Color(0xFF0F172A)
            )
            if (profile.address.isNotBlank()) {
                Text(text = profile.address, fontSize = 9.sp, color = Color(0xFF64748B))
            }
            if (profile.phone.isNotBlank() || profile.email.isNotBlank()) {
                Text(text = "Helpline: ${profile.phone} • ${profile.email}", fontSize = 9.sp, color = Color(0xFF64748B))
            }
            if (profile.taxId.isNotBlank() || profile.gstin.isNotBlank()) {
                Text(text = "Reg / Tax ID: ${profile.taxId.ifBlank { profile.gstin }}", fontSize = 9.sp, color = Color(0xFF64748B))
            }
        }

        Column(horizontalAlignment = Alignment.End, modifier = Modifier.weight(0.9f)) {
            Surface(
                color = Color(0xFFF0FDF4),
                shape = RoundedCornerShape(4.dp),
                border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFBBF7D0))
            ) {
                Text(
                    text = "PROFESSIONAL FEE BILL",
                    fontSize = 9.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color(0xFF166534),
                    modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                )
            }
            Spacer(modifier = Modifier.height(2.dp))
            Text(text = "Bill #: $invoiceNumber", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = Color(0xFF0F172A))
            Text(text = "Date: $issueDate", fontSize = 9.sp, color = Color(0xFF64748B))
            Text(text = "Due: $dueDate", fontSize = 9.sp, color = Color(0xFF64748B))
        }
    }

    Spacer(modifier = Modifier.height(8.dp))
    HorizontalDivider(color = Color(0xFF0D9488), thickness = 1.5.dp)
    Spacer(modifier = Modifier.height(8.dp))

    // Patient Information Card
    Surface(
        modifier = Modifier.fillMaxWidth(),
        color = Color(0xFFF8FAFC),
        shape = RoundedCornerShape(6.dp),
        border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFE2E8F0))
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(8.dp),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text("PATIENT NAME:", fontSize = 8.sp, fontWeight = FontWeight.Bold, color = Color(0xFF64748B))
                Text(clientName.ifBlank { "Patient / Client" }, fontSize = 12.sp, fontWeight = FontWeight.Bold, color = Color(0xFF0F172A))
                if (clientPhone.isNotBlank()) Text("Phone: $clientPhone", fontSize = 9.sp, color = Color(0xFF64748B))
                if (clientAddress.isNotBlank()) Text(clientAddress, fontSize = 9.sp, color = Color(0xFF64748B))
            }

            Column(horizontalAlignment = Alignment.End, modifier = Modifier.weight(1f)) {
                if (clientTaxId.isNotBlank()) {
                    Text("Insurance / Claim ID: $clientTaxId", fontSize = 9.sp, fontWeight = FontWeight.Medium, color = Color(0xFF0D9488))
                }
                Text("Payment Terms: ${paymentTerms.ifBlank { "Due on treatment" }}", fontSize = 9.sp, color = Color(0xFF64748B))
            }
        }
    }

    Spacer(modifier = Modifier.height(10.dp))

    // Clinical Procedures & Services Table
    RenderItemTable(visibleCols, items, currencySymbol, headerBg = Color(0xFF0F766E), headerText = Color.White, isBordered = true)

    Spacer(modifier = Modifier.height(10.dp))

    // Totals Breakdown
    RenderTotalsSection(calculations, currencySymbol, currencyCode, taxLabel, taxRate, isTaxInclusive, paymentInstructions)

    Spacer(modifier = Modifier.height(10.dp))
    HorizontalDivider(color = Color(0xFFCBD5E1), thickness = 1.dp)
    Spacer(modifier = Modifier.height(8.dp))

    RenderFooterSection(notes, terms, notesLabel, termsLabel, profile)
}

// =============================================================================
// SHARED REUSABLE COMPONENTS FOR TEMPLATES
// =============================================================================
@Composable
private fun MetadataChip(label: String, value: String, isAlert: Boolean = false) {
    Surface(
        color = if (isAlert) Color(0xFFFEF2F2) else Color(0xFFF1F5F9),
        shape = RoundedCornerShape(4.dp),
        border = androidx.compose.foundation.BorderStroke(1.dp, if (isAlert) Color(0xFFFECACA) else Color(0xFFE2E8F0))
    ) {
        Text(
            text = "$label: $value",
            fontSize = 9.sp,
            fontWeight = FontWeight.SemiBold,
            color = if (isAlert) Color(0xFFDC2626) else Color(0xFF475569),
            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
        )
    }
}

@Composable
private fun RenderItemTable(
    visibleCols: List<ItemColumnDef>,
    items: List<InvoiceItem>,
    currencySymbol: String,
    headerBg: Color,
    headerText: Color,
    isBordered: Boolean
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(4.dp))
            .then(
                if (isBordered) Modifier.border(1.dp, Color(0xFFCBD5E1), RoundedCornerShape(4.dp))
                else Modifier.border(1.dp, Color(0xFFE2E8F0), RoundedCornerShape(4.dp))
            )
    ) {
        // Table Header
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(headerBg)
                .padding(horizontal = 8.dp, vertical = 6.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            visibleCols.forEach { col ->
                Text(
                    text = col.label,
                    fontSize = 9.sp,
                    fontWeight = FontWeight.Bold,
                    color = headerText,
                    textAlign = when (col.key) {
                        "quantity", "unit", "hsn", "batch_no", "hours" -> TextAlign.Center
                        "unitPrice", "total", "discountRate", "charges", "expense" -> TextAlign.End
                        else -> TextAlign.Start
                    },
                    modifier = Modifier.weight(col.widthWeight)
                )
            }
        }

        // Table Rows
        items.forEachIndexed { idx, item ->
            val rowBg = if (idx % 2 == 0) Color.White else Color(0xFFF8FAFC)
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(rowBg)
                    .padding(horizontal = 8.dp, vertical = 5.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                visibleCols.forEach { col ->
                    val textVal = when (col.key) {
                        "description" -> item.description.ifBlank { "Item ${idx + 1}" }
                        "quantity" -> if (item.quantity % 1.0 == 0.0) item.quantity.toInt().toString() else item.quantity.toString()
                        "unit" -> item.unit
                        "unitPrice" -> "$currencySymbol${String.format(Locale.US, "%,.2f", item.unitPrice)}"
                        "discountRate" -> if (item.discountRate > 0) "${item.discountRate}%" else "-"
                        "taxRate" -> if (item.taxRate > 0) "${item.taxRate}%" else "-"
                        "total" -> "$currencySymbol${String.format(Locale.US, "%,.2f", item.total)}"
                        else -> item.customFields[col.key] ?: "-"
                    }

                    Text(
                        text = textVal,
                        fontSize = 10.sp,
                        color = if (col.key == "total") PrimaryNavy else Color(0xFF334155),
                        fontWeight = if (col.key == "total" || col.key == "description") FontWeight.SemiBold else FontWeight.Normal,
                        textAlign = when (col.key) {
                            "quantity", "unit", "hsn", "batch_no", "hours" -> TextAlign.Center
                            "unitPrice", "total", "discountRate", "charges", "expense" -> TextAlign.End
                            else -> TextAlign.Start
                        },
                        modifier = Modifier.weight(col.widthWeight)
                    )
                }
            }
            if (idx < items.size - 1) {
                HorizontalDivider(color = Color(0xFFF1F5F9), thickness = 0.5.dp)
            }
        }
    }
}

@Composable
private fun RenderTotalsSection(
    calculations: InvoiceCalculations,
    currencySymbol: String,
    currencyCode: String,
    taxLabel: String,
    taxRate: Double,
    isTaxInclusive: Boolean,
    paymentInstructions: String
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.Top
    ) {
        // Left: Amount in words & Bank instructions
        Column(modifier = Modifier.weight(1.1f)) {
            Surface(
                color = Color(0xFFF8FAFC),
                shape = RoundedCornerShape(4.dp),
                border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFFE2E8F0))
            ) {
                Column(modifier = Modifier.padding(6.dp)) {
                    Text("TOTAL IN WORDS", fontSize = 8.sp, fontWeight = FontWeight.Bold, color = Color(0xFF64748B))
                    Text(
                        text = InvoiceUtils.amountInWords(calculations.grandTotal, currencyCode),
                        fontSize = 9.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = PrimaryNavy
                    )
                }
            }

            if (paymentInstructions.isNotBlank()) {
                Spacer(modifier = Modifier.height(6.dp))
                Text("PAYMENT INSTRUCTIONS", fontSize = 8.sp, fontWeight = FontWeight.Bold, color = Color(0xFF94A3B8))
                Text(text = paymentInstructions, fontSize = 8.sp, color = Color(0xFF475569))
            }
        }

        Spacer(modifier = Modifier.width(14.dp))

        // Right: Financial Summary Breakdown
        Column(modifier = Modifier.weight(1f)) {
            PreviewSummaryRow("Subtotal", "$currencySymbol${String.format(Locale.US, "%,.2f", calculations.subtotal)}")

            if (calculations.discountTotal > 0) {
                PreviewSummaryRow("Discount", "-$currencySymbol${String.format(Locale.US, "%,.2f", calculations.discountTotal)}", Color(0xFF059669))
            }

            if (calculations.shipping > 0) {
                PreviewSummaryRow("Shipping", "$currencySymbol${String.format(Locale.US, "%,.2f", calculations.shipping)}")
            }

            if (calculations.additionalCharges > 0) {
                PreviewSummaryRow("Additional Charges", "$currencySymbol${String.format(Locale.US, "%,.2f", calculations.additionalCharges)}")
            }

            PreviewSummaryRow(
                "$taxLabel (${taxRate}%) ${if (isTaxInclusive) "(Incl)" else ""}",
                "$currencySymbol${String.format(Locale.US, "%,.2f", calculations.taxTotal)}"
            )

            if (calculations.roundOff != 0.0) {
                PreviewSummaryRow("Round Off", "$currencySymbol${String.format(Locale.US, "%,.2f", calculations.roundOff)}")
            }

            HorizontalDivider(modifier = Modifier.padding(vertical = 3.dp), color = Color(0xFFCBD5E1), thickness = 1.dp)

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("Grand Total", fontSize = 12.sp, fontWeight = FontWeight.Bold, color = PrimaryNavy)
                Text(
                    text = "$currencySymbol${String.format(Locale.US, "%,.2f", calculations.grandTotal)}",
                    fontSize = 14.sp,
                    fontWeight = FontWeight.ExtraBold,
                    color = PrimaryNavy
                )
            }
        }
    }
}

@Composable
private fun RenderFooterSection(
    notes: String,
    terms: String,
    notesLabel: String,
    termsLabel: String,
    profile: BusinessProfile
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.Bottom
    ) {
        Column(modifier = Modifier.weight(1.2f)) {
            if (notes.isNotBlank()) {
                Text(notesLabel.uppercase(), fontSize = 8.sp, fontWeight = FontWeight.Bold, color = Color(0xFF94A3B8))
                Text(notes, fontSize = 8.sp, color = Color(0xFF475569))
                Spacer(modifier = Modifier.height(4.dp))
            }
            if (terms.isNotBlank()) {
                Text(termsLabel.uppercase(), fontSize = 8.sp, fontWeight = FontWeight.Bold, color = Color(0xFF94A3B8))
                Text(terms, fontSize = 8.sp, color = Color(0xFF64748B))
            }
        }

        Spacer(modifier = Modifier.width(12.dp))

        // Signatory & Stamp
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.weight(0.9f)
        ) {
            if (profile.showStamp) {
                Surface(
                    color = Color(0xFFEFF6FF),
                    shape = RoundedCornerShape(6.dp),
                    border = androidx.compose.foundation.BorderStroke(1.dp, Color(0xFF1E3A8A)),
                    modifier = Modifier.padding(bottom = 4.dp)
                ) {
                    Text(
                        text = profile.stampText.ifBlank { "OFFICIAL SEAL" },
                        fontSize = 8.sp,
                        fontWeight = FontWeight.Black,
                        color = Color(0xFF1E3A8A),
                        modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp)
                    )
                }
            }

            if (profile.showSignature) {
                Text(
                    text = profile.signeeName.ifBlank { "Authorized Signature" },
                    fontSize = 12.sp,
                    fontWeight = FontWeight.SemiBold,
                    fontStyle = androidx.compose.ui.text.font.FontStyle.Italic,
                    color = Color(0xFF1E3A8A)
                )
                HorizontalDivider(modifier = Modifier.width(90.dp), color = Color(0xFF94A3B8), thickness = 0.8.dp)
                Text(
                    text = profile.signeeTitle.ifBlank { "Authorized Signatory" },
                    fontSize = 8.sp,
                    color = Color(0xFF64748B)
                )
            }
        }
    }
}

@Composable
private fun PreviewSummaryRow(label: String, value: String, valueColor: Color = Color(0xFF1E293B)) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 1.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(text = label, fontSize = 9.sp, color = Color(0xFF64748B))
        Text(text = value, fontSize = 9.sp, fontWeight = FontWeight.SemiBold, color = valueColor)
    }
}
