package com.invoicely.backend.controller;

import com.invoicely.backend.dto.ApiResponse;
import com.invoicely.backend.model.CatalogItem;
import com.invoicely.backend.model.Role;
import com.invoicely.backend.security.UserPrincipal;
import com.invoicely.backend.service.CatalogItemService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/catalog-items")
@Tag(name = "Catalog & Rate Cards", description = "Manage products, billable services, hourly guard rate cards, and HSN/SAC codes")
public class CatalogItemController {

    private final CatalogItemService catalogItemService;

    public CatalogItemController(CatalogItemService catalogItemService) {
        this.catalogItemService = catalogItemService;
    }

    @GetMapping
    @Operation(summary = "List catalog items and services for current workspace")
    public ResponseEntity<ApiResponse<List<CatalogItem>>> listItems(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Long companyId,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long resolvedCompanyId = resolveCompanyId(principal, companyId);
        List<CatalogItem> items = catalogItemService.listItems(resolvedCompanyId, search);
        return ResponseEntity.ok(ApiResponse.ok(items));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get single catalog item by ID")
    public ResponseEntity<ApiResponse<CatalogItem>> getItem(
            @PathVariable Long id,
            @RequestParam(required = false) Long companyId,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long resolvedCompanyId = resolveCompanyId(principal, companyId);
        CatalogItem item = catalogItemService.getItem(id, resolvedCompanyId);
        return ResponseEntity.ok(ApiResponse.ok(item));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'DEVELOPER')")
    @Operation(summary = "Create a new catalog item or service rate card")
    public ResponseEntity<ApiResponse<CatalogItem>> createItem(
            @RequestBody CatalogItem item,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long resolvedCompanyId = resolveCompanyId(principal, item.getCompanyId());
        CatalogItem created = catalogItemService.createItem(item, resolvedCompanyId);
        return new ResponseEntity<>(ApiResponse.ok("Item added to catalog", created), HttpStatus.CREATED);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'DEVELOPER')")
    @Operation(summary = "Update an existing catalog item or service rate card")
    public ResponseEntity<ApiResponse<CatalogItem>> updateItem(
            @PathVariable Long id,
            @RequestBody CatalogItem item,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long resolvedCompanyId = resolveCompanyId(principal, item.getCompanyId());
        CatalogItem updated = catalogItemService.updateItem(id, item, resolvedCompanyId);
        return ResponseEntity.ok(ApiResponse.ok("Catalog item updated successfully", updated));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'DEVELOPER')")
    @Operation(summary = "Delete a catalog item")
    public ResponseEntity<ApiResponse<Void>> deleteItem(
            @PathVariable Long id,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long resolvedCompanyId = resolveCompanyId(principal, null);
        catalogItemService.deleteItem(id, resolvedCompanyId);
        return ResponseEntity.ok(ApiResponse.ok("Item removed from catalog", null));
    }

    private Long resolveCompanyId(UserPrincipal principal, Long requestedCompanyId) {
        if (principal == null) return requestedCompanyId;
        if (principal.getRole() == Role.DEVELOPER) return requestedCompanyId != null ? requestedCompanyId : principal.getCompanyId();
        return principal.getCompanyId() != null ? principal.getCompanyId() : requestedCompanyId;
    }
}
