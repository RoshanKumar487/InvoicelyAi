package com.example

import com.example.data.model.InvoiceItem
import com.example.data.model.InvoiceUtils
import com.example.docx.DocxTemplatePreset
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

@RunWith(RobolectricTestRunner::class)
class ExampleUnitTest {

    @Test
    fun testTenTemplatesExist() {
        assertEquals(10, DocxTemplatePreset.allTemplates.size)
        val gst = DocxTemplatePreset.getById("gst_tax")
        assertNotNull(gst)
        assertEquals("GST Standard Tax Invoice (Indian Biz)", gst.templateName)

        val zoho = DocxTemplatePreset.getById("zoho_elegance")
        assertNotNull(zoho)
        assertEquals("Zoho Invoice Clean", zoho.templateName)
    }

    @Test
    fun testInvoiceCalculations() {
        val items = listOf(
            InvoiceItem(description = "Consulting", quantity = 10.0, unitPrice = 1000.0),
            InvoiceItem(description = "Design", quantity = 2.0, unitPrice = 5000.0)
        )
        // Subtotal = 10*1000 + 2*5000 = 20,000
        val calcs = InvoiceUtils.calculateInvoice(
            items = items,
            taxRate = 18.0,
            discountPercent = 10.0, // 10% on 20000 = 2000 => taxable base = 18,000
            discountAmount = 0.0,
            shippingFee = 500.0,
            amountPaid = 5000.0
        )

        assertEquals(20000.0, calcs.subtotal, 0.01)
        assertEquals(2000.0, calcs.discountTotal, 0.01)
        // 18000 * 0.18 = 3240
        assertEquals(3240.0, calcs.taxTotal, 0.01)
        // 18000 + 3240 + 500 = 21740
        assertEquals(21740.0, calcs.grandTotal, 0.01)
        assertEquals(16740.0, calcs.balanceDue, 0.01)
    }

    @Test
    fun testAmountInWords() {
        val words = InvoiceUtils.amountInWords(25450.0, "INR")
        assertTrue(words.contains("Rupees Twenty-Five Thousand Four Hundred and Fifty"))
    }

    @Test
    fun testInvoiceDataClassStructureAndCalculations() {
        val item1 = InvoiceItem(
            description = "Software Architecture",
            quantity = 20.0,
            unitPrice = 100.0,
            unit = "hrs",
            taxRate = 18.0,
            discountRate = 10.0
        )
        // total = 20 * 100 * 0.9 = 1800.0
        assertEquals(1800.0, item1.total, 0.01)
        assertEquals(200.0, item1.discountAmount, 0.01)
        // tax = 1800 * 0.18 = 324.0
        assertEquals(324.0, item1.taxAmount, 0.01)
        assertEquals(2124.0, item1.grossTotal, 0.01)

        val invoice = com.example.data.model.Invoice(
            invoiceNumber = "INV-2026-TEST",
            clientName = "Acme Corp",
            currency = "INR",
            currencySymbol = "₹",
            taxRate = 18.0,
            status = com.example.data.model.InvoiceStatus.SENT,
            items = listOf(item1),
            shippingFee = 100.0,
            amountPaid = 500.0
        )

        assertEquals("INR", invoice.currency)
        assertEquals("₹", invoice.currencySymbol)
        assertEquals(com.example.data.model.InvoiceStatus.SENT, invoice.status)
        assertEquals(2000.0, invoice.subtotal, 0.01)
        assertEquals(1800.0, invoice.taxableAmount, 0.01)
        assertEquals(324.0, invoice.taxAmount, 0.01)
        assertEquals(2224.0, invoice.grandTotal, 0.01) // 1800 + 324 + 100
        assertEquals(1724.0, invoice.balanceDue, 0.01) // 2224 - 500

        // Test conversion to/from Entity
        val entity = invoice.toEntity()
        assertEquals("INV-2026-TEST", entity.invoiceNumber)
        assertEquals("INR", entity.currencyCode)
        assertEquals("₹", entity.currencySymbol)
        assertEquals("Sent", entity.status)

        val roundTrip = com.example.data.model.Invoice.fromEntity(entity)
        assertEquals(invoice.invoiceNumber, roundTrip.invoiceNumber)
        assertEquals(invoice.currency, roundTrip.currency)
        assertEquals(invoice.status, roundTrip.status)
        assertEquals(1, roundTrip.items.size)
        assertEquals("Software Architecture", roundTrip.items[0].description)
    }

    @Test
    fun testInvoiceViewModelFormStateAndEntry() = kotlinx.coroutines.test.runTest {
        val app = androidx.test.core.app.ApplicationProvider.getApplicationContext<android.app.Application>()
        val viewModel = com.example.ui.viewmodel.InvoiceViewModel(app)

        // Initialize new invoice form
        viewModel.initInvoiceCreationForm(0L)
        val initialForm = viewModel.invoiceFormState.value
        assertNotNull(initialForm.invoiceNumber)
        assertTrue(initialForm.invoiceNumber.startsWith("INV-"))

        // Update form data entry
        viewModel.updateFormInvoiceNumber("INV-2026-TESTVM")
        viewModel.updateFormClientDetails(
            name = "Zenith Enterprises",
            company = "Zenith Global LLC",
            email = "billing@zenith.com",
            phone = "+1-555-8822",
            address = "777 Market St, Suite 100",
            taxId = "US-EIN-992211"
        )
        viewModel.updateFormCurrency("EUR", "€")
        viewModel.updateFormTax(20.0, "VAT")
        viewModel.updateFormDiscounts(percent = 5.0, fixedAmount = 50.0)
        viewModel.updateFormShippingFee(15.0)
        viewModel.updateFormAmountPaid(200.0)
        viewModel.updateFormStatus("Sent")

        // Update first item and add second item
        viewModel.updateFormItem(0, InvoiceItem(description = "Cloud Architecture", quantity = 10.0, unitPrice = 100.0, unit = "hrs"))
        viewModel.addFormItem(InvoiceItem(description = "Security Audit", quantity = 5.0, unitPrice = 120.0, unit = "hrs"))

        val state = viewModel.invoiceFormState.value
        assertEquals("INV-2026-TESTVM", state.invoiceNumber)
        assertEquals("Zenith Enterprises", state.clientName)
        assertEquals("EUR", state.currencyCode)
        assertEquals("€", state.currencySymbol)
        assertEquals(2, state.items.size)

        // Calculations check:
        // Subtotal = 10*100 + 5*120 = 1000 + 600 = 1600.0
        assertEquals(1600.0, state.subtotal, 0.01)
        // Discount = 5% of 1600 = 80 + 50 = 130.0
        assertEquals(130.0, state.totalDiscount, 0.01)
        // Taxable Base = 1600 - 130 = 1470.0
        assertEquals(1470.0, state.taxableBase, 0.01)
        // Tax (20%) = 1470 * 0.20 = 294.0
        assertEquals(294.0, state.taxTotal, 0.01)
        // Grand Total = 1470 + 294 + 15 = 1779.0
        assertEquals(1779.0, state.grandTotal, 0.01)
        // Balance Due = 1779 - 200 = 1579.0
        assertEquals(1579.0, state.balanceDue, 0.01)

        // Test saving from form into Room database via suspend direct function
        val savedId = viewModel.saveInvoiceFromFormDirect()
        assertTrue("Saved ID should be positive", savedId > 0L)
    }

    @Test
    fun testGeminiAiServiceSaveClientExtraction() = kotlinx.coroutines.test.runTest {
        val aiService = com.example.ai.GeminiAiService()
        val profile = com.example.data.model.BusinessProfile()
        val result = aiService.processUserPrompt(
            prompt = "Save client Wayne Enterprises with email bruce@wayne.com and phone +1-555-0199",
            profile = profile,
            existingClients = emptyList(),
            nextInvoiceNumber = "INV-2026-001"
        )

        assertEquals(com.example.ai.AiActionType.SAVE_CLIENT, result.actionType)
        assertNotNull(result.clientToSave)
        assertTrue(result.clientToSave!!.name.contains("Wayne Enterprises"))
        assertEquals("bruce@wayne.com", result.clientToSave!!.email)
        assertTrue(result.clientToSave!!.phone.contains("555"))
    }

    @Test
    fun testGeminiAiServiceInvoiceGenerationExtraction() = kotlinx.coroutines.test.runTest {
        val aiService = com.example.ai.GeminiAiService()
        val profile = com.example.data.model.BusinessProfile(defaultCurrency = "USD", defaultCurrencySymbol = "$")
        val result = aiService.processUserPrompt(
            prompt = "Generate invoice for Stark Industries, 20 hrs of consulting at $150 with 18% tax",
            profile = profile,
            existingClients = emptyList(),
            nextInvoiceNumber = "INV-2026-099"
        )

        assertEquals(com.example.ai.AiActionType.GENERATE_INVOICE, result.actionType)
        assertNotNull(result.invoiceToGenerate)
        assertEquals("Stark Industries", result.invoiceToGenerate!!.clientName)
        assertEquals("INV-2026-099", result.invoiceToGenerate!!.invoiceNumber)
        assertEquals(18.0, result.invoiceToGenerate!!.taxRate, 0.01)

        val items = InvoiceUtils.deserializeInvoiceItems(result.invoiceToGenerate!!.itemsJson)
        assertTrue(items.isNotEmpty())
        assertEquals(20.0, items[0].quantity, 0.01)
        assertEquals(150.0, items[0].unitPrice, 0.01)
    }

    @Test
    fun testGeminiAiServiceTaxEnquiry() = kotlinx.coroutines.test.runTest {
        val aiService = com.example.ai.GeminiAiService()
        val profile = com.example.data.model.BusinessProfile()
        val result = aiService.processUserPrompt(
            prompt = "What is the GST tax rate for software consulting services?",
            profile = profile,
            existingClients = emptyList(),
            nextInvoiceNumber = "INV-2026-001"
        )

        assertEquals(com.example.ai.AiActionType.INVOICE_ENQUIRY, result.actionType)
        assertTrue(result.conversationalReply.contains("GST") || result.conversationalReply.contains("18%"))
    }

    @Test
    fun testGeminiAiServiceExpenseExtraction() = kotlinx.coroutines.test.runTest {
        val aiService = com.example.ai.GeminiAiService()
        val profile = com.example.data.model.BusinessProfile(defaultCurrency = "USD", defaultCurrencySymbol = "$")
        val result = aiService.processUserPrompt(
            prompt = "Record expense: $85 for Uber travel on Credit Card",
            profile = profile,
            existingClients = emptyList(),
            nextInvoiceNumber = "INV-2026-001"
        )

        assertEquals(com.example.ai.AiActionType.SAVE_EXPENSE, result.actionType)
        assertNotNull(result.expenseToSave)
        assertEquals(85.0, result.expenseToSave!!.amount, 0.01)
        assertEquals("Travel & Transport", result.expenseToSave!!.category)
        assertEquals("Credit Card", result.expenseToSave!!.paymentMethod)
        assertTrue(result.expenseToSave!!.taxDeductible)
    }

    @Test
    fun testExpenseDaoAndViewModelSaving() = kotlinx.coroutines.test.runTest {
        val app = androidx.test.core.app.ApplicationProvider.getApplicationContext<android.app.Application>()
        val db = com.example.data.local.AppDatabase.getDatabase(app)
        val expenseDao = db.expenseDao()

        val expense = com.example.data.model.ExpenseEntity(
            title = "AWS Cloud Hosting",
            category = "Software & IT",
            amount = 120.0,
            currency = "USD",
            currencySymbol = "$",
            date = "2026-09-30",
            vendor = "Amazon Web Services",
            paymentMethod = "Credit Card",
            taxDeductible = true
        )

        val id = expenseDao.insertExpense(expense)
        assertTrue("Expense ID should be positive", id > 0L)

        val retrieved = expenseDao.getExpenseById(id)
        assertNotNull(retrieved)
        assertEquals("AWS Cloud Hosting", retrieved!!.title)
        assertEquals(120.0, retrieved.amount, 0.01)
    }
}
