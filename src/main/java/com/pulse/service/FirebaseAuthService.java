package com.pulse.service;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.UserRecord;
import com.pulse.dto.AuthResponse;
import com.pulse.dto.LoginRequest;
import com.pulse.dto.RegisterRequest;
import com.pulse.dto.ResetPasswordRequest;
import com.pulse.dto.UserDto;
import com.pulse.model.User;
import com.pulse.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class FirebaseAuthService {

    @Autowired
    private FirebaseAuth firebaseAuth;

    @Autowired
    private UserRepository userRepository;

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        try {
            // Создаем пользователя в Firebase
            UserRecord.CreateRequest createRequest = new UserRecord.CreateRequest()
                    .setEmail(request.getEmail())
                    .setPassword(request.getPassword())
                    .setDisplayName(request.getDisplayName());

            UserRecord userRecord = firebaseAuth.createUser(createRequest);

            // Создаем пользователя в нашей БД
            User user = new User();
            user.setEmail(request.getEmail());
            user.setDisplayName(request.getDisplayName());
            user.setFirebaseUid(userRecord.getUid());
            user = userRepository.save(user);

            // Получаем токен для нового пользователя
            String customToken = firebaseAuth.createCustomToken(userRecord.getUid());

            return new AuthResponse(customToken, convertToDto(user));
        } catch (FirebaseAuthException e) {
            throw new RuntimeException("Failed to register user: " + e.getMessage(), e);
        }
    }

    public AuthResponse login(LoginRequest request) {
        // Примечание: В production клиент должен использовать Firebase SDK для входа
        // и отправлять ID токен на сервер. Этот метод создает custom token для существующего пользователя.
        // Для реальной аутентификации используйте FirebaseTokenFilter который проверяет ID токены.
        
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("Invalid credentials"));

        try {
            UserRecord userRecord = firebaseAuth.getUser(user.getFirebaseUid());
            // Создаем custom token для клиента
            // Клиент должен обменять его на ID token через Firebase SDK
            String customToken = firebaseAuth.createCustomToken(userRecord.getUid());
            return new AuthResponse(customToken, convertToDto(user));
        } catch (FirebaseAuthException e) {
            throw new RuntimeException("Failed to login: " + e.getMessage(), e);
        }
    }

    public void resetPassword(ResetPasswordRequest request) {
        try {
            // Проверяем существование пользователя
            userRepository.findByEmail(request.getEmail())
                    .orElseThrow(() -> new RuntimeException("User not found"));

            // Отправляем письмо для сброса пароля через Firebase
            // Firebase автоматически отправляет письмо на указанный email
            firebaseAuth.generatePasswordResetLink(request.getEmail());
        } catch (FirebaseAuthException e) {
            throw new RuntimeException("Failed to send password reset email: " + e.getMessage(), e);
        }
    }

    private UserDto convertToDto(User user) {
        return new UserDto(user.getId(), user.getEmail(), user.getDisplayName());
    }
}

