package com.invoicely.backend.dto;

import com.invoicely.backend.model.NotificationChannel;
import jakarta.validation.constraints.NotBlank;
import java.time.OffsetDateTime;

public class SendInviteRequest {

    @NotBlank(message = "inviteeEmail is required")
    private String inviteeEmail;

    private String inviteePhone;

    private String inviteeName;

    private NotificationChannel channel = NotificationChannel.EMAIL;

    private String role = "EMPLOYEE";

    private String customNote;

    private OffsetDateTime scheduledAt;

    public SendInviteRequest() {}

    public String getInviteeEmail() { return inviteeEmail; }
    public void setInviteeEmail(String inviteeEmail) { this.inviteeEmail = inviteeEmail; }

    public String getInviteePhone() { return inviteePhone; }
    public void setInviteePhone(String inviteePhone) { this.inviteePhone = inviteePhone; }

    public String getInviteeName() { return inviteeName; }
    public void setInviteeName(String inviteeName) { this.inviteeName = inviteeName; }

    public NotificationChannel getChannel() { return channel; }
    public void setChannel(NotificationChannel channel) { this.channel = channel; }

    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }

    public String getCustomNote() { return customNote; }
    public void setCustomNote(String customNote) { this.customNote = customNote; }

    public OffsetDateTime getScheduledAt() { return scheduledAt; }
    public void setScheduledAt(OffsetDateTime scheduledAt) { this.scheduledAt = scheduledAt; }
}
