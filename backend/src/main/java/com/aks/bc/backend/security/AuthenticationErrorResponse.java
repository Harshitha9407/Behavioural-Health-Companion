package com.aks.bc.backend.security;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class AuthenticationErrorResponse {
    private String code;
    private String message;
    private final LocalDateTime timestamp = LocalDateTime.now();
}
