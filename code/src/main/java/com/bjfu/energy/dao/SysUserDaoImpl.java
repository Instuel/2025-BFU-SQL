package com.bjfu.energy.dao;

import com.bjfu.energy.entity.SysUser;
import com.bjfu.energy.util.DBUtil;

import java.sql.*;

/**
 * Sys_User 表的 JDBC 实现
 */
public class SysUserDaoImpl implements SysUserDao {

    private SysUser mapRow(ResultSet rs) throws Exception {
        SysUser u = new SysUser();
        u.setUserId(rs.getLong("User_ID"));
        u.setLoginAccount(rs.getString("Login_Account"));
        u.setLoginPassword(rs.getString("Login_Password"));
        u.setSalt(rs.getString("Salt"));
        u.setRealName(rs.getString("Real_Name"));
        u.setDepartment(rs.getString("Department"));
        u.setContactPhone(rs.getString("Contact_Phone"));

        int status = rs.getInt("Account_Status");
        if (rs.wasNull()) {
            u.setAccountStatus(null);
        } else {
            u.setAccountStatus(status);
        }

        Timestamp ts = rs.getTimestamp("Created_Time");
        if (ts != null) {
            u.setCreatedTime(ts.toLocalDateTime());
        }
        Timestamp updated = rs.getTimestamp("Updated_Time");
        if (updated != null) {
            u.setUpdatedTime(updated.toLocalDateTime());
        }
        Timestamp lastLogin = rs.getTimestamp("Last_Login_Time");
        if (lastLogin != null) {
            u.setLastLoginTime(lastLogin.toLocalDateTime());
        }
        long createdBy = rs.getLong("Created_By");
        if (rs.wasNull()) {
            u.setCreatedBy(null);
        } else {
            u.setCreatedBy(createdBy);
        }
        long updatedBy = rs.getLong("Updated_By");
        if (rs.wasNull()) {
            u.setUpdatedBy(null);
        } else {
            u.setUpdatedBy(updatedBy);
        }
        return u;
    }

    @Override
    public SysUser findByLoginAccount(String loginAccount) throws Exception {
        String sql = "SELECT TOP 1 User_ID, Login_Account, Login_Password, Salt, Real_Name, " +
                     "Department, Contact_Phone, Account_Status, Created_Time, Updated_Time, " +
                     "Last_Login_Time, Created_By, Updated_By " +
                     "FROM Sys_User WHERE Login_Account = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, loginAccount);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
                return null;
            }
        }
    }

    @Override
    public Long insert(SysUser user) throws Exception {
        String sql = "INSERT INTO Sys_User (Login_Account, Login_Password, Salt, Real_Name, " +
                     "Department, Contact_Phone, Account_Status) " +
                     "VALUES (?,?,?,?,?,?,?)";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {

            ps.setString(1, user.getLoginAccount());
            ps.setString(2, user.getLoginPassword());
            ps.setString(3, user.getSalt());
            ps.setString(4, user.getRealName());
            ps.setString(5, user.getDepartment());
            ps.setString(6, user.getContactPhone());
            if (user.getAccountStatus() == null) {
                ps.setNull(7, Types.TINYINT);
            } else {
                ps.setInt(7, user.getAccountStatus());
            }

            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    long id = rs.getLong(1);
                    user.setUserId(id);
                    return id;
                }
            }
        }
        return null;
    }

    @Override
    public void updateLastLogin(Long userId) throws Exception {
        String sql = "UPDATE Sys_User SET Last_Login_Time = SYSDATETIME(), " +
                     "Updated_Time = SYSDATETIME() WHERE User_ID = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            ps.executeUpdate();
        }
    }

    @Override
    public void increaseFailedLogin(Long userId) throws Exception {
        // 当前数据库脚本未设计失败登录次数字段，如需持久化可在此处扩展
    }

    @Override
    public void resetFailedLogin(Long userId) throws Exception {
        // 同上：保留空实现，方便后续扩展
    }

    @Override
    public void lockAccount(Long userId, int minutes) throws Exception {
        // 同上：可在数据库增加锁定字段后，在此实现锁定逻辑
    }

    @Override
    public String getRoleTypeByUserId(Long userId) throws Exception {
        String sql = "SELECT TOP 1 Role_Type FROM Sys_Role_Assignment " +
                     "WHERE User_ID = ? ORDER BY Assigned_Time DESC";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getString("Role_Type");
                }
                return null;
            }
        }
    }
}
