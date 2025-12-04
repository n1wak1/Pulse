package com.pulse.controller;

import com.pulse.dto.CreateTeamRequest;
import com.pulse.dto.ErrorResponse;
import com.pulse.dto.TeamDto;
import com.pulse.dto.TeamMemberDto;
import com.pulse.service.TeamService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/teams")
public class TeamController {

    @Autowired
    private TeamService teamService;

    @GetMapping
    public ResponseEntity<List<TeamDto>> getAllTeams() {
        List<TeamDto> teams = teamService.getAllTeams();
        return ResponseEntity.ok(teams);
    }

    @GetMapping("/{id}")
    public ResponseEntity<?> getTeamById(@PathVariable Long id) {
        try {
            TeamDto team = teamService.getTeamById(id);
            return ResponseEntity.ok(team);
        } catch (RuntimeException e) {
            if (e.getMessage().contains("not found")) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(new ErrorResponse("Team not found", "TEAM_NOT_FOUND", null));
            }
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(new ErrorResponse("Access denied", "ACCESS_DENIED", null));
        }
    }

    @PostMapping
    public ResponseEntity<?> createTeam(@Valid @RequestBody CreateTeamRequest request) {
        try {
            // Логирование для отладки
            System.out.println("Received create team request: name=" + request.getName() + ", description=" + request.getDescription());
            System.out.println("Request hash: " + (request.getName() + request.getDescription() + System.currentTimeMillis() / 1000).hashCode());
            
            TeamDto team = teamService.createTeam(request);
            System.out.println("Team created successfully with ID: " + team.getId());
            return ResponseEntity.status(HttpStatus.CREATED).body(team);
        } catch (RuntimeException e) {
            System.err.println("Error creating team: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(new ErrorResponse(e.getMessage(), "VALIDATION_ERROR", null));
        }
    }

    @GetMapping("/{teamId}/members")
    public ResponseEntity<?> getTeamMembers(@PathVariable Long teamId) {
        try {
            List<TeamMemberDto> members = teamService.getTeamMembers(teamId);
            return ResponseEntity.ok(members);
        } catch (RuntimeException e) {
            if (e.getMessage().contains("not found")) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(new ErrorResponse("Team not found", "TEAM_NOT_FOUND", null));
            }
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(new ErrorResponse("Access denied", "ACCESS_DENIED", null));
        }
    }
}


