package com.bfu.energy.util;

import java.util.List;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

public class DAOFactory {

    private static final ConcurrentMap<Class<?>, Object> DAO_CACHE = new ConcurrentHashMap<>();

    @SuppressWarnings("unchecked")
    public static <T> T getDAO(Class<T> daoClass) {
        return (T) DAO_CACHE.computeIfAbsent(daoClass, clazz -> {
            try {
                return clazz.getDeclaredConstructor().newInstance();
            } catch (Exception e) {
                throw new RuntimeException("创建DAO失败", e);
            }
        });
    }

    public static void clearCache() {
        DAO_CACHE.clear();
    }
}
