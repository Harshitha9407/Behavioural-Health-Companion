package com.aks.bc.backend.payload;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDate;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class ProfileUpdateDTO {
    private String name;
    private String phoneNumber;
    private String gender;
    private Integer age;
    private LocalDate dateOfBirth;
}
