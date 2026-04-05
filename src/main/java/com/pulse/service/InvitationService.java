package com.pulse.service;

import com.pulse.dto.CreateInvitationRequest;
import com.pulse.dto.TeamInvitationDto;
import com.pulse.model.InvitationStatus;
import com.pulse.model.Team;
import com.pulse.model.TeamInvitation;
import com.pulse.model.TeamMember;
import com.pulse.model.TeamMemberRole;
import com.pulse.model.User;
import com.pulse.repository.TeamInvitationRepository;
import com.pulse.repository.TeamMemberRepository;
import com.pulse.repository.TeamRepository;
import com.pulse.repository.UserRepository;
import com.pulse.security.UserPrincipal;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Service
public class InvitationService {
    private final TeamInvitationRepository invitationRepository;
    private final TeamRepository teamRepository;
    private final TeamMemberRepository teamMemberRepository;
    private final UserRepository userRepository;

    private static final DateTimeFormatter ISO_INSTANT = DateTimeFormatter.ISO_INSTANT;

    public InvitationService(
            TeamInvitationRepository invitationRepository,
            TeamRepository teamRepository,
            TeamMemberRepository teamMemberRepository,
            UserRepository userRepository
    ) {
        this.invitationRepository = invitationRepository;
        this.teamRepository = teamRepository;
        this.teamMemberRepository = teamMemberRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public TeamInvitationDto createInvitation(Long teamId, CreateInvitationRequest request) {
        User currentUser = UserPrincipal.getCurrentUser();
        Team team = teamRepository.findById(teamId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Team not found"));

        TeamMemberRole currentRole = teamMemberRepository.findByTeamAndUser(team, currentUser)
                .map(TeamMember::getRole)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.FORBIDDEN, "Access denied"));

        if (!(currentRole == TeamMemberRole.ADMIN || currentRole == TeamMemberRole.MANAGER)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "No permission to invite");
        }

        String inviteeEmail = request.getEmail().trim().toLowerCase();

        invitationRepository.findFirstByTeamIdAndInviteeEmailAndStatus(teamId, inviteeEmail, InvitationStatus.PENDING)
                .ifPresent(existing -> {
                    throw new ResponseStatusException(HttpStatus.CONFLICT, "Invitation already exists");
                });

        TeamMemberRole role;
        try {
            role = TeamMemberRole.valueOf(request.getRole().trim().toUpperCase());
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Invalid role");
        }

        TeamInvitation invitation = new TeamInvitation();
        invitation.setTeam(team);
        invitation.setInviter(currentUser);
        invitation.setInviteeEmail(inviteeEmail);
        invitation.setRole(role);
        invitation.setStatus(InvitationStatus.PENDING);

        userRepository.findByEmail(inviteeEmail).ifPresent(invitation::setInviteeUser);

        TeamInvitation saved = invitationRepository.save(invitation);
        return toDto(saved);
    }

    public List<TeamInvitationDto> getIncomingInvitations(InvitationStatus status) {
        User currentUser = UserPrincipal.getCurrentUser();
        String email = currentUser.getEmail();
        if (email == null || email.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "User email is missing");
        }

        List<TeamInvitation> invs = (status == null)
                ? invitationRepository.findByInviteeEmailOrderByCreatedAtDesc(email.toLowerCase())
                : invitationRepository.findByInviteeEmailAndStatusOrderByCreatedAtDesc(email.toLowerCase(), status);

        return invs.stream().map(this::toDto).toList();
    }

    public List<TeamInvitationDto> getTeamOutgoingInvitations(Long teamId, InvitationStatus status) {
        User currentUser = UserPrincipal.getCurrentUser();
        Team team = teamRepository.findById(teamId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Team not found"));

        TeamMemberRole currentRole = teamMemberRepository.findByTeamAndUser(team, currentUser)
                .map(TeamMember::getRole)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.FORBIDDEN, "Access denied"));

        if (!(currentRole == TeamMemberRole.ADMIN || currentRole == TeamMemberRole.MANAGER)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "No permission to view invitations");
        }

        List<TeamInvitation> invs = (status == null)
                ? invitationRepository.findByTeamOrderByCreatedAtDesc(team)
                : invitationRepository.findByTeamAndStatusOrderByCreatedAtDesc(team, status);

        return invs.stream().map(this::toDto).toList();
    }

    @Transactional
    public void acceptInvitation(Long invitationId) {
        User currentUser = UserPrincipal.getCurrentUser();

        TeamInvitation inv = invitationRepository.findById(invitationId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Invitation not found"));

        ensureBelongsToCurrentUser(inv, currentUser);

        if (inv.getStatus() != InvitationStatus.PENDING) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Invitation is not pending");
        }

        Team team = inv.getTeam();
        if (!teamMemberRepository.existsByTeamAndUser(team, currentUser)) {
            TeamMember member = new TeamMember();
            member.setTeam(team);
            member.setUser(currentUser);
            member.setRole(inv.getRole());
            teamMemberRepository.save(member);
        }

        inv.setStatus(InvitationStatus.ACCEPTED);
        inv.setRespondedAt(java.time.LocalDateTime.now());
        inv.setInviteeUser(currentUser);
        invitationRepository.save(inv);
    }

    @Transactional
    public void declineInvitation(Long invitationId) {
        User currentUser = UserPrincipal.getCurrentUser();

        TeamInvitation inv = invitationRepository.findById(invitationId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Invitation not found"));

        ensureBelongsToCurrentUser(inv, currentUser);

        if (inv.getStatus() != InvitationStatus.PENDING) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Invitation is not pending");
        }

        inv.setStatus(InvitationStatus.DECLINED);
        inv.setRespondedAt(java.time.LocalDateTime.now());
        inv.setInviteeUser(currentUser);
        invitationRepository.save(inv);
    }

    private void ensureBelongsToCurrentUser(TeamInvitation inv, User currentUser) {
        String currentEmail = (currentUser.getEmail() == null) ? "" : currentUser.getEmail().toLowerCase();
        if (!inv.getInviteeEmail().toLowerCase().equals(currentEmail)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Invitation does not belong to current user");
        }
    }

    private TeamInvitationDto toDto(TeamInvitation inv) {
        TeamInvitationDto dto = new TeamInvitationDto();
        dto.setId(inv.getId());
        dto.setTeamId(inv.getTeam().getId());
        dto.setTeamName(inv.getTeam().getName());
        dto.setInviterName(inv.getInviter().getDisplayName() != null ? inv.getInviter().getDisplayName() : inv.getInviter().getEmail());
        dto.setInviteeEmail(inv.getInviteeEmail());
        dto.setInviteeName(inv.getInviteeUser() != null ? inv.getInviteeUser().getDisplayName() : null);
        dto.setRole(inv.getRole().name());
        dto.setStatus(inv.getStatus().name());
        dto.setCreatedAt(ISO_INSTANT.format(inv.getCreatedAt().toInstant(ZoneOffset.UTC)));
        return dto;
    }
}

