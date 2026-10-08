package com.invoicely.backend.service;

import com.invoicely.backend.exception.ResourceNotFoundException;
import com.invoicely.backend.model.Client;
import com.invoicely.backend.repository.ClientRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class ClientService {

    private final ClientRepository clientRepository;

    @Autowired
    public ClientService(ClientRepository clientRepository) {
        this.clientRepository = clientRepository;
    }

    public List<Client> getAllClients() {
        return clientRepository.findAllByOrderByCreatedAtDesc();
    }

    public List<Client> getClients(Long companyId, String search) {
        if (companyId != null) {
            if (search != null && !search.trim().isEmpty()) {
                String q = search.trim();
                return clientRepository.findByCompanyIdAndNameContainingIgnoreCaseOrCompanyIdAndCompanyNameContainingIgnoreCase(companyId, q, companyId, q);
            }
            return clientRepository.findByCompanyIdOrderByCreatedAtDesc(companyId);
        }

        if (search != null && !search.trim().isEmpty()) {
            return clientRepository.findByNameContainingIgnoreCaseOrCompanyNameContainingIgnoreCase(search.trim(), search.trim());
        }
        return clientRepository.findAllByOrderByCreatedAtDesc();
    }

    public Client getClientById(Long id) {
        return clientRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Client", "id", id));
    }

    public Client getClientById(Long id, Long companyId) {
        if (companyId != null) {
            return clientRepository.findByIdAndCompanyId(id, companyId)
                    .orElseThrow(() -> new ResourceNotFoundException("Client", "id", id));
        }
        return getClientById(id);
    }

    public List<Client> searchClients(String query) {
        if (query == null || query.trim().isEmpty()) {
            return getAllClients();
        }
        return clientRepository.findByNameContainingIgnoreCaseOrCompanyNameContainingIgnoreCase(query.trim(), query.trim());
    }

    @Transactional
    public Client createClient(Client client) {
        return createClient(client, client.getCompanyId());
    }

    @Transactional
    public Client createClient(Client client, Long companyId) {
        if (companyId != null && client.getCompanyId() == null) {
            client.setCompanyId(companyId);
        }
        if (client.getCreatedAt() == null) {
            client.setCreatedAt(System.currentTimeMillis());
        }
        return clientRepository.save(client);
    }

    @Transactional
    public Client updateClient(Long id, Client updated) {
        return updateClient(id, updated, updated.getCompanyId());
    }

    @Transactional
    public Client updateClient(Long id, Client updated, Long companyId) {
        Client existing = getClientById(id, companyId);
        if (companyId != null) {
            existing.setCompanyId(companyId);
        }
        existing.setName(updated.getName());
        existing.setCompanyName(updated.getCompanyName());
        existing.setEmail(updated.getEmail());
        existing.setPhone(updated.getPhone());
        existing.setAddress(updated.getAddress());
        existing.setTaxId(updated.getTaxId());
        existing.setPreferredCurrency(updated.getPreferredCurrency());
        existing.setDefaultPaymentTerms(updated.getDefaultPaymentTerms());
        existing.setNotes(updated.getNotes());
        return clientRepository.save(existing);
    }

    @Transactional
    public void deleteClient(Long id) {
        deleteClient(id, null);
    }

    @Transactional
    public void deleteClient(Long id, Long companyId) {
        Client existing = getClientById(id, companyId);
        clientRepository.delete(existing);
    }
}
