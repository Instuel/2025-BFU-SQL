package com.bfu.energy.util;

import org.apache.commons.codec.digest.DigestUtils;

import java.security.SecureRandom;
import java.util.Base64;

public class PasswordUtil {

    private static final int SALT_LENGTH = 16;

    public static String generateSalt() {
        SecureRandom random = new SecureRandom();
        byte[] salt = new byte[SALT_LENGTH];
        random.nextBytes(salt);
        return Base64.getEncoder().encodeToString(salt);
    }

    public static String encryptPassword(String password, String salt) {
        return DigestUtils.sha256Hex(password + salt);
    }

    public static boolean verifyPassword(String password, String salt, String encryptedPassword) {
        return encryptPassword(password, salt).equals(encryptedPassword);
    }
}
