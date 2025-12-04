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
                logger.debug("Verifying Firebase token for request: " + request.getRequestURI());
                FirebaseToken decodedToken = firebaseAuth.verifyIdToken(token);
                String firebaseUid = decodedToken.getUid();
                logger.debug("Token verified successfully, Firebase UID: " + firebaseUid);
                
                User user = userRepository.findByFirebaseUid(firebaseUid)
                        .orElseThrow(() -> {
                            logger.error("User not found in database for Firebase UID: " + firebaseUid);
                            return new RuntimeException("User not found in database");
                        });

                logger.debug("User found: " + user.getEmail());
                UsernamePasswordAuthenticationToken authentication = 
                    new UsernamePasswordAuthenticationToken(user, null, null);
                authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                SecurityContextHolder.getContext().setAuthentication(authentication);
                logger.debug("Authentication set successfully");
            } catch (FirebaseAuthException e) {
                logger.error("Firebase token verification failed: " + e.getMessage(), e);
                logger.error("Token (first 50 chars): " + (token.length() > 50 ? token.substring(0, 50) + "..." : token));
                // Не устанавливаем аутентификацию, Spring Security вернет 403
            } catch (RuntimeException e) {
                logger.error("Error processing authentication: " + e.getMessage(), e);
                // Не устанавливаем аутентификацию, Spring Security вернет 403
            }
        } else {
            logger.debug("No Authorization header found for request: " + request.getRequestURI());
        }

        filterChain.doFilter(request, response);
    }
}

