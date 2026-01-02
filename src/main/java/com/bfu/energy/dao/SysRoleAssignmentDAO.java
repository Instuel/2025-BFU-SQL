package com.bfu.energy.dao;

import com.bfu.energy.dao.BaseDAO;
import com.bfu.energy.entity.SysRoleAssignment;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

public class SysRoleAssignmentDAO extends BaseDAO<SysRoleAssignment, Long> {

    @Override
    protected String getTableName() {
        return "Sys_Role_Assignment";
    }

    @Override
    protected String getIdColumnName() {
        return "Assignment_ID";
    }

    @Override
    protected SysRoleAssignment mapRow(ResultSet rs) throws SQLException {
        SysRoleAssignment assignment = new SysRoleAssignment();
        assignment.setAssignmentId(rs.getLong("Assignment_ID"));
        assignment.setUserId(rs.getLong("User_ID"));
        assignment.setRoleType(rs.getString("Role_Type"));
        assignment.setAssignedBy(rs.getObject("Assigned_By", Long.class));
        Timestamp assignedTime = rs.getTimestamp("Assigned_Time");
        if (assignedTime != null) {
            assignment.setAssignedTime(assignedTime.toLocalDateTime());
        }
        return assignment;
    }

    @Override
    protected String buildInsertSQL() {
        return "INSERT INTO Sys_Role_Assignment (User_ID, Role_Type, Assigned_By) VALUES (?, ?, ?)";
    }

    @Override
    protected void setInsertParameters(PreparedStatement ps, SysRoleAssignment entity) throws SQLException {
        ps.setLong(1, entity.getUserId());
        ps.setString(2, entity.getRoleType());
        if (entity.getAssignedBy() != null) {
            ps.setLong(3, entity.getAssignedBy());
        } else {
            ps.setNull(3, java.sql.Types.BIGINT);
        }
    }

    @Override
    protected String buildUpdateSQL() {
        return "UPDATE Sys_Role_Assignment SET User_ID=?, Role_Type=?, Assigned_By=? WHERE Assignment_ID=?";
    }

    @Override
    protected void setUpdateParameters(PreparedStatement ps, SysRoleAssignment entity) throws SQLException {
        ps.setLong(1, entity.getUserId());
        ps.setString(2, entity.getRoleType());
        if (entity.getAssignedBy() != null) {
            ps.setLong(3, entity.getAssignedBy());
        } else {
            ps.setNull(3, java.sql.Types.BIGINT);
        }
        ps.setLong(4, entity.getAssignmentId());
    }

    public List<SysRoleAssignment> findByUserId(Long userId) {
        String sql = "SELECT * FROM Sys_Role_Assignment WHERE User_ID = ?";
        List<SysRoleAssignment> list = new ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setLong(1, userId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public String findPrimaryRoleByUserId(Long userId) {
        String sql = "SELECT TOP 1 Role_Type FROM Sys_Role_Assignment WHERE User_ID = ? ORDER BY Assigned_Time DESC";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setLong(1, userId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getString("Role_Type");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    public boolean hasRole(Long userId, String roleType) {
        String sql = "SELECT COUNT(*) FROM Sys_Role_Assignment WHERE User_ID = ? AND Role_Type = ?";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setLong(1, userId);
            ps.setString(2, roleType);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean deleteByUserId(Long userId) {
        String sql = "DELETE FROM Sys_Role_Assignment WHERE User_ID = ?";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setLong(1, userId);
            int rows = ps.executeUpdate();
            return rows > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
}
