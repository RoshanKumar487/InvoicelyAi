# Invoicely AI - Enterprise Invoicing, Payroll & Expense Management Platform

[![Platform](https://img.shields.io/badge/Platform-Flutter%20%7C%20Spring%20Boot-blue.svg)](https://flutter.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20%26%20Modular-green.svg)](#architecture)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)](#)

Invoicely AI is an enterprise-grade financial management platform providing AI-powered invoice generation, company letterhead stationery printing, OCR bill scanning, team salary advance tracking, and automated multi-month payroll calculations.

---

## 1. Role-Based Access Control (RBAC) Matrix

The system implements strict Role-Based Access Control across the database, backend Spring Security filter chains, and Flutter presentation layers:

| Role Identifier | Target Profile | Database Access & Assignment | Dashboard & Analytics Scope | Invoices & Quotations | Expense Management & Advances | Payroll & Salary Disbursals | Audit Logs & Settings |
|---|---|---|---|---|---|---|---|
| `SUPER_ADMIN` / `DEVELOPER` | Platform Engineers, Core Devs, System Administrators | Assigned directly via database (`users.role = 'SUPER_ADMIN'` or `'DEVELOPER'`) | **Global Multi-Tenant Scope**: Inspects telemetry, server status, across all registered companies | Full Global CRUD across all tenants | Full Global CRUD; can view and audit all expenses and advance ledgers | Full Global Payroll visibility and ledger audit | Full Database, server configurations, template defaults & system logs |
| `ADMIN` (Org Admin) | Company Owners, Directors, Managing Partners | Assigned upon company registration (`users.role = 'ADMIN'`) | **Company-Wide Scope**: Views entire company revenue, outstanding balances, team expenses, and disbursements | Full Organization CRUD, custom terms, approval workflows | Full Organization CRUD; views team advances, creator filters, and bills | Full Execution: run payroll, auto-deduct advances, mark paid | Edit company profile, upload logo/stamp/signature, team invites |
| `STAFF` / `EMPLOYEE` | Field Employees, Accountants, Sales Staff | Created by Org Admin (`users.role = 'STAFF'` or `'EMPLOYEE'`) | **Personal Operational Scope**: Only displays metrics for expenses and invoices created by this user | Create & View assigned invoices/clients | View only their own logged expenses; submit advance requests | View personal payslips and recorded advance balance | Restricted from company settings, audit logs, and other staff data |

---

## 2. Security & User Permissions Schema

Permissions are stored as comma-delimited tokens in `users.permissions`:

| Permission Key | Description | Applicable Roles |
|---|---|---|
| `INVOICES` | Access invoice listing, template studio, preview and PDF export | `SUPER_ADMIN`, `ADMIN`, `STAFF` |
| `EXPENSES` | Access expense ledger, bill upload, and salary advance logging | `SUPER_ADMIN`, `ADMIN`, `STAFF` |
| `CLIENTS` | Create and manage client master profiles and GSTIN records | `SUPER_ADMIN`, `ADMIN`, `STAFF` |
| `PAYROLL` | Execute payroll runs, review salary advances, and mark disbursals | `SUPER_ADMIN`, `ADMIN` |
| `REPORTS` | Download consolidated multi-sheet Excel and PDF financial statements | `SUPER_ADMIN`, `ADMIN` |
| `AUDIT_LOGS` | Access security audit logs and user action history | `SUPER_ADMIN`, `ADMIN` |
| `SYSTEM_CONFIG` | Direct developer configuration and multi-tenant management | `SUPER_ADMIN`, `DEVELOPER` |

---

## 3. Core Data Properties & Entity Schema

### 3.1 Expense & Advance Entity (`expenses` table)
| Property | Type | Nullable | Description |
|---|---|---|---|
| `id` | `BIGINT` (PK) | No | Auto-generated unique expense record identifier |
| `company_id` | `BIGINT` (FK) | No | Scopes the expense to the specific organization |
| `created_by_user_id` | `BIGINT` (FK) | Yes | Identifies which staff member or admin entered the record |
| `created_by_user_name` | `VARCHAR(120)` | Yes | Cached full name of the creator for fast ledger displays |
| `title` | `VARCHAR(200)` | No | Title or short description of the expense |
| `category` | `VARCHAR(80)` | No | E.g., `'Salary Advance'`, `'Office & Rent'`, `'Hardware & Equipment'` |
| `amount` | `DOUBLE PRECISION`| No | Net expenditure amount |
| `vendor` | `VARCHAR(150)` | Yes | Vendor, store, or Employee Name (when salary advance) |
| `date` | `VARCHAR(30)` | No | ISO Date string (`YYYY-MM-DD`) |
| `status` | `VARCHAR(30)` | No | `'Paid'`, `'Due'`, or `'Pending'` |
| `is_salary_advance` | `BOOLEAN` | No | Flag indicating if this is an employee advance to be recovered in payroll |
| `employee_id` | `BIGINT` (FK) | Yes | Foreign key to `employees.id` for advance reconciliation |
| `employee_name` | `VARCHAR(120)` | Yes | Cached name of employee receiving the advance |
| `advance_settled` | `BOOLEAN` | No | `true` once recovered via payroll run; prevents double recovery |
| `settled_payroll_run_id`| `BIGINT` (FK) | Yes | ID of payroll run where this advance was settled |
| `receipt_image_uri` | `TEXT` | Yes | Base64 or URL of the attached receipt/bill |

### 3.2 Payroll Run & Entry Schema (`payroll_runs` & `payroll_entries`)
| Property | Type | Description |
|---|---|---|
| `monthly_salary` | `DOUBLE PRECISION` | Base gross salary defined in employee master |
| `advance_deduction` | `DOUBLE PRECISION` | Auto-calculated sum of all unsettled advances taken from expenses |
| `unpaid_backlog` | `DOUBLE PRECISION` | Unpaid salary balance from previous payroll months |
| `net_payable` | `DOUBLE PRECISION` | Formula: `monthly_salary - advance_deduction + unpaid_backlog` |
| `status` | `VARCHAR(30)` | `'PENDING'`, `'PROCESSING'`, `'PAID'`, or `'CANCELLED'` |

---

## 4. Pre-Printed Physical Letterhead Paper Mode

The platform provides a dual-mode letterhead architecture:

```
+-------------------------------------------------------------------+
|               MODE A: DIGITAL LETTERHEAD BANNER ACTIVE            |
| - Prints company logo, trade name, GSTIN, PAN, and header banner. |
| - Prints digital styled footer and page numbers at the bottom.   |
+-------------------------------------------------------------------+
|               MODE B: PRE-PRINTED STATIONERY PAPER MODE           |
| - Digital Letterhead = UNSELECTED (isLetterheadActive = false)   |
| - Billed-From company details are completely SUPPRESSED.         |
| - Blank top margin (90-95 pt) reserved for pre-printed letterhead.|
| - Blank bottom margin (30-35 pt) reserved for stationery footer.  |
| - Invoices & Biodata print neatly inside pre-printed paper!      |
+-------------------------------------------------------------------+
```

---

## 5. REST API Reference (CRUD Operations)

### Authentication & Profile
- `POST /api/v1/auth/login`: Authenticate user and return JWT session with role & permissions.
- `POST /api/v1/auth/register`: Register company and root admin account.
- `GET /api/v1/settings/profile`: Retrieve company settings, address, GSTIN, and saved brand assets.
- `PUT /api/v1/settings/profile`: Update business profile and save `logoUrl`, `stampUrl`, `signatureUrl`.

### Invoices
- `GET /api/v1/invoices`: List invoices (scoping applied per role).
- `POST /api/v1/invoices`: Create new invoice or draft.
- `GET /api/v1/invoices/{id}`: Fetch complete invoice details, client info, and line items.
- `PUT /api/v1/invoices/{id}`: Update existing invoice.
- `DELETE /api/v1/invoices/{id}`: Delete invoice record.

### Expenses & Employee Advances
- `GET /api/v1/expenses`: Query expenses (auto-filtered to creator for staff; all for admin).
- `POST /api/v1/expenses`: Log expense or salary advance (links `employeeId` & `employeeName`).
- `PUT /api/v1/expenses/{id}`: Update expense, amount, vendor, or settlement status.
- `DELETE /api/v1/expenses/{id}`: Remove expense entry.
- `POST /api/v1/expenses/ocr`: OCR receipt parsing and auto-fill.

### Employees & Payroll Disbursals
- `GET /api/v1/employees`: List active company employees and salary baselines.
- `POST /api/v1/employees`: Add new employee with designation, code, and salary.
- `PUT /api/v1/employees/{id}`: Update employee details or active status.
- `DELETE /api/v1/employees/{id}`: Delete employee record.
- `GET /api/v1/payroll/runs`: List monthly payroll runs and status.
- `POST /api/v1/payroll/runs`: Generate monthly payroll run (auto-calculates advance deductions).
- `PUT /api/v1/payroll/runs/{id}/status`: Mark payroll run as `'PAID'` and finalize advance settlements.

### Templates & Settings
- `GET /api/v1/templates/settings`: Retrieve organization template settings and active letterhead style.
- `POST /api/v1/templates/settings`: Persist section toggles and custom letterhead styles.

---

## 6. Build & Deployment Instructions

### Web Production Build
```powershell
cd flutter_client
flutter build web --release
```

### Android Release APK Build
```powershell
cd flutter_client
flutter build apk --release
```
Output APK location: `flutter_client/build/app/outputs/flutter-apk/app-release.apk`
Parent copy: `build/app/app-release.apk`

---
Copyright (c) 2025-2026 Invoicely AI. All rights reserved.
