package com.aks.bc.backend.payload;

import lombok.Data;

@Data
public class ResponseDTO {
    private String message;

    public ResponseDTO(String message) {
        this.message = message;
    }
}
