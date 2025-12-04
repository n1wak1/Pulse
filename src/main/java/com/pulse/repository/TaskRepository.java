package com.pulse.repository;

import com.pulse.model.Task;
import com.pulse.model.TaskStatus;
import com.pulse.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TaskRepository extends JpaRepository<Task, Long> {
    List<Task> findByAssignee(User assignee);
    List<Task> findByStatus(TaskStatus status);
    List<Task> findByAssigneeAndStatus(User assignee, TaskStatus status);
    List<Task> findByProjectId(Long projectId);
}


