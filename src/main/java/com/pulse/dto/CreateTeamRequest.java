package com.pulse.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;

import java.util.ArrayList;
import java.util.List;

@Getter
public class CreateTeamRequest {
    @NotBlank(message = "Team name is required")
    private String name;

    private String description;
    
    // Список участников команды - используем поле "participants" как отправляет фронтенд
    @JsonProperty("participants")
    private List<TeamMemberRequest> participants = new ArrayList<>();
    
    // Переопределяем setter для participants с логированием (без @Setter на классе, чтобы не конфликтовать)
    public void setParticipants(List<TeamMemberRequest> participants) {
        System.out.println("=== SET PARTICIPANTS CALLED ===");
        System.out.println("Input: " + (participants != null ? participants.size() : "null") + " items");
        this.participants = participants != null ? participants : new ArrayList<>();
        System.out.println("Stored: " + this.participants.size() + " items");
        if (!this.participants.isEmpty()) {
            this.participants.forEach(p -> System.out.println("  - " + p.getName() + " (" + p.getRole() + ")"));
        }
        System.out.println("==============================");
    }
    
    // Геттер для participants
    public List<TeamMemberRequest> getParticipants() {
        System.out.println("getParticipants() called, returning " + (participants != null ? participants.size() : "null") + " items");
        return participants != null ? participants : new ArrayList<>();
    }
    
    // Геттер для обратной совместимости с кодом, который использует getMembers()
    public List<TeamMemberRequest> getMembers() {
        System.out.println("getMembers() called, returning " + (participants != null ? participants.size() : "null") + " items");
        return participants != null ? participants : new ArrayList<>();
    }
    
    // Стандартные setters для name и description
    public void setName(String name) {
        this.name = name;
    }
    
    public void setDescription(String description) {
        this.description = description;
    }
}



