package com.aks.bc.backend.service;

import com.aks.bc.backend.payload.SignUpRequestDTO;
import com.aks.bc.backend.payload.SignUpResponseDTO;

public interface AuthService {
    SignUpResponseDTO signUp(SignUpRequestDTO signUpRequest,String firebaseUid);
}
