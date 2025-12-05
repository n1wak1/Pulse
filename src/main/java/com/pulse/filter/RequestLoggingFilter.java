package com.pulse.filter;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.util.StreamUtils;

import java.io.IOException;
import java.nio.charset.StandardCharsets;

@Component
@Order(1)
public class RequestLoggingFilter implements Filter {

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        
        if (httpRequest.getRequestURI().equals("/api/teams") && 
            "POST".equalsIgnoreCase(httpRequest.getMethod())) {
            
            // Читаем тело запроса
            byte[] body = StreamUtils.copyToByteArray(httpRequest.getInputStream());
            String bodyString = new String(body, StandardCharsets.UTF_8);
            
            System.out.println("=== RAW JSON REQUEST ===");
            System.out.println("URI: " + httpRequest.getRequestURI());
            System.out.println("Method: " + httpRequest.getMethod());
            System.out.println("Body: " + bodyString);
            System.out.println("========================");
            
            // Создаем новый request wrapper для повторного чтения
            CachedBodyHttpServletRequest cachedBodyHttpServletRequest = 
                new CachedBodyHttpServletRequest(httpRequest, body);
            
            chain.doFilter(cachedBodyHttpServletRequest, response);
        } else {
            chain.doFilter(request, response);
        }
    }
}

