package com.pulse.dto;

import com.pulse.model.TeamMemberRole;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class TeamMemberDto {
    private Long id;
    private Long userId;
    private String userName;
    private String userEmail;
    private TeamMemberRole role;
}


