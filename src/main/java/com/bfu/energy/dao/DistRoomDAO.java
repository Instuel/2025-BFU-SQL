package com.bfu.energy.dao;

import com.bfu.energy.dao.BaseDAO;
import com.bfu.energy.entity.DistRoom;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class DistRoomDAO extends BaseDAO<DistRoom, Long> {

    @Override
    protected String getTableName() {
        return "Dist_Room";
    }

    @Override
    protected String getIdColumnName() {
        return "Room_ID";
    }

    @Override
    protected DistRoom mapRow(ResultSet rs) throws SQLException {
        DistRoom room = new DistRoom();
        room.setRoomId(rs.getLong("Room_ID"));
        room.setRoomName(rs.getString("Room_Name"));
        room.setLocation(rs.getString("Location"));
        room.setVoltageLevel(rs.getString("Voltage_Level"));
        room.setManagerUserId(rs.getObject("Manager_User_ID", Long.class));
        room.setFactoryId(rs.getObject("Factory_ID", Long.class));
        return room;
    }

    @Override
    protected String buildInsertSQL() {
        return "INSERT INTO Dist_Room (Room_Name, Location, Voltage_Level, Manager_User_ID, Factory_ID) VALUES (?, ?, ?, ?, ?)";
    }

    @Override
    protected void setInsertParameters(PreparedStatement ps, DistRoom entity) throws SQLException {
        ps.setString(1, entity.getRoomName());
        ps.setString(2, entity.getLocation());
        ps.setString(3, entity.getVoltageLevel());
        if (entity.getManagerUserId() != null) {
            ps.setLong(4, entity.getManagerUserId());
        } else {
            ps.setNull(4, java.sql.Types.BIGINT);
        }
        if (entity.getFactoryId() != null) {
            ps.setLong(5, entity.getFactoryId());
        } else {
            ps.setNull(5, java.sql.Types.BIGINT);
        }
    }

    @Override
    protected String buildUpdateSQL() {
        return "UPDATE Dist_Room SET Room_Name=?, Location=?, Voltage_Level=?, Manager_User_ID=?, Factory_ID=? WHERE Room_ID=?";
    }

    @Override
    protected void setUpdateParameters(PreparedStatement ps, DistRoom entity) throws SQLException {
        ps.setString(1, entity.getRoomName());
        ps.setString(2, entity.getLocation());
        ps.setString(3, entity.getVoltageLevel());
        if (entity.getManagerUserId() != null) {
            ps.setLong(4, entity.getManagerUserId());
        } else {
            ps.setNull(4, java.sql.Types.BIGINT);
        }
        if (entity.getFactoryId() != null) {
            ps.setLong(5, entity.getFactoryId());
        } else {
            ps.setNull(5, java.sql.Types.BIGINT);
        }
        ps.setLong(6, entity.getRoomId());
    }
}
