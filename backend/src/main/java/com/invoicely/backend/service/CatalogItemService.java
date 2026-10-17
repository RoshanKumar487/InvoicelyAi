package com.invoicely.backend.service;

import com.invoicely.backend.exception.ResourceNotFoundException;
import com.invoicely.backend.model.CatalogItem;
import com.invoicely.backend.repository.CatalogItemRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class CatalogItemService {

    private final CatalogItemRepository catalogItemRepository;

    public CatalogItemService(CatalogItemRepository catalogItemRepository) {
        this.catalogItemRepository = catalogItemRepository;
    }

    @Transactional(readOnly = true)
    public List<CatalogItem> listItems(Long companyId, String search) {
        if (search != null && !search.trim().isEmpty()) {
            return catalogItemRepository.findByCompanyIdAndNameContainingIgnoreCase(companyId, search.trim());
        }
        return catalogItemRepository.findByCompanyIdOrderByNameAsc(companyId);
    }

    @Transactional(readOnly = true)
    public CatalogItem getItem(Long id, Long companyId) {
        return catalogItemRepository.findByIdAndCompanyId(id, companyId)
                .orElseThrow(() -> new ResourceNotFoundException("CatalogItem", "id", id));
    }

    @Transactional
    public CatalogItem createItem(CatalogItem item, Long companyId) {
        item.setCompanyId(companyId);
        return catalogItemRepository.save(item);
    }

    @Transactional
    public CatalogItem updateItem(Long id, CatalogItem updated, Long companyId) {
        CatalogItem existing = getItem(id, companyId);
        existing.setName(updated.getName());
        existing.setDescription(updated.getDescription());
        existing.setItemType(updated.getItemType());
        existing.setHsnSacCode(updated.getHsnSacCode());
        existing.setUnitPrice(updated.getUnitPrice());
        existing.setUnit(updated.getUnit());
        existing.setTaxRate(updated.getTaxRate());
        if (updated.getIsActive() != null) {
            existing.setIsActive(updated.getIsActive());
        }
        return catalogItemRepository.save(existing);
    }

    @Transactional
    public void deleteItem(Long id, Long companyId) {
        CatalogItem existing = getItem(id, companyId);
        catalogItemRepository.delete(existing);
    }
}
