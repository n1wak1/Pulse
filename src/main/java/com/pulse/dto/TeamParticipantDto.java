package com.pulse.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class TeamParticipantDto {
    private Long id;
    private String name;
    private String role;
}

