package com.invoicely.backend.dto;

public class KnowledgeDocumentResponse {

    private final String title;
    private final int indexedChunks;

    public KnowledgeDocumentResponse(String title, int indexedChunks) {
        this.title = title;
        this.indexedChunks = indexedChunks;
    }

    public String getTitle() { return title; }
    public int getIndexedChunks() { return indexedChunks; }
}
