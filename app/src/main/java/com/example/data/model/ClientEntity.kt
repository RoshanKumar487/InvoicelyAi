package com.example.data.model

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "clients")
data class ClientEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val name: String,
    val companyName: String = "",
    val email: String = "",
    val phone: String = "",
    val address: String = "",
    val taxId: String = "",
    val preferredCurrency: String = "USD",
    val defaultPaymentTerms: String = "Net 30",
    val notes: String = "",
    val createdAt: Long = System.currentTimeMillis()
)
