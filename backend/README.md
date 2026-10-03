# InvoicelyAi Backend Service (Spring Boot 3 + PostgreSQL)

An enterprise multi-tenant REST API service built with **Spring Boot 3**, **Spring Security (JWT)**, **Spring Data JPA**, and **PostgreSQL (Supabase)**.

---

## 🏛️ Architecture & Clean Layered Design

```
backend/
├── pom.xml                                 # Maven build descriptor
├── build.gradle                            # Gradle build descriptor
├── settings.gradle                         # Gradle standalone project settings
├── README.md                               # Developer guide
└── src/main/
    ├── java/com/invoicely/backend/
    │   ├── InvoicelyBackendApplication.java # Spring Boot Main Class
    │   ├── config/                         # Security, CORS & Swagger config
    │   │   ├── CorsConfig.java
    │   │   ├── OpenApiConfig.java          # OpenAPI + JWT Bearer Auth for Swagger
    │   │   └── SecurityConfig.java         # Spring Security 6 / Stateless JWT Filter Chain
    │   ├── controller/                     # REST API Controllers
    │   │   ├── AuthController.java         # /api/v1/auth (Register & Login)
    │   │   ├── CompanyController.java      # /api/v1/companies (Join requests & Employees)
    │   │   ├── InvoiceController.java      # /api/v1/invoices (Multi-tenant scoped)
    │   │   ├── ClientController.java       # /api/v1/clients (Multi-tenant scoped)
    │   │   ├── ExpenseController.java      # /api/v1/expenses (Multi-tenant scoped)
    │   │   ├── BusinessProfileController.java # /api/v1/profile (Multi-tenant scoped)
    │   │   └── DashboardController.java    # /api/v1/dashboard/stats
    │   ├── dto/                            # API Responses & Data Transfer Objects
    │   │   ├── ApiResponse.java
    │   │   ├── AuthResponse.java
    │   │   ├── LoginRequest.java
    │   │   ├── RegisterCompanyRequest.java
    │   │   ├── RegisterEmployeeRequest.java
    │   │   ├── RegisterDeveloperRequest.java
    │   │   ├── CompanyJoinRequestDto.java
    │   │   ├── CompanySummaryDto.java
    │   │   ├── JoinRequestActionRequest.java
    │   │   ├── UserSummaryDto.java
    │   │   └── DashboardStatsResponse.java
    │   ├── exception/                      # Global HTTP Error Handling
    │   │   ├── GlobalExceptionHandler.java
    │   │   └── ResourceNotFoundException.java
    │   ├── model/                          # JPA Entities mapping to Supabase
    │   │   ├── Role.java                   # DEVELOPER, ADMIN, EMPLOYEE
    │   │   ├── UserStatus.java             # ACTIVE, PENDING_APPROVAL, REJECTED, INACTIVE
    │   │   ├── JoinRequestStatus.java      # PENDING, APPROVED, REJECTED
    │   │   ├── User.java
    │   │   ├── Company.java
    │   │   ├── CompanyJoinRequest.java
    │   │   ├── Invoice.java
    │   │   ├── Client.java
    │   │   ├── Expense.java
    │   │   └── BusinessProfile.java
    │   ├── repository/                     # Spring Data JPA Repositories
    │   │   ├── UserRepository.java
    │   │   ├── CompanyRepository.java
    │   │   ├── CompanyJoinRequestRepository.java
    │   │   ├── InvoiceRepository.java
    │   │   ├── ClientRepository.java
    │   │   ├── ExpenseRepository.java
    │   │   └── BusinessProfileRepository.java
    │   ├── security/                       # JWT & Principal components
    │   │   ├── CustomUserDetailsService.java
    │   │   ├── JwtAuthenticationFilter.java
    │   │   ├── JwtTokenProvider.java
    │   │   └── UserPrincipal.java
    │   └── service/                        # Business Logic Layer
    │       ├── AuthService.java
    │       ├── CompanyService.java
    │       ├── InvoiceService.java
    │       ├── ClientService.java
    │       ├── ExpenseService.java
    │       └── BusinessProfileService.java
    └── resources/
        ├── application.properties          # Active Database & Server Config
        ├── application.properties.example  # Config Template
        └── schema.sql                      # Supabase PostgreSQL Database Schema
```

---

## 👥 3-Tier Role-Based Access Control (RBAC)

1. **`DEVELOPER`**:
   - Platform developer with global administrative access across all organizations.
   - Register via `POST /api/v1/auth/register-developer` with secret key (`app.developer.secret-key`).
2. **`ADMIN`**:
   - Company owner/administrator.
   - Registers their company via `POST /api/v1/auth/register-company`.
   - Obtains a unique `company_code` to share with team members.
   - Approves or rejects employee join requests via `POST /api/v1/companies/join-requests/{id}/action`.
   - Full control over their company's invoices, expenses, clients, and business profile.
3. **`EMPLOYEE`**:
   - Staff member.
   - Registers via `POST /api/v1/auth/register-employee` using the company code.
   - Account starts in `PENDING_APPROVAL` status until approved by their Company Admin.
   - Once approved, has operational access to create and manage invoices, clients, and expenses for their company.

---

## 🚀 How to Run

### 1. Configure your Database Credentials
Open `src/main/resources/application.properties` and replace:
```properties
spring.datasource.url=jdbc:postgresql://db.[YOUR_PROJECT_REF].supabase.co:5432/postgres?sslmode=require
spring.datasource.password=YOUR_SUPABASE_PASSWORD
```

### 2. Run Database Migrations
Run `src/main/resources/schema.sql` in your Supabase SQL Editor to create or update all tables and indexes.

### 3. Start the Server
From the root directory or inside `backend/`:

Using Maven:
```powershell
mvn spring-boot:run
```

Or using Gradle:
```powershell
..\gradlew.bat bootRun
```

---

## 📖 Interactive API Documentation (Swagger UI)

Once running, open your web browser:
👉 **[http://localhost:8080/swagger-ui/index.html](http://localhost:8080/swagger-ui/index.html)**

Click the **Authorize** button in Swagger to enter your JWT token (`Bearer <token>`) and test protected endpoints!
