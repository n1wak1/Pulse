package com.pulse.service;

import com.pulse.dto.AuthResponse;
import com.pulse.dto.LoginRequest;
import com.pulse.dto.RegisterRequest;
import com.pulse.dto.ResetPasswordRequest;
import org.springframework.stereotype.Service;

/**
 * Сервис для работы с Firebase Authentication
 * 
 * ВАЖНО: Регистрация и логин теперь происходят напрямую через Firebase SDK на клиенте.
 * Бэкенд НЕ участвует в регистрации и логине - только валидирует токены через FirebaseTokenFilter.
 * 
 * Эндпоинты /api/auth/login и /api/auth/register помечены как @Deprecated и возвращают ошибку.
 * Они оставлены для обратной совместимости, но не должны использоваться.
 */
@Service
public class FirebaseAuthService {

    // Регистрация теперь происходит напрямую через Firebase SDK на клиенте
    // Бэкенд НЕ участвует в регистрации - только валидирует токены
    @Deprecated
    public AuthResponse register(RegisterRequest request) {
        throw new RuntimeException("Registration is handled by Firebase SDK on the client side. This endpoint is deprecated.");
    }

    // Логин теперь происходит напрямую через Firebase SDK на клиенте
    // Бэкенд НЕ участвует в логине - только валидирует токены
    @Deprecated
    public AuthResponse login(LoginRequest request) {
        throw new RuntimeException("Login is handled by Firebase SDK on the client side. This endpoint is deprecated.");
    }

    // Восстановление пароля теперь происходит напрямую через Firebase SDK на клиенте
    @Deprecated
    public void resetPassword(ResetPasswordRequest request) {
        throw new RuntimeException("Password reset is handled by Firebase SDK on the client side. This endpoint is deprecated.");
    }
}

