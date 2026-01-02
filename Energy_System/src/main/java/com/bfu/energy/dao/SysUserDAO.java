package com.bfu.energy.dao;

import com.bfu.energy.dao.BaseDAO;
import com.bfu.energy.entity.SysUser;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class SysUserDAO extends BaseDAO<SysUser, Long> {

    @Override
    protected String getTableName() {
        return "Sys_User";
    }

    @Override
    protected String getIdColumnName() {
        return "User_ID";
    }

    @Override
    protected SysUser mapRow(ResultSet rs) throws SQLException {
        SysUser user = new SysUser();
        user.setUserId(rs.getLong("User_ID"));
        user.setLoginAccount(rs.getString("Login_Account"));
        user.setLoginPassword(rs.getString("Login_Password"));
        user.setSalt(rs.getString("Salt"));
        user.setRealName(rs.getString("Real_Name"));
        user.setDepartment(rs.getString("Department"));
        user.setContactPhone(rs.getString("Contact_Phone"));
        user.setAccountStatus(rs.getInt("Account_Status"));
        user.setCreatedTime(rs.getObject("Created_Time", java.time.LocalDateTime.class));
        return user;
    }

    @Override
    protected String buildInsertSQL() {
        return "INSERT INTO Sys_User (Login_Account, Login_Password, Salt, Real_Name, Department, Contact_Phone, Account_Status) VALUES (?, ?, ?, ?, ?, ?, ?)";
    }

    @Override
    protected void setInsertParameters(PreparedStatement ps, SysUser entity) throws SQLException {
        ps.setString(1, entity.getLoginAccount());
        ps.setString(2, entity.getLoginPassword());
        ps.setString(3, entity.getSalt());
        ps.setString(4, entity.getRealName());
        ps.setString(5, entity.getDepartment());
        ps.setString(6, entity.getContactPhone());
        ps.setInt(7, entity.getAccountStatus());
    }

    @Override
    protected String buildUpdateSQL() {
        return "UPDATE Sys_User SET Login_Account=?, Login_Password=?, Salt=?, Real_Name=?, Department=?, Contact_Phone=?, Account_Status=? WHERE User_ID=?";
    }

    @Override
    protected void setUpdateParameters(PreparedStatement ps, SysUser entity) throws SQLException {
        ps.setString(1, entity.getLoginAccount());
        ps.setString(2, entity.getLoginPassword());
        ps.setString(3, entity.getSalt());
        ps.setString(4, entity.getRealName());
        ps.setString(5, entity.getDepartment());
        ps.setString(6, entity.getContactPhone());
        ps.setInt(7, entity.getAccountStatus());
        ps.setLong(8, entity.getUserId());
    }

    public SysUser findByLoginAccount(String loginAccount) {
        String sql = "SELECT * FROM Sys_User WHERE Login_Account = ?";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setString(1, loginAccount);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return mapRow(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    public List<SysUser> findByDepartment(String department) {
        String sql = "SELECT * FROM Sys_User WHERE Department = ?";
        List<SysUser> list = new ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setString(1, department);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<SysUser> findByAccountStatus(Integer accountStatus) {
        String sql = "SELECT * FROM Sys_User WHERE Account_Status = ?";
        List<SysUser> list = new ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setInt(1, accountStatus);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public boolean updateAccountStatus(Long userId, Integer newStatus) {
        String sql = "UPDATE Sys_User SET Account_Status = ? WHERE User_ID = ?";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setInt(1, newStatus);
            ps.setLong(2, userId);
            int rows = ps.executeUpdate();
            return rows > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public boolean updatePassword(Long userId, String newPassword, String newSalt) {
        String sql = "UPDATE Sys_User SET Login_Password = ?, Salt = ? WHERE User_ID = ?";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setString(1, newPassword);
            ps.setString(2, newSalt);
            ps.setLong(3, userId);
            int rows = ps.executeUpdate();
            return rows > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public List<SysUser> findByRealName(String realName) {
        String sql = "SELECT * FROM Sys_User WHERE Real_Name LIKE ?";
        List<SysUser> list = new ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setString(1, "%" + realName + "%");
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public int countByAccountStatus(Integer accountStatus) {
        String sql = "SELECT COUNT(*) FROM Sys_User WHERE Account_Status = ?";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setInt(1, accountStatus);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }
}
