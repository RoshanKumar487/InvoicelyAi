package com.invoicely.backend.controller;

import com.invoicely.backend.dto.ApiResponse;
import com.invoicely.backend.model.Role;
import com.invoicely.backend.security.UserPrincipal;
import com.invoicely.backend.service.EmailService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/email")
@Tag(name = "Email & Reminders", description = "SMTP test gateway, invoice payment reminders, and expense due date alerts")
public class EmailController {

    private final EmailService emailService;

    public EmailController(EmailService emailService) {
        this.emailService = emailService;
    }

    @PostMapping("/test")
    @Operation(summary = "Test SMTP connectivity and dispatch verification test email")
    public ResponseEntity<ApiResponse<Map<String, Object>>> testSmtp(
            @RequestBody(required = false) Map<String, Object> body,
            @AuthenticationPrincipal UserPrincipal principal) {
        String toEmail = body != null && body.containsKey("toEmail") ? (String) body.get("toEmail") : null;
        String host = body != null && body.containsKey("host") ? (String) body.get("host") : null;
        Integer port = body != null && body.containsKey("port") ? ((Number) body.get("port")).intValue() : null;
        String username = body != null && body.containsKey("username") ? (String) body.get("username") : null;
        String password = body != null && body.containsKey("password") ? (String) body.get("password") : null;
        Boolean startTls = body != null && body.containsKey("startTls") ? (Boolean) body.get("startTls") : null;

        Map<String, Object> result = emailService.testSmtp(toEmail, host, port, username, password, startTls);
        boolean success = Boolean.TRUE.equals(result.get("success"));
        if (success) {
            return ResponseEntity.ok(ApiResponse.ok("SMTP verified successfully", result));
        } else {
            return ResponseEntity.badRequest().body(new ApiResponse<>(false, (String) result.get("message"), result));
        }
    }

    @PostMapping("/send-invoice-reminder")
    @Operation(summary = "Send invoice overdue / due payment reminder to client")
    public ResponseEntity<ApiResponse<Map<String, Object>>> sendInvoiceReminder(
            @RequestBody Map<String, Object> request,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long invoiceId = ((Number) request.get("invoiceId")).longValue();
        String recipientEmail = request.containsKey("recipientEmail") ? (String) request.get("recipientEmail") : null;
        String customNote = request.containsKey("customNote") ? (String) request.get("customNote") : null;
        Long companyId = (principal != null && principal.getRole() != Role.DEVELOPER) ? principal.getCompanyId() : null;

        Map<String, Object> result = emailService.sendInvoiceReminder(invoiceId, recipientEmail, customNote, companyId);
        return ResponseEntity.ok(ApiResponse.ok("Reminder sent successfully", result));
    }

    @PostMapping("/send-expense-reminder")
    @Operation(summary = "Send expense due reminder to finance / accounting")
    public ResponseEntity<ApiResponse<Map<String, Object>>> sendExpenseReminder(
            @RequestBody Map<String, Object> request,
            @AuthenticationPrincipal UserPrincipal principal) {
        Long expenseId = ((Number) request.get("expenseId")).longValue();
        String recipientEmail = request.containsKey("recipientEmail") ? (String) request.get("recipientEmail") : null;
        String customNote = request.containsKey("customNote") ? (String) request.get("customNote") : null;
        Long companyId = (principal != null && principal.getRole() != Role.DEVELOPER) ? principal.getCompanyId() : null;

        Map<String, Object> result = emailService.sendExpenseReminder(expenseId, recipientEmail, customNote, companyId);
        return ResponseEntity.ok(ApiResponse.ok("Expense reminder sent", result));
    }
}
