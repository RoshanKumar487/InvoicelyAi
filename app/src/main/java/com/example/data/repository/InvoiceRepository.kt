package com.example.data.repository

import com.example.data.local.InvoiceDao
import com.example.data.model.InvoiceEntity
import kotlinx.coroutines.flow.Flow

class InvoiceRepository(private val invoiceDao: InvoiceDao) {

    val allInvoices: Flow<List<InvoiceEntity>> = invoiceDao.getAllInvoices()

    fun getInvoiceById(id: Long): Flow<InvoiceEntity?> = invoiceDao.getInvoiceById(id)

    suspend fun getInvoiceByIdDirect(id: Long): InvoiceEntity? = invoiceDao.getInvoiceByIdDirect(id)

    fun getInvoicesForClient(clientId: Long): Flow<List<InvoiceEntity>> =
        invoiceDao.getInvoicesForClient(clientId)

    suspend fun insertInvoice(invoice: InvoiceEntity): Long = invoiceDao.insertInvoice(invoice)

    suspend fun updateInvoice(invoice: InvoiceEntity) = invoiceDao.updateInvoice(invoice)

    suspend fun deleteInvoice(invoice: InvoiceEntity) = invoiceDao.deleteInvoice(invoice)

    suspend fun deleteInvoiceById(id: Long) = invoiceDao.deleteInvoiceById(id)

    suspend fun updateStatus(id: Long, status: String) = invoiceDao.updateStatus(id, status)

    suspend fun updateReminderSent(id: Long, timestamp: Long) =
        invoiceDao.updateReminderSent(id, timestamp)

    suspend fun deleteAllInvoices() = invoiceDao.deleteAllInvoices()
}
