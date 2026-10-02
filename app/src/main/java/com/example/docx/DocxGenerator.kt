package com.example.docx

import android.content.Context
import com.example.data.model.BusinessProfile
import com.example.data.model.InvoiceCalculations
import com.example.data.model.InvoiceEntity
import com.example.data.model.InvoiceItem
import com.example.data.model.InvoiceUtils
import com.example.data.model.TemplateConfig
import java.io.File
import java.io.FileOutputStream
import java.nio.charset.StandardCharsets
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream

object DocxGenerator {

    private fun escapeXml(text: String?): String {
        if (text == null) return ""
        return text
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace("\"", "&quot;")
            .replace("'", "&apos;")
    }

    private fun colorHexToDocx(hex: String): String {
        return hex.removePrefix("#").uppercase()
    }

    /**
     * Generates a genuine .docx file from the invoice, business profile, and template config.
     * Returns the created File.
     */
    fun generateInvoiceDocx(
        context: Context,
        invoice: InvoiceEntity,
        items: List<InvoiceItem>,
        profile: BusinessProfile,
        templateConfig: TemplateConfig,
        calculations: InvoiceCalculations
    ): File {
        val safeInvoiceNum = invoice.invoiceNumber.replace("[^a-zA-Z0-9_-]".toRegex(), "_")
        val fileName = "${safeInvoiceNum}_Invoice.docx"
        val outDir = File(context.cacheDir, "invoices")
        if (!outDir.exists()) outDir.mkdirs()
        val docxFile = File(outDir, fileName)

        val brandHex = colorHexToDocx(templateConfig.primaryColorHex)
        val secondaryHex = colorHexToDocx(templateConfig.secondaryColorHex)

        val contentTypesXml = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>""".trimIndent()

        val rootRelsXml = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>""".trimIndent()

        val docRelsXml = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>""".trimIndent()

        val stylesXml = """<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults>
    <w:rPrDefault>
      <w:rPr>
        <w:rFonts w:ascii="${templateConfig.fontStyle}" w:hAnsi="${templateConfig.fontStyle}"/>
        <w:sz w:val="22"/>
        <w:color w:val="1E293B"/>
      </w:rPr>
    </w:rPrDefault>
    <w:pPrDefault>
      <w:pPr>
        <w:spacing w:after="120" w:line="240" w:lineRule="auto"/>
      </w:pPr>
    </w:pPrDefault>
  </w:docDefaults>
</w:styles>""".trimIndent()

        val documentXml = buildDocumentXml(
            invoice = invoice,
            items = items,
            profile = profile,
            templateConfig = templateConfig,
            calculations = calculations,
            brandHex = brandHex,
            secondaryHex = secondaryHex
        )

        FileOutputStream(docxFile).use { fos ->
            ZipOutputStream(fos).use { zos ->
                addZipEntry(zos, "[Content_Types].xml", contentTypesXml)
                addZipEntry(zos, "_rels/.rels", rootRelsXml)
                addZipEntry(zos, "word/_rels/document.xml.rels", docRelsXml)
                addZipEntry(zos, "word/styles.xml", stylesXml)
                addZipEntry(zos, "word/document.xml", documentXml)
            }
        }

        return docxFile
    }

    private fun addZipEntry(zos: ZipOutputStream, entryName: String, content: String) {
        val entry = ZipEntry(entryName)
        zos.putNextEntry(entry)
        val bytes = content.toByteArray(StandardCharsets.UTF_8)
        zos.write(bytes)
        zos.closeEntry()
    }

    private fun buildDocumentXml(
        invoice: InvoiceEntity,
        items: List<InvoiceItem>,
        profile: BusinessProfile,
        templateConfig: TemplateConfig,
        calculations: InvoiceCalculations,
        brandHex: String,
        secondaryHex: String
    ): String {
        val sb = StringBuilder()
        sb.append("""<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
""")

        // Header Table with Business Details on Left and Invoice Meta on Right
        sb.append("""
    <!-- Top Header Table -->
    <w:tbl>
      <w:tblPr>
        <w:tblW w:w="9360" w:type="dxa"/>
        <w:tblBorders>
          <w:top w:val="none"/>
          <w:left w:val="none"/>
          <w:bottom w:val="single" w:sz="12" w:color="$brandHex"/>
          <w:right w:val="none"/>
          <w:insideH w:val="none"/>
          <w:insideV w:val="none"/>
        </w:tblBorders>
      </w:tblPr>
      <w:tr>
        <!-- Business Info Left -->
        <w:tc>
          <w:tcPr><w:tcW w:w="5200" w:type="dxa"/></w:tcPr>
          <w:p>
            <w:r>
              <w:rPr>
                <w:b/>
                <w:sz w:val="36"/>
                <w:color w:val="$brandHex"/>
              </w:rPr>
              <w:t>${escapeXml(profile.businessName)}</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr><w:spacing w:after="40"/></w:pPr>
            <w:r>
              <w:rPr><w:sz w:val="18"/><w:color w:val="64748B"/></w:rPr>
              <w:t>${escapeXml(profile.legalName)}</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr><w:spacing w:after="40"/></w:pPr>
            <w:r>
              <w:rPr><w:sz w:val="18"/><w:color w:val="475569"/></w:rPr>
              <w:t>${escapeXml(profile.address.replace("\n", ", "))}</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr><w:spacing w:after="40"/></w:pPr>
            <w:r>
              <w:rPr><w:sz w:val="18"/><w:color w:val="475569"/></w:rPr>
              <w:t>Email: ${escapeXml(profile.email)} | Phone: ${escapeXml(profile.phone)}</w:t>
            </w:r>
          </w:p>
""")
        if (profile.gstin.isNotBlank()) {
            sb.append("""
          <w:p>
            <w:pPr><w:spacing w:after="40"/></w:pPr>
            <w:r>
              <w:rPr><w:b/><w:sz w:val="18"/><w:color w:val="$brandHex"/></w:rPr>
              <w:t>GSTIN: ${escapeXml(profile.gstin)} | PAN: ${escapeXml(profile.panNumber)}</w:t>
            </w:r>
          </w:p>
""")
        } else if (profile.taxId.isNotBlank()) {
            sb.append("""
          <w:p>
            <w:pPr><w:spacing w:after="40"/></w:pPr>
            <w:r>
              <w:rPr><w:sz w:val="18"/><w:color w:val="475569"/></w:rPr>
              <w:t>Tax / VAT ID: ${escapeXml(profile.taxId)}</w:t>
            </w:r>
          </w:p>
""")
        }
        if (profile.placeOfSupply.isNotBlank()) {
            sb.append("""
          <w:p>
            <w:pPr><w:spacing w:after="120"/></w:pPr>
            <w:r>
              <w:rPr><w:sz w:val="18"/><w:color w:val="475569"/></w:rPr>
              <w:t>Place of Supply: ${escapeXml(profile.placeOfSupply)}</w:t>
            </w:r>
          </w:p>
""")
        }

        sb.append("""
        </w:tc>
        <!-- Invoice Title & Info Right -->
        <w:tc>
          <w:tcPr><w:tcW w:w="4160" w:type="dxa"/></w:tcPr>
          <w:p>
            <w:pPr><w:jc w:val="right"/></w:pPr>
            <w:r>
              <w:rPr>
                <w:b/>
                <w:sz w:val="46"/>
                <w:color w:val="$brandHex"/>
              </w:rPr>
              <w:t>${escapeXml(templateConfig.docxTitle)}</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr><w:jc w:val="right"/><w:spacing w:after="40"/></w:pPr>
            <w:r>
              <w:rPr><w:b/><w:sz w:val="22"/><w:color w:val="0F172A"/></w:rPr>
              <w:t>${escapeXml(invoice.invoiceNumber)}</w:t>
            </w:r>
          </w:p>
""")

        if (profile.showPoNumber && invoice.poNumber.isNotBlank()) {
            sb.append("""
          <w:p>
            <w:pPr><w:jc w:val="right"/><w:spacing w:after="40"/></w:pPr>
            <w:r>
              <w:rPr><w:sz w:val="18"/><w:color w:val="64748B"/></w:rPr>
              <w:t>PO #: </w:t>
            </w:r>
            <w:r>
              <w:rPr><w:b/><w:sz w:val="18"/><w:color w:val="0F172A"/></w:rPr>
              <w:t>${escapeXml(invoice.poNumber)}</w:t>
            </w:r>
          </w:p>
""")
        }

        if (profile.showIssueDate) {
            sb.append("""
          <w:p>
            <w:pPr><w:jc w:val="right"/><w:spacing w:after="40"/></w:pPr>
            <w:r>
              <w:rPr><w:sz w:val="18"/><w:color w:val="64748B"/></w:rPr>
              <w:t>Issue Date: </w:t>
            </w:r>
            <w:r>
              <w:rPr><w:b/><w:sz w:val="18"/><w:color w:val="1E293B"/></w:rPr>
              <w:t>${escapeXml(invoice.issueDate)}</w:t>
            </w:r>
          </w:p>
""")
        }

        if (profile.showDueDate) {
            sb.append("""
          <w:p>
            <w:pPr><w:jc w:val="right"/><w:spacing w:after="40"/></w:pPr>
            <w:r>
              <w:rPr><w:sz w:val="18"/><w:color w:val="64748B"/></w:rPr>
              <w:t>Due Date: </w:t>
            </w:r>
            <w:r>
              <w:rPr><w:b/><w:sz w:val="18"/><w:color w:val="DC2626"/></w:rPr>
              <w:t>${escapeXml(invoice.dueDate)}</w:t>
            </w:r>
          </w:p>
""")
        }

        if (profile.showPaymentTerms || profile.showStatus) {
            val termsPart = if (profile.showPaymentTerms) "Terms: ${escapeXml(invoice.paymentTerms)}" else ""
            val statusPart = if (profile.showStatus) "Status: ${escapeXml(invoice.status.uppercase())}" else ""
            val separator = if (termsPart.isNotBlank() && statusPart.isNotBlank()) " | " else ""

            sb.append("""
          <w:p>
            <w:pPr><w:jc w:val="right"/><w:spacing w:after="160"/></w:pPr>
            <w:r>
              <w:rPr><w:sz w:val="18"/><w:color w:val="64748B"/></w:rPr>
              <w:t>${termsPart}${separator}</w:t>
            </w:r>
            <w:r>
              <w:rPr><w:b/><w:sz w:val="18"/><w:color w:val="$brandHex"/></w:rPr>
              <w:t>${statusPart}</w:t>
            </w:r>
          </w:p>
""")
        }

        sb.append("""
        </w:tc>
      </w:tr>
    </w:tbl>
""")

        // Spacer
        sb.append("<w:p><w:pPr><w:spacing w:before=\"160\" w:after=\"160\"/></w:pPr></w:p>")

        // Bill To & Invoice Summary Block
        sb.append("""
    <!-- Bill To Block -->
    <w:tbl>
      <w:tblPr>
        <w:tblW w:w="9360" w:type="dxa"/>
        <w:tblBorders>
          <w:top w:val="none"/>
          <w:left w:val="none"/>
          <w:bottom w:val="none"/>
          <w:right w:val="none"/>
          <w:insideH w:val="none"/>
          <w:insideV w:val="none"/>
        </w:tblBorders>
      </w:tblPr>
      <w:tr>
        <w:tc>
          <w:tcPr>
            <w:tcW w:w="4680" w:type="dxa"/>
            <w:shd w:fill="F8FAFC"/>
            <w:tcMar>
              <w:top w:w="120" w:type="dxa"/>
              <w:left w:w="160" w:type="dxa"/>
              <w:bottom w:w="120" w:type="dxa"/>
              <w:right w:w="160" w:type="dxa"/>
            </w:tcMar>
          </w:tcPr>
          <w:p>
            <w:r>
              <w:rPr><w:b/><w:sz w:val="18"/><w:color w:val="$brandHex"/></w:rPr>
              <w:t>BILLED TO:</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:r>
              <w:rPr><w:b/><w:sz w:val="24"/><w:color w:val="0F172A"/></w:rPr>
              <w:t>${escapeXml(invoice.clientName)}</w:t>
            </w:r>
          </w:p>
""")
        if (invoice.clientCompany.isNotBlank()) {
            sb.append("""
          <w:p>
            <w:r>
              <w:rPr><w:sz w:val="20"/><w:color w:val="475569"/></w:rPr>
              <w:t>${escapeXml(invoice.clientCompany)}</w:t>
            </w:r>
          </w:p>
""")
        }
        if (invoice.clientAddress.isNotBlank()) {
            sb.append("""
          <w:p>
            <w:r>
              <w:rPr><w:sz w:val="18"/><w:color w:val="64748B"/></w:rPr>
              <w:t>${escapeXml(invoice.clientAddress.replace("\n", ", "))}</w:t>
            </w:r>
          </w:p>
""")
        }
        if (invoice.clientEmail.isNotBlank() || invoice.clientPhone.isNotBlank()) {
            sb.append("""
          <w:p>
            <w:r>
              <w:rPr><w:sz w:val="18"/><w:color w:val="64748B"/></w:rPr>
              <w:t>${escapeXml(invoice.clientEmail)} ${if (invoice.clientPhone.isNotBlank()) "| " + escapeXml(invoice.clientPhone) else ""}</w:t>
            </w:r>
          </w:p>
""")
        }
        if (invoice.clientTaxId.isNotBlank()) {
            sb.append("""
          <w:p>
            <w:r>
              <w:rPr><w:sz w:val="18"/><w:color w:val="64748B"/></w:rPr>
              <w:t>Client GSTIN / Tax ID: ${escapeXml(invoice.clientTaxId)}</w:t>
            </w:r>
          </w:p>
""")
        }

        sb.append("""
        </w:tc>
        <w:tc>
          <w:tcPr>
            <w:tcW w:w="4680" w:type="dxa"/>
            <w:shd w:fill="F1F5F9"/>
            <w:tcMar>
              <w:top w:w="120" w:type="dxa"/>
              <w:left w:w="160" w:type="dxa"/>
              <w:bottom w:w="120" w:type="dxa"/>
              <w:right w:w="160" w:type="dxa"/>
            </w:tcMar>
          </w:tcPr>
          <w:p>
            <w:r>
              <w:rPr><w:b/><w:sz w:val="18"/><w:color w:val="$secondaryHex"/></w:rPr>
              <w:t>INVOICE SUMMARY:</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:r>
              <w:rPr><w:sz w:val="18"/><w:color w:val="475569"/></w:rPr>
              <w:t>Currency: </w:t>
            </w:r>
            <w:r>
              <w:rPr><w:b/><w:sz w:val="18"/><w:color w:val="0F172A"/></w:rPr>
              <w:t>${escapeXml(invoice.currencyCode)} (${escapeXml(invoice.currencySymbol)})</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:r>
              <w:rPr><w:sz w:val="18"/><w:color w:val="475569"/></w:rPr>
              <w:t>Total Balance Due: </w:t>
            </w:r>
            <w:r>
              <w:rPr><w:b/><w:sz w:val="28"/><w:color w:val="$brandHex"/></w:rPr>
              <w:t>${escapeXml(InvoiceUtils.formatMoney(calculations.balanceDue, invoice.currencySymbol))}</w:t>
            </w:r>
          </w:p>
        </w:tc>
      </w:tr>
    </w:tbl>
""")

        // Spacer
        sb.append("<w:p><w:pPr><w:spacing w:before=\"200\" w:after=\"120\"/></w:pPr></w:p>")

        // Custom Column Names - User editable for all in Settings (e.g. Salary vs Price, Hours vs Qty)
        val colItem = profile.colHeaderItem.ifBlank { templateConfig.colHeaderItem }
        val colQty = profile.colHeaderQty.ifBlank { templateConfig.colHeaderQty }
        val colUnit = profile.colHeaderUnit.ifBlank { templateConfig.colHeaderUnit }
        val colRate = profile.colHeaderRate.ifBlank { templateConfig.colHeaderRate }
        val colAmount = profile.colHeaderAmount.ifBlank { templateConfig.colHeaderAmount }

        val showUnit = profile.showItemUnit
        val showQty = profile.showItemQty
        val showRate = profile.showItemRate

        // Determine column widths
        val itemColWidth = when {
            !showUnit && !showQty && !showRate -> 6500
            !showUnit && showQty && showRate -> 4800
            showUnit && showQty && showRate -> 4200
            else -> 4800
        }

        // Line Items Table
        sb.append("""
    <!-- Line Items Table -->
    <w:tbl>
      <w:tblPr>
        <w:tblW w:w="9360" w:type="dxa"/>
        <w:tblBorders>
          <w:top w:val="single" w:sz="6" w:color="CBD5E1"/>
          <w:left w:val="none"/>
          <w:bottom w:val="single" w:sz="8" w:color="$brandHex"/>
          <w:right w:val="none"/>
          <w:insideH w:val="single" w:sz="4" w:color="E2E8F0"/>
          <w:insideV w:val="none"/>
        </w:tblBorders>
      </w:tblPr>

      <!-- Table Header Row -->
      <w:tr>
        <w:tc>
          <w:tcPr>
            <w:tcW w:w="$itemColWidth" w:type="dxa"/>
            <w:shd w:fill="$brandHex"/>
            <w:tcMar><w:top w:w="120" w:type="dxa"/><w:left w:w="120" w:type="dxa"/><w:bottom w:w="120" w:type="dxa"/></w:tcMar>
          </w:tcPr>
          <w:p>
            <w:r>
              <w:rPr><w:b/><w:sz w:val="18"/><w:color w:val="FFFFFF"/></w:rPr>
              <w:t>${escapeXml(colItem)}</w:t>
            </w:r>
          </w:p>
        </w:tc>
""")

        if (showQty) {
            sb.append("""
        <w:tc>
          <w:tcPr>
            <w:tcW w:w="1200" w:type="dxa"/>
            <w:shd w:fill="$brandHex"/>
            <w:tcMar><w:top w:w="120" w:type="dxa"/><w:right w:w="120" w:type="dxa"/><w:bottom w:w="120" w:type="dxa"/></w:tcMar>
          </w:tcPr>
          <w:p>
            <w:pPr><w:jc w:val="right"/></w:pPr>
            <w:r>
              <w:rPr><w:b/><w:sz w:val="18"/><w:color w:val="FFFFFF"/></w:rPr>
              <w:t>${escapeXml(colQty)}</w:t>
            </w:r>
          </w:p>
        </w:tc>
""")
        }

        if (showUnit) {
            sb.append("""
        <w:tc>
          <w:tcPr>
            <w:tcW w:w="1000" w:type="dxa"/>
            <w:shd w:fill="$brandHex"/>
            <w:tcMar><w:top w:w="120" w:type="dxa"/><w:right w:w="120" w:type="dxa"/><w:bottom w:w="120" w:type="dxa"/></w:tcMar>
          </w:tcPr>
          <w:p>
            <w:pPr><w:jc w:val="center"/></w:pPr>
            <w:r>
              <w:rPr><w:b/><w:sz w:val="18"/><w:color w:val="FFFFFF"/></w:rPr>
              <w:t>${escapeXml(colUnit)}</w:t>
            </w:r>
          </w:p>
        </w:tc>
""")
        }

        if (showRate) {
            sb.append("""
        <w:tc>
          <w:tcPr>
            <w:tcW w:w="1400" w:type="dxa"/>
            <w:shd w:fill="$brandHex"/>
            <w:tcMar><w:top w:w="120" w:type="dxa"/><w:right w:w="120" w:type="dxa"/><w:bottom w:w="120" w:type="dxa"/></w:tcMar>
          </w:tcPr>
          <w:p>
            <w:pPr><w:jc w:val="right"/></w:pPr>
            <w:r>
              <w:rPr><w:b/><w:sz w:val="18"/><w:color w:val="FFFFFF"/></w:rPr>
              <w:t>${escapeXml(colRate)}</w:t>
            </w:r>
          </w:p>
        </w:tc>
""")
        }

        sb.append("""
        <w:tc>
          <w:tcPr>
            <w:tcW w:w="1560" w:type="dxa"/>
            <w:shd w:fill="$brandHex"/>
            <w:tcMar><w:top w:w="120" w:type="dxa"/><w:right w:w="120" w:type="dxa"/><w:bottom w:w="120" w:type="dxa"/></w:tcMar>
          </w:tcPr>
          <w:p>
            <w:pPr><w:jc w:val="right"/></w:pPr>
            <w:r>
              <w:rPr><w:b/><w:sz w:val="18"/><w:color w:val="FFFFFF"/></w:rPr>
              <w:t>${escapeXml(colAmount)}</w:t>
            </w:r>
          </w:p>
        </w:tc>
      </w:tr>
""")

        // Item Rows
        for ((index, item) in items.withIndex()) {
            val rowShade = if (index % 2 == 1) "F8FAFC" else "FFFFFF"
            val qtyStr = if (item.quantity % 1.0 == 0.0) item.quantity.toInt().toString() else item.quantity.toString()
            val unitStr = item.unit
            val rateFormatted = InvoiceUtils.formatMoney(item.unitPrice, invoice.currencySymbol)
            val lineTotalFormatted = InvoiceUtils.formatMoney(item.total, invoice.currencySymbol)

            sb.append("""
      <w:tr>
        <w:tc>
          <w:tcPr>
            <w:tcW w:w="$itemColWidth" w:type="dxa"/>
            <w:shd w:fill="$rowShade"/>
            <w:tcMar><w:top w:w="100" w:type="dxa"/><w:left w:w="120" w:type="dxa"/><w:bottom w:w="100" w:type="dxa"/></w:tcMar>
          </w:tcPr>
          <w:p>
            <w:r>
              <w:rPr><w:sz w:val="20"/><w:color w:val="0F172A"/></w:rPr>
              <w:t>${escapeXml(item.description)}</w:t>
            </w:r>
          </w:p>
        </w:tc>
""")

            if (showQty) {
                sb.append("""
        <w:tc>
          <w:tcPr>
            <w:tcW w:w="1200" w:type="dxa"/>
            <w:shd w:fill="$rowShade"/>
            <w:tcMar><w:top w:w="100" w:type="dxa"/><w:right w:w="120" w:type="dxa"/><w:bottom w:w="100" w:type="dxa"/></w:tcMar>
          </w:tcPr>
          <w:p>
            <w:pPr><w:jc w:val="right"/></w:pPr>
            <w:r>
              <w:rPr><w:sz w:val="20"/><w:color w:val="334155"/></w:rPr>
              <w:t>${escapeXml(qtyStr)}</w:t>
            </w:r>
          </w:p>
        </w:tc>
""")
            }

            if (showUnit) {
                sb.append("""
        <w:tc>
          <w:tcPr>
            <w:tcW w:w="1000" w:type="dxa"/>
            <w:shd w:fill="$rowShade"/>
            <w:tcMar><w:top w:w="100" w:type="dxa"/><w:right w:w="120" w:type="dxa"/><w:bottom w:w="100" w:type="dxa"/></w:tcMar>
          </w:tcPr>
          <w:p>
            <w:pPr><w:jc w:val="center"/></w:pPr>
            <w:r>
              <w:rPr><w:sz w:val="18"/><w:color w:val="64748B"/></w:rPr>
              <w:t>${escapeXml(unitStr)}</w:t>
            </w:r>
          </w:p>
        </w:tc>
""")
            }

            if (showRate) {
                sb.append("""
        <w:tc>
          <w:tcPr>
            <w:tcW w:w="1400" w:type="dxa"/>
            <w:shd w:fill="$rowShade"/>
            <w:tcMar><w:top w:w="100" w:type="dxa"/><w:right w:w="120" w:type="dxa"/><w:bottom w:w="100" w:type="dxa"/></w:tcMar>
          </w:tcPr>
          <w:p>
            <w:pPr><w:jc w:val="right"/></w:pPr>
            <w:r>
              <w:rPr><w:sz w:val="20"/><w:color w:val="334155"/></w:rPr>
              <w:t>${escapeXml(rateFormatted)}</w:t>
            </w:r>
          </w:p>
        </w:tc>
""")
            }

            sb.append("""
        <w:tc>
          <w:tcPr>
            <w:tcW w:w="1560" w:type="dxa"/>
            <w:shd w:fill="$rowShade"/>
            <w:tcMar><w:top w:w="100" w:type="dxa"/><w:right w:w="120" w:type="dxa"/><w:bottom w:w="100" w:type="dxa"/></w:tcMar>
          </w:tcPr>
          <w:p>
            <w:pPr><w:jc w:val="right"/></w:pPr>
            <w:r>
              <w:rPr><w:b/><w:sz w:val="20"/><w:color w:val="0F172A"/></w:rPr>
              <w:t>${escapeXml(lineTotalFormatted)}</w:t>
            </w:r>
          </w:p>
        </w:tc>
      </w:tr>
""")
        }

        sb.append("    </w:tbl>")

        // Totals Calculation Block
        sb.append("""
    <w:p><w:pPr><w:spacing w:before="120" w:after="80"/></w:pPr></w:p>
    <w:tbl>
      <w:tblPr>
        <w:tblW w:w="9360" w:type="dxa"/>
        <w:tblBorders>
          <w:top w:val="none"/>
          <w:left w:val="none"/>
          <w:bottom w:val="none"/>
          <w:right w:val="none"/>
          <w:insideH w:val="none"/>
          <w:insideV w:val="none"/>
        </w:tblBorders>
      </w:tblPr>
      <w:tr>
        <!-- Left Notes & Payment Info -->
        <w:tc>
          <w:tcPr><w:tcW w:w="5200" w:type="dxa"/></w:tcPr>
""")

        if (profile.showAmountInWords) {
            val words = InvoiceUtils.amountInWords(calculations.grandTotal, invoice.currencyCode)
            sb.append("""
          <w:p>
            <w:r>
              <w:rPr><w:b/><w:sz w:val="18"/><w:color w:val="$brandHex"/></w:rPr>
              <w:t>AMOUNT IN WORDS:</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr><w:spacing w:after="100"/></w:pPr>
            <w:r>
              <w:rPr><w:i/><w:sz w:val="18"/><w:color w:val="0F172A"/></w:rPr>
              <w:t>${escapeXml(words)}</w:t>
            </w:r>
          </w:p>
""")
        }

        if (templateConfig.showPaymentInstructions) {
            sb.append("""
          <w:p>
            <w:r>
              <w:rPr><w:b/><w:sz w:val="18"/><w:color w:val="$brandHex"/></w:rPr>
              <w:t>BANK &amp; PAYMENT DETAILS:</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:pPr><w:spacing w:after="20"/></w:pPr>
            <w:r>
              <w:rPr><w:sz w:val="18"/><w:color w:val="475569"/></w:rPr>
              <w:t>Bank: ${escapeXml(profile.bankName)} | A/C: ${escapeXml(profile.accountNumber)}</w:t>
            </w:r>
          </w:p>
""")
            if (profile.ifscCode.isNotBlank()) {
                sb.append("""
          <w:p>
            <w:pPr><w:spacing w:after="20"/></w:pPr>
            <w:r>
              <w:rPr><w:sz w:val="18"/><w:color w:val="475569"/></w:rPr>
              <w:t>IFSC Code: ${escapeXml(profile.ifscCode)} | Branch: ${escapeXml(profile.branchName)}</w:t>
            </w:r>
          </w:p>
""")
            }
            if (profile.upiId.isNotBlank()) {
                sb.append("""
          <w:p>
            <w:pPr><w:spacing w:after="40"/></w:pPr>
            <w:r>
              <w:rPr><w:b/><w:sz w:val="18"/><w:color w:val="$brandHex"/></w:rPr>
              <w:t>UPI ID (GPay / PhonePe / Paytm): ${escapeXml(profile.upiId)}</w:t>
            </w:r>
          </w:p>
""")
            }
        }

        if (invoice.notes.isNotBlank()) {
            sb.append("""
          <w:p>
            <w:pPr><w:spacing w:before="60"/></w:pPr>
            <w:r>
              <w:rPr><w:b/><w:sz w:val="18"/><w:color w:val="475569"/></w:rPr>
              <w:t>Notes: </w:t>
            </w:r>
            <w:r>
              <w:rPr><w:sz w:val="18"/><w:color w:val="64748B"/></w:rPr>
              <w:t>${escapeXml(invoice.notes)}</w:t>
            </w:r>
          </w:p>
""")
        }

        sb.append("""
        </w:tc>
        <!-- Right Totals Table -->
        <w:tc>
          <w:tcPr><w:tcW w:w="4160" w:type="dxa"/></w:tcPr>
          <!-- Subtotal -->
          <w:p>
            <w:pPr><w:jc w:val="right"/><w:spacing w:after="40"/></w:pPr>
            <w:r>
              <w:rPr><w:sz w:val="20"/><w:color w:val="64748B"/></w:rPr>
              <w:t>Subtotal: </w:t>
            </w:r>
            <w:r>
              <w:rPr><w:b/><w:sz w:val="20"/><w:color w:val="0F172A"/></w:rPr>
              <w:t>${escapeXml(InvoiceUtils.formatMoney(calculations.subtotal, invoice.currencySymbol))}</w:t>
            </w:r>
          </w:p>
""")

        if (calculations.discountTotal > 0) {
            sb.append("""
          <w:p>
            <w:pPr><w:jc w:val="right"/><w:spacing w:after="40"/></w:pPr>
            <w:r>
              <w:rPr><w:sz w:val="20"/><w:color w:val="059669"/></w:rPr>
              <w:t>Discount: -</w:t>
            </w:r>
            <w:r>
              <w:rPr><w:b/><w:sz w:val="20"/><w:color w:val="059669"/></w:rPr>
              <w:t>${escapeXml(InvoiceUtils.formatMoney(calculations.discountTotal, invoice.currencySymbol))}</w:t>
            </w:r>
          </w:p>
""")
        }

        if (templateConfig.showTaxBreakdown && (calculations.taxTotal > 0 || invoice.taxRate > 0)) {
            if (profile.showGstBreakdown && profile.defaultCurrency == "INR") {
                val halfTax = calculations.taxTotal / 2.0
                val halfRate = invoice.taxRate / 2.0
                sb.append("""
          <w:p>
            <w:pPr><w:jc w:val="right"/><w:spacing w:after="20"/></w:pPr>
            <w:r><w:rPr><w:sz w:val="18"/><w:color w:val="64748B"/></w:rPr><w:t>CGST (${halfRate}%): </w:t></w:r>
            <w:r><w:rPr><w:b/><w:sz w:val="18"/><w:color w:val="0F172A"/></w:rPr><w:t>${escapeXml(InvoiceUtils.formatMoney(halfTax, invoice.currencySymbol))}</w:t></w:r>
          </w:p>
          <w:p>
            <w:pPr><w:jc w:val="right"/><w:spacing w:after="40"/></w:pPr>
            <w:r><w:rPr><w:sz w:val="18"/><w:color w:val="64748B"/></w:rPr><w:t>SGST (${halfRate}%): </w:t></w:r>
            <w:r><w:rPr><w:b/><w:sz w:val="18"/><w:color w:val="0F172A"/></w:rPr><w:t>${escapeXml(InvoiceUtils.formatMoney(halfTax, invoice.currencySymbol))}</w:t></w:r>
          </w:p>
""")
            } else {
                sb.append("""
          <w:p>
            <w:pPr><w:jc w:val="right"/><w:spacing w:after="40"/></w:pPr>
            <w:r>
              <w:rPr><w:sz w:val="20"/><w:color w:val="64748B"/></w:rPr>
              <w:t>${escapeXml(invoice.taxLabel)} (${invoice.taxRate}%): </w:t>
            </w:r>
            <w:r>
              <w:rPr><w:b/><w:sz w:val="20"/><w:color w:val="0F172A"/></w:rPr>
              <w:t>${escapeXml(InvoiceUtils.formatMoney(calculations.taxTotal, invoice.currencySymbol))}</w:t>
            </w:r>
          </w:p>
""")
            }
        }

        if (calculations.shipping > 0) {
            sb.append("""
          <w:p>
            <w:pPr><w:jc w:val="right"/><w:spacing w:after="40"/></w:pPr>
            <w:r>
              <w:rPr><w:sz w:val="20"/><w:color w:val="64748B"/></w:rPr>
              <w:t>Shipping &amp; Handling: </w:t>
            </w:r>
            <w:r>
              <w:rPr><w:b/><w:sz w:val="20"/><w:color w:val="0F172A"/></w:rPr>
              <w:t>${escapeXml(InvoiceUtils.formatMoney(calculations.shipping, invoice.currencySymbol))}</w:t>
            </w:r>
          </w:p>
""")
        }

        sb.append("""
          <!-- Grand Total -->
          <w:p>
            <w:pPr>
              <w:jc w:val="right"/>
              <w:spacing w:before="60" w:after="40"/>
            </w:pPr>
            <w:r>
              <w:rPr><w:b/><w:sz w:val="24"/><w:color w:val="$brandHex"/></w:rPr>
              <w:t>Total: </w:t>
            </w:r>
            <w:r>
              <w:rPr><w:b/><w:sz w:val="28"/><w:color w:val="$brandHex"/></w:rPr>
              <w:t>${escapeXml(InvoiceUtils.formatMoney(calculations.grandTotal, invoice.currencySymbol))}</w:t>
            </w:r>
          </w:p>
""")

        if (calculations.amountPaid > 0) {
            sb.append("""
          <w:p>
            <w:pPr><w:jc w:val="right"/><w:spacing w:after="40"/></w:pPr>
            <w:r>
              <w:rPr><w:sz w:val="20"/><w:color w:val="059669"/></w:rPr>
              <w:t>Amount Paid: </w:t>
            </w:r>
            <w:r>
              <w:rPr><w:b/><w:sz w:val="20"/><w:color w:val="059669"/></w:rPr>
              <w:t>${escapeXml(InvoiceUtils.formatMoney(calculations.amountPaid, invoice.currencySymbol))}</w:t>
            </w:r>
          </w:p>
""")
        }

        sb.append("""
          <!-- Balance Due Highlight -->
          <w:p>
            <w:pPr><w:jc w:val="right"/><w:spacing w:before="60"/></w:pPr>
            <w:r>
              <w:rPr><w:b/><w:sz w:val="24"/><w:color w:val="0F172A"/></w:rPr>
              <w:t>Balance Due: </w:t>
            </w:r>
            <w:r>
              <w:rPr><w:b/><w:sz w:val="28"/><w:color w:val="DC2626"/></w:rPr>
              <w:t>${escapeXml(InvoiceUtils.formatMoney(calculations.balanceDue, invoice.currencySymbol))}</w:t>
            </w:r>
          </w:p>
        </w:tc>
      </w:tr>
    </w:tbl>
""")

        // Terms and Signature Section
        if (invoice.terms.isNotBlank() || templateConfig.showSignature) {
            sb.append("<w:p><w:pPr><w:spacing w:before=\"240\" w:after=\"80\"/></w:pPr></w:p>")
            sb.append("""
    <w:tbl>
      <w:tblPr>
        <w:tblW w:w="9360" w:type="dxa"/>
        <w:tblBorders>
          <w:top w:val="single" w:sz="4" w:color="E2E8F0"/>
          <w:left w:val="none"/><w:bottom w:val="none"/><w:right w:val="none"/>
          <w:insideH w:val="none"/><w:insideV w:val="none"/>
        </w:tblBorders>
      </w:tblPr>
      <w:tr>
        <w:tc>
          <w:tcPr><w:tcW w:w="5600" w:type="dxa"/></w:tcPr>
""")
            if (invoice.terms.isNotBlank()) {
                sb.append("""
          <w:p>
            <w:r>
              <w:rPr><w:b/><w:sz w:val="18"/><w:color w:val="475569"/></w:rPr>
              <w:t>TERMS &amp; CONDITIONS:</w:t>
            </w:r>
          </w:p>
          <w:p>
            <w:r>
              <w:rPr><w:sz w:val="18"/><w:color w:val="64748B"/></w:rPr>
              <w:t>${escapeXml(invoice.terms)}</w:t>
            </w:r>
          </w:p>
""")
            }
            sb.append("""
        </w:tc>
        <w:tc>
          <w:tcPr><w:tcW w:w="3760" w:type="dxa"/></w:tcPr>
""")
            if (templateConfig.showSignature) {
                sb.append("""
          <w:p><w:pPr><w:jc w:val="right"/><w:spacing w:before="360" w:after="40"/></w:pPr>
            <w:r>
              <w:rPr><w:sz w:val="20"/><w:color w:val="94A3B8"/></w:rPr>
              <w:t>_____________________________</w:t>
            </w:r>
          </w:p>
          <w:p><w:pPr><w:jc w:val="right"/><w:spacing w:after="20"/></w:pPr>
            <w:r>
              <w:rPr><w:b/><w:sz w:val="20"/><w:color w:val="0F172A"/></w:rPr>
              <w:t>${escapeXml(profile.signeeName)}</w:t>
            </w:r>
          </w:p>
          <w:p><w:pPr><w:jc w:val="right"/></w:pPr>
            <w:r>
              <w:rPr><w:sz w:val="18"/><w:color w:val="64748B"/></w:rPr>
              <w:t>${escapeXml(profile.signeeTitle)} (For ${escapeXml(profile.businessName)})</w:t>
            </w:r>
          </w:p>
""")
            }
            sb.append("""
        </w:tc>
      </w:tr>
    </w:tbl>
""")
        }

        // Document Footer
        if (templateConfig.customFooterNote.isNotBlank()) {
            sb.append("""
    <w:p><w:pPr><w:jc w:val="center"/><w:spacing w:before="300"/></w:pPr>
      <w:r>
        <w:rPr><w:i/><w:sz w:val="18"/><w:color w:val="94A3B8"/></w:rPr>
        <w:t>${escapeXml(templateConfig.customFooterNote)}</w:t>
      </w:r>
    </w:p>
""")
        }

        sb.append("""
  </w:body>
</w:document>
""")
        return sb.toString()
    }
}
