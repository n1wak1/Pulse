package com.pulse.service;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.UserRecord;
import com.pulse.dto.AuthResponse;
import com.pulse.dto.LoginRequest;
import com.pulse.dto.RegisterRequest;
import com.pulse.dto.ResetPasswordRequest;
import com.pulse.dto.UserDto;
import com.pulse.model.User;
import com.pulse.repository.UserRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import java.util.Map;

@Service
public class FirebaseAuthService {

    private final FirebaseAuth firebaseAuth;
    private final UserRepository userRepository;
    private final RestTemplate restTemplate;
    private final String firebaseApiKey;

    public FirebaseAuthService(
            FirebaseAuth firebaseAuth,
            UserRepository userRepository,
            @Value("${firebase.api.key}") String firebaseApiKey
    ) {
        this.firebaseAuth = firebaseAuth;
        this.userRepository = userRepository;
        this.firebaseApiKey = firebaseApiKey;
        this.restTemplate = new RestTemplate();
    }

    public AuthResponse register(RegisterRequest request) {
        try {
            UserRecord.CreateRequest createRequest = new UserRecord.CreateRequest()
                    .setEmail(request.getEmail())
                    .setPassword(request.getPassword());

            if (request.getDisplayName() != null && !request.getDisplayName().isBlank()) {
                createRequest.setDisplayName(request.getDisplayName().trim());
            }

            UserRecord firebaseUser = firebaseAuth.createUser(createRequest);
            User user = upsertLocalUser(
                    firebaseUser.getUid(),
                    firebaseUser.getEmail(),
                    firebaseUser.getDisplayName()
            );

            String idToken = signInAndGetIdToken(request.getEmail(), request.getPassword());
            return new AuthResponse(idToken, toUserDto(user));
        } catch (ResponseStatusException e) {
            throw e;
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Registration failed: " + e.getMessage(), e);
        }
    }

    public AuthResponse login(LoginRequest request) {
        try {
            String idToken = signInAndGetIdToken(request.getEmail(), request.getPassword());

            UserRecord firebaseUser = firebaseAuth.getUserByEmail(request.getEmail());
            User user = upsertLocalUser(
                    firebaseUser.getUid(),
                    firebaseUser.getEmail(),
                    firebaseUser.getDisplayName()
            );

            return new AuthResponse(idToken, toUserDto(user));
        } catch (ResponseStatusException e) {
            throw e;
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Login failed: " + e.getMessage(), e);
        }
    }

    public void resetPassword(ResetPasswordRequest request) {
        try {
            firebaseAuth.generatePasswordResetLink(request.getEmail());
        } catch (ResponseStatusException e) {
            throw e;
        } catch (Exception e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Password reset failed: " + e.getMessage(), e);
        }
    }

    private String signInAndGetIdToken(String email, String password) {
        String url = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=" + firebaseApiKey;

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(
                Map.of(
                        "email", email,
                        "password", password,
                        "returnSecureToken", true
                ),
                headers
        );

        try {
            ResponseEntity<FirebaseSignInResponse> response = restTemplate.postForEntity(
                    url,
                    entity,
                    FirebaseSignInResponse.class
            );

            FirebaseSignInResponse body = response.getBody();
            if (body == null || body.idToken == null || body.idToken.isBlank()) {
                throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, "Firebase did not return ID token");
            }
            return body.idToken;
        } catch (RestClientException e) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid credentials or Firebase API error", e);
        }
    }

    private User upsertLocalUser(String firebaseUid, String email, String displayName) {
        return userRepository.findByFirebaseUid(firebaseUid)
                .map(existing -> {
                    existing.setEmail(email);
                    existing.setDisplayName(displayName);
                    return userRepository.save(existing);
                })
                .orElseGet(() -> userRepository.findByEmail(email)
                        .map(existingByEmail -> {
                            existingByEmail.setFirebaseUid(firebaseUid);
                            existingByEmail.setDisplayName(displayName);
                            return userRepository.save(existingByEmail);
                        })
                        .orElseGet(() -> {
                            User newUser = new User();
                            newUser.setEmail(email);
                            newUser.setDisplayName(displayName);
                            newUser.setFirebaseUid(firebaseUid);
                            return userRepository.save(newUser);
                        }));
    }

    private UserDto toUserDto(User user) {
        return new UserDto(user.getId(), user.getEmail(), user.getDisplayName());
    }

    private static class FirebaseSignInResponse {
        @JsonProperty("idToken")
        public String idToken;
    }
}

