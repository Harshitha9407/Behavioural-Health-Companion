package com.aks.bc.backend.payload;

import lombok.Data;
import java.util.ArrayList;
import java.util.List;

@Data
public class JournalEntriesDTO {
    private List<JournalEntryRequestDTO> journalEntries = new ArrayList<>();

    public JournalEntriesDTO() {
    }

    public JournalEntriesDTO(List<JournalEntryRequestDTO> journalEntries) {
        this.journalEntries = journalEntries;
    }

    public List<JournalEntryRequestDTO> getJournalEntries() {
        return journalEntries;
    }

    public void setJournalEntries(List<JournalEntryRequestDTO> journalEntries) {
        this.journalEntries = journalEntries;
    }
}