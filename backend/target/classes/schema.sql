-- ===================================================================
-- InvoicelyAi Database Schema for Supabase PostgreSQL
-- Multi-Tenant, Role-Based Access Control (DEVELOPER, ADMIN, EMPLOYEE)
-- ===================================================================

-- 1. Companies Table (Multi-Tenant Organizations)
CREATE TABLE IF NOT EXISTS companies (
    id BIGSERIAL PRIMARY KEY,
    company_code VARCHAR(50) NOT NULL UNIQUE,
    company_name VARCHAR(255) NOT NULL,
    details TEXT DEFAULT '',
    gstin VARCHAR(100) DEFAULT '',
    location TEXT DEFAULT '',
    signature_stamp_url TEXT DEFAULT '',
    email VARCHAR(255) DEFAULT '',
    phone VARCHAR(50) DEFAULT '',
    website VARCHAR(255) DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Users Table (Authentication & RBAC)
CREATE TABLE IF NOT EXISTS users (
    id BIGSERIAL PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    mobile VARCHAR(50) DEFAULT '',
    password VARCHAR(255) NOT NULL,
    role VARCHAR(30) NOT NULL DEFAULT 'EMPLOYEE',
    status VARCHAR(30) NOT NULL DEFAULT 'PENDING_APPROVAL',
    company_id BIGINT REFERENCES companies(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Company Join Requests Table (Employee Join Workflow)
CREATE TABLE IF NOT EXISTS company_join_requests (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    company_id BIGINT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    user_full_name VARCHAR(255),
    user_email VARCHAR(255),
    user_mobile VARCHAR(50),
    company_name VARCHAR(255),
    company_code VARCHAR(50),
    status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    request_message TEXT DEFAULT '',
    requested_at TIMESTAMPTZ DEFAULT NOW(),
    reviewed_at TIMESTAMPTZ,
    reviewed_by_user_id BIGINT REFERENCES users(id) ON DELETE SET NULL
);

-- 4. Clients Table
CREATE TABLE IF NOT EXISTS clients (
    id BIGSERIAL PRIMARY KEY,
    company_id BIGINT REFERENCES companies(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    company_name VARCHAR(255) DEFAULT '',
    email VARCHAR(255) DEFAULT '',
    phone VARCHAR(50) DEFAULT '',
    address TEXT DEFAULT '',
    tax_id VARCHAR(255) DEFAULT '',
    preferred_currency VARCHAR(10) DEFAULT 'USD',
    default_payment_terms VARCHAR(50) DEFAULT 'Net 30',
    notes TEXT DEFAULT '',
    created_at BIGINT
);

-- 5. Invoices Table
CREATE TABLE IF NOT EXISTS invoices (
    id BIGSERIAL PRIMARY KEY,
    company_id BIGINT REFERENCES companies(id) ON DELETE CASCADE,
    invoice_number VARCHAR(255) NOT NULL UNIQUE,
    client_id BIGINT REFERENCES clients(id) ON DELETE SET NULL,
    client_name VARCHAR(255) NOT NULL,
    client_company VARCHAR(255) DEFAULT '',
    client_email VARCHAR(255) DEFAULT '',
    client_phone VARCHAR(50) DEFAULT '',
    client_address TEXT DEFAULT '',
    client_tax_id VARCHAR(255) DEFAULT '',
    issue_date VARCHAR(50) NOT NULL,
    due_date VARCHAR(50) NOT NULL,
    po_number VARCHAR(100) DEFAULT '',
    payment_terms VARCHAR(50) DEFAULT 'Net 30',
    currency_code VARCHAR(10) DEFAULT 'USD',
    currency_symbol VARCHAR(10) DEFAULT '$',
    items_json JSONB DEFAULT '[]'::jsonb,
    notes TEXT DEFAULT '',
    terms TEXT DEFAULT '',
    payment_instructions TEXT DEFAULT '',
    tax_rate NUMERIC(5, 2) DEFAULT 0.00,
    tax_label VARCHAR(100) DEFAULT 'Tax',
    tax_type VARCHAR(50) DEFAULT 'GST',
    is_tax_inclusive BOOLEAN DEFAULT FALSE,
    discount_percent NUMERIC(5, 2) DEFAULT 0.00,
    discount_amount NUMERIC(12, 2) DEFAULT 0.00,
    shipping_fee NUMERIC(12, 2) DEFAULT 0.00,
    additional_charges NUMERIC(12, 2) DEFAULT 0.00,
    round_off NUMERIC(12, 2) DEFAULT 0.00,
    amount_paid NUMERIC(12, 2) DEFAULT 0.00,
    status VARCHAR(50) NOT NULL DEFAULT 'Draft',
    template_id VARCHAR(50) DEFAULT 'modern',
    docx_template_title VARCHAR(100) DEFAULT 'INVOICE',
    paid_date BIGINT,
    reminder_last_sent BIGINT,
    shipping_details_json JSONB DEFAULT '{}'::jsonb,
    custom_fields_json JSONB DEFAULT '{}'::jsonb,
    item_columns_json TEXT DEFAULT '',
    created_at BIGINT
);

-- 6. Expenses Table
CREATE TABLE IF NOT EXISTS expenses (
    id BIGSERIAL PRIMARY KEY,
    company_id BIGINT REFERENCES companies(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    category VARCHAR(100) DEFAULT 'General',
    amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    currency VARCHAR(10) DEFAULT 'USD',
    currency_symbol VARCHAR(10) DEFAULT '$',
    date VARCHAR(50) DEFAULT '',
    vendor VARCHAR(255) DEFAULT '',
    payment_method VARCHAR(100) DEFAULT 'Credit Card',
    tax_deductible BOOLEAN DEFAULT TRUE,
    tax_amount NUMERIC(12, 2) DEFAULT 0.00,
    receipt_image_uri TEXT,
    notes TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. Business Profile Table
CREATE TABLE IF NOT EXISTS business_profile (
    id SERIAL PRIMARY KEY,
    company_id BIGINT REFERENCES companies(id) ON DELETE CASCADE,
    business_name VARCHAR(255) NOT NULL DEFAULT 'Apex Nova Dynamics',
    legal_name VARCHAR(255) DEFAULT 'Apex Nova Dynamics LLC',
    email VARCHAR(255) DEFAULT 'billing@apexnova.io',
    phone VARCHAR(50) DEFAULT '',
    website VARCHAR(255) DEFAULT '',
    address TEXT DEFAULT '',
    tax_id VARCHAR(100) DEFAULT '',
    gstin VARCHAR(100) DEFAULT '',
    pan_number VARCHAR(100) DEFAULT '',
    place_of_supply VARCHAR(255) DEFAULT '',
    upi_id VARCHAR(255) DEFAULT '',
    bank_name VARCHAR(255) DEFAULT '',
    account_holder VARCHAR(255) DEFAULT '',
    account_number VARCHAR(100) DEFAULT '',
    ifsc_code VARCHAR(50) DEFAULT '',
    routing_number VARCHAR(50) DEFAULT '',
    swift_bic VARCHAR(50) DEFAULT '',
    payment_link TEXT DEFAULT '',
    logo_uri TEXT DEFAULT '',
    signature_uri TEXT DEFAULT '',
    default_notes TEXT DEFAULT '',
    default_terms TEXT DEFAULT '',
    default_payment_instructions TEXT DEFAULT '',
    default_currency VARCHAR(10) DEFAULT 'USD',
    default_currency_symbol VARCHAR(10) DEFAULT '$',
    default_tax_rate NUMERIC(5, 2) DEFAULT 0.00,
    tax_label VARCHAR(100) DEFAULT 'Tax',
    tax_type VARCHAR(50) DEFAULT 'GST',
    tax_inclusive BOOLEAN DEFAULT FALSE,
    default_payment_terms VARCHAR(50) DEFAULT 'Net 30',
    primary_color VARCHAR(20) DEFAULT '#0A84FF',
    accent_color VARCHAR(20) DEFAULT '#5E5CE6',
    default_template_id VARCHAR(50) DEFAULT 'modern',
    invoice_number_prefix VARCHAR(50) DEFAULT 'INV-',
    next_invoice_number INT DEFAULT 1,
    padding_digits INT DEFAULT 4,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===================================================================
-- Safe Migrations for Existing Tables (in case tables already exist)
-- ===================================================================
ALTER TABLE clients ADD COLUMN IF NOT EXISTS company_id BIGINT REFERENCES companies(id) ON DELETE CASCADE;
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS company_id BIGINT REFERENCES companies(id) ON DELETE CASCADE;
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS shipping_details_json JSONB DEFAULT '{}'::jsonb;
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS custom_fields_json JSONB DEFAULT '{}'::jsonb;
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS item_columns_json TEXT DEFAULT '';
ALTER TABLE expenses ADD COLUMN IF NOT EXISTS company_id BIGINT REFERENCES companies(id) ON DELETE CASCADE;
ALTER TABLE business_profile ADD COLUMN IF NOT EXISTS company_id BIGINT REFERENCES companies(id) ON DELETE CASCADE;

-- ===================================================================
-- Performance Indexes for Multi-Tenant Lookups & RBAC
-- ===================================================================
CREATE INDEX IF NOT EXISTS idx_companies_code ON companies(company_code);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_mobile ON users(mobile);
CREATE INDEX IF NOT EXISTS idx_users_company_id ON users(company_id);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);
CREATE INDEX IF NOT EXISTS idx_join_requests_company ON company_join_requests(company_id, status);
CREATE INDEX IF NOT EXISTS idx_join_requests_user ON company_join_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_clients_company ON clients(company_id);
CREATE INDEX IF NOT EXISTS idx_invoices_company ON invoices(company_id);
CREATE INDEX IF NOT EXISTS idx_invoices_status ON invoices(status);
CREATE INDEX IF NOT EXISTS idx_invoices_client ON invoices(client_id);
CREATE INDEX IF NOT EXISTS idx_expenses_company ON expenses(company_id);
CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category);
CREATE INDEX IF NOT EXISTS idx_business_profile_company ON business_profile(company_id);
