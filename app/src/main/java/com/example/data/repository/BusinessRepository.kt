package com.example.data.repository

import com.example.data.local.BusinessProfileDao
import com.example.data.model.BusinessProfile
import kotlinx.coroutines.flow.Flow

class BusinessRepository(private val businessProfileDao: BusinessProfileDao) {

    val profile: Flow<BusinessProfile?> = businessProfileDao.getBusinessProfile()

    suspend fun getProfileDirect(): BusinessProfile? = businessProfileDao.getBusinessProfileDirect()

    suspend fun saveProfile(profile: BusinessProfile) =
        businessProfileDao.insertOrUpdate(profile)

    suspend fun clearProfile() = businessProfileDao.deleteAll()
}
