package com.pulse.repository;

import com.pulse.model.Team;
import com.pulse.model.TeamParticipant;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TeamParticipantRepository extends JpaRepository<TeamParticipant, Long> {
    List<TeamParticipant> findByTeam(Team team);
    void deleteByTeam(Team team);
}

