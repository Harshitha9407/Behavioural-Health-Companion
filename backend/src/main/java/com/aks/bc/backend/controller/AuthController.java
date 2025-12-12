package com.aks.bc.backend.controller;

import com.aks.bc.backend.payload.SignUpRequestDTO;
import com.aks.bc.backend.payload.SignUpResponseDTO;
import com.aks.bc.backend.service.AuthService;
import com.aks.bc.backend.utils.AuthUtils;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
public class AuthController {
    @Autowired
    AuthService authService;
    @Autowired
    AuthUtils authUtils;

    @PostMapping("/signUp")
    public ResponseEntity<SignUpResponseDTO> signUp(@RequestBody SignUpRequestDTO signUpRequestDTO, HttpServletRequest request){
        String firebaseUid = (String) request.getAttribute("firebaseUid");

        if (firebaseUid == null) {
            // This should not happen if FirebaseTokenFilter runs, but as a fallback
            return new ResponseEntity<>(HttpStatus.UNAUTHORIZED); // Or a more specific error
        }
        SignUpResponseDTO signUpResponse = authService.signUp(signUpRequestDTO,firebaseUid);
        return new ResponseEntity<>(signUpResponse, HttpStatus.CREATED);
    }
}
