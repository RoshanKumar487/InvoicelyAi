package com.example.ui.viewmodel

import android.app.Application
import android.content.Context
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.example.ai.AiBusinessMemory
import com.example.ai.AiChatHistoryManager
import com.example.ai.ChatMessage
import com.example.ai.GeminiAiService
import com.example.data.local.AppDatabase
import com.example.data.model.BusinessProfile
import com.example.data.model.ClientEntity
import com.example.data.model.ExpenseEntity
import com.example.data.model.InvoiceCalculations
import com.example.data.model.InvoiceEntity
import com.example.data.model.InvoiceItem
import com.example.data.model.InvoiceUtils
import com.example.data.model.TemplateConfig
import com.example.data.api.ApiConfig
import com.example.data.api.InvoicelyApiManager
import com.example.data.api.model.DashboardStatsResponse
import com.example.data.api.model.toBackendDto
import com.example.data.repository.BusinessRepository
import com.example.data.repository.ClientRepository
import com.example.data.repository.ExpenseRepository
import com.example.data.repository.InvoiceRepository
import com.example.docx.DocxGenerator
import com.example.docx.DocxTemplatePreset
import com.example.pdf.PdfInvoiceGenerator
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import java.io.File
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

data class DashboardAnalytics(
    val totalInvoiced: Double = 0.0,
    val totalPaid: Double = 0.0,
    val totalOutstanding: Double = 0.0,
    val totalOverdue: Double = 0.0,
    val totalInvoiceCount: Int = 0,
    val paidCount: Int = 0,
    val pendingCount: Int = 0,
    val overdueCount: Int = 0,
    val draftCount: Int = 0,
    val monthlyRevenue: List<MonthlyRevenueItem> = emptyList()
)

data class MonthlyRevenueItem(
    val monthName: String,
    val totalAmount: Double,
    val paidAmount: Double
)

class InvoiceViewModel(application: Application) : AndroidViewModel(application) {

    private val database = AppDatabase.getDatabase(application)
    private val invoiceRepository = InvoiceRepository(database.invoiceDao())
    private val clientRepository = ClientRepository(database.clientDao())
    private val businessRepository = BusinessRepository(database.businessProfileDao())
    private val expenseRepository = ExpenseRepository(database.expenseDao())
    private val geminiService = GeminiAiService()
    val chatHistoryManager = AiChatHistoryManager(application.applicationContext)
    private val _chatMessages = MutableStateFlow<List<ChatMessage>>(emptyList())
    val chatMessages: StateFlow<List<ChatMessage>> = _chatMessages.asStateFlow()
    private val _isAiThinking = MutableStateFlow(false)
    val isAiThinking: StateFlow<Boolean> = _isAiThinking.asStateFlow()

    // All Invoices stream
    val allInvoices: StateFlow<List<InvoiceEntity>> = invoiceRepository.allInvoices
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    // All Clients stream
    val allClients: StateFlow<List<ClientEntity>> = clientRepository.allClients
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    // All Expenses stream
    val allExpenses: StateFlow<List<ExpenseEntity>> = expenseRepository.allExpenses
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    // Business Profile stream
    val businessProfile: StateFlow<BusinessProfile> = businessRepository.profile
        .combine(MutableStateFlow(Unit)) { profile, _ ->
            profile ?: BusinessProfile()
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), BusinessProfile())

    // Backend API & Server State Flows
    val isBackendOnline: StateFlow<Boolean> = ApiConfig.isBackendReachable
    val isSyncing: StateFlow<Boolean> = ApiConfig.isSyncing
    val lastSyncTime: StateFlow<Long> = ApiConfig.lastSyncTimestamp
    val syncErrorMessage: StateFlow<String?> = ApiConfig.lastErrorMessage

    private val _backendStats = MutableStateFlow<DashboardStatsResponse?>(null)
    val backendStats: StateFlow<DashboardStatsResponse?> = _backendStats.asStateFlow()

    fun refreshBackendStats() {
        if (!com.example.data.repository.AuthSessionManager.isLoggedIn.value || com.example.data.api.client.ApiClient.getAuthToken().isNullOrBlank()) {
            return
        }
        viewModelScope.launch(kotlinx.coroutines.Dispatchers.IO) {
            val result = InvoicelyApiManager.getDashboardStats()
            if (result.isSuccess) {
                _backendStats.value = result.getOrNull()
            }
        }
    }

    fun syncAllDataWithBackend(onComplete: ((Boolean, String) -> Unit)? = null) {
        if (!com.example.data.repository.AuthSessionManager.isLoggedIn.value || com.example.data.api.client.ApiClient.getAuthToken().isNullOrBlank()) {
            onComplete?.invoke(false, "Please sign in to sync with cloud backend")
            return
        }
        viewModelScope.launch(kotlinx.coroutines.Dispatchers.IO) {
            val res = InvoicelyApiManager.syncAllWithBackend(
                invoiceRepository = invoiceRepository,
                clientRepository = clientRepository,
                expenseRepository = expenseRepository,
                businessRepository = businessRepository
            )
            refreshBackendStats()
            kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.Main) {
                if (res.isSuccess) {
                    onComplete?.invoke(true, res.getOrNull() ?: "Backend sync completed successfully")
                } else {
                    onComplete?.invoke(false, res.exceptionOrNull()?.message ?: "Backend sync encountered an issue")
                }
            }
        }
    }

    init {
        viewModelScope.launch {

            // Initialize chat history from persistent storage or generate proactive executive greeting
            val savedHistory = chatHistoryManager.loadChatHistory()
            if (savedHistory.isNotEmpty()) {
                _chatMessages.value = savedHistory
            } else {
                _chatMessages.value = listOf(
                    chatHistoryManager.createExecutiveGreeting(
                        profile = businessProfile.value,
                        invoices = allInvoices.value,
                        clients = allClients.value
                    )
                )
            }

            // Sync with backend API and fetch live stats only if user is logged in
            if (com.example.data.repository.AuthSessionManager.isLoggedIn.value && !com.example.data.api.client.ApiClient.getAuthToken().isNullOrBlank()) {
                try {
                    refreshBackendStats()
                    syncAllDataWithBackend()
                } catch (e: Exception) {}
            }
        }
    }

    // Filter and Search States
    private val _invoiceSearchQuery = MutableStateFlow("")
    val invoiceSearchQuery = _invoiceSearchQuery.asStateFlow()

    private val _invoiceStatusFilter = MutableStateFlow("All") // "All", "Draft", "Sent", "Paid", "Overdue"
    val invoiceStatusFilter = _invoiceStatusFilter.asStateFlow()

    private val _clientSearchQuery = MutableStateFlow("")
    val clientSearchQuery = _clientSearchQuery.asStateFlow()

    // Filtered Invoices
    val filteredInvoices: StateFlow<List<InvoiceEntity>> = combine(
        allInvoices,
        _invoiceSearchQuery,
        _invoiceStatusFilter
    ) { invoices, query, filter ->
        invoices.filter { inv ->
            val matchesFilter = if (filter == "All") true else inv.status.equals(filter, ignoreCase = true)
            val matchesQuery = query.isBlank() ||
                    inv.invoiceNumber.contains(query, ignoreCase = true) ||
                    inv.clientName.contains(query, ignoreCase = true) ||
                    inv.clientCompany.contains(query, ignoreCase = true)
            matchesFilter && matchesQuery
        }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    // Filtered Clients
    val filteredClients: StateFlow<List<ClientEntity>> = combine(
        allClients,
        _clientSearchQuery
    ) { clients, query ->
        if (query.isBlank()) clients
        else clients.filter {
            it.name.contains(query, ignoreCase = true) ||
                    it.companyName.contains(query, ignoreCase = true) ||
                    it.email.contains(query, ignoreCase = true)
        }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    // Dashboard Analytics State
    val dashboardAnalytics: StateFlow<DashboardAnalytics> = allInvoices.combine(businessProfile) { invoices, _ ->
        calculateAnalytics(invoices)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), DashboardAnalytics())

    // Active Template Config for Template Customizer
    private val _activeTemplateConfig = MutableStateFlow(DocxTemplatePreset.gstTax)
    val activeTemplateConfig = _activeTemplateConfig.asStateFlow()

    fun setDefaultTemplate(templateId: String) {
        val preset = DocxTemplatePreset.getById(templateId)
        _activeTemplateConfig.value = preset
        val updatedProfile = businessProfile.value.copy(defaultTemplateId = templateId)
        saveBusinessProfile(updatedProfile)
    }

    fun setInvoiceSearchQuery(query: String) {
        _invoiceSearchQuery.value = query
    }

    fun setInvoiceStatusFilter(filter: String) {
        _invoiceStatusFilter.value = filter
    }

    fun setClientSearchQuery(query: String) {
        _clientSearchQuery.value = query
    }

    fun selectTemplatePreset(preset: TemplateConfig) {
        _activeTemplateConfig.value = preset
    }

    fun updateActiveTemplateConfig(updated: TemplateConfig) {
        _activeTemplateConfig.value = updated
    }

    // =========================================================================
    // INVOICE CREATION & FORM STATE MANAGEMENT
    // =========================================================================
    private val _invoiceFormState = MutableStateFlow(InvoiceFormState())
    val invoiceFormState: StateFlow<InvoiceFormState> = _invoiceFormState.asStateFlow()

    fun initInvoiceCreationForm(existingId: Long = 0L) {
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        val defaultDue = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date(System.currentTimeMillis() + 30L * 86400000L))
        val currentProfile = businessProfile.value

        if (existingId == 0L) {
            val nextNumber = generateNextInvoiceNumber()
            _invoiceFormState.value = InvoiceFormState(
                invoiceId = 0L,
                invoiceNumber = nextNumber,
                issueDate = today,
                dueDate = defaultDue,
                paymentTerms = currentProfile.defaultPaymentTerms.ifBlank { "Net 30" },
                currencyCode = currentProfile.defaultCurrency.ifBlank { "USD" },
                currencySymbol = currentProfile.defaultCurrencySymbol.ifBlank { "$" },
                taxRate = currentProfile.defaultTaxRate,
                taxLabel = currentProfile.defaultTaxLabel.ifBlank { "Tax" },
                templateId = currentProfile.defaultTemplateId.ifBlank { "gst_tax" },
                notes = currentProfile.defaultNotes,
                terms = currentProfile.defaultTerms,
                paymentInstructions = "Bank: ${currentProfile.bankName}\nAccount: ${currentProfile.accountNumber}\nRouting: ${currentProfile.routingNumber}\nUPI: ${currentProfile.upiId}",
                items = listOf(
                    InvoiceItem(description = "", quantity = 1.0, unitPrice = 0.0, unit = "hrs")
                )
            )
        } else {
            val existing = allInvoices.value.find { it.id == existingId }
            if (existing != null) {
                _invoiceFormState.value = InvoiceFormState(
                    invoiceId = existing.id,
                    invoiceNumber = existing.invoiceNumber,
                    clientId = existing.clientId,
                    clientName = existing.clientName,
                    clientCompany = existing.clientCompany,
                    clientEmail = existing.clientEmail,
                    clientPhone = existing.clientPhone,
                    clientAddress = existing.clientAddress,
                    clientTaxId = existing.clientTaxId,
                    issueDate = existing.issueDate,
                    dueDate = existing.dueDate,
                    poNumber = existing.poNumber,
                    paymentTerms = existing.paymentTerms,
                    currencyCode = existing.currencyCode,
                    currencySymbol = existing.currencySymbol,
                    taxRate = existing.taxRate,
                    taxLabel = existing.taxLabel,
                    discountPercent = existing.discountPercent,
                    discountAmount = existing.discountAmount,
                    shippingFee = existing.shippingFee,
                    amountPaid = existing.amountPaid,
                    status = existing.status,
                    templateId = existing.templateId,
                    notes = existing.notes,
                    terms = existing.terms,
                    paymentInstructions = existing.paymentInstructions,
                    items = InvoiceUtils.deserializeInvoiceItems(existing.itemsJson).ifEmpty {
                        listOf(InvoiceItem(description = "", quantity = 1.0, unitPrice = 0.0, unit = "hrs"))
                    }
                )
            }
        }
    }

    fun prefillClientInForm(client: ClientEntity) {
        _invoiceFormState.value = _invoiceFormState.value.copy(
            clientId = client.id,
            clientName = client.name,
            clientCompany = client.companyName,
            clientEmail = client.email,
            clientPhone = client.phone,
            clientAddress = client.address,
            clientTaxId = client.taxId,
            paymentTerms = if (client.defaultPaymentTerms.isNotBlank()) client.defaultPaymentTerms else _invoiceFormState.value.paymentTerms,
            currencyCode = if (client.preferredCurrency.isNotBlank()) client.preferredCurrency else _invoiceFormState.value.currencyCode
        )
    }

    fun updateFormInvoiceNumber(number: String) {
        _invoiceFormState.value = _invoiceFormState.value.copy(invoiceNumber = number, validationError = null)
    }

    fun updateFormClientDetails(
        name: String,
        company: String = "",
        email: String = "",
        phone: String = "",
        address: String = "",
        taxId: String = ""
    ) {
        _invoiceFormState.value = _invoiceFormState.value.copy(
            clientName = name,
            clientCompany = company,
            clientEmail = email,
            clientPhone = phone,
            clientAddress = address,
            clientTaxId = taxId,
            validationError = null
        )
    }

    fun updateFormClientName(name: String) {
        _invoiceFormState.value = _invoiceFormState.value.copy(clientName = name, validationError = null)
    }

    fun updateFormClientCompany(company: String) {
        _invoiceFormState.value = _invoiceFormState.value.copy(clientCompany = company)
    }

    fun updateFormClientEmail(email: String) {
        _invoiceFormState.value = _invoiceFormState.value.copy(clientEmail = email)
    }

    fun updateFormClientPhone(phone: String) {
        _invoiceFormState.value = _invoiceFormState.value.copy(clientPhone = phone)
    }

    fun updateFormClientAddress(address: String) {
        _invoiceFormState.value = _invoiceFormState.value.copy(clientAddress = address)
    }

    fun updateFormClientTaxId(taxId: String) {
        _invoiceFormState.value = _invoiceFormState.value.copy(clientTaxId = taxId)
    }

    fun updateFormDates(issueDate: String, dueDate: String) {
        _invoiceFormState.value = _invoiceFormState.value.copy(issueDate = issueDate, dueDate = dueDate)
    }

    fun updateFormPaymentTerms(terms: String) {
        _invoiceFormState.value = _invoiceFormState.value.copy(paymentTerms = terms)
    }

    fun updateFormPoNumber(poNumber: String) {
        _invoiceFormState.value = _invoiceFormState.value.copy(poNumber = poNumber)
    }

    fun updateFormCurrency(code: String, symbol: String) {
        _invoiceFormState.value = _invoiceFormState.value.copy(currencyCode = code, currencySymbol = symbol)
    }

    fun updateFormTax(rate: Double, label: String) {
        _invoiceFormState.value = _invoiceFormState.value.copy(taxRate = rate, taxLabel = label)
    }

    fun updateFormDiscounts(percent: Double, fixedAmount: Double) {
        _invoiceFormState.value = _invoiceFormState.value.copy(discountPercent = percent, discountAmount = fixedAmount)
    }

    fun updateFormShippingFee(fee: Double) {
        _invoiceFormState.value = _invoiceFormState.value.copy(shippingFee = fee)
    }

    fun updateFormAmountPaid(paid: Double) {
        _invoiceFormState.value = _invoiceFormState.value.copy(amountPaid = paid)
    }

    fun updateFormStatus(status: String) {
        _invoiceFormState.value = _invoiceFormState.value.copy(status = status)
    }

    fun updateFormTemplateId(templateId: String) {
        _invoiceFormState.value = _invoiceFormState.value.copy(templateId = templateId)
    }

    fun updateFormNotes(notes: String, terms: String, paymentInstructions: String) {
        _invoiceFormState.value = _invoiceFormState.value.copy(
            notes = notes,
            terms = terms,
            paymentInstructions = paymentInstructions
        )
    }

    fun addFormItem(item: InvoiceItem = InvoiceItem(description = "", quantity = 1.0, unitPrice = 0.0, unit = "hrs")) {
        val updated = _invoiceFormState.value.items + item
        _invoiceFormState.value = _invoiceFormState.value.copy(items = updated, validationError = null)
    }

    fun updateFormItem(index: Int, updatedItem: InvoiceItem) {
        val list = _invoiceFormState.value.items.toMutableList()
        if (index in list.indices) {
            list[index] = updatedItem
            _invoiceFormState.value = _invoiceFormState.value.copy(items = list)
        }
    }

    fun removeFormItem(index: Int) {
        val list = _invoiceFormState.value.items.toMutableList()
        if (index in list.indices && list.size > 1) {
            list.removeAt(index)
            _invoiceFormState.value = _invoiceFormState.value.copy(items = list)
        }
    }

    fun resetInvoiceForm() {
        initInvoiceCreationForm(0L)
    }

    /**
     * Validates form data and persists the invoice to Room Database.
     */
    fun saveInvoiceFromForm(
        onSuccess: (Long) -> Unit,
        onError: (String) -> Unit = {}
    ) {
        val state = _invoiceFormState.value
        if (state.invoiceNumber.isBlank()) {
            val error = "Invoice Number cannot be empty"
            _invoiceFormState.value = state.copy(validationError = error)
            onError(error)
            return
        }
        if (state.clientName.isBlank()) {
            val error = "Client Name cannot be empty"
            _invoiceFormState.value = state.copy(validationError = error)
            onError(error)
            return
        }
        if (state.items.isEmpty() || state.items.all { it.description.isBlank() && it.unitPrice == 0.0 }) {
            val error = "Please add at least one line item"
            _invoiceFormState.value = state.copy(validationError = error)
            onError(error)
            return
        }

        viewModelScope.launch(kotlinx.coroutines.Dispatchers.IO) {
            _invoiceFormState.value = state.copy(isSaving = true, validationError = null)
            val entity = state.toInvoiceEntity()
            val id = if (entity.id == 0L) {
                invoiceRepository.insertInvoice(entity)
            } else {
                invoiceRepository.updateInvoice(entity)
                entity.id
            }
            _invoiceFormState.value = _invoiceFormState.value.copy(isSaving = false, invoiceId = id)

            // Asynchronous Backend Sync
            try {
                val dto = entity.copy(id = id).toBackendDto()
                if (entity.id == 0L) {
                    InvoicelyApiManager.createInvoice(dto)
                } else {
                    InvoicelyApiManager.updateInvoice(id, dto)
                }
                refreshBackendStats()
            } catch (_: Exception) {}

            kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.Main) {
                onSuccess(id)
            }
        }
    }

    /**
     * Direct suspend saving function for coroutine callers and unit tests.
     */
    suspend fun saveInvoiceFromFormDirect(): Long {
        val state = _invoiceFormState.value
        val entity = state.toInvoiceEntity()
        val id = if (entity.id == 0L) {
            invoiceRepository.insertInvoice(entity)
        } else {
            invoiceRepository.updateInvoice(entity)
            entity.id
        }
        _invoiceFormState.value = _invoiceFormState.value.copy(invoiceId = id)

        try {
            val dto = entity.copy(id = id).toBackendDto()
            if (entity.id == 0L) {
                InvoicelyApiManager.createInvoice(dto)
            } else {
                InvoicelyApiManager.updateInvoice(id, dto)
            }
            refreshBackendStats()
        } catch (_: Exception) {}

        return id
    }

    // Invoice CRUD Actions
    fun saveInvoice(invoice: InvoiceEntity, onSaved: (Long) -> Unit = {}) {
        viewModelScope.launch {
            val finalId: Long
            if (invoice.id == 0L) {
                finalId = invoiceRepository.insertInvoice(invoice)
                onSaved(finalId)
            } else {
                finalId = invoice.id
                invoiceRepository.updateInvoice(invoice)
                onSaved(finalId)
            }

            try {
                val dto = invoice.copy(id = finalId).toBackendDto()
                if (invoice.id == 0L) {
                    InvoicelyApiManager.createInvoice(dto)
                } else {
                    InvoicelyApiManager.updateInvoice(finalId, dto)
                }
                refreshBackendStats()
            } catch (_: Exception) {}
        }
    }

    fun deleteInvoice(invoice: InvoiceEntity) {
        viewModelScope.launch {
            invoiceRepository.deleteInvoice(invoice)
            try {
                if (invoice.id > 0) {
                    InvoicelyApiManager.deleteInvoice(invoice.id)
                    refreshBackendStats()
                }
            } catch (_: Exception) {}
        }
    }

    fun updateInvoiceStatus(invoiceId: Long, status: String) {
        viewModelScope.launch {
            invoiceRepository.updateStatus(invoiceId, status)
            try {
                InvoicelyApiManager.updateInvoiceStatus(invoiceId, status)
                refreshBackendStats()
            } catch (_: Exception) {}
        }
    }

    fun markReminderSent(invoiceId: Long) {
        viewModelScope.launch {
            invoiceRepository.updateReminderSent(invoiceId, System.currentTimeMillis())
        }
    }

    // Client CRUD Actions
    fun saveClient(client: ClientEntity, onSaved: (Long) -> Unit = {}) {
        viewModelScope.launch {
            val finalId: Long
            if (client.id == 0L) {
                finalId = clientRepository.insertClient(client)
                onSaved(finalId)
            } else {
                finalId = client.id
                clientRepository.updateClient(client)
                onSaved(finalId)
            }

            try {
                val dto = client.copy(id = finalId).toBackendDto()
                if (client.id == 0L) {
                    InvoicelyApiManager.createClient(dto)
                } else {
                    InvoicelyApiManager.updateClient(finalId, dto)
                }
                refreshBackendStats()
            } catch (_: Exception) {}
        }
    }

    fun deleteClient(client: ClientEntity) {
        viewModelScope.launch {
            clientRepository.deleteClient(client)
            try {
                if (client.id > 0) {
                    InvoicelyApiManager.deleteClient(client.id)
                    refreshBackendStats()
                }
            } catch (_: Exception) {}
        }
    }

    // Business Profile Actions
    fun saveBusinessProfile(profile: BusinessProfile) {
        viewModelScope.launch {
            businessRepository.saveProfile(profile)
            try {
                InvoicelyApiManager.updateBusinessProfile(profile.toBackendDto())
            } catch (_: Exception) {}
        }
    }

    fun clearAllLocalData() {
        viewModelScope.launch(kotlinx.coroutines.Dispatchers.IO) {
            invoiceRepository.deleteAllInvoices()
            clientRepository.deleteAllClients()
            expenseRepository.deleteAllExpenses()
            businessRepository.clearProfile()
        }
    }

    fun resyncFromCloudDatabase(onComplete: ((Boolean, String) -> Unit)? = null) {
        viewModelScope.launch(kotlinx.coroutines.Dispatchers.IO) {
            invoiceRepository.deleteAllInvoices()
            clientRepository.deleteAllClients()
            expenseRepository.deleteAllExpenses()
            businessRepository.clearProfile()
            syncAllDataWithBackend(onComplete)
        }
    }

    fun clearAllInvoices() {
        viewModelScope.launch {
            invoiceRepository.deleteAllInvoices()
        }
    }

    // Generate DOCX file
    fun generateDocx(
        context: Context,
        invoice: InvoiceEntity,
        templateConfig: TemplateConfig = _activeTemplateConfig.value
    ): File {
        val items = InvoiceUtils.deserializeInvoiceItems(invoice.itemsJson)
        val profile = businessProfile.value
        val calcs = InvoiceUtils.calculateInvoice(
            items = items,
            taxRate = invoice.taxRate,
            discountPercent = invoice.discountPercent,
            discountAmount = invoice.discountAmount,
            shippingFee = invoice.shippingFee,
            amountPaid = invoice.amountPaid
        )
        return DocxGenerator.generateInvoiceDocx(
            context = context,
            invoice = invoice,
            items = items,
            profile = profile,
            templateConfig = templateConfig,
            calculations = calcs
        )
    }

    // Generate PDF file conforming to selected template and custom branding
    fun generatePdf(
        context: Context,
        invoice: InvoiceEntity,
        templateConfig: TemplateConfig = _activeTemplateConfig.value
    ): File {
        val items = InvoiceUtils.deserializeInvoiceItems(invoice.itemsJson)
        val profile = businessProfile.value
        val calcs = InvoiceUtils.calculateInvoice(
            items = items,
            taxRate = invoice.taxRate,
            discountPercent = invoice.discountPercent,
            discountAmount = invoice.discountAmount,
            shippingFee = invoice.shippingFee,
            amountPaid = invoice.amountPaid
        )
        return PdfInvoiceGenerator.generateInvoicePdf(
            context = context,
            invoice = invoice,
            items = items,
            calculations = calcs,
            profile = profile,
            templateConfig = templateConfig
        )
    }

    // Helper: Compute Analytics
    private fun calculateAnalytics(invoices: List<InvoiceEntity>): DashboardAnalytics {
        var totalInvoiced = 0.0
        var totalPaid = 0.0
        var totalOutstanding = 0.0
        var totalOverdue = 0.0

        var paidCount = 0
        var pendingCount = 0
        var overdueCount = 0
        var draftCount = 0

        val monthMap = linkedMapOf<String, Pair<Double, Double>>() // Month -> (Total, Paid)
        val cal = Calendar.getInstance()
        val monthFmt = SimpleDateFormat("MMM", Locale.US)
        val fullDateFmt = SimpleDateFormat("yyyy-MM-dd", Locale.US)

        // Initialize last 5 months
        for (i in 4 downTo 0) {
            val c = Calendar.getInstance()
            c.add(Calendar.MONTH, -i)
            val mName = monthFmt.format(c.time)
            monthMap[mName] = Pair(0.0, 0.0)
        }

        for (inv in invoices) {
            val items = InvoiceUtils.deserializeInvoiceItems(inv.itemsJson)
            val calcs = InvoiceUtils.calculateInvoice(
                items = items,
                taxRate = inv.taxRate,
                discountPercent = inv.discountPercent,
                discountAmount = inv.discountAmount,
                shippingFee = inv.shippingFee,
                amountPaid = inv.amountPaid
            )

            totalInvoiced += calcs.grandTotal

            when (inv.status.lowercase(Locale.US)) {
                "paid" -> {
                    totalPaid += calcs.grandTotal
                    paidCount++
                }
                "sent" -> {
                    totalOutstanding += calcs.balanceDue
                    pendingCount++
                }
                "overdue" -> {
                    totalOverdue += calcs.balanceDue
                    overdueCount++
                }
                "draft" -> {
                    draftCount++
                }
            }

            // Month aggregation
            try {
                val date = fullDateFmt.parse(inv.issueDate)
                if (date != null) {
                    val mName = monthFmt.format(date)
                    if (monthMap.containsKey(mName)) {
                        val current = monthMap[mName] ?: Pair(0.0, 0.0)
                        val paidPart = if (inv.status.equals("paid", true)) calcs.grandTotal else calcs.amountPaid
                        monthMap[mName] = Pair(current.first + calcs.grandTotal, current.second + paidPart)
                    }
                }
            } catch (_: Exception) {}
        }

        val monthlyItems = monthMap.map { (m, pair) ->
            MonthlyRevenueItem(m, pair.first, pair.second)
        }

        return DashboardAnalytics(
            totalInvoiced = totalInvoiced,
            totalPaid = totalPaid,
            totalOutstanding = totalOutstanding,
            totalOverdue = totalOverdue,
            totalInvoiceCount = invoices.size,
            paidCount = paidCount,
            pendingCount = pendingCount,
            overdueCount = overdueCount,
            draftCount = draftCount,
            monthlyRevenue = monthlyItems
        )
    }

    // Helper: generate next invoice number
    fun generateNextInvoiceNumber(): String {
        val invoices = allInvoices.value
        val nextIndex = invoices.size + 1
        return "INV-${Calendar.getInstance().get(Calendar.YEAR)}-${String.format(Locale.US, "%03d", nextIndex)}"
    }

    // =========================================================================
    // GEMINI AI CHAT & CONVERSATIONAL ASSISTANT (PERSISTENT & CONTEXT-AWARE)
    // =========================================================================

    val dynamicPredictions: StateFlow<List<String>> = combine(
        allInvoices,
        allClients,
        allExpenses,
        businessProfile
    ) { invoices, clients, expenses, profile ->
        chatHistoryManager.generateDynamicPredictions(
            invoices = invoices,
            clients = clients,
            expenses = expenses,
            currencySymbol = profile.defaultCurrencySymbol.ifBlank { "$" }
        )
    }.stateIn(
        viewModelScope,
        SharingStarted.WhileSubscribed(5000),
        listOf(
            "💰 कुल कितना पेंडिंग पेमेंट बाकी है?",
            "📊 Show complete revenue & profit overview",
            "⚡ Create an invoice with GST",
            "💸 Record a new business expense",
            "👥 Who are my active clients?",
            "💡 How to recover overdue payments faster?"
        )
    )

    fun sendAiChatMessage(userPrompt: String, isVoiceInput: Boolean = false, onInvoiceCreated: ((Long) -> Unit)? = null) {
        val trimmed = userPrompt.trim()
        if (trimmed.isBlank()) return

        val userMessage = ChatMessage(text = trimmed, isUser = true, isVoiceInput = isVoiceInput)
        val updatedList = _chatMessages.value + userMessage
        _chatMessages.value = updatedList
        _isAiThinking.value = true

        viewModelScope.launch(kotlinx.coroutines.Dispatchers.IO) {
            val memory = chatHistoryManager.loadMemory()
            val result = geminiService.processUserPrompt(
                prompt = trimmed,
                profile = businessProfile.value,
                existingClients = allClients.value,
                invoices = allInvoices.value,
                expenses = allExpenses.value,
                nextInvoiceNumber = generateNextInvoiceNumber(),
                conversationHistory = updatedList,
                businessMemory = memory
            )

            // Learn user habits, language tone, frequent clients from this turn
            chatHistoryManager.learnFromTurn(
                userPrompt = trimmed,
                isVoice = isVoiceInput,
                aiResult = result,
                existingClients = allClients.value
            )

            var createdInvoiceId: Long? = null
            var finalInvoice: InvoiceEntity? = null
            var savedClient: ClientEntity? = null

            // If action is SAVE_CLIENT
            if (result.clientToSave != null) {
                val newClientId = clientRepository.insertClient(result.clientToSave)
                savedClient = result.clientToSave.copy(id = newClientId)
            }

            // If action is GENERATE_INVOICE
            if (result.invoiceToGenerate != null) {
                val newInvoiceId = invoiceRepository.insertInvoice(result.invoiceToGenerate)
                createdInvoiceId = newInvoiceId
                finalInvoice = result.invoiceToGenerate.copy(id = newInvoiceId)
                kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.Main) {
                    onInvoiceCreated?.invoke(newInvoiceId)
                }
            }

            var savedExpense: ExpenseEntity? = null
            // If action is SAVE_EXPENSE
            if (result.expenseToSave != null) {
                val newExpenseId = expenseRepository.insertExpense(result.expenseToSave)
                savedExpense = result.expenseToSave.copy(id = newExpenseId)
            }

            val botMessage = ChatMessage(
                text = result.conversationalReply,
                isUser = false,
                generatedInvoiceId = createdInvoiceId,
                generatedInvoice = finalInvoice,
                generatedClient = savedClient,
                generatedExpense = savedExpense,
                financialSummary = result.financialSummary,
                matchedInvoices = result.matchedInvoices
            )

            val finalList = _chatMessages.value + botMessage
            _chatMessages.value = finalList
            chatHistoryManager.saveChatHistory(finalList)
            _isAiThinking.value = false
        }
    }

    fun clearAiChat() {
        chatHistoryManager.clearChatHistory()
        _chatMessages.value = listOf(
            chatHistoryManager.createExecutiveGreeting(
                profile = businessProfile.value,
                invoices = allInvoices.value,
                clients = allClients.value
            )
        )
    }

    // =========================================================================
    // EXPENSE MANAGEMENT ACTIONS
    // =========================================================================
    fun saveExpense(expense: ExpenseEntity, onSaved: (Long) -> Unit = {}) {
        viewModelScope.launch(kotlinx.coroutines.Dispatchers.IO) {
            val id = if (expense.id == 0L) {
                expenseRepository.insertExpense(expense)
            } else {
                expenseRepository.updateExpense(expense)
                expense.id
            }

            try {
                val dto = expense.copy(id = id).toBackendDto()
                if (expense.id == 0L) {
                    InvoicelyApiManager.createExpense(dto)
                } else {
                    InvoicelyApiManager.updateExpense(id, dto)
                }
                refreshBackendStats()
            } catch (e: Exception) {}

            kotlinx.coroutines.withContext(kotlinx.coroutines.Dispatchers.Main) {
                onSaved(id)
            }
        }
    }

    fun deleteExpense(expense: ExpenseEntity) {
        viewModelScope.launch(kotlinx.coroutines.Dispatchers.IO) {
            expenseRepository.deleteExpense(expense)
            try {
                if (expense.id > 0) {
                    InvoicelyApiManager.deleteExpense(expense.id)
                    refreshBackendStats()
                }
            } catch (e: Exception) {}
        }
    }

    // =========================================================================
    // BACKEND API ENTITY REFRESH HELPERS
    // =========================================================================

    fun refreshClientsFromBackend() {
        viewModelScope.launch(kotlinx.coroutines.Dispatchers.IO) {
            val res = InvoicelyApiManager.getAllClients()
            if (res.isSuccess) {
                val remoteList = res.getOrNull() ?: emptyList()
                val localList = allClients.value
                val localIds = localList.map { it.id }.toSet()
                for (rc in remoteList) {
                    val entity = rc.toEntity()
                    if (entity.id in localIds) {
                        clientRepository.updateClient(entity)
                    } else {
                        clientRepository.insertClient(entity)
                    }
                }
            }
        }
    }

    fun refreshExpensesFromBackend() {
        viewModelScope.launch(kotlinx.coroutines.Dispatchers.IO) {
            val res = InvoicelyApiManager.getAllExpenses()
            if (res.isSuccess) {
                val remoteList = res.getOrNull() ?: emptyList()
                val localList = allExpenses.value
                val localIds = localList.map { it.id }.toSet()
                for (re in remoteList) {
                    val entity = re.toEntity()
                    if (entity.id in localIds) {
                        expenseRepository.updateExpense(entity)
                    } else {
                        expenseRepository.insertExpense(entity)
                    }
                }
            }
        }
    }

    fun refreshInvoicesFromBackend() {
        viewModelScope.launch(kotlinx.coroutines.Dispatchers.IO) {
            val res = InvoicelyApiManager.getAllInvoices()
            if (res.isSuccess) {
                val remoteList = res.getOrNull() ?: emptyList()
                val localList = allInvoices.value
                val localNumbers = localList.map { it.invoiceNumber }.toSet()
                for (ri in remoteList) {
                    val entity = ri.toEntity()
                    if (entity.invoiceNumber in localNumbers) {
                        val localMatch = localList.find { it.invoiceNumber == entity.invoiceNumber }
                        if (localMatch != null) {
                            invoiceRepository.updateInvoice(entity.copy(id = localMatch.id))
                        }
                    } else {
                        invoiceRepository.insertInvoice(entity)
                    }
                }
                refreshBackendStats()
            }
        }
    }
}
