package com.aks.bc.backend.service.Impl;

import com.aks.bc.backend.model.User;
import com.aks.bc.backend.payload.ProfileUpdateDTO;
import com.aks.bc.backend.repository.UserRepository;
import com.aks.bc.backend.service.UserService;
import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class UserServiceImpl implements UserService {
    @Autowired
    UserRepository userRepository;

    @Autowired
    ModelMapper modelMapper;

    @Override
    public ProfileUpdateDTO updateUserProfile(String firebaseUid, ProfileUpdateDTO updateRequest) {
        User user = userRepository.findByFirebaseUid(firebaseUid)
                .orElseThrow(()->new IllegalArgumentException
                        ("User not found with firebaseUid:"+ firebaseUid));

        if (updateRequest.getName() != null) {
            user.setName(updateRequest.getName());
        }
        if (updateRequest.getGender() != null) {
            user.setGender(updateRequest.getGender());
        }
        if (updateRequest.getPhoneNumber() != null) {
            user.setPhoneNumber(updateRequest.getPhoneNumber());
        }
        if (updateRequest.getDateOfBirth() != null) {
            user.setDateOfBirth(updateRequest.getDateOfBirth());
        }
        if (updateRequest.getAge() != null) {
            user.setAge(updateRequest.getAge());
        }
        userRepository.save(user);
        return modelMapper.map(user,ProfileUpdateDTO.class);
    }

    @Override
    public ProfileUpdateDTO getUserProfile(String firebaseUid) {
        User user = userRepository.findByFirebaseUid(firebaseUid)
                .orElseThrow(() -> new IllegalArgumentException("User not found with firebaseUid: " + firebaseUid));
        return modelMapper.map(user, ProfileUpdateDTO.class);
    }
}
