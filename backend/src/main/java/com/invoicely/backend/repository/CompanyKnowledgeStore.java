package com.invoicely.backend.repository;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Repository
public class CompanyKnowledgeStore {

    private final JdbcTemplate jdbcTemplate;

    public CompanyKnowledgeStore(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Transactional
    public void replaceDocument(Long companyId, String title, List<KnowledgeChunk> chunks) {
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
    }

    public record KnowledgeChunk(String title, String content, Integer index, String embedding) {}
}
