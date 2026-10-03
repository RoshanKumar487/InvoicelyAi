package com.invoicely.backend.controller;

import com.invoicely.backend.dto.ApiResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/health")
@Tag(name = "Health", description = "Service health and readiness check for Docker and cloud deployments")
public class HealthController {

    @GetMapping
    @Operation(summary = "Check backend service health status")
    public ResponseEntity<ApiResponse<Map<String, Object>>> checkHealth() {
        Map<String, Object> healthInfo = Map.of(
            "status", "UP",
            "timestamp", Instant.now().toString(),
            "service", "InvoicelyAi Backend"
        );
        return ResponseEntity.ok(ApiResponse.ok("Service is running smoothly", healthInfo));
    }
}
