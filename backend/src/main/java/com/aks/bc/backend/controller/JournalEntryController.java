package com.aks.bc.backend.controller;

import com.aks.bc.backend.payload.JournalEntriesDTO;
import com.aks.bc.backend.payload.JournalEntryRequestDTO;
import com.aks.bc.backend.payload.ResponseDTO;
import com.aks.bc.backend.service.JournalEntryService;
import com.aks.bc.backend.utils.AuthUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.nio.file.AccessDeniedException;

@RestController
@RequestMapping("/api/journal-entries")
public class JournalEntryController {
    @Autowired
    private JournalEntryService journalEntryService;

    @Autowired
    private AuthUtils authUtils;

    @PostMapping
    public ResponseEntity<ResponseDTO> saveJournalEntry(@RequestBody JournalEntryRequestDTO journalEntryRequest){
        String firebaseUid =  authUtils.getFirebaseUid();
        ResponseDTO response = journalEntryService.saveJournalEntry(journalEntryRequest,firebaseUid);
        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    @GetMapping
    public ResponseEntity<JournalEntriesDTO> getJournalEntries(){
        String firebaseUid =  authUtils.getFirebaseUid();
        JournalEntriesDTO response = journalEntryService.getAllJournalEntries(firebaseUid);
        return new ResponseEntity<>(response, HttpStatus.OK);
    }
    @GetMapping("/{journalEntryId}")
    public ResponseEntity<JournalEntryRequestDTO> getJournalEntryById(@PathVariable Long journalEntryId) throws AccessDeniedException {
        String firebaseUid =  authUtils.getFirebaseUid();
        JournalEntryRequestDTO response = journalEntryService.getJournalEntryById(journalEntryId,firebaseUid);
        return new ResponseEntity<>(response, HttpStatus.OK);
    }
    @DeleteMapping("/{journalEntryId}")
    public ResponseEntity<ResponseDTO> deleteJournalEntryById(@PathVariable Long journalEntryId) throws AccessDeniedException {
        String firebaseUid =  authUtils.getFirebaseUid();
        ResponseDTO response = journalEntryService.deleteJournalEntryById(journalEntryId,firebaseUid);
        return new ResponseEntity<>(response, HttpStatus.OK);
    }
}
