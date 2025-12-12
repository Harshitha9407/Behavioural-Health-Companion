package com.aks.bc.backend.service.Impl;

import com.aks.bc.backend.model.HealthMetric;
import com.aks.bc.backend.model.User;
import com.aks.bc.backend.payload.HealthMetricRequestDTO;
import com.aks.bc.backend.payload.HealthMetricsDTO;
import com.aks.bc.backend.payload.ResponseDTO;
import com.aks.bc.backend.repository.HealthMetricRepository;
import com.aks.bc.backend.repository.UserRepository;
import com.aks.bc.backend.service.HealthMetricService;
import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class HealthMetricServiceImpl implements HealthMetricService {
    @Autowired
    UserRepository userRepository;
    @Autowired
    HealthMetricRepository healthMetricRepository;
    @Autowired
    ModelMapper modelMapper;

    @Override
    public HealthMetricRequestDTO saveHealthMetric(String firebaseUid, HealthMetricRequestDTO healthMetricRequest) {
        User user = userRepository.findByFirebaseUid(firebaseUid)
                .orElseThrow(()->new IllegalArgumentException("User not found with firebaseUid:"+ firebaseUid));
        HealthMetric healthMetric = modelMapper.map(healthMetricRequest, HealthMetric.class);
        healthMetric.setUser(user);
        healthMetricRepository.save(healthMetric);
        return modelMapper.map(healthMetric, HealthMetricRequestDTO.class);
    }

    @Override
    public HealthMetricsDTO getHealthMetricsByUserId(String firebaseUid) {
        User user = userRepository.findByFirebaseUid(firebaseUid)
                .orElseThrow(()->new IllegalArgumentException("User not found with firebaseUid:"+ firebaseUid));
        List<HealthMetric> metrics = healthMetricRepository.findAllByFirebaseUid(firebaseUid);
        List<HealthMetricRequestDTO> metricsDto = metrics.stream().map(metric -> modelMapper.map(metric, HealthMetricRequestDTO.class)).toList();
        HealthMetricsDTO res = new HealthMetricsDTO(metricsDto);
        return res;
    }

    @Override
    public HealthMetricsDTO getHealthMetricsByType(String firebaseUid, String type) {
        User user = userRepository.findByFirebaseUid(firebaseUid)
                .orElseThrow(()->new IllegalArgumentException("User not found with firebaseUid:"+ firebaseUid));
        List<HealthMetric> metrics = healthMetricRepository.findAllByTypeAndFirebaseUid(firebaseUid,type);
        List<HealthMetricRequestDTO> metricsDto = metrics.stream().map(metric -> modelMapper.map(metric, HealthMetricRequestDTO.class)).toList();
        HealthMetricsDTO res = new HealthMetricsDTO(metricsDto);
        return res;
    }
}
