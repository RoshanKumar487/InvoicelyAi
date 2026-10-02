package com.example.data.repository

import com.example.data.local.ClientDao
import com.example.data.model.ClientEntity
import kotlinx.coroutines.flow.Flow

class ClientRepository(private val clientDao: ClientDao) {

    val allClients: Flow<List<ClientEntity>> = clientDao.getAllClients()

    fun getClientById(id: Long): Flow<ClientEntity?> = clientDao.getClientById(id)

    suspend fun getClientByIdDirect(id: Long): ClientEntity? = clientDao.getClientByIdDirect(id)

    suspend fun insertClient(client: ClientEntity): Long = clientDao.insertClient(client)

    suspend fun updateClient(client: ClientEntity) = clientDao.updateClient(client)

    suspend fun deleteClient(client: ClientEntity) = clientDao.deleteClient(client)

    suspend fun deleteClientById(id: Long) = clientDao.deleteClientById(id)

    suspend fun deleteAllClients() = clientDao.deleteAllClients()
}
