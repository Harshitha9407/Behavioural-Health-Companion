// File: src/main/java/com/aks/bc/backend/config/FirebaseConfig.java
package com.aks.bc.backend.security;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import org.springframework.beans.factory.annotation.Value; // Import @Value
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;

import java.io.IOException;
import java.io.InputStream;

@Configuration
public class FirebaseConfig {

    // Inject the path from application.properties
    @Value("${firebase.service-account-file}")
    private String serviceAccountFilePath;

    @Bean
    public FirebaseApp firebaseApp() throws IOException {
        // Check if FirebaseApp is already initialized to prevent re-initialization in tests or specific contexts
        if (!FirebaseApp.getApps().isEmpty()) {
            System.out.println("FirebaseApp is already initialized.");
            return FirebaseApp.getInstance(); // Return existing instance
        }

        // Use the injected path
        ClassPathResource resource = new ClassPathResource(serviceAccountFilePath);
        InputStream serviceAccount = resource.getInputStream();

        FirebaseOptions options = FirebaseOptions.builder()
                .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                // Add any other options if you use other Firebase services like Database URL or Storage Bucket
                // .setDatabaseUrl("https://YOUR_PROJECT_ID.firebaseio.com")
                // .setStorageBucket("YOUR_PROJECT_ID.appspot.com")
                .build();

        FirebaseApp initializedApp = FirebaseApp.initializeApp(options);
        System.out.println("Firebase Admin SDK initialized successfully.");
        return initializedApp;
    }
}