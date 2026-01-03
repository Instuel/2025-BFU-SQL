package com.bjfu.energy.service;

import com.bjfu.energy.dao.UserDao;
import com.bjfu.energy.dao.UserDaoImpl;
import com.bjfu.energy.entity.SysUser;
import com.bjfu.energy.util.PasswordUtil;

import java.util.List;

public class UserService {

    public static final String DEFAULT_RESET_PASSWORD = "123456";

    private final UserDao userDao = new UserDaoImpl();

    public List<SysUser> listUsers() throws Exception {
        return userDao.findAll();
    }

    public SysUser getUser(Long userId) throws Exception {
        return userDao.findById(userId);
    }

    public Long createUser(SysUser user, String rawPassword, Long operatorId) throws Exception {
        if (user == null) {
            throw new IllegalArgumentException("用户信息不能为空");
        }
        String loginAccount = safeTrim(user.getLoginAccount());
        if (loginAccount.isEmpty()) {
            throw new IllegalArgumentException("账号不能为空");
        }
        if (rawPassword == null || rawPassword.trim().isEmpty()) {
            throw new IllegalArgumentException("初始密码不能为空");
        }
        if (userDao.findByLoginAccount(loginAccount) != null) {
            throw new IllegalStateException("该账号已存在，请更换账号");
        }
        user.setLoginAccount(loginAccount);
        String salt = PasswordUtil.generateSalt();
        user.setSalt(salt);
        user.setLoginPassword(PasswordUtil.sha256Hex(rawPassword, salt));
        if (user.getAccountStatus() == null) {
            user.setAccountStatus(1);
        }
        user.setCreatedBy(operatorId);
        user.setUpdatedBy(operatorId);
        return userDao.insert(user);
    }

    public void updateUser(SysUser user, String newPassword, Long operatorId) throws Exception {
        if (user == null || user.getUserId() == null) {
            throw new IllegalArgumentException("用户信息不完整");
        }
        String loginAccount = safeTrim(user.getLoginAccount());
        if (loginAccount.isEmpty()) {
            throw new IllegalArgumentException("账号不能为空");
        }
        SysUser existing = userDao.findByLoginAccount(loginAccount);
        if (existing != null && !existing.getUserId().equals(user.getUserId())) {
            throw new IllegalStateException("账号已被其他用户占用");
        }
        user.setLoginAccount(loginAccount);
        user.setUpdatedBy(operatorId);
        userDao.update(user);

        if (newPassword != null && !newPassword.trim().isEmpty()) {
            String salt = PasswordUtil.generateSalt();
            String hash = PasswordUtil.sha256Hex(newPassword, salt);
            userDao.updatePassword(user.getUserId(), hash, salt, operatorId);
        }
    }

    public void updateStatus(Long userId, int status, Long operatorId) throws Exception {
        userDao.updateStatus(userId, status, operatorId);
    }

    public void resetPassword(Long userId, Long operatorId) throws Exception {
        String salt = PasswordUtil.generateSalt();
        String hash = PasswordUtil.sha256Hex(DEFAULT_RESET_PASSWORD, salt);
        userDao.updatePassword(userId, hash, salt, operatorId);
    }

    public void deleteUser(Long userId) throws Exception {
        userDao.delete(userId);
    }

    private String safeTrim(String value) {
        return value == null ? "" : value.trim();
    }
}
