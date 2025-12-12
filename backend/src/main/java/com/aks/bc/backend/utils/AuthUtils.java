package com.aks.bc.backend.utils;

import com.aks.bc.backend.repository.UserRepository;
import com.aks.bc.backend.security.CustomUserDetails;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Component;

@Component
public class AuthUtils {
    @Autowired
    UserRepository userRepository;

    public static String getFirebaseUid() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

        if (authentication == null || !authentication.isAuthenticated()) {
            // This might happen for permitAll() endpoints if no authentication was explicitly set,
            // or if the token was invalid/missing.
            // For /api/auth/register, the user is not yet registered in *your* DB,
            // but Firebase token is valid. We need to get the UID directly from the token if possible.
            // For now, throw an exception as the user is expected to be authenticated via Firebase token.
            throw new IllegalStateException("User not authenticated or no authentication principal found in SecurityContext.");
        }

        Object principal = authentication.getPrincipal();

        if (principal instanceof CustomUserDetails) {
            CustomUserDetails userDetails = (CustomUserDetails) principal;
            return userDetails.getUsername(); // getUsername() from CustomUserDetails should return the Firebase UID
        } else if (principal instanceof UserDetails) {
            // This handles if Spring Security wrapped your CustomUserDetails in another UserDetails implementation
            // or if you used a different UserDetails directly.
            return ((UserDetails) principal).getUsername();
        }
        else if (principal instanceof String) {
            // This means an unauthenticated (e.g., anonymous) user, where principal is a String.
            // For /api/auth/register, this would imply FirebaseTokenFilter failed to set CustomUserDetails.
            throw new IllegalStateException("Authentication principal is a String (likely anonymous user), not CustomUserDetails. " +
                    "Ensure FirebaseTokenFilter correctly processes the token for this endpoint.");
        } else {
            throw new IllegalStateException("Unexpected authentication principal type: " + principal.getClass().getName());
        }
    }
    public String getLoggedInEmail(){
        CustomUserDetails userDetails = (CustomUserDetails) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        return userRepository.findByFirebaseUid(userDetails.getUsername())
                .orElseThrow(()->
                        new UsernameNotFoundException("User not found with firebaseUid:"+ userDetails.getUsername()))
                .getEmail();
    }
    public Long getLoggedInUserId(){
        CustomUserDetails userDetails = (CustomUserDetails) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        return userRepository.findByFirebaseUid(userDetails.getUsername())
                .orElseThrow(()->
                        new UsernameNotFoundException("User not found with firebaseUid:"+ userDetails.getUsername()))
                .getUserId();
    }
}
