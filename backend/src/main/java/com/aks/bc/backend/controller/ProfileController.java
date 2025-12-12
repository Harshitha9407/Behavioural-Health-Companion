package com.aks.bc.backend.controller;

import com.aks.bc.backend.model.User;
import com.aks.bc.backend.payload.ProfileUpdateDTO;
import com.aks.bc.backend.service.UserService;
import com.aks.bc.backend.utils.AuthUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/profile")
public class ProfileController {
    @Autowired
    private UserService userService;
    @Autowired
    private AuthUtils authUtils;
    @PutMapping
    public ResponseEntity<ProfileUpdateDTO> updateProfile(@RequestBody ProfileUpdateDTO updateRequest) {
        String firebaseUid = authUtils.getFirebaseUid();
        ProfileUpdateDTO updatedUser = userService.updateUserProfile(firebaseUid, updateRequest);

        return new ResponseEntity<>(updatedUser, HttpStatus.OK);
    }
    @GetMapping
    public ResponseEntity<ProfileUpdateDTO> getProfile() {
        String firebaseUid = authUtils.getFirebaseUid();
        ProfileUpdateDTO userProfile = userService.getUserProfile(firebaseUid);
        return new ResponseEntity<>(userProfile, HttpStatus.OK);
    }
}
