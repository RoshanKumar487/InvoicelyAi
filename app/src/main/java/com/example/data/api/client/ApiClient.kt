package com.example.data.api.client

import com.example.data.api.ApiConfig
import com.example.data.api.service.InvoicelyApiService
import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import okhttp3.Interceptor
import okhttp3.OkHttpClient
import okhttp3.Response
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.moshi.MoshiConverterFactory
import java.util.concurrent.TimeUnit

/**
 * Singleton network client configuring OkHttpClient, JWT Auth Interceptor, Moshi, and Retrofit.
 */
object ApiClient {

    @Volatile
    private var cachedToken: String? = null

    @Volatile
    private var apiService: InvoicelyApiService? = null

    fun setAuthToken(token: String?) {
        cachedToken = token
    }

    fun getAuthToken(): String? = cachedToken ?: com.example.data.repository.AuthSessionManager.jwtToken.value

    private val authInterceptor = Interceptor { chain ->
        val original = chain.request()
        val requestBuilder = original.newBuilder()

        val activeToken = getAuthToken()
        if (!activeToken.isNullOrBlank()) {
            val bearer = if (activeToken.startsWith("Bearer ", ignoreCase = true)) activeToken else "Bearer $activeToken"
            requestBuilder.header("Authorization", bearer)
            requestBuilder.header("X-Auth-Token", activeToken)
            requestBuilder.header("X-Session-Id", activeToken)
        }

        requestBuilder.header("Content-Type", "application/json")
        requestBuilder.header("Accept", "application/json")

        val request = requestBuilder.build()
        val response = chain.proceed(request)

        if (response.code == 401) {
            com.example.data.repository.AuthSessionManager.notifySessionExpired()
        }

        response
    }

    private val loggingInterceptor = HttpLoggingInterceptor().apply {
        level = HttpLoggingInterceptor.Level.BODY
    }

    private val okHttpClient: OkHttpClient by lazy {
        buildOkHttpClient()
    }

    private fun buildOkHttpClient(): OkHttpClient {
        return OkHttpClient.Builder()
            .addInterceptor(authInterceptor)
            .addInterceptor(loggingInterceptor)
            .connectTimeout(60, TimeUnit.SECONDS)
            .readTimeout(60, TimeUnit.SECONDS)
            .writeTimeout(60, TimeUnit.SECONDS)
            .retryOnConnectionFailure(true)
            .build()
    }

    private val moshi: Moshi = Moshi.Builder()
        .addLast(KotlinJsonAdapterFactory())
        .build()

    fun getService(): InvoicelyApiService {
        return apiService ?: synchronized(this) {
            apiService ?: buildRetrofit().create(InvoicelyApiService::class.java).also {
                apiService = it
            }
        }
    }

    private fun buildRetrofit(): Retrofit {
        val currentBaseUrl = ApiConfig.baseUrl.value
        return Retrofit.Builder()
            .baseUrl(currentBaseUrl)
            .client(okHttpClient)
            .addConverterFactory(MoshiConverterFactory.create(moshi))
            .build()
    }

    fun resetClient() {
        synchronized(this) {
            apiService = null
        }
    }
}
