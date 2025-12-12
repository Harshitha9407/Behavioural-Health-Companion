package com.aks.bc.backend.payload;


import lombok.Data;
import java.util.List;
import java.util.Map;

@Data
public class InferenceResultResponse {

    private List<Object> prediction; // Can be an Integer (class index) or a Double (score)
    private List<List<Double>> probabilities; // Optional: Only for classification models
    private String modelId;
    private String modelName;
    private String timestamp;

    // Optional: Error message from the Python service
    private String error;
}