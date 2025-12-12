package com.aks.bc.backend.service;

import com.aks.bc.backend.model.User;
import com.aks.bc.backend.payload.ProfileUpdateDTO;

public interface UserService {
    ProfileUpdateDTO updateUserProfile(String firebaseUid, ProfileUpdateDTO updateRequest);
    ProfileUpdateDTO getUserProfile(String firebaseUid);
}
