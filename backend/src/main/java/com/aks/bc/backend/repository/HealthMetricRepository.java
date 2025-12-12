package com.aks.bc.backend.repository;

import com.aks.bc.backend.model.HealthMetric;
import com.aks.bc.backend.model.User;
import com.aks.bc.backend.payload.HealthMetricRequestDTO;
import com.aks.bc.backend.payload.HealthMetricsDTO;
import com.aks.bc.backend.payload.ResponseDTO;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;

public interface HealthMetricRepository extends JpaRepository<HealthMetric, Long> {
    @Query("SELECT hm FROM HealthMetric hm WHERE hm.user.firebaseUid = ?1")
    List<HealthMetric> findAllByFirebaseUid(String firebaseUid);
    @Query("SELECT hm FROM HealthMetric hm WHERE hm.user.firebaseUid = ?1 AND hm.type = ?2")
    List<HealthMetric> findAllByTypeAndFirebaseUid(String firebaseUid, String type);

    @Query("SELECT hm FROM HealthMetric hm WHERE hm.user.firebaseUid = :firebaseUid " +
            "AND hm.type = :type AND hm.timestamp >= :startTime ORDER BY hm.timestamp DESC")
    List<HealthMetric> findByUserFirebaseUidAndTypeAndTimestampAfter(
            @Param("firebaseUid") String firebaseUid,
            @Param("type") String type,
            @Param("startTime") LocalDateTime startTime
    );

    @Query("SELECT hm FROM HealthMetric hm WHERE hm.user.firebaseUid = :firebaseUid " +
            "AND hm.type IN :types AND hm.timestamp >= :startTime ORDER BY hm.timestamp DESC")
    List<HealthMetric> findByUserFirebaseUidAndTypeInAndTimestampAfter(
            @Param("firebaseUid") String firebaseUid,
            @Param("types") List<String> relevantMetricTypes,
            @Param("startTime") LocalDateTime twentyFourHoursAgo
    );
}
