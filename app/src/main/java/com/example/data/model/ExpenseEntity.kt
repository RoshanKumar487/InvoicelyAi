package com.example.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * Entity representing an expense record with receipt scanning and tax deductible tracking.
 */
@Entity(tableName = "expenses")
data class ExpenseEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0L,
    val title: String,
    val category: String = "General",
    val amount: Double = 0.0,
    val currency: String = "USD",
    val currencySymbol: String = "$",
    val date: String = "",
    val vendor: String = "",
    val paymentMethod: String = "Credit Card",
    val taxDeductible: Boolean = true,
    val taxAmount: Double = 0.0,
    val receiptImageUri: String? = null,
    val notes: String = ""
)
