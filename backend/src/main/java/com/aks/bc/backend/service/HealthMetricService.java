package com.aks.bc.backend.service;

import com.aks.bc.backend.payload.HealthMetricRequestDTO;
import com.aks.bc.backend.payload.HealthMetricsDTO;
import com.aks.bc.backend.payload.ResponseDTO;

public interface HealthMetricService{
    HealthMetricRequestDTO saveHealthMetric(String firebaseUid, HealthMetricRequestDTO healthMetricRequest);
    HealthMetricsDTO getHealthMetricsByUserId(String firebaseUid);
    HealthMetricsDTO getHealthMetricsByType(String firebaseUid, String type);
}
