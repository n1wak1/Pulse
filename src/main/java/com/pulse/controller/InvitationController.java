package com.pulse.controller;

import com.pulse.dto.CreateInvitationRequest;
import com.pulse.dto.TeamInvitationDto;
import com.pulse.model.InvitationStatus;
import com.pulse.service.InvitationService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
public class InvitationController {
    private final InvitationService invitationService;

    public InvitationController(InvitationService invitationService) {
        this.invitationService = invitationService;
    }

    @PostMapping("/api/teams/{teamId}/invitations")
    public ResponseEntity<TeamInvitationDto> create(@PathVariable Long teamId, @Valid @RequestBody CreateInvitationRequest request) {
        TeamInvitationDto created = invitationService.createInvitation(teamId, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @GetMapping("/api/invitations/incoming")
    public ResponseEntity<List<TeamInvitationDto>> incoming(@RequestParam(value = "status", required = false) String status) {
        InvitationStatus st = parseStatusOrNull(status);
        return ResponseEntity.ok(invitationService.getIncomingInvitations(st));
    }

    @GetMapping("/api/teams/{teamId}/invitations")
    public ResponseEntity<List<TeamInvitationDto>> outgoing(@PathVariable Long teamId, @RequestParam(value = "status", required = false) String status) {
        InvitationStatus st = parseStatusOrNull(status);
        return ResponseEntity.ok(invitationService.getTeamOutgoingInvitations(teamId, st));
    }

    @PostMapping("/api/invitations/{invitationId}/accept")
    public ResponseEntity<Void> accept(@PathVariable Long invitationId) {
        invitationService.acceptInvitation(invitationId);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/api/invitations/{invitationId}/decline")
    public ResponseEntity<Void> decline(@PathVariable Long invitationId) {
        invitationService.declineInvitation(invitationId);
        return ResponseEntity.ok().build();
    }

    private InvitationStatus parseStatusOrNull(String status) {
        if (status == null || status.isBlank()) return null;
        try {
            return InvitationStatus.valueOf(status.trim().toUpperCase());
        } catch (Exception e) {
            return null;
        }
    }
}

