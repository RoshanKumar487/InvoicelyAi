package com.invoicely.backend.controller;

import com.invoicely.backend.dto.ApiResponse;
import com.invoicely.backend.dto.KnowledgeDocumentRequest;
import com.invoicely.backend.dto.KnowledgeDocumentResponse;
import com.invoicely.backend.security.UserPrincipal;
import com.invoicely.backend.service.CompanyKnowledgeService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/ai/knowledge")
@Tag(name = "AI Knowledge", description = "Index company-specific text documents for AI retrieval")
public class CompanyKnowledgeController {

    private final CompanyKnowledgeService knowledgeService;

    public CompanyKnowledgeController(CompanyKnowledgeService knowledgeService) {
        this.knowledgeService = knowledgeService;
    }

    @PostMapping
    @Operation(summary = "Index or replace a company knowledge text document (company administrator only)")
    public ResponseEntity<ApiResponse<KnowledgeDocumentResponse>> index(
            @Valid @RequestBody KnowledgeDocumentRequest request,
            @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(ApiResponse.ok(
                knowledgeService.indexDocument(request.getTitle(), request.getContent(), principal)));
    }
}
