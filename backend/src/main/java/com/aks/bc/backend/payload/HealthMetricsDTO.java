package com.aks.bc.backend.payload;

import lombok.Data;
import java.util.ArrayList;
import java.util.List;

@Data
public class HealthMetricsDTO {
    private List<HealthMetricRequestDTO> healthMetrics = new ArrayList<>();

    public HealthMetricsDTO() {
    }

    public HealthMetricsDTO(List<HealthMetricRequestDTO> healthMetrics) {
        this.healthMetrics = healthMetrics;
    }

    public List<HealthMetricRequestDTO> getHealthMetrics() {
        return healthMetrics;
    }

    public void setHealthMetrics(List<HealthMetricRequestDTO> healthMetrics) {
        this.healthMetrics = healthMetrics;
    }
}