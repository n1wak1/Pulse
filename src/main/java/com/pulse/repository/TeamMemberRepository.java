package com.pulse.repository;

import com.pulse.model.Team;
import com.pulse.model.TeamMember;
import com.pulse.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface TeamMemberRepository extends JpaRepository<TeamMember, Long> {
    List<TeamMember> findByTeam(Team team);
    Optional<TeamMember> findByTeamAndUser(Team team, User user);
    boolean existsByTeamAndUser(Team team, User user);
}

