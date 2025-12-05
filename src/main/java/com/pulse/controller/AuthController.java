package com.pulse.controller;

import com.pulse.dto.ErrorResponse;
import com.pulse.dto.LoginRequest;
import com.pulse.dto.RegisterRequest;
import com.pulse.dto.ResetPasswordRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * Контроллер для авторизации
 * 
 * ВАЖНО: Все эндпоинты помечены как @Deprecated.
 * Регистрация, логин и восстановление пароля теперь происходят напрямую через Firebase SDK на клиенте.
 * Бэкенд только валидирует токены через FirebaseTokenFilter.
 */
@RestController
@RequestMapping("/api/auth")
public class AuthController {

    /**
     * @deprecated Логин теперь происходит напрямую через Firebase SDK на клиенте.
     * Этот эндпоинт оставлен для обратной совместимости, но не должен использоваться.
     */
    @Deprecated
    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.status(HttpStatus.GONE)
                .body(new ErrorResponse(
                    "Login is now handled by Firebase SDK on the client side. Please use Firebase Auth directly.",
                    "DEPRECATED_ENDPOINT",
                    null
                ));
    }

    /**
     * @deprecated Регистрация теперь происходит напрямую через Firebase SDK на клиенте.
     * Этот эндпоинт оставлен для обратной совместимости, но не должен использоваться.
     */
    @Deprecated
    @PostMapping("/register")
    public ResponseEntity<?> register(@Valid @RequestBody RegisterRequest request) {
        return ResponseEntity.status(HttpStatus.GONE)
                .body(new ErrorResponse(
                    "Registration is now handled by Firebase SDK on the client side. Please use Firebase Auth directly.",
                    "DEPRECATED_ENDPOINT",
                    null
                ));
    }

    /**
     * @deprecated Восстановление пароля теперь происходит напрямую через Firebase SDK на клиенте.
     * Этот эндпоинт оставлен для обратной совместимости, но не должен использоваться.
     */
    @Deprecated
    @PostMapping("/reset-password")
    public ResponseEntity<?> resetPassword(@Valid @RequestBody ResetPasswordRequest request) {
        return ResponseEntity.status(HttpStatus.GONE)
                .body(new ErrorResponse(
                    "Password reset is now handled by Firebase SDK on the client side. Please use Firebase Auth directly.",
                    "DEPRECATED_ENDPOINT",
                    null
                ));
    }
}


