package com.invoicely.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public class ReceiptScanRequest {

    @NotBlank
    @Size(max = 8_000_000)
    private String imageBase64;

    @NotBlank
    @Pattern(regexp = "image/(jpeg|png|webp)")
    private String mimeType;

    public String getImageBase64() { return imageBase64; }
    public void setImageBase64(String imageBase64) { this.imageBase64 = imageBase64; }
    public String getMimeType() { return mimeType; }
    public void setMimeType(String mimeType) { this.mimeType = mimeType; }
}
