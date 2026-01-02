package com.bfu.energy.exception;

import java.util.Map;

public class ValidationException extends BaseException {
    private Map<String, String> fieldErrors;

    public ValidationException(String code, String message, 
                              Map<String, String> fieldErrors) {
        super(code, message);
        this.fieldErrors = fieldErrors;
    }

    public Map<String, String> getFieldErrors() {
        return fieldErrors;
    }
}
