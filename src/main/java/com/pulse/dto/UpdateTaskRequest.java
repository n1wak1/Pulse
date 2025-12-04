package com.pulse.dto;

import com.pulse.model.TaskStatus;
import lombok.Data;

import java.time.LocalDate;

@Data
public class UpdateTaskRequest {
    private String title;
    private String description;
    private TaskStatus status;
    private Long assigneeId;
    private Long teamId;
    private Long sprintId;
    private LocalDate deadline;
}


