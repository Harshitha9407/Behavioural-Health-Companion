package com.aks.bc.backend.service.Impl;

import com.aks.bc.backend.model.JournalEntry;
import com.aks.bc.backend.model.User;
import com.aks.bc.backend.payload.JournalEntriesDTO;
import com.aks.bc.backend.payload.JournalEntryRequestDTO;
import com.aks.bc.backend.payload.ResponseDTO;
import com.aks.bc.backend.repository.JournalEntryRepository;
import com.aks.bc.backend.repository.UserRepository;
import com.aks.bc.backend.service.JournalEntryService;
import org.modelmapper.ModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.nio.file.AccessDeniedException;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
public class JournalEntryServiceImpl implements JournalEntryService {
    @Autowired
    UserRepository userRepository;
    @Autowired
    JournalEntryRepository journalEntryRepository;
    @Autowired
    ModelMapper modelMapper;

    @Override
    public ResponseDTO saveJournalEntry(JournalEntryRequestDTO journalEntryRequest, String firebaseUid) {
        User user = userRepository.findByFirebaseUid(firebaseUid)
                .orElseThrow(() -> new IllegalArgumentException("User not found with firebaseUid:" + firebaseUid));
        JournalEntry journalEntry = modelMapper.map(journalEntryRequest, JournalEntry.class);
        journalEntry.setUser(user);
        journalEntryRepository.save(journalEntry);
        return new ResponseDTO("Successfully saved the journal entry");
    }

    @Override
    public JournalEntriesDTO getAllJournalEntries(String firebaseUid) {
        User user = userRepository.findByFirebaseUid(firebaseUid)
                .orElseThrow(() -> new IllegalArgumentException("User not found with firebaseUid:" + firebaseUid));
        List<JournalEntry> journalEntries = journalEntryRepository.findAllByUser(user);
        List<JournalEntryRequestDTO> journalEntriesDto = journalEntries.stream()
                .map(journalEntry -> modelMapper.map(journalEntry, JournalEntryRequestDTO.class)).toList();
        JournalEntriesDTO journalEntriesDTO = new JournalEntriesDTO();
        journalEntriesDTO.setJournalEntries(journalEntriesDto);
        return journalEntriesDTO;
    }

    @Override
    public JournalEntryRequestDTO getJournalEntryById(Long journalEntryId, String firebaseUid) throws AccessDeniedException {
        User user = userRepository.findByFirebaseUid(firebaseUid)
                .orElseThrow(() -> new IllegalArgumentException("User not found with firebaseUid:" + firebaseUid));
        Optional<JournalEntry> journalEntry = journalEntryRepository.findById(journalEntryId);
        if (journalEntry.isEmpty()) {
            throw new IllegalArgumentException("Journal entry not found with id:" + journalEntryId);
        }
        String jFirebaseUid = journalEntryRepository.findById(journalEntryId).get().getUser().getFirebaseUid();
        if (!jFirebaseUid.equals(firebaseUid)) {
            throw new AccessDeniedException("Access Denied");
        }
        return modelMapper.map(journalEntry.get(), JournalEntryRequestDTO.class);
    }

    @Override
    public ResponseDTO deleteJournalEntryById(Long journalEntryId, String firebaseUid) throws AccessDeniedException {

        User user = userRepository.findByFirebaseUid(firebaseUid)
                .orElseThrow(()->new IllegalArgumentException("User not found with firebaseUid:"+ firebaseUid));
        Optional<JournalEntry> journalEntry = journalEntryRepository.findById(journalEntryId);
        if(journalEntry.isEmpty()){
            throw new IllegalArgumentException("Journal entry not found with id:"+ journalEntryId);
        }
        String jFirebaseUid = journalEntryRepository.findById(journalEntryId).get().getUser().getFirebaseUid();
        if(!jFirebaseUid.equals(firebaseUid)){
            throw new AccessDeniedException("Access Denied");
        }
        journalEntryRepository.deleteById(journalEntryId);
        return new ResponseDTO("Successfully deleted the journal entry");
    }
}