package com.pulse.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Data;
import com.pulse.validation.RussianEmail;

@Data
public class RegisterRequest {
    @NotBlank(message = "Email is required")
    @RussianEmail(message = "Email must use allowed symbols and Russian mail domain")
    private String email;

    @NotBlank(message = "Password is required")
    @Pattern(
            regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[^A-Za-z\\d])[\\x21-\\x7E]{8,64}$",
            message = "Password must include uppercase, lowercase, number, symbol and be 8-64 chars"
    )
    private String password;

    private String displayName;
}



