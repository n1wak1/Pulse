package com.pulse.controller;

import com.pulse.dto.PublicUserDto;
import com.pulse.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/users")
public class UserController {
    private final UserRepository userRepository;

    public UserController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @GetMapping("/lookup")
    public ResponseEntity<?> lookup(@RequestParam("email") String email) {
        String normalized = email == null ? "" : email.trim().toLowerCase();
        if (normalized.isBlank()) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("email is required");
        }

        return userRepository.findByEmail(normalized)
                .<ResponseEntity<?>>map(u -> ResponseEntity.ok(new PublicUserDto(u.getId(), u.getEmail(), u.getDisplayName())))
                .orElseGet(() -> ResponseEntity.status(HttpStatus.NOT_FOUND).build());
    }
}

