package com.pulse.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.pulse.model.TaskStatus;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class TaskDto {
    private Long id;
    private String title;
    private String description;
    private TaskStatus status;
    private Long assigneeId;
    private String assigneeName;
    private Long creatorId;
    private String creatorName;
    
    // teamId - основное поле
    private Long teamId;
    
    // projectId - для обратной совместимости с фронтендом (алиас для teamId)
    @JsonProperty("projectId")
    public Long getProjectId() {
        return teamId;
    }
    
    @JsonProperty("projectId")
    public void setProjectId(Long projectId) {
        this.teamId = projectId;
    }
    
    private Long sprintId;
    private LocalDate deadline;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}


