package com.invoicely.backend.repository;

import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Repository
public class CompanyKnowledgeStore {

    private static final Logger LOGGER = LoggerFactory.getLogger(CompanyKnowledgeStore.class);
    private final JdbcTemplate jdbcTemplate;

    public CompanyKnowledgeStore(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @PostConstruct
    public void init() {
        try {
            jdbcTemplate.execute("CREATE EXTENSION IF NOT EXISTS vector");
            jdbcTemplate.execute("""
                    CREATE TABLE IF NOT EXISTS company_knowledge_chunks (
                        id BIGSERIAL PRIMARY KEY,
                        company_id BIGINT NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
                        document_title VARCHAR(200) NOT NULL,
                        chunk_index INT NOT NULL,
                        content TEXT NOT NULL,
                        embedding vector(768) NOT NULL,
                        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                        UNIQUE (company_id, document_title, chunk_index)
                    )
                    """);
            jdbcTemplate.execute("""
                    CREATE INDEX IF NOT EXISTS idx_company_knowledge_company
                        ON company_knowledge_chunks(company_id)
                    """);
            LOGGER.info("Initialized company_knowledge_chunks vector table and index.");
        } catch (Exception ex) {
            LOGGER.warn("pgvector extension or company_knowledge_chunks auto-init skipped (will operate with fallback retrieval): {}", ex.getMessage());
        }
    }

    @Transactional
    public void replaceDocument(Long companyId, String title, List<KnowledgeChunk> chunks) {
        init();
        jdbcTemplate.update("DELETE FROM company_knowledge_chunks WHERE company_id = ? AND document_title = ?",
                companyId, title);
        for (KnowledgeChunk chunk : chunks) {
            jdbcTemplate.update("""
                    INSERT INTO company_knowledge_chunks
                        (company_id, document_title, chunk_index, content, embedding)
                    VALUES (?, ?, ?, ?, CAST(? AS vector))
                    """,
                    companyId, title, chunk.index(), chunk.content(), chunk.embedding());
        }
    }

    public List<KnowledgeChunk> search(Long companyId, String embedding, int limit) {
        try {
            return jdbcTemplate.query("""
                    SELECT document_title, content
                    FROM company_knowledge_chunks
                    WHERE company_id = ?
                      AND embedding <=> CAST(? AS vector) < 0.55
                    ORDER BY embedding <=> CAST(? AS vector)
                    LIMIT ?
                    """,
                    (resultSet, rowNum) -> new KnowledgeChunk(
                            resultSet.getString("document_title"),
                            resultSet.getString("content"),
                            null,
                            null),
                    companyId, embedding, embedding, limit);
        } catch (DataAccessException ex) {
            LOGGER.warn("Vector search failed or table does not exist: {}", ex.getMessage());
            return List.of();
        }
    }

    public record KnowledgeChunk(String title, String content, Integer index, String embedding) {}
}
