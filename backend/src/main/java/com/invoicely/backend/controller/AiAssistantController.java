package com.invoicely.backend.controller;

import com.invoicely.backend.dto.AiChatRequest;
import com.invoicely.backend.dto.AiChatResponse;
import com.invoicely.backend.dto.AiInvoiceDraftResponse;
import com.invoicely.backend.dto.ReceiptScanRequest;
import com.invoicely.backend.dto.ReceiptScanResponse;
import com.invoicely.backend.dto.ApiResponse;
import com.invoicely.backend.security.UserPrincipal;
import com.invoicely.backend.service.AiAssistantService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.PathVariable;

@RestController
@RequestMapping("/api/v1/ai")
@Tag(name = "AI Assistant", description = "Read-only, tenant-scoped AI answers grounded in business records")
public class AiAssistantController {

    private final AiAssistantService aiAssistantService;

    public AiAssistantController(AiAssistantService aiAssistantService) {
        this.aiAssistantService = aiAssistantService;
    }

    @PostMapping("/chat")
    @Operation(summary = "Ask a read-only question about the authenticated user's business data")
    public ResponseEntity<ApiResponse<AiChatResponse>> chat(
            @Valid @RequestBody AiChatRequest request,
            @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(ApiResponse.ok(
                aiAssistantService.answer(request.getMessage(), principal)));
    }

    @PostMapping("/commands/{commandId}/confirm")
    @Operation(summary = "Confirm and execute one pending AI-created draft command")
    public ResponseEntity<ApiResponse<AiChatResponse>> confirm(
            @PathVariable String commandId,
            @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(ApiResponse.ok(aiAssistantService.confirm(commandId, principal)));
    }

    @PostMapping("/invoice-draft")
    @Operation(summary = "Parse a natural-language invoice description into an editable, unsaved invoice draft")
    public ResponseEntity<ApiResponse<AiInvoiceDraftResponse>> invoiceDraft(
            @Valid @RequestBody AiChatRequest request,
            @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(ApiResponse.ok(
                aiAssistantService.prepareInvoiceDraft(request.getMessage(), principal)));
    }

    @PostMapping("/receipt-scan")
    @Operation(summary = "Extract expense details from a receipt image; user review and explicit save are still required")
    public ResponseEntity<ApiResponse<ReceiptScanResponse>> receiptScan(
            @Valid @RequestBody ReceiptScanRequest request,
            @AuthenticationPrincipal UserPrincipal principal) {
        return ResponseEntity.ok(ApiResponse.ok(
                aiAssistantService.scanReceipt(request.getImageBase64(), request.getMimeType(), principal)));
    }
}
