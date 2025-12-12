package com.aks.bc.backend.exception;


public class MLModelException extends RuntimeException {

    // Standard constructor that takes an error message
    public MLModelException(String message) {
        super(message);
    }

    // Constructor to wrap another exception (like IOException or RestClientException)
    public MLModelException(String message, Throwable cause) {
        super(message, cause);
    }
}
