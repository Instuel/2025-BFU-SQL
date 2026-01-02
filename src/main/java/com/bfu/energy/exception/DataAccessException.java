package com.bfu.energy.exception;

public class DataAccessException extends BaseException {
    public DataAccessException(String code, String message) {
        super(code, message);
    }

    public DataAccessException(String code, String message, Throwable cause) {
        super(code, message, cause);
    }
}
