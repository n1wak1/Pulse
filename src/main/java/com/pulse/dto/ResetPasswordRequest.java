package com.pulse.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import com.pulse.validation.RussianEmail;

@Data
public class ResetPasswordRequest {
    @NotBlank(message = "Email is required")
    @RussianEmail(message = "Email must use allowed symbols and Russian mail domain")
    private String email;
}



