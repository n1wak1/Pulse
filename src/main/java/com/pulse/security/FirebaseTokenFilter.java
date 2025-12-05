package com.pulse.security;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;
import com.pulse.model.User;
import com.pulse.repository.UserRepository;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
public class FirebaseTokenFilter extends OncePerRequestFilter {

    @Autowired
    private FirebaseAuth firebaseAuth;

    @Autowired
    private UserRepository userRepository;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        String authHeader = request.getHeader("Authorization");

        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7);
            try {
                logger.debug("Verifying Firebase ID Token for request: " + request.getRequestURI());
                
                // Проверяем, что это ID Token (JWT формат, начинается с "eyJ")
                if (!token.startsWith("eyJ")) {
                    logger.error("Invalid token format - expected Firebase ID Token (JWT), got: " + 
                                 (token.length() > 50 ? token.substring(0, 50) + "..." : token));
                    response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                    response.setContentType("application/json");
                    response.getWriter().write("{\"error\":\"Invalid token format. Expected Firebase ID Token.\"}");
                    return;
                }
                
                // verifyIdToken автоматически проверяет истечение токена и подпись
                // Если токен истек, будет выброшено FirebaseAuthException с кодом auth/id-token-expired
                FirebaseToken decodedToken = firebaseAuth.verifyIdToken(token, true); // true = проверять истечение
                String firebaseUid = decodedToken.getUid();
                
                logger.info("Token verified successfully, Firebase UID: " + firebaseUid);
                
                // Получаем email из токена
                String email = decodedToken.getEmail();
                String displayName = decodedToken.getName();
                
                logger.info("Token email: " + email + ", displayName: " + displayName);
                
                // Находим пользователя в БД или создаем автоматически, если его нет
                User user = userRepository.findByFirebaseUid(firebaseUid)
                        .orElseGet(() -> {
                            // Если пользователь не найден по firebaseUid, проверяем по email
                            if (email != null) {
                                return userRepository.findByEmail(email)
                                        .map(existingUser -> {
                                            // Пользователь существует с таким email, но без firebaseUid - обновляем
                                            logger.info("User found by email but without firebaseUid. Updating firebaseUid: " + firebaseUid);
                                            existingUser.setFirebaseUid(firebaseUid);
                                            if (displayName != null && !displayName.isEmpty()) {
                                                existingUser.setDisplayName(displayName);
                                            }
                                            User updatedUser = userRepository.save(existingUser);
                                            logger.info("User updated successfully: " + updatedUser.getId() + " (" + updatedUser.getEmail() + ")");
                                            return updatedUser;
                                        })
                                        .orElseGet(() -> {
                                            // Пользователь не найден ни по firebaseUid, ни по email - создаем нового
                                            logger.info("User exists in Firebase but not in database. Creating user: " + firebaseUid);
                                            User newUser = new User();
                                            newUser.setEmail(email);
                                            newUser.setDisplayName(displayName);
                                            newUser.setFirebaseUid(firebaseUid);
                                            User savedUser = userRepository.save(newUser);
                                            logger.info("User created successfully in database: " + savedUser.getId() + " (" + savedUser.getEmail() + ")");
                                            return savedUser;
                                        });
                            } else {
                                // Email отсутствует - создаем пользователя с unknown email
                                logger.info("User exists in Firebase but email is null. Creating user: " + firebaseUid);
                                User newUser = new User();
                                newUser.setEmail("unknown@example.com");
                                newUser.setDisplayName(displayName);
                                newUser.setFirebaseUid(firebaseUid);
                                User savedUser = userRepository.save(newUser);
                                logger.info("User created successfully in database: " + savedUser.getId() + " (" + savedUser.getEmail() + ")");
                                return savedUser;
                            }
                        });

                logger.info("User found/created: " + user.getEmail() + " (ID: " + user.getId() + ")");
                UsernamePasswordAuthenticationToken authentication = 
                    new UsernamePasswordAuthenticationToken(user, null, null);
                authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                SecurityContextHolder.getContext().setAuthentication(authentication);
                logger.debug("Authentication set successfully");
            } catch (FirebaseAuthException e) {
                logger.error("Firebase token verification failed: " + e.getMessage());
                logger.error("Error code: " + e.getErrorCode());
                
                // Определяем тип ошибки
                String errorMessage = "Authentication failed";
                int statusCode = HttpServletResponse.SC_FORBIDDEN;
                
                if (e.getErrorCode() != null) {
                    String errorCode = e.getErrorCode().toString();
                    if (errorCode.equals("auth/id-token-expired")) {
                        errorMessage = "Token expired. Please login again.";
                        statusCode = HttpServletResponse.SC_UNAUTHORIZED;
                    } else if (errorCode.equals("auth/id-token-revoked")) {
                        errorMessage = "Token revoked. Please login again.";
                        statusCode = HttpServletResponse.SC_UNAUTHORIZED;
                    } else if (errorCode.equals("auth/invalid-id-token")) {
                        errorMessage = "Invalid token format.";
                    } else {
                        errorMessage = "Authentication failed: " + e.getMessage();
                    }
                }
                
                response.setStatus(statusCode);
                response.setContentType("application/json");
                response.getWriter().write("{\"error\":\"" + errorMessage + "\"}");
                return;
            } catch (RuntimeException e) {
                logger.error("Error processing authentication: " + e.getMessage(), e);
                response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                response.setContentType("application/json");
                response.getWriter().write("{\"error\":\"" + e.getMessage() + "\"}");
                return;
            }
        } else {
            logger.debug("No Authorization header found for request: " + request.getRequestURI());
        }

        filterChain.doFilter(request, response);
    }
}

