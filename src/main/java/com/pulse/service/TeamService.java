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
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

@Service
public class TeamService {

    @Autowired
    private TeamRepository teamRepository;

    @Autowired
    private TeamMemberRepository teamMemberRepository;
    
    // Кэш для защиты от дублирования запросов (ключ: userId + name, значение: teamId + timestamp)
    private final ConcurrentHashMap<String, TeamCreationInfo> recentTeamCreations = new ConcurrentHashMap<>();
    
    private static class TeamCreationInfo {
        Long teamId;
        long timestamp;
        
        TeamCreationInfo(Long teamId, long timestamp) {
            this.teamId = teamId;
            this.timestamp = timestamp;
        }
    }

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
        long currentTime = System.currentTimeMillis();
        
        // Защита от дублирования: проверяем, не создавалась ли команда с таким именем недавно (в последние 3 секунды)
        String duplicateKey = currentUser.getId() + "_" + request.getName();
        
        synchronized (this) {
            // Очищаем старые записи (старше 5 секунд)
            recentTeamCreations.entrySet().removeIf(entry -> 
                currentTime - entry.getValue().timestamp > 5000
            );
            
            // Проверяем, не создавалась ли команда с таким именем недавно
            TeamCreationInfo existing = recentTeamCreations.get(duplicateKey);
            if (existing != null && (currentTime - existing.timestamp) < 3000) {
                // Если команда создавалась менее 3 секунд назад, возвращаем существующую
                Team existingTeam = teamRepository.findById(existing.teamId)
                        .orElse(null);
                if (existingTeam != null) {
                    System.out.println("Duplicate request detected for user " + currentUser.getId() + 
                                     ", team name: " + request.getName() + 
                                     ", returning existing team ID: " + existing.teamId);
                    return convertToDto(existingTeam);
                }
            }
        }
        
        Team team = new Team();
        team.setName(request.getName());
        team.setDescription(request.getDescription());

        // Добавляем создателя как администратора
        TeamMember adminMember = new TeamMember();
        adminMember.setTeam(team);
        adminMember.setUser(currentUser);
        adminMember.setRole(TeamMemberRole.ADMIN);
        
        // Добавляем в список members команды (каскадное сохранение сохранит его автоматически)
        team.getMembers().add(adminMember);
        
        team = teamRepository.save(team);
        
        // Сохраняем в кэш для защиты от дублирования
        synchronized (this) {
            recentTeamCreations.put(duplicateKey, new TeamCreationInfo(team.getId(), currentTime));
        }
        
        System.out.println("Team created: ID=" + team.getId() + ", name=" + team.getName() + ", user=" + currentUser.getId());

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


