package com.aks.bc.backend.security;

import com.aks.bc.backend.exception.AuthenticationErrorResponse; // Assuming you have this DTO
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import com.google.firebase.auth.FirebaseToken;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger; // Use SLF4J for proper logging
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource; // Added for more details
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
public class FirebaseTokenFilter extends OncePerRequestFilter {

    private static final Logger logger = LoggerFactory.getLogger(FirebaseTokenFilter.class); // Initialize logger

    @Autowired
    private CustomUserDetailsService userDetailsService;

    // FirebaseAuth is already a singleton and initialized via FirebaseConfig
    // No need to inject it directly here if getInstance() is used.
    // However, if you have a bean, it's better to inject it for testability.
    // private final FirebaseAuth firebaseAuth;
    // public FirebaseTokenFilter(FirebaseAuth firebaseAuth) { this.firebaseAuth = firebaseAuth; }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        logger.debug("Entering FirebaseTokenFilter for path: {}", request.getRequestURI());

        String header = request.getHeader("Authorization");
        logger.debug("Authorization Header: {}", header != null ? header.substring(0, Math.min(header.length(), 30)) + "..." : "null");

        if (header == null || !header.startsWith("Bearer ")) {
            logger.debug("No Bearer token found or invalid format. Proceeding unauthenticated.");
            filterChain.doFilter(request, response);
            return;
        }

        String idToken = header.substring(7);
        logger.debug("Extracted ID Token (first 20 chars): {}...", idToken.substring(0, Math.min(idToken.length(), 20)));

        try {
            // Verify the Firebase ID Token
            FirebaseToken decodedToken = FirebaseAuth.getInstance().verifyIdToken(idToken);
            String firebaseUid = decodedToken.getUid();
            logger.debug("Firebase Token SUCCESSFULLY verified for UID: {}", firebaseUid);

            // Set the Firebase UID as a request attribute for controllers to access (especially /api/auth/register)
            request.setAttribute("firebaseUid", firebaseUid);
            request.setAttribute("firebaseDecodedToken", decodedToken); // Optionally, pass the full token

            // Attempt to load the user from our database
            UserDetails userDetails = userDetailsService.loadUserByUsername(firebaseUid);
            logger.debug("User found in DB for Firebase UID: {}", firebaseUid);

            // If user exists in DB, create an authenticated principal and set it in SecurityContext
            UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                    userDetails, null, userDetails.getAuthorities());
            authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request)); // Add web details
            SecurityContextHolder.getContext().setAuthentication(authentication);
            logger.debug("SecurityContextHolder set with CustomUserDetails for existing user UID: {}", firebaseUid);

        } catch (UsernameNotFoundException e) {
            // This specific exception means the Firebase token is valid, but the user does not exist in our DB.
            // This is expected for the /api/auth/register endpoint for new users.
            // We set the UID as a request attribute and let the request proceed to the controller.
            // The controller will then register this new user.
            logger.info("User with Firebase UID {} not found in application database. Token is valid. Proceeding to controller.", request.getAttribute("firebaseUid"));
            SecurityContextHolder.clearContext(); // Ensure no stale/anonymous authentication is present
            // DO NOT return 401 here if this is the registration endpoint.
            // Let the filter chain continue so the AuthController can handle registration.

        } catch (FirebaseAuthException e) {
            // Catch specific Firebase authentication exceptions (e.g., token expired, invalid token)
            logger.error("Firebase token authentication error: {}", e.getMessage(), e);
            handleAuthenticationError(response, HttpServletResponse.SC_UNAUTHORIZED, "TOKEN_AUTHENTICATION_FAILED", "Invalid or expired authentication token.");
            return; // Stop the filter chain
        } catch (Exception e) {
            // Catch any other unexpected exceptions during token processing or user loading
            logger.error("An unexpected error occurred during Firebase authentication filter: {}", e.getMessage(), e);
            handleAuthenticationError(response, HttpServletResponse.SC_UNAUTHORIZED, "INTERNAL_ERROR", "An unexpected authentication error occurred.");
            return; // Stop the filter chain
        }

        filterChain.doFilter(request, response);
        logger.debug("Exiting FirebaseTokenFilter for path: {}", request.getRequestURI());
    }

    private void handleAuthenticationError(HttpServletResponse response, int status, String errorCode, String errorMessage) throws IOException {
        response.setStatus(status);
        response.setContentType("application/json");
        response.getWriter().write(new ObjectMapper().writeValueAsString(
                new AuthenticationErrorResponse(errorCode, errorMessage)
        ));
    }
}