package com.bjfu.energy.service;

import com.bjfu.energy.dao.SysUserDao;
import com.bjfu.energy.dao.SysUserDaoImpl;
import com.bjfu.energy.entity.SysUser;
import com.bjfu.energy.util.PasswordUtil;

/**
 * 登录 / 注册服务：
 * - 登录时对密码进行 SHA-256+salt 校验
 * - 简化实现：暂不在数据库中持久化失败次数和锁定信息
 */
public class AuthService {

    private final SysUserDao userDao = new SysUserDaoImpl();

    /**
     * 登录校验
     * @param loginAccount 账号
     * @param rawPassword  明文密码
     * @return 成功则返回用户实体，失败返回 null
     */
    public SysUser login(String loginAccount, String rawPassword) throws Exception {
        if (loginAccount == null || loginAccount.trim().isEmpty()) {
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

        // 如需记录最近登录时间，可在此调用 DAO 更新（当前数据库脚本未提供对应字段，暂略）
        return user;
    }

    /**
     * 注册新用户（仅示例骨架：角色由管理员在后台分配）
     * @param u           用户基础信息（不含密码相关字段）
     * @param rawPassword 明文密码
     */
    public Long register(SysUser u, String rawPassword) throws Exception {
        // 简化：固定 salt（真实项目应使用随机盐）
        String salt = "VGVzdFNhbHQxMjM0NTY3OA==";
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
}
