package com.pulse.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.pulse.model.TaskStatus;
import lombok.Data;

import java.time.LocalDate;

@Data
public class UpdateTaskRequest {
    private String title;
    private String description;
    private TaskStatus status;
    private Long assigneeId;
    
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
}


