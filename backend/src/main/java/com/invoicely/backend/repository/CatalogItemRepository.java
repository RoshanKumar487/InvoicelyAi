package com.invoicely.backend.repository;

import com.invoicely.backend.model.CatalogItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CatalogItemRepository extends JpaRepository<CatalogItem, Long> {
    List<CatalogItem> findByCompanyIdAndIsActiveTrueOrderByNameAsc(Long companyId);
    List<CatalogItem> findByCompanyIdOrderByNameAsc(Long companyId);
    Optional<CatalogItem> findByIdAndCompanyId(Long id, Long companyId);
    List<CatalogItem> findByCompanyIdAndNameContainingIgnoreCase(Long companyId, String name);
}
