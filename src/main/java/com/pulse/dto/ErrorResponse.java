package com.pulse.dto;

import lombok.Data;

import java.util.Map;

@Data
public class ErrorResponse {
    private String message;
    private String error;
    private Map<String, Object> details;

    public ErrorResponse() {
    }

    public ErrorResponse(String message, String error, Map<String, Object> details) {
        this.message = message;
        this.error = error;
        this.details = details;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String getError() {
        return error;
    }

    public void setError(String error) {
        this.error = error;
    }

    public Map<String, Object> getDetails() {
        return details;
    }

    public void setDetails(Map<String, Object> details) {
        this.details = details;
    }
}



