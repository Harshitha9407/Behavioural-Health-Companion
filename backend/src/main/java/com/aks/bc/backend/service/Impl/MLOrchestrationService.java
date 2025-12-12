package com.aks.bc.backend.service.Impl;

import com.aks.bc.backend.exception.MLModelException;
import com.aks.bc.backend.model.HealthMetric;
import com.aks.bc.backend.model.User;
import com.aks.bc.backend.payload.GenericInferenceRequest;
import com.aks.bc.backend.payload.InferenceResultResponse;
import com.aks.bc.backend.repository.HealthMetricRepository;
import com.aks.bc.backend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class MLOrchestrationService {

    @Value("${ml.service.url}")
    private String mlServiceUrl;

    private final UserRepository userRepository;
    private final HealthMetricRepository healthMetricRepository;
    private final RestTemplate restTemplate;

    public MLOrchestrationService(
            UserRepository userRepository,
            HealthMetricRepository healthMetricRepository) {
        this.userRepository = userRepository;
        this.healthMetricRepository = healthMetricRepository;
        this.restTemplate = new RestTemplate();
    }

    public InferenceResultResponse runSingleInference(String firebaseUid, String modelName) {
        try {
            System.out.println("🔍 Running inference for model: " + modelName);
            System.out.println("🔍 Firebase UID: " + firebaseUid);

            // 1. Get user from database
            User user = userRepository.findByFirebaseUid(firebaseUid)
                    .orElseThrow(() -> new MLModelException("User not found with UID: " + firebaseUid));

            System.out.println("✅ User found: " + user.getName());

            // 2. Get recent health metrics for the user
            LocalDateTime oneDayAgo = LocalDateTime.now().minusDays(1);
            List<String> metricTypes = Arrays.asList(
                "heart_rate", "blood_pressure", "temperature", 
                "oxygen_saturation", "steps", "sleep_hours"
            );
            
            List<HealthMetric> recentMetrics = healthMetricRepository
                    .findByUserFirebaseUidAndTypeInAndTimestampAfter(
                        firebaseUid, 
                        metricTypes, 
                        oneDayAgo
                    );

            if (recentMetrics.isEmpty()) {
                System.out.println("⚠️ No health metrics found, returning mock data");
                return createMockResponse(modelName);
            }

            System.out.println("✅ Found " + recentMetrics.size() + " health metrics");

            // 3. Build inference request from metrics
            GenericInferenceRequest inferenceRequest = buildInferenceRequest(user, recentMetrics);

            // 4. Try to call Python ML service
            try {
                String mlEndpoint = mlServiceUrl + "/" + modelName;
                System.out.println("📤 Calling ML service: " + mlEndpoint);

                HttpHeaders headers = new HttpHeaders();
                headers.setContentType(MediaType.APPLICATION_JSON);
                HttpEntity<GenericInferenceRequest> entity = new HttpEntity<>(inferenceRequest, headers);

                ResponseEntity<InferenceResultResponse> response = restTemplate.exchange(
                        mlEndpoint,
                        HttpMethod.POST,
                        entity,
                        InferenceResultResponse.class
                );

                InferenceResultResponse result = response.getBody();
                if (result != null) {
                    result.setModelName(modelName);
                    result.setTimestamp(LocalDateTime.now().toString());
                    System.out.println("✅ Real ML prediction received");
                    return result;
                }
            } catch (Exception mlError) {
                System.out.println("⚠️ ML service unavailable: " + mlError.getMessage());
            }

            // 5. Return mock data
            return createMockResponse(modelName);

        } catch (Exception e) {
            System.err.println("❌ Error: " + e.getMessage());
            e.printStackTrace();
            return createMockResponse(modelName);
        }
    }

    private GenericInferenceRequest buildInferenceRequest(User user, List<HealthMetric> metrics) {
        GenericInferenceRequest request = new GenericInferenceRequest();

        // Convert metrics list to map
        Map<String, Double> metricMap = metrics.stream()
                .collect(Collectors.toMap(
                    HealthMetric::getType,
                    HealthMetric::getValue,
                    (v1, v2) -> v1
                ));

        // Map health metrics with defaults
        request.setHeartRate(metricMap.getOrDefault("heart_rate", 75.0));
        request.setActivityLevel(metricMap.getOrDefault("steps", 5000.0) / 1000.0);
        request.setSleepQuality(metricMap.getOrDefault("sleep_hours", 7.0));
        request.setSkinTemp(metricMap.getOrDefault("temperature", 37.0));
        
        // Default EEG values
        request.setEegAlpha(8.5);
        request.setEegBeta(15.0);
        request.setEegGamma(30.0);
        request.setEegTheta(6.0);
        request.setEegDelta(2.0);
        request.setGsr(5.0);

        // Time features
        LocalDateTime now = LocalDateTime.now();
        request.setHourOfDay(now.getHour());
        request.setDayOfWeek(now.getDayOfWeek().getValue());
        request.setTimeOfDay(now.getHour());

        // User features
        request.setUserId(user.getUserId());
        request.setAge(user.getAge());
        request.setGender("Male".equalsIgnoreCase(user.getGender()) ? 1 : 0);
        request.setActivityType(2);

        return request;
    }

    private InferenceResultResponse createMockResponse(String modelName) {
        InferenceResultResponse response = new InferenceResultResponse();
        response.setModelName(modelName);
        response.setTimestamp(LocalDateTime.now().toString());

        switch (modelName.toLowerCase()) {
            case "stress_level_classifier":
                response.setPrediction(List.of(1));
                response.setProbabilities(List.of(List.of(0.2, 0.6, 0.2)));
                break;

            case "mood_predictor":
                response.setPrediction(List.of(2));
                response.setProbabilities(List.of(List.of(0.1, 0.2, 0.7)));
                break;

            case "anxiety_level_classifier":
                response.setPrediction(List.of(0));
                response.setProbabilities(List.of(List.of(0.7, 0.2, 0.1)));
                break;

            case "sleep_quality_predictor":
                response.setPrediction(List.of(7.5));
                break;

            case "user_normal_range_predictor":
                response.setPrediction(List.of(1));
                break;

            case "anomaly_detector":
                response.setPrediction(List.of(0));
                break;

            default:
                response.setPrediction(List.of(0));
                break;
        }

        System.out.println("✅ Mock response for " + modelName);
        return response;
    }
}