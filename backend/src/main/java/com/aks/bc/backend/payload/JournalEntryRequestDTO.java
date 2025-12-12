package com.aks.bc.backend.payload;

import lombok.Data;

@Data
public class JournalEntryRequestDTO {
    private String content;
    private Integer moodRating;
    private String moodTags;
    private Integer stressRating;
    private String emotions;
}
