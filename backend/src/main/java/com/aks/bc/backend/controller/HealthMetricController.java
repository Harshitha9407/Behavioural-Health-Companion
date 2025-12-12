package com.aks.bc.backend.controller;

import com.aks.bc.backend.model.HealthMetric;
import com.aks.bc.backend.payload.HealthMetricRequestDTO;
import com.aks.bc.backend.payload.HealthMetricsDTO;
import com.aks.bc.backend.payload.ResponseDTO;
import com.aks.bc.backend.service.Impl.HealthMetricServiceImpl;
import com.aks.bc.backend.utils.AuthUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/health-metrics")
public class HealthMetricController {

    @Autowired
    AuthUtils authUtils;
    @Autowired
    HealthMetricServiceImpl healthMetricService;

    @PostMapping
    public ResponseEntity<HealthMetricRequestDTO> saveHealthMetric(@RequestBody HealthMetricRequestDTO healthMetricRequest){
        String firebaseUid = authUtils.getFirebaseUid();
        HealthMetricRequestDTO res = healthMetricService.saveHealthMetric(firebaseUid,healthMetricRequest);
        return new ResponseEntity<>(res, HttpStatus.CREATED);
    }
    @GetMapping("/user")
    public ResponseEntity<HealthMetricsDTO> getHealthMetricsByUserId(){
        String firebaseUid = authUtils.getFirebaseUid();
        HealthMetricsDTO res = healthMetricService.getHealthMetricsByUserId(firebaseUid);
        return new ResponseEntity<>(res, HttpStatus.OK);
    }
    @GetMapping("/{type}")
    public ResponseEntity<HealthMetricsDTO> getHealthMetricsByType(@PathVariable String type){
        String firebaseUid = authUtils.getFirebaseUid();
        HealthMetricsDTO res = healthMetricService.getHealthMetricsByType(firebaseUid,type);
        return new ResponseEntity<>(res,HttpStatus.OK); 
    }
}
