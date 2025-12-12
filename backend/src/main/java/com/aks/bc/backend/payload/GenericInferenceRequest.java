package com.aks.bc.backend.payload;

import lombok.Data;
import java.util.List;

@Data
public class GenericInferenceRequest {

    // --- Core 12 Emotional State Features ---
    // (These are the physiological and behavioral metrics, required by most models)
    private double eegAlpha;
    private double eegBeta;
    private double eegGamma;
    private double eegTheta;
    private double eegDelta;
    private double heartRate;
    private double gsr;
    private double skinTemp;
    private double activityLevel;
    private double sleepQuality;
    private int hourOfDay;
    private int dayOfWeek;

    // --- Additional Features for User Baseline Models (11-feature input) ---
    // Note: The 11-feature input includes some of the above, but also these user-specific fields.
    // We map these explicitly to ensure we have all required inputs.

    private Long userId; // Required for 'user_normal_range_predictor' etc.
    private int age;     // Required for 'user_normal_range_predictor' etc.
    private int gender;  // 0=Female, 1=Male. Required for 'user_normal_range_predictor' etc.

    private int timeOfDay; // (Duplicate of hourOfDay, but keeping for clarity based on guide)
    private int activityType; // 0=rest, 1=light, 2=moderate, 3=intense, 4=sleep

    // --- Optional: Raw data points for batch processing ---
    // If you plan to send a batch of data, this structure is more efficient.
    // private List<List<Double>> rawInputVector;
}