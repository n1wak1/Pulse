package com.pulse.service;

import com.pulse.dto.CreateTeamRequest;
import com.pulse.dto.TeamDto;
import com.pulse.dto.TeamMemberDto;
import com.pulse.model.Team;
import com.pulse.model.TeamMember;
import com.pulse.model.TeamMemberRole;
import com.pulse.model.User;
import com.pulse.repository.TeamMemberRepository;
import com.pulse.repository.TeamRepository;
import com.pulse.security.UserPrincipal;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class TeamService {

    @Autowired
    private TeamRepository teamRepository;

    @Autowired
    private TeamMemberRepository teamMemberRepository;

    public List<TeamDto> getAllTeams() {
        User currentUser = UserPrincipal.getCurrentUser();
        return teamRepository.findByUserMembership(currentUser).stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public TeamDto getTeamById(Long id) {
        User currentUser = UserPrincipal.getCurrentUser();
        Team team = teamRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Team not found"));

        if (!teamMemberRepository.existsByTeamAndUser(team, currentUser)) {
            throw new RuntimeException("Access denied");
        }

        return convertToDto(team);
    }

    @Transactional
    public TeamDto createTeam(CreateTeamRequest request) {
        User currentUser = UserPrincipal.getCurrentUser();
        
        Team team = new Team();
        team.setName(request.getName());
        team.setDescription(request.getDescription());
        team = teamRepository.save(team);

        // Добавляем создателя как администратора
        TeamMember adminMember = new TeamMember();
        adminMember.setTeam(team);
        adminMember.setUser(currentUser);
        adminMember.setRole(TeamMemberRole.ADMIN);
        teamMemberRepository.save(adminMember);

        return convertToDto(team);
    }

    public List<TeamMemberDto> getTeamMembers(Long teamId) {
        User currentUser = UserPrincipal.getCurrentUser();
        Team team = teamRepository.findById(teamId)
                .orElseThrow(() -> new RuntimeException("Team not found"));

        if (!teamMemberRepository.existsByTeamAndUser(team, currentUser)) {
            throw new RuntimeException("Access denied");
        }

        return teamMemberRepository.findByTeam(team).stream()
                .map(this::convertMemberToDto)
                .collect(Collectors.toList());
    }

    private TeamDto convertToDto(Team team) {
        TeamDto dto = new TeamDto();
        dto.setId(team.getId());
        dto.setName(team.getName());
        dto.setDescription(team.getDescription());
        dto.setCreatedAt(team.getCreatedAt());
        
        List<TeamMemberDto> members = teamMemberRepository.findByTeam(team).stream()
                .map(this::convertMemberToDto)
                .collect(Collectors.toList());
        dto.setMembers(members);

        return dto;
    }

    private TeamMemberDto convertMemberToDto(TeamMember member) {
        TeamMemberDto dto = new TeamMemberDto();
        dto.setId(member.getId());
        dto.setUserId(member.getUser().getId());
        dto.setUserName(member.getUser().getDisplayName());
        dto.setUserEmail(member.getUser().getEmail());
        dto.setRole(member.getRole());
        return dto;
    }
}

