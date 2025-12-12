package com.aks.bc.backend.repository;

import com.aks.bc.backend.model.JournalEntry;
import com.aks.bc.backend.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;

public interface JournalEntryRepository extends JpaRepository<JournalEntry,Long> {

    List<JournalEntry> findAllByUser(User user);

    @Query("SELECT je FROM JournalEntry je WHERE je.user.firebaseUid = :firebaseUid " +
            "AND je.timestamp >= :startTime ORDER BY je.timestamp DESC")
    List<JournalEntry> findByUserFirebaseUidAndTimestampAfter(
            @Param("firebaseUid") String firebaseUid,
            @Param("startTime") LocalDateTime startTime
    );
}
