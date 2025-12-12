package com.aks.bc.backend.controller;

import com.aks.bc.backend.payload.InferenceResultResponse;
import com.aks.bc.backend.service.Impl.MLOrchestrationService;
import com.aks.bc.backend.utils.AuthUtils;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/analysis")
public class AnalysisController {

    private final MLOrchestrationService mlOrchestrationService;
    private final AuthUtils authUtils; // Injected for clean UID retrieval

    /**
     * Recommended: Constructor Injection for all dependencies.
     */
    public AnalysisController(MLOrchestrationService mlOrchestrationService, AuthUtils authUtils) {
        this.mlOrchestrationService = mlOrchestrationService;
        this.authUtils = authUtils;
    }

    /**
     * Endpoint to retrieve the result of a single, specific ML model for the authenticated user.
     * The service handles fetching all necessary user data and metrics.
     */
    @GetMapping("/{modelName}")
    public ResponseEntity<InferenceResultResponse> getModelAnalysis(@PathVariable String modelName) {

        // 1. Get the validated user's Firebase UID using the utility class.
        // This is clean and secure.
        String firebaseUid = authUtils.getFirebaseUid();

        // 2. Delegate the entire process (data fetching, request building, HTTP call)
        // to the MLOrchestrationService's single public method.
        InferenceResultResponse analysisResult =
                mlOrchestrationService.runSingleInference(firebaseUid, modelName);

        // 3. Return the result to the mobile application
        return ResponseEntity.ok(analysisResult);
    }
}