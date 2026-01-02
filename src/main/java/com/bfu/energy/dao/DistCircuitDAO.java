package com.bfu.energy.dao;

import com.bfu.energy.dao.BaseDAO;
import com.bfu.energy.entity.DistCircuit;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class DistCircuitDAO extends BaseDAO<DistCircuit, Long> {

    @Override
    protected String getTableName() {
        return "Dist_Circuit";
    }

    @Override
    protected String getIdColumnName() {
        return "Circuit_ID";
    }

    @Override
    protected DistCircuit mapRow(ResultSet rs) throws SQLException {
        DistCircuit circuit = new DistCircuit();
        circuit.setCircuitId(rs.getLong("Circuit_ID"));
        circuit.setCircuitName(rs.getString("Circuit_Name"));
        circuit.setRoomId(rs.getObject("Room_ID", Long.class));
        circuit.setLedgerId(rs.getObject("Ledger_ID", Long.class));
        return circuit;
    }

    @Override
    protected String buildInsertSQL() {
        return "INSERT INTO Dist_Circuit (Circuit_Name, Room_ID, Ledger_ID) VALUES (?, ?, ?)";
    }

    @Override
    protected void setInsertParameters(PreparedStatement ps, DistCircuit entity) throws SQLException {
        ps.setString(1, entity.getCircuitName());
        if (entity.getRoomId() != null) {
            ps.setLong(2, entity.getRoomId());
        } else {
            ps.setNull(2, java.sql.Types.BIGINT);
        }
        if (entity.getLedgerId() != null) {
            ps.setLong(3, entity.getLedgerId());
        } else {
            ps.setNull(3, java.sql.Types.BIGINT);
        }
    }

    @Override
    protected String buildUpdateSQL() {
        return "UPDATE Dist_Circuit SET Circuit_Name=?, Room_ID=?, Ledger_ID=? WHERE Circuit_ID=?";
    }

    @Override
    protected void setUpdateParameters(PreparedStatement ps, DistCircuit entity) throws SQLException {
        ps.setString(1, entity.getCircuitName());
        if (entity.getRoomId() != null) {
            ps.setLong(2, entity.getRoomId());
        } else {
            ps.setNull(2, java.sql.Types.BIGINT);
        }
        if (entity.getLedgerId() != null) {
            ps.setLong(3, entity.getLedgerId());
        } else {
            ps.setNull(3, java.sql.Types.BIGINT);
        }
        ps.setLong(4, entity.getCircuitId());
    }
}
