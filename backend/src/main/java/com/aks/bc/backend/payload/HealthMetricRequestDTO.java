package com.aks.bc.backend.payload;

import lombok.Data;

@Data
public class HealthMetricRequestDTO {
    private String type;
    private double value;
    private String source;
}
