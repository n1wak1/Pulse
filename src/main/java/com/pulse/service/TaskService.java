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
        task.setCreator(currentUser); // Устанавливаем создателя задачи

        // Определяем команду для задачи
        Team team = null;
        if (request.getTeamId() != null) {
            // Если teamId указан, используем его
            team = teamRepository.findById(request.getTeamId())
                    .orElseThrow(() -> new RuntimeException("Team not found"));
            
            // Проверяем, что пользователь является членом команды
            if (!teamMemberRepository.existsByTeamAndUser(team, currentUser)) {
                throw new RuntimeException("Access denied: User is not a member of this team");
            }
        } else {
            // Если teamId не указан, автоматически берем первую команду пользователя
            List<Team> userTeams = teamRepository.findByUserMembership(currentUser);
            if (userTeams.isEmpty()) {
                throw new RuntimeException("User must be a member of at least one team to create tasks");
            }
            // Берем первую (самую новую) команду пользователя
            team = userTeams.get(0);
        }
        task.setProject(team);

        if (request.getAssigneeId() != null) {
            User assignee = userRepository.findById(request.getAssigneeId())
                    .orElseThrow(() -> new RuntimeException("Assignee not found"));
            
            // Проверяем, что assignee в той же команде
            if (!teamMemberRepository.existsByTeamAndUser(team, assignee)) {
                throw new RuntimeException("Assignee must be a member of the same team");
            }
            
            task.setAssignee(assignee);
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
        // Определяем команду задачи (текущая или новая из запроса)
        Team taskTeam = task.getProject();
        if (request.getTeamId() != null) {
            Team newTeam = teamRepository.findById(request.getTeamId())
                    .orElseThrow(() -> new RuntimeException("Team not found"));
            
            // Проверяем, что пользователь является членом команды
            if (!teamMemberRepository.existsByTeamAndUser(newTeam, currentUser)) {
                throw new RuntimeException("Access denied: User is not a member of this team");
            }
            
            taskTeam = newTeam;
            task.setProject(newTeam);
        }
        
        // Проверяем, что у задачи есть команда
        if (taskTeam == null) {
            throw new RuntimeException("Task must belong to a team");
        }
        
        if (request.getAssigneeId() != null) {
            User assignee = userRepository.findById(request.getAssigneeId())
                    .orElseThrow(() -> new RuntimeException("Assignee not found"));
            
            // Проверяем, что assignee в той же команде, что и задача
            if (!teamMemberRepository.existsByTeamAndUser(taskTeam, assignee)) {
                throw new RuntimeException("Assignee must be a member of the same team as the task");
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

    public List<TaskDto> getTasksByTeamId(Long teamId) {
        User currentUser = UserPrincipal.getCurrentUser();
        System.out.println("=== TASK SERVICE: getTasksByTeamId ===");
        System.out.println("TeamId: " + teamId);
        System.out.println("Current User: " + currentUser.getEmail() + " (ID: " + currentUser.getId() + ")");
        
        // Проверяем, что команда существует
        Team team = teamRepository.findById(teamId)
                .orElseThrow(() -> {
                    System.err.println("Team not found: " + teamId);
                    return new RuntimeException("Team not found");
                });
        
        System.out.println("Team found: " + team.getName() + " (ID: " + team.getId() + ")");
        
        // Проверяем, что пользователь является членом команды
        boolean isMember = teamMemberRepository.existsByTeamAndUser(team, currentUser);
        System.out.println("User is member: " + isMember);
        
        if (!isMember) {
            System.err.println("Access denied: User " + currentUser.getEmail() + " is not a member of team " + team.getName());
            throw new RuntimeException("Access denied: User is not a member of this team");
        }
        
        // Возвращаем задачи по teamId
        List<TaskDto> tasks = taskRepository.findByProjectId(teamId).stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
        System.out.println("Tasks found: " + tasks.size());
        System.out.println("=======================================");
        return tasks;
    }

    private boolean belongsToUserTeam(Task task, User user) {
        if (task.getProject() == null) {
            // Задачи без проекта доступны только создателю или назначенному пользователю
            if (task.getCreator() != null && task.getCreator().getId().equals(user.getId())) {
                return true;
            }
            if (task.getAssignee() != null && task.getAssignee().getId().equals(user.getId())) {
                return true;
            }
            return false;
        }
        return teamMemberRepository.existsByTeamAndUser(task.getProject(), user);
    }


    private TaskDto convertToDto(Task task) {
        TaskDto dto = new TaskDto();
        dto.setId(task.getId());
        dto.setTitle(task.getTitle());
        dto.setDescription(task.getDescription());
        dto.setStatus(task.getStatus());
        dto.setTeamId(task.getProject() != null ? task.getProject().getId() : null);
        dto.setSprintId(task.getSprintId());
        dto.setDeadline(task.getDeadline());
        dto.setCreatedAt(task.getCreatedAt());
        dto.setUpdatedAt(task.getUpdatedAt());

        if (task.getAssignee() != null) {
            dto.setAssigneeId(task.getAssignee().getId());
            dto.setAssigneeName(task.getAssignee().getDisplayName());
        }

        if (task.getCreator() != null) {
            dto.setCreatorId(task.getCreator().getId());
            dto.setCreatorName(task.getCreator().getDisplayName());
        }

        return dto;
    }
}

