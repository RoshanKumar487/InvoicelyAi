package com.example.data.local

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.sqlite.db.SupportSQLiteDatabase
import com.example.data.model.BusinessProfile
import com.example.data.model.ClientEntity
import com.example.data.model.ExpenseEntity
import com.example.data.model.InvoiceEntity
import com.example.data.model.InvoiceItem
import com.example.data.model.InvoiceUtils
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

@Database(
    entities = [
        InvoiceEntity::class,
        ClientEntity::class,
        BusinessProfile::class,
        ExpenseEntity::class
    ],
    version = 7,
    exportSchema = false
)
abstract class AppDatabase : RoomDatabase() {

    abstract fun invoiceDao(): InvoiceDao
    abstract fun clientDao(): ClientDao
    abstract fun businessProfileDao(): BusinessProfileDao
    abstract fun expenseDao(): ExpenseDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getDatabase(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "invoicely_database"
                )
                    .addCallback(DatabaseCallback())
                    .fallbackToDestructiveMigration()
                    .build()
                INSTANCE = instance
                instance
            }
        }

        private class DatabaseCallback : RoomDatabase.Callback() {
            override fun onCreate(db: SupportSQLiteDatabase) {
                super.onCreate(db)
                INSTANCE?.let { database ->
                    CoroutineScope(Dispatchers.IO).launch {
                        populateInitialData(database)
                    }
                }
            }

            override fun onDestructiveMigration(db: SupportSQLiteDatabase) {
                super.onDestructiveMigration(db)
                INSTANCE?.let { database ->
                    CoroutineScope(Dispatchers.IO).launch {
                        populateInitialData(database)
                    }
                }
            }

            override fun onOpen(db: SupportSQLiteDatabase) {
                super.onOpen(db)
                INSTANCE?.let { database ->
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            val prof = database.businessProfileDao().getBusinessProfileDirect()
                            if (prof == null) {
                                populateInitialData(database)
                            }
                        } catch (_: Exception) {}
                    }
                }
            }
        }

        suspend fun populateInitialData(db: AppDatabase) {
            // Seed Business Profile
            val defaultProfile = BusinessProfile(
                id = 1,
                businessName = "Apex Nova Dynamics",
                legalName = "Apex Nova Dynamics LLC",
                email = "billing@apexnova.io",
                phone = "+1 (415) 890-2345",
                website = "www.apexnova.io",
                address = "742 Market Street, Suite 500\nSan Francisco, CA 94103",
                taxId = "US-EIN-92-3481928",
                bankName = "First Horizon Commercial Bank",
                accountHolder = "Apex Nova Dynamics LLC",
                accountNumber = "849204910283",
                routingNumber = "121000358",
                swiftBic = "FHRZUS6S",
                paymentLink = "https://pay.apexnova.io/inv",
                defaultCurrency = "USD",
                defaultCurrencySymbol = "$",
                defaultTaxRate = 8.25,
                defaultTaxLabel = "Sales Tax",
                defaultPaymentTerms = "Net 30",
                defaultNotes = "Thank you for partnering with Apex Nova! We appreciate your business.",
                defaultTerms = "Payment is due within 30 days. Accounts overdue by 15 days accrue 1.5% interest monthly.",
                signeeName = "Jordan Vance",
                signeeTitle = "Managing Director",
                brandColorHex = "#1E3A8A"
            )
            db.businessProfileDao().insertOrUpdate(defaultProfile)

            // Seed Sample Clients
            val c1Id = db.clientDao().insertClient(
                ClientEntity(
                    name = "Sophia Martinez",
                    companyName = "Vanguard Digital Media",
                    email = "sophia@vanguarddigital.co",
                    phone = "+1 (310) 456-7890",
                    address = "900 Wilshire Blvd, Fl 14\nLos Angeles, CA 90017",
                    taxId = "US-CA-7729104",
                    preferredCurrency = "USD",
                    defaultPaymentTerms = "Net 30",
                    notes = "Priority VIP client for enterprise UI/UX consulting."
                )
            )

            val c2Id = db.clientDao().insertClient(
                ClientEntity(
                    name = "Marcus Chen",
                    companyName = "Quantum Robotics Labs",
                    email = "marcus.chen@quantumrobotics.tech",
                    phone = "+1 (650) 332-1199",
                    address = "2100 University Ave\nPalo Alto, CA 94301",
                    taxId = "US-CA-8839210",
                    preferredCurrency = "USD",
                    defaultPaymentTerms = "Net 15",
                    notes = "Monthly AI & embedded software development contracts."
                )
            )

            val c3Id = db.clientDao().insertClient(
                ClientEntity(
                    name = "Elena Rostova",
                    companyName = "Nordic Horizon Ventures",
                    email = "elena@nordichorizon.eu",
                    phone = "+44 20 7946 0912",
                    address = "45 Berkeley Square\nLondon W1J 5AT, UK",
                    taxId = "GB-VAT-982341",
                    preferredCurrency = "EUR",
                    defaultPaymentTerms = "Due on Receipt",
                    notes = "International partner - billing in EUR."
                )
            )

            val dateFormat = SimpleDateFormat("yyyy-MM-dd", Locale.US)
            val cal = Calendar.getInstance()

            // 1. Paid Invoice
            val items1 = listOf(
                InvoiceItem(
                    description = "Enterprise Mobile Application Architecture & UI Design",
                    quantity = 40.0,
                    unitPrice = 125.0,
                    unit = "hrs"
                ),
                InvoiceItem(
                    description = "Design System & Figma Component Kit",
                    quantity = 1.0,
                    unitPrice = 1800.0,
                    unit = "units"
                )
            )
            cal.add(Calendar.DAY_OF_YEAR, -25)
            val issue1 = dateFormat.format(cal.time)
            cal.add(Calendar.DAY_OF_YEAR, 20)
            val due1 = dateFormat.format(cal.time)

            db.invoiceDao().insertInvoice(
                InvoiceEntity(
                    invoiceNumber = "INV-2026-001",
                    clientId = c1Id,
                    clientName = "Sophia Martinez",
                    clientCompany = "Vanguard Digital Media",
                    clientEmail = "sophia@vanguarddigital.co",
                    clientPhone = "+1 (310) 456-7890",
                    clientAddress = "900 Wilshire Blvd, Fl 14\nLos Angeles, CA 90017",
                    clientTaxId = "US-CA-7729104",
                    issueDate = issue1,
                    dueDate = due1,
                    paymentTerms = "Net 30",
                    currencyCode = "USD",
                    currencySymbol = "$",
                    itemsJson = InvoiceUtils.serializeInvoiceItems(items1),
                    notes = "Thank you for your business on the Vanguard redesign!",
                    terms = defaultProfile.defaultTerms,
                    paymentInstructions = "Wire Transfer to First Horizon Bank\nAccount: 849204910283 | Routing: 121000358",
                    taxRate = 8.25,
                    taxLabel = "Sales Tax",
                    discountPercent = 5.0,
                    discountAmount = 0.0,
                    shippingFee = 0.0,
                    amountPaid = 6992.94,
                    status = "Paid",
                    templateId = "modern",
                    docxTemplateTitle = "INVOICE",
                    paidDate = System.currentTimeMillis() - (5L * 24 * 3600 * 1000)
                )
            )

            // 2. Sent / Pending Invoice
            val items2 = listOf(
                InvoiceItem(
                    description = "Autonomous Drone Navigation Algorithm Tuning",
                    quantity = 35.0,
                    unitPrice = 150.0,
                    unit = "hrs"
                ),
                InvoiceItem(
                    description = "Hardware Interface Integration & Sensor Calibration",
                    quantity = 15.0,
                    unitPrice = 160.0,
                    unit = "hrs"
                )
            )
            cal.time = Date()
            cal.add(Calendar.DAY_OF_YEAR, -5)
            val issue2 = dateFormat.format(cal.time)
            cal.add(Calendar.DAY_OF_YEAR, 25)
            val due2 = dateFormat.format(cal.time)

            db.invoiceDao().insertInvoice(
                InvoiceEntity(
                    invoiceNumber = "INV-2026-002",
                    clientId = c2Id,
                    clientName = "Marcus Chen",
                    clientCompany = "Quantum Robotics Labs",
                    clientEmail = "marcus.chen@quantumrobotics.tech",
                    clientPhone = "+1 (650) 332-1199",
                    clientAddress = "2100 University Ave\nPalo Alto, CA 94301",
                    clientTaxId = "US-CA-8839210",
                    issueDate = issue2,
                    dueDate = due2,
                    paymentTerms = "Net 30",
                    currencyCode = "USD",
                    currencySymbol = "$",
                    itemsJson = InvoiceUtils.serializeInvoiceItems(items2),
                    notes = "Phase 2 Milestone delivery completed as per SOW #4.",
                    terms = defaultProfile.defaultTerms,
                    paymentInstructions = "Wire Transfer to First Horizon Bank\nAccount: 849204910283 | Routing: 121000358",
                    taxRate = 8.25,
                    taxLabel = "Sales Tax",
                    discountPercent = 0.0,
                    discountAmount = 0.0,
                    shippingFee = 0.0,
                    amountPaid = 0.0,
                    status = "Sent",
                    templateId = "corporate",
                    docxTemplateTitle = "COMMERCIAL INVOICE"
                )
            )

            // 3. Overdue Invoice
            val items3 = listOf(
                InvoiceItem(
                    description = "Cross-border Market Feasibility Report & Strategy",
                    quantity = 1.0,
                    unitPrice = 4200.0,
                    unit = "units"
                )
            )
            cal.time = Date()
            cal.add(Calendar.DAY_OF_YEAR, -35)
            val issue3 = dateFormat.format(cal.time)
            cal.add(Calendar.DAY_OF_YEAR, 20)
            val due3 = dateFormat.format(cal.time)

            db.invoiceDao().insertInvoice(
                InvoiceEntity(
                    invoiceNumber = "INV-2026-003",
                    clientId = c3Id,
                    clientName = "Elena Rostova",
                    clientCompany = "Nordic Horizon Ventures",
                    clientEmail = "elena@nordichorizon.eu",
                    clientPhone = "+44 20 7946 0912",
                    clientAddress = "45 Berkeley Square\nLondon W1J 5AT, UK",
                    clientTaxId = "GB-VAT-982341",
                    issueDate = issue3,
                    dueDate = due3,
                    paymentTerms = "Net 15",
                    currencyCode = "EUR",
                    currencySymbol = "€",
                    itemsJson = InvoiceUtils.serializeInvoiceItems(items3),
                    notes = "Final market assessment deliverable.",
                    terms = defaultProfile.defaultTerms,
                    paymentInstructions = "IBAN / SWIFT transfer to: FHRZUS6S | Acc: 849204910283",
                    taxRate = 0.0,
                    taxLabel = "Zero-rated VAT (Cross-border)",
                    discountPercent = 0.0,
                    discountAmount = 0.0,
                    shippingFee = 0.0,
                    amountPaid = 0.0,
                    status = "Overdue",
                    templateId = "creative",
                    docxTemplateTitle = "INVOICE"
                )
            )

            // Initial Sample Expenses
            val todayStr = dateFormat.format(Date())
            db.expenseDao().insertExpense(
                ExpenseEntity(
                    title = "AWS Cloud Server Hosting",
                    category = "Software & IT",
                    amount = 185.50,
                    currency = "USD",
                    currencySymbol = "$",
                    date = todayStr,
                    vendor = "Amazon Web Services Inc",
                    paymentMethod = "Credit Card",
                    taxDeductible = true,
                    taxAmount = 33.39,
                    notes = "Monthly infrastructure & backup compute"
                )
            )
            db.expenseDao().insertExpense(
                ExpenseEntity(
                    title = "WeWork Dedicated Coworking Desk",
                    category = "Office & Rent",
                    amount = 450.00,
                    currency = "USD",
                    currencySymbol = "$",
                    date = todayStr,
                    vendor = "WeWork Companies LLC",
                    paymentMethod = "Bank Transfer",
                    taxDeductible = true,
                    taxAmount = 0.0,
                    notes = "Monthly desk subscription"
                )
            )
            db.expenseDao().insertExpense(
                ExpenseEntity(
                    title = "Client Strategy Dinner",
                    category = "Meals & Entertainment",
                    amount = 120.00,
                    currency = "USD",
                    currencySymbol = "$",
                    date = todayStr,
                    vendor = "The Capital Grille",
                    paymentMethod = "Credit Card",
                    taxDeductible = true,
                    taxAmount = 10.80,
                    notes = "Quarterly review with Quantum Tech team"
                )
            )
            db.expenseDao().insertExpense(
                ExpenseEntity(
                    title = "Google Workspace & Domain",
                    category = "Software & IT",
                    amount = 36.00,
                    currency = "USD",
                    currencySymbol = "$",
                    date = todayStr,
                    vendor = "Google LLC",
                    paymentMethod = "UPI",
                    taxDeductible = true,
                    taxAmount = 6.48,
                    notes = "Company email seats"
                )
            )
        }
    }
}
