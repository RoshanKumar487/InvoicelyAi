package com.invoicely.backend.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.invoicely.backend.dto.KnowledgeDocumentResponse;
import com.invoicely.backend.model.Role;
import com.invoicely.backend.repository.CompanyKnowledgeStore;
import com.invoicely.backend.repository.CompanyKnowledgeStore.KnowledgeChunk;
import com.invoicely.backend.security.UserPrincipal;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.dao.DataAccessException;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.util.UriComponentsBuilder;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class CompanyKnowledgeService {

    private static final Logger LOGGER = LoggerFactory.getLogger(CompanyKnowledgeService.class);
    private static final int CHUNK_SIZE = 1200;
    private static final int CHUNK_OVERLAP = 150;
    private static final int EMBEDDING_DIMENSIONS = 768;
    private static final int MAX_CONTEXT_CHUNKS = 4;
    private final CompanyKnowledgeStore knowledgeStore;
    private final RestClient restClient;
    private final String apiKey;
    private final String model;

    public CompanyKnowledgeService(
            CompanyKnowledgeStore knowledgeStore,
            RestClient.Builder restClientBuilder,
            @Value("${app.ai.gemini.api-key:}") String apiKey,
            @Value("${app.ai.gemini.embedding-model:gemini-embedding-001}") String model) {
        this.knowledgeStore = knowledgeStore;
        this.restClient = restClientBuilder.build();
        this.apiKey = apiKey;
        this.model = model;
    }

    public KnowledgeDocumentResponse indexDocument(String title, String content, UserPrincipal principal) {
        if (principal == null || principal.getCompanyId() == null || principal.getRole() != Role.ADMIN) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                    "Only a company administrator can add company knowledge.");
        }
        if (apiKey == null || apiKey.isBlank()) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "AI knowledge indexing is not configured. Set GEMINI_API_KEY on the backend.");
        }
        String cleanTitle = title == null ? "" : title.trim();
        String cleanContent = content == null ? "" : content.trim();
        if (cleanTitle.isBlank() || cleanTitle.length() > 200 || cleanContent.isBlank() || cleanContent.length() > 50_000) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Provide a title (up to 200 characters) and text content (up to 50,000 characters).");
        }

        List<String> textChunks = chunk(cleanContent);
        List<KnowledgeChunk> indexed = new ArrayList<>(textChunks.size());
        for (int i = 0; i < textChunks.size(); i++) {
            indexed.add(new KnowledgeChunk(cleanTitle, textChunks.get(i), i,
                    vectorLiteral(embed(textChunks.get(i), "RETRIEVAL_DOCUMENT"))));
        }
        try {
            knowledgeStore.replaceDocument(principal.getCompanyId(), cleanTitle, indexed);
        } catch (DataAccessException ex) {
            LOGGER.error("Could not store company knowledge chunks.", ex);
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Company knowledge storage is unavailable. Verify that the vector schema migration was applied.");
        }
        return new KnowledgeDocumentResponse(cleanTitle, indexed.size());
    }

    public List<KnowledgeChunk> retrieve(Long companyId, String query) {
        if (apiKey == null || apiKey.isBlank()) return List.of();
        String embedding = vectorLiteral(embed(query, "RETRIEVAL_QUERY"));
        try {
            return knowledgeStore.search(companyId, embedding, MAX_CONTEXT_CHUNKS);
        } catch (DataAccessException ex) {
            LOGGER.error("Could not retrieve company knowledge chunks.", ex);
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE,
                    "Company knowledge search is unavailable. Verify that the vector schema migration was applied.");
        }
    }

    private List<String> chunk(String content) {
        List<String> chunks = new ArrayList<>();
        int start = 0;
        while (start < content.length()) {
            int end = Math.min(start + CHUNK_SIZE, content.length());
            if (end < content.length()) {
                int boundary = content.lastIndexOf(' ', end);
                if (boundary > start + CHUNK_SIZE / 2) end = boundary;
            }
            chunks.add(content.substring(start, end).trim());
            if (end == content.length()) break;
            start = Math.max(end - CHUNK_OVERLAP, start + 1);
        }
        return chunks.stream().filter(chunk -> !chunk.isBlank()).collect(Collectors.toList());
    }

    private List<Double> embed(String text, String taskType) {
        String uri = UriComponentsBuilder
                .fromUriString("https://generativelanguage.googleapis.com/v1beta/models/{model}:embedContent")
                .buildAndExpand(model)
                .toUriString();
        Map<String, Object> payload = Map.of(
                "model", "models/" + model,
                "content", Map.of("parts", List.of(Map.of("text", text))),
                "taskType", taskType,
                "outputDimensionality", EMBEDDING_DIMENSIONS);
        try {
            JsonNode response = restClient.post()
                    .uri(uri)
                    .header("x-goog-api-key", apiKey)
                    .body(payload)
                    .retrieve()
                    .body(JsonNode.class);
            JsonNode values = response == null ? null : response.path("embedding").path("values");
            if (values == null || !values.isArray() || values.size() != EMBEDDING_DIMENSIONS) {
                throw new ResponseStatusException(HttpStatus.BAD_GATEWAY,
                        "The embedding provider returned an invalid vector.");
            }
            List<Double> vector = new ArrayList<>(values.size());
            values.forEach(value -> vector.add(value.asDouble()));
            return vector;
        } catch (ResponseStatusException ex) {
            throw ex;
        } catch (RuntimeException ex) {
            LOGGER.warn("Knowledge embedding failed with {}.", ex.getClass().getSimpleName());
            throw new ResponseStatusException(HttpStatus.BAD_GATEWAY,
                    "The knowledge embedding provider is temporarily unavailable.");
        }
    }

    private String vectorLiteral(List<Double> values) {
        return values.stream()
                .map(value -> String.format(Locale.ROOT, "%.8f", value))
                .collect(Collectors.joining(",", "[", "]"));
    }
}
