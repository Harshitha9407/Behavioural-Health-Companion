package com.aks.bc.backend.payload;

import com.google.firebase.database.annotations.NotNull;
import lombok.Data;

import java.time.LocalDate;

@Data
public class SignUpRequestDTO {
    @NotNull
    private String email;
    private String name;
    private String phoneNumber;
    private String gender;
    private LocalDate dateOfBirth;
    private Integer age;
}
