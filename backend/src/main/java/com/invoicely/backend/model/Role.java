package com.invoicely.backend.model;

/**
 * System roles:
 * - DEVELOPER: Global access to all organizations, data, and management pages.
 * - ADMIN: Organization Admin. Full access to their company's data and employee join requests.
 * - EMPLOYEE: Organization Staff. Operational access to create/manage invoices, clients, expenses.
 */
public enum Role {
    DEVELOPER,
    ADMIN,
    EMPLOYEE
}
