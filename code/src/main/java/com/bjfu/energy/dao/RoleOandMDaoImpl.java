package com.bjfu.energy.dao;

import com.bjfu.energy.entity.RoleOandM;
import com.bjfu.energy.entity.SysUser;
import com.bjfu.energy.util.DBUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;

public class RoleOandMDaoImpl implements RoleOandMDao {

    private RoleOandM mapRow(ResultSet rs) throws Exception {
        RoleOandM roleOandM = new RoleOandM();
        roleOandM.setOandmId(rs.getLong("OandM_ID"));
        roleOandM.setUserId(rs.getLong("User_ID"));
        long factoryId = rs.getLong("Factory_ID");
        if (!rs.wasNull()) {
            roleOandM.setFactoryId(factoryId);
        }
        return roleOandM;
    }

    private SysUser mapUserRow(ResultSet rs) throws Exception {
        SysUser user = new SysUser();
        user.setUserId(rs.getLong("User_ID"));
        user.setLoginAccount(rs.getString("Login_Account"));
        user.setLoginPassword(rs.getString("Login_Password"));
        user.setRealName(rs.getString("Real_Name"));
        user.setContactPhone(rs.getString("Contact_Phone"));
        user.setDepartment(rs.getString("Department"));
        user.setAccountStatus(rs.getInt("Account_Status"));
        return user;
    }

    @Override
    public List<SysUser> findAll() throws Exception {
        String sql = "SELECT u.User_ID, u.Login_Account, u.Login_Password, u.Real_Name, u.Contact_Phone, u.Department, u.Account_Status " +
                     "FROM Sys_User u " +
                     "INNER JOIN Role_OandM r ON u.User_ID = r.User_ID " +
                     "ORDER BY u.User_ID";
        List<SysUser> list = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapUserRow(rs));
            }
        }
        return list;
    }

    @Override
    public List<SysUser> findByFactory(Long factoryId) throws Exception {
        String sql = "SELECT u.User_ID, u.Login_Account, u.Login_Password, u.Real_Name, u.Contact_Phone, u.Department, u.Account_Status " +
                     "FROM Sys_User u " +
                     "INNER JOIN Role_OandM r ON u.User_ID = r.User_ID " +
                     "WHERE r.Factory_ID = ? " +
                     "ORDER BY u.User_ID";
        List<SysUser> list = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, factoryId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapUserRow(rs));
                }
            }
        }
        return list;
    }

    @Override
    public RoleOandM findByUserId(Long userId) throws Exception {
        String sql = "SELECT TOP 1 OandM_ID, User_ID, Factory_ID FROM Role_OandM WHERE User_ID = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
            }
        }
        return null;
    }

    @Override
    public RoleOandM findById(Long oandmId) throws Exception {
        String sql = "SELECT TOP 1 OandM_ID, User_ID, Factory_ID FROM Role_OandM WHERE OandM_ID = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, oandmId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
            }
        }
        return null;
    }

    @Override
    public Long insert(RoleOandM roleOandM) throws Exception {
        String sql = "INSERT INTO Role_OandM (User_ID, Factory_ID) VALUES (?, ?)";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setLong(1, roleOandM.getUserId());
            if (roleOandM.getFactoryId() == null) {
                ps.setNull(2, Types.BIGINT);
            } else {
                ps.setLong(2, roleOandM.getFactoryId());
            }
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    long id = rs.getLong(1);
                    roleOandM.setOandmId(id);
                    return id;
                }
            }
        }
        return null;
    }

    @Override
    public void update(RoleOandM roleOandM) throws Exception {
        String sql = "UPDATE Role_OandM SET User_ID = ?, Factory_ID = ? WHERE OandM_ID = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, roleOandM.getUserId());
            if (roleOandM.getFactoryId() == null) {
                ps.setNull(2, Types.BIGINT);
            } else {
                ps.setLong(2, roleOandM.getFactoryId());
            }
            ps.setLong(3, roleOandM.getOandmId());
            ps.executeUpdate();
        }
    }

    @Override
    public void delete(Long oandmId) throws Exception {
        String sql = "DELETE FROM Role_OandM WHERE OandM_ID = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, oandmId);
            ps.executeUpdate();
        }
    }
}
