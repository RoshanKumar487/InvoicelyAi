package com.invoicely.backend.repository;

import com.invoicely.backend.model.Client;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ClientRepository extends JpaRepository<Client, Long> {
    List<Client> findAllByOrderByCreatedAtDesc();
    List<Client> findByNameContainingIgnoreCaseOrCompanyNameContainingIgnoreCase(String name, String companyName);

    // Multi-tenant company queries
    List<Client> findByCompanyIdOrderByCreatedAtDesc(Long companyId);
    List<Client> findTop12ByCompanyIdOrderByCreatedAtDesc(Long companyId);
    List<Client> findByCompanyIdAndNameContainingIgnoreCase(Long companyId, String name);
    List<Client> findByCompanyIdAndNameContainingIgnoreCaseOrCompanyIdAndCompanyNameContainingIgnoreCase(Long companyId1, String name, Long companyId2, String companyName);
    java.util.Optional<Client> findByIdAndCompanyId(Long id, Long companyId);
    long countByCompanyId(Long companyId);
}
