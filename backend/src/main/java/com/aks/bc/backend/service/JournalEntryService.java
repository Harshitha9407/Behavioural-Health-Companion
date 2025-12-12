package com.aks.bc.backend.service;

import com.aks.bc.backend.payload.JournalEntriesDTO;
import com.aks.bc.backend.payload.JournalEntryRequestDTO;
import com.aks.bc.backend.payload.ResponseDTO;

import java.nio.file.AccessDeniedException;

public interface JournalEntryService {
    ResponseDTO saveJournalEntry(JournalEntryRequestDTO journalEntryRequest, String firebaseUid);

    JournalEntriesDTO getAllJournalEntries(String firebaseUid);

    JournalEntryRequestDTO getJournalEntryById(Long journalEntryId, String firebaseUid) throws AccessDeniedException;

    ResponseDTO deleteJournalEntryById(Long journalEntryId, String firebaseUid) throws AccessDeniedException;
}
