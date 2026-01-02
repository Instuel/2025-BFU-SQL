package com.bfu.energy.dao;

import com.bfu.energy.dao.BaseDAO;
import com.bfu.energy.entity.DataPVGen;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class DataPVGenDAO extends BaseDAO<DataPVGen, Long> {

    @Override
    protected String getTableName() {
        return "Data_PV_Gen";
    }

    @Override
    protected String getIdColumnName() {
        return "Data_ID";
    }

    @Override
    protected DataPVGen mapRow(ResultSet rs) throws SQLException {
        DataPVGen data = new DataPVGen();
        data.setDataId(rs.getLong("Data_ID"));
        data.setDeviceId(rs.getLong("Device_ID"));
        data.setCollectTime(rs.getObject("Collect_Time", java.util.Date.class));
        data.setGenKwh(rs.getObject("Gen_KWH", Double.class));
        data.setGridKwh(rs.getObject("Grid_KWH", Double.class));
        data.setSelfKwh(rs.getObject("Self_KWH", Double.class));
        data.setInverterEff(rs.getObject("Inverter_Eff", Double.class));
        data.setFactoryId(rs.getObject("Factory_ID", Long.class));
        return data;
    }

    @Override
    protected String buildInsertSQL() {
        return "INSERT INTO Data_PV_Gen (Device_ID, Collect_Time, Gen_KWH, Grid_KWH, Self_KWH, Inverter_Eff, Factory_ID) VALUES (?, ?, ?, ?, ?, ?, ?)";
    }

    @Override
    protected void setInsertParameters(PreparedStatement ps, DataPVGen entity) throws SQLException {
        ps.setLong(1, entity.getDeviceId());
        if (entity.getCollectTime() != null) {
            ps.setTimestamp(2, new java.sql.Timestamp(entity.getCollectTime().getTime()));
        } else {
            ps.setNull(2, java.sql.Types.TIMESTAMP);
        }
        if (entity.getGenKwh() != null) {
            ps.setDouble(3, entity.getGenKwh());
        } else {
            ps.setNull(3, java.sql.Types.DECIMAL);
        }
        if (entity.getGridKwh() != null) {
            ps.setDouble(4, entity.getGridKwh());
        } else {
            ps.setNull(4, java.sql.Types.DECIMAL);
        }
        if (entity.getSelfKwh() != null) {
            ps.setDouble(5, entity.getSelfKwh());
        } else {
            ps.setNull(5, java.sql.Types.DECIMAL);
        }
        if (entity.getInverterEff() != null) {
            ps.setDouble(6, entity.getInverterEff());
        } else {
            ps.setNull(6, java.sql.Types.DECIMAL);
        }
        if (entity.getFactoryId() != null) {
            ps.setLong(7, entity.getFactoryId());
        } else {
            ps.setNull(7, java.sql.Types.BIGINT);
        }
    }

    @Override
    protected String buildUpdateSQL() {
        return "UPDATE Data_PV_Gen SET Device_ID=?, Collect_Time=?, Gen_KWH=?, Grid_KWH=?, Self_KWH=?, Inverter_Eff=?, Factory_ID=? WHERE Data_ID=?";
    }

    @Override
    protected void setUpdateParameters(PreparedStatement ps, DataPVGen entity) throws SQLException {
        ps.setLong(1, entity.getDeviceId());
        if (entity.getCollectTime() != null) {
            ps.setTimestamp(2, new java.sql.Timestamp(entity.getCollectTime().getTime()));
        } else {
            ps.setNull(2, java.sql.Types.TIMESTAMP);
        }
        if (entity.getGenKwh() != null) {
            ps.setDouble(3, entity.getGenKwh());
        } else {
            ps.setNull(3, java.sql.Types.DECIMAL);
        }
        if (entity.getGridKwh() != null) {
            ps.setDouble(4, entity.getGridKwh());
        } else {
            ps.setNull(4, java.sql.Types.DECIMAL);
        }
        if (entity.getSelfKwh() != null) {
            ps.setDouble(5, entity.getSelfKwh());
        } else {
            ps.setNull(5, java.sql.Types.DECIMAL);
        }
        if (entity.getInverterEff() != null) {
            ps.setDouble(6, entity.getInverterEff());
        } else {
            ps.setNull(6, java.sql.Types.DECIMAL);
        }
        if (entity.getFactoryId() != null) {
            ps.setLong(7, entity.getFactoryId());
        } else {
            ps.setNull(7, java.sql.Types.BIGINT);
        }
        ps.setLong(8, entity.getDataId());
    }
}
