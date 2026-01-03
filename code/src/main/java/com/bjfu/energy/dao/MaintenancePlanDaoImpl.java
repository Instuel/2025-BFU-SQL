package com.bjfu.energy.dao;

import com.bjfu.energy.entity.MaintenancePlan;
import com.bjfu.energy.util.DBUtil;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.Timestamp;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;

public class MaintenancePlanDaoImpl implements MaintenancePlanDao {

    private MaintenancePlan mapRow(ResultSet rs) throws Exception {
        MaintenancePlan plan = new MaintenancePlan();
        plan.setPlanId(rs.getLong("Plan_ID"));
        long ledgerId = rs.getLong("Ledger_ID");
        plan.setLedgerId(rs.wasNull() ? null : ledgerId);
        plan.setPlanType(rs.getString("Plan_Type"));
        plan.setPlanContent(rs.getString("Plan_Content"));
        Date planDate = rs.getDate("Plan_Date");
        if (planDate != null) {
            plan.setPlanDate(planDate.toLocalDate());
        }
        plan.setOwnerName(rs.getString("Owner_Name"));
        plan.setStatus(rs.getString("Status"));
        Timestamp createdAt = rs.getTimestamp("Created_At");
        if (createdAt != null) {
            plan.setCreatedAt(createdAt.toLocalDateTime());
        }
        plan.setDeviceName(rs.getString("Device_Name"));
        plan.setDeviceType(rs.getString("Device_Type"));
        return plan;
    }

    @Override
    public List<MaintenancePlan> findAll(String deviceType, String status) throws Exception {
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT p.Plan_ID, p.Ledger_ID, p.Plan_Type, p.Plan_Content, p.Plan_Date, ")
           .append("p.Owner_Name, p.Status, p.Created_At, ")
           .append("l.Device_Name, l.Device_Type ")
           .append("FROM Maintenance_Plan p ")
           .append("LEFT JOIN Device_Ledger l ON p.Ledger_ID = l.Ledger_ID ")
           .append("WHERE 1=1 ");
        List<Object> params = new ArrayList<>();
        if (deviceType != null && !deviceType.trim().isEmpty()) {
            sql.append("AND l.Device_Type = ? ");
            params.add(deviceType.trim());
        }
        if (status != null && !status.trim().isEmpty()) {
            sql.append("AND p.Status = ? ");
            params.add(status.trim());
        }
        sql.append("ORDER BY p.Plan_Date ASC, p.Plan_ID DESC");

        List<MaintenancePlan> list = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRow(rs));
                }
            }
        }
        return list;
    }

    @Override
    public List<MaintenancePlan> findByLedgerId(Long ledgerId) throws Exception {
        String sql = "SELECT p.Plan_ID, p.Ledger_ID, p.Plan_Type, p.Plan_Content, p.Plan_Date, " +
                     "p.Owner_Name, p.Status, p.Created_At, " +
                     "l.Device_Name, l.Device_Type " +
                     "FROM Maintenance_Plan p " +
                     "LEFT JOIN Device_Ledger l ON p.Ledger_ID = l.Ledger_ID " +
                     "WHERE p.Ledger_ID = ? " +
                     "ORDER BY p.Plan_Date ASC, p.Plan_ID DESC";
        List<MaintenancePlan> list = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, ledgerId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRow(rs));
                }
            }
        }
        return list;
    }

    @Override
    public Long insert(MaintenancePlan plan) throws Exception {
        String sql = "INSERT INTO Maintenance_Plan (Ledger_ID, Plan_Type, Plan_Content, Plan_Date, " +
                     "Owner_Name, Status, Created_At) VALUES (?,?,?,?,?,?,?)";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            if (plan.getLedgerId() == null) {
                ps.setNull(1, Types.BIGINT);
            } else {
                ps.setLong(1, plan.getLedgerId());
            }
            ps.setString(2, plan.getPlanType());
            ps.setString(3, plan.getPlanContent());
            if (plan.getPlanDate() == null) {
                ps.setNull(4, Types.DATE);
            } else {
                ps.setDate(4, Date.valueOf(plan.getPlanDate()));
            }
            ps.setString(5, plan.getOwnerName());
            ps.setString(6, plan.getStatus());
            if (plan.getCreatedAt() == null) {
                ps.setTimestamp(7, new Timestamp(System.currentTimeMillis()));
            } else {
                ps.setTimestamp(7, Timestamp.valueOf(plan.getCreatedAt()));
            }
            ps.executeUpdate();
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    long id = rs.getLong(1);
                    plan.setPlanId(id);
                    return id;
                }
            }
        }
        return null;
    }
}
