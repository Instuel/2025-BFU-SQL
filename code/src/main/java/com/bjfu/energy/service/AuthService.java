package com.bjfu.energy.service;

import com.bjfu.energy.dao.PermissionDao;
import com.bjfu.energy.dao.PermissionDaoImpl;
import com.bjfu.energy.dao.SysUserDao;
import com.bjfu.energy.dao.SysUserDaoImpl;
import com.bjfu.energy.entity.SysUser;
import com.bjfu.energy.entity.SysPermission;
import com.bjfu.energy.util.PasswordUtil;

import java.util.List;

/**
 * 登录 / 注册服务：
 * - 登录时对密码进行 SHA-256+salt 校验
 * - 简化实现：暂不在数据库中持久化失败次数和锁定信息
 */
public class AuthService {

    private final SysUserDao userDao = new SysUserDaoImpl();
    private final PermissionDao permissionDao = new PermissionDaoImpl();

    /**
     * 登录校验
     * @param loginAccount 账号
     * @param rawPassword  明文密码
     * @return 成功则返回用户实体，失败返回 null
     */
    public SysUser login(String loginAccount, String rawPassword) throws Exception {
        if (loginAccount == null || loginAccount.trim().isEmpty()
                || rawPassword == null || rawPassword.trim().isEmpty()) {
            return null;
        }
        SysUser user = userDao.findByLoginAccount(loginAccount.trim());
        if (user == null) {
            return null;
        }

        // 账号状态检查：0=禁用
        Integer status = user.getAccountStatus();
        if (status != null && status == 0) {
            return null;
        }

        String salt = user.getSalt();
        if (salt == null) {
            return null;
        }
        String calc = PasswordUtil.sha256Hex(rawPassword, salt);
        if (!calc.equalsIgnoreCase(user.getLoginPassword())) {
            return null;
        }

        userDao.updateLastLogin(user.getUserId());
        return user;
    }

    /**
     * 注册新用户（仅示例骨架：角色由管理员在后台分配）
     * @param u           用户基础信息（不含密码相关字段）
     * @param rawPassword 明文密码
     */
    public Long register(SysUser u, String rawPassword) throws Exception {
        if (u == null) {
            throw new IllegalArgumentException("用户信息不能为空");
        }
        String loginAccount = u.getLoginAccount();
        if (loginAccount == null || loginAccount.trim().isEmpty()) {
            throw new IllegalArgumentException("账号不能为空");
        }
        if (rawPassword == null || rawPassword.trim().isEmpty()) {
            throw new IllegalArgumentException("密码不能为空");
        }
        if (userDao.findByLoginAccount(loginAccount.trim()) != null) {
            throw new IllegalStateException("该账号已存在，请更换账号");
        }

        String salt = PasswordUtil.generateSalt();
        u.setSalt(salt);
        u.setLoginPassword(PasswordUtil.sha256Hex(rawPassword, salt));
        u.setAccountStatus(1);
        return userDao.insert(u);
    }

    /**
     * 查询用户当前角色类型（Sys_Role_Assignment.Role_Type）
     */
    public String getRoleType(Long userId) throws Exception {
        return userDao.getRoleTypeByUserId(userId);
    }

    public List<SysPermission> getPermissions(Long userId) throws Exception {
        return permissionDao.findByUserId(userId);
    }
}
