// File: src/main/java/com/aks/bc/backend/exceptions/AuthenticationErrorResponse.java
package com.aks.bc.backend.exception; // Or com.aks.bc.backend.dto; adjust package as needed

public class AuthenticationErrorResponse {
    private String errorCode;
    private String message;
    private long timestamp;

    public AuthenticationErrorResponse(String errorCode, String message) {
        this.errorCode = errorCode;
        this.message = message;
        this.timestamp = System.currentTimeMillis();
    }

    // Getters for errorCode, message, and timestamp
    public String getErrorCode() {
        return errorCode;
    }

    public String getMessage() {
        return message;
    }

    public long getTimestamp() {
        return timestamp;
    }

    // Setters (optional, but good practice if deserialization is ever needed)
    public void setErrorCode(String errorCode) {
        this.errorCode = errorCode;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public void setTimestamp(long timestamp) {
        this.timestamp = timestamp;
    }
}