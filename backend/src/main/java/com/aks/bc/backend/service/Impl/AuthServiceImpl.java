package com.aks.bc.backend.service.Impl;

import com.aks.bc.backend.model.User;
import com.aks.bc.backend.payload.SignUpRequestDTO;
import com.aks.bc.backend.payload.SignUpResponseDTO;
import com.aks.bc.backend.repository.UserRepository;
import com.aks.bc.backend.service.AuthService;
import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class AuthServiceImpl implements AuthService {
    @Autowired
    UserRepository userRepository;
    @Autowired
    ModelMapper modelMapper;
    @Override
    public SignUpResponseDTO signUp(SignUpRequestDTO signUpRequest,String firebaseUid) {
        if(userRepository.findByFirebaseUid(firebaseUid).isPresent()){
            throw new IllegalArgumentException("Firebase uid already exists, Try with a new uid");
        }
        if(userRepository.findByEmail(signUpRequest.getEmail()).isPresent()){
            throw new IllegalArgumentException("Email already exists, Try with a new email");
         }
        User user  = modelMapper.map(signUpRequest,User.class);
        user.setFirebaseUid(firebaseUid);
        userRepository.save(user);
        return modelMapper.map(user,SignUpResponseDTO.class);
    }
}
