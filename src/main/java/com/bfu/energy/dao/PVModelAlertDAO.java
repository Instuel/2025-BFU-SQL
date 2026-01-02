package com.bfu.energy.dao;

import com.bfu.energy.dao.BaseDAO;
import com.bfu.energy.entity.PVModelAlert;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class PVModelAlertDAO extends BaseDAO<PVModelAlert, Long> {

    @Override
    protected String getTableName() {
        return "PV_Model_Alert";
    }

    @Override
    protected String getIdColumnName() {
        return "Alert_ID";
    }

    @Override
    protected PVModelAlert mapRow(ResultSet rs) throws SQLException {
        PVModelAlert alert = new PVModelAlert();
        alert.setAlertId(rs.getLong("Alert_ID"));
        alert.setPointId(rs.getLong("Point_ID"));
        alert.setTriggerTime(rs.getObject("Trigger_Time", java.util.Date.class));
        alert.setRemark(rs.getString("Remark"));
        alert.setProcessStatus(rs.getString("Process_Status"));
        alert.setModelVersion(rs.getString("Model_Version"));
        return alert;
    }

    @Override
    protected String buildInsertSQL() {
        return "INSERT INTO PV_Model_Alert (Point_ID, Trigger_Time, Remark, Process_Status, Model_Version) VALUES (?, ?, ?, ?, ?)";
    }

    @Override
    protected void setInsertParameters(PreparedStatement ps, PVModelAlert entity) throws SQLException {
        ps.setLong(1, entity.getPointId());
        if (entity.getTriggerTime() != null) {
            ps.setTimestamp(2, new java.sql.Timestamp(entity.getTriggerTime().getTime()));
        } else {
            ps.setNull(2, java.sql.Types.TIMESTAMP);
        }
        ps.setString(3, entity.getRemark());
        ps.setString(4, entity.getProcessStatus());
        ps.setString(5, entity.getModelVersion());
    }

    @Override
    protected String buildUpdateSQL() {
        return "UPDATE PV_Model_Alert SET Point_ID=?, Trigger_Time=?, Remark=?, Process_Status=?, Model_Version=? WHERE Alert_ID=?";
    }

    @Override
    protected void setUpdateParameters(PreparedStatement ps, PVModelAlert entity) throws SQLException {
        ps.setLong(1, entity.getPointId());
        if (entity.getTriggerTime() != null) {
            ps.setTimestamp(2, new java.sql.Timestamp(entity.getTriggerTime().getTime()));
        } else {
            ps.setNull(2, java.sql.Types.TIMESTAMP);
        }
        ps.setString(3, entity.getRemark());
        ps.setString(4, entity.getProcessStatus());
        ps.setString(5, entity.getModelVersion());
        ps.setLong(6, entity.getAlertId());
    }
}
