package com.pulse.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class GetTasksByTeamRequest {
    @NotNull(message = "Team ID is required")
    private Long teamId;
}

