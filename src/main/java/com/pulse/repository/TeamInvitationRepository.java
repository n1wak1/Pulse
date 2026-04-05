package com.pulse.repository;

import com.pulse.model.InvitationStatus;
import com.pulse.model.Team;
import com.pulse.model.TeamInvitation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface TeamInvitationRepository extends JpaRepository<TeamInvitation, Long> {
    Optional<TeamInvitation> findFirstByTeamIdAndInviteeEmailAndStatus(Long teamId, String inviteeEmail, InvitationStatus status);

    List<TeamInvitation> findByInviteeEmailOrderByCreatedAtDesc(String inviteeEmail);
    List<TeamInvitation> findByInviteeEmailAndStatusOrderByCreatedAtDesc(String inviteeEmail, InvitationStatus status);

    List<TeamInvitation> findByTeamOrderByCreatedAtDesc(Team team);
    List<TeamInvitation> findByTeamAndStatusOrderByCreatedAtDesc(Team team, InvitationStatus status);
}

