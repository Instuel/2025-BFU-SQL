package com.bjfu.energy.dao;

import com.bjfu.energy.entity.SysUser;
import com.bjfu.energy.util.DBUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.Timestamp;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;

public class UserDaoImpl implements UserDao {

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

        Timestamp created = rs.getTimestamp("Created_Time");
        if (created != null) {
            u.setCreatedTime(created.toLocalDateTime());
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
    public List<SysUser> findAll() throws Exception {
        String sql = "SELECT User_ID, Login_Account, Login_Password, Salt, Real_Name, Department, " +
                     "Contact_Phone, Account_Status, Created_Time, Updated_Time, Last_Login_Time, " +
                     "Created_By, Updated_By FROM Sys_User ORDER BY User_ID DESC";
        List<SysUser> list = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        }
        return list;
    }

    @Override
    public SysUser findById(Long userId) throws Exception {
        String sql = "SELECT TOP 1 User_ID, Login_Account, Login_Password, Salt, Real_Name, Department, " +
                     "Contact_Phone, Account_Status, Created_Time, Updated_Time, Last_Login_Time, " +
                     "Created_By, Updated_By FROM Sys_User WHERE User_ID = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
                return null;
            }
        }
    }

    @Override
    public SysUser findByLoginAccount(String loginAccount) throws Exception {
        String sql = "SELECT TOP 1 User_ID, Login_Account, Login_Password, Salt, Real_Name, Department, " +
                     "Contact_Phone, Account_Status, Created_Time, Updated_Time, Last_Login_Time, " +
                     "Created_By, Updated_By FROM Sys_User WHERE Login_Account = ?";
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
                     "Department, Contact_Phone, Account_Status, Created_By, Updated_By) " +
                     "VALUES (?,?,?,?,?,?,?,?,?)";
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
            if (user.getCreatedBy() == null) {
                ps.setNull(8, Types.BIGINT);
            } else {
                ps.setLong(8, user.getCreatedBy());
            }
            if (user.getUpdatedBy() == null) {
                ps.setNull(9, Types.BIGINT);
            } else {
                ps.setLong(9, user.getUpdatedBy());
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
    public void update(SysUser user) throws Exception {
        String sql = "UPDATE Sys_User SET Login_Account = ?, Real_Name = ?, Department = ?, " +
                     "Contact_Phone = ?, Account_Status = ?, Updated_Time = SYSDATETIME(), Updated_By = ? " +
                     "WHERE User_ID = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, user.getLoginAccount());
            ps.setString(2, user.getRealName());
            ps.setString(3, user.getDepartment());
            ps.setString(4, user.getContactPhone());
            if (user.getAccountStatus() == null) {
                ps.setNull(5, Types.TINYINT);
            } else {
                ps.setInt(5, user.getAccountStatus());
            }
            if (user.getUpdatedBy() == null) {
                ps.setNull(6, Types.BIGINT);
            } else {
                ps.setLong(6, user.getUpdatedBy());
            }
            ps.setLong(7, user.getUserId());
            ps.executeUpdate();
        }
    }

    @Override
    public void updateStatus(Long userId, int status, Long updatedBy) throws Exception {
        String sql = "UPDATE Sys_User SET Account_Status = ?, Updated_Time = SYSDATETIME(), Updated_By = ? " +
                     "WHERE User_ID = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, status);
            if (updatedBy == null) {
                ps.setNull(2, Types.BIGINT);
            } else {
                ps.setLong(2, updatedBy);
            }
            ps.setLong(3, userId);
            ps.executeUpdate();
        }
    }

    @Override
    public void updatePassword(Long userId, String passwordHash, String salt, Long updatedBy) throws Exception {
        String sql = "UPDATE Sys_User SET Login_Password = ?, Salt = ?, Updated_Time = SYSDATETIME(), " +
                     "Updated_By = ? WHERE User_ID = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, passwordHash);
            ps.setString(2, salt);
            if (updatedBy == null) {
                ps.setNull(3, Types.BIGINT);
            } else {
                ps.setLong(3, updatedBy);
            }
            ps.setLong(4, userId);
            ps.executeUpdate();
        }
    }

    @Override
    public void delete(Long userId) throws Exception {
        String sql = "DELETE FROM Sys_User WHERE User_ID = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            ps.executeUpdate();
        }
    }
}
