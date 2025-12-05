package com.pulse.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class TeamMemberRequest {
    @NotBlank(message = "Participant name is required")
    private String name; // Имя участника (текст)
    
    @NotBlank(message = "Role is required")
    private String role; // Роль участника (текст)
}

