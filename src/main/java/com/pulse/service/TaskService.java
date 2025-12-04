package com.pulse.service;

import com.pulse.dto.CreateTaskRequest;
import com.pulse.dto.TaskDto;
import com.pulse.dto.UpdateTaskRequest;
import com.pulse.model.Task;
import com.pulse.model.TaskStatus;
import com.pulse.model.Team;
import com.pulse.model.User;
import com.pulse.repository.TaskRepository;
import com.pulse.repository.TeamMemberRepository;
import com.pulse.repository.TeamRepository;
import com.pulse.repository.UserRepository;
import com.pulse.security.UserPrincipal;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class TaskService {

    @Autowired
    private TaskRepository taskRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private TeamRepository teamRepository;

    @Autowired
    private TeamMemberRepository teamMemberRepository;

    public List<TaskDto> getAllTasks() {
        User currentUser = UserPrincipal.getCurrentUser();
        return taskRepository.findAll().stream()
                .filter(task -> belongsToUserTeam(task, currentUser))
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public TaskDto getTaskById(Long id) {
        User currentUser = UserPrincipal.getCurrentUser();
        Task task = taskRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Task not found"));
        
        if (!belongsToUserTeam(task, currentUser)) {
            throw new RuntimeException("Access denied");
        }
        
        return convertToDto(task);
    }

    @Transactional
    public TaskDto createTask(CreateTaskRequest request) {
        User currentUser = UserPrincipal.getCurrentUser();
        Task task = new Task();
        task.setTitle(request.getTitle());
        task.setDescription(request.getDescription());
        task.setStatus(request.getStatus());

        if (request.getAssigneeId() != null) {
            User assignee = userRepository.findById(request.getAssigneeId())
                    .orElseThrow(() -> new RuntimeException("Assignee not found"));
            
            // Проверяем, что assignee в команде пользователя
            if (!isUserInSameTeam(currentUser, assignee)) {
                throw new RuntimeException("Assignee not found in user's team");
            }
            
            task.setAssignee(assignee);
        }

        if (request.getProjectId() != null) {
            Team project = teamRepository.findById(request.getProjectId())
                    .orElseThrow(() -> new RuntimeException("Project not found"));
            task.setProject(project);
        }

        task.setSprintId(request.getSprintId());
        task.setDeadline(request.getDeadline());

        task = taskRepository.save(task);
        return convertToDto(task);
    }

    @Transactional
    public TaskDto updateTask(Long id, UpdateTaskRequest request) {
        User currentUser = UserPrincipal.getCurrentUser();
        Task task = taskRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Task not found"));

        if (!belongsToUserTeam(task, currentUser)) {
            throw new RuntimeException("Access denied");
        }

        if (request.getTitle() != null) {
            task.setTitle(request.getTitle());
        }
        if (request.getDescription() != null) {
            task.setDescription(request.getDescription());
        }
        if (request.getStatus() != null) {
            task.setStatus(request.getStatus());
        }
        if (request.getAssigneeId() != null) {
            User assignee = userRepository.findById(request.getAssigneeId())
                    .orElseThrow(() -> new RuntimeException("Assignee not found"));
            
            if (!isUserInSameTeam(currentUser, assignee)) {
                throw new RuntimeException("Assignee not found in user's team");
            }
            
            task.setAssignee(assignee);
        }
        if (request.getSprintId() != null) {
            task.setSprintId(request.getSprintId());
        }
        if (request.getDeadline() != null) {
            task.setDeadline(request.getDeadline());
        }

        task = taskRepository.save(task);
        return convertToDto(task);
    }

    @Transactional
    public void deleteTask(Long id) {
        User currentUser = UserPrincipal.getCurrentUser();
        Task task = taskRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Task not found"));

        if (!belongsToUserTeam(task, currentUser)) {
            throw new RuntimeException("Access denied");
        }

        taskRepository.delete(task);
    }

    public List<TaskDto> getTasksByStatus(TaskStatus status) {
        User currentUser = UserPrincipal.getCurrentUser();
        return taskRepository.findByStatus(status).stream()
                .filter(task -> belongsToUserTeam(task, currentUser))
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public List<TaskDto> getTasksAssignedToMe() {
        User currentUser = UserPrincipal.getCurrentUser();
        return taskRepository.findByAssignee(currentUser).stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    private boolean belongsToUserTeam(Task task, User user) {
        if (task.getProject() == null) {
            return true; // Задачи без проекта доступны всем
        }
        return teamMemberRepository.existsByTeamAndUser(task.getProject(), user);
    }

    private boolean isUserInSameTeam(User user1, User user2) {
        List<Team> user1Teams = teamRepository.findByUserMembership(user1);
        List<Team> user2Teams = teamRepository.findByUserMembership(user2);
        
        return user1Teams.stream().anyMatch(user2Teams::contains);
    }

    private TaskDto convertToDto(Task task) {
        TaskDto dto = new TaskDto();
        dto.setId(task.getId());
        dto.setTitle(task.getTitle());
        dto.setDescription(task.getDescription());
        dto.setStatus(task.getStatus());
        dto.setProjectId(task.getProject() != null ? task.getProject().getId() : null);
        dto.setSprintId(task.getSprintId());
        dto.setDeadline(task.getDeadline());
        dto.setCreatedAt(task.getCreatedAt());
        dto.setUpdatedAt(task.getUpdatedAt());

        if (task.getAssignee() != null) {
            dto.setAssigneeId(task.getAssignee().getId());
            dto.setAssigneeName(task.getAssignee().getDisplayName());
        }

        return dto;
    }
}

