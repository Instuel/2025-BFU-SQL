package com.bfu.energy.dao;

import com.bfu.energy.dao.BaseDAO;
import com.bfu.energy.entity.DistTransformer;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class DistTransformerDAO extends BaseDAO<DistTransformer, Long> {

    @Override
    protected String getTableName() {
        return "Dist_Transformer";
    }

    @Override
    protected String getIdColumnName() {
        return "Transformer_ID";
    }

    @Override
    protected DistTransformer mapRow(ResultSet rs) throws SQLException {
        DistTransformer transformer = new DistTransformer();
        transformer.setTransformerId(rs.getLong("Transformer_ID"));
        transformer.setTransformerName(rs.getString("Transformer_Name"));
        transformer.setRoomId(rs.getObject("Room_ID", Long.class));
        transformer.setLedgerId(rs.getObject("Ledger_ID", Long.class));
        return transformer;
    }

    @Override
    protected String buildInsertSQL() {
        return "INSERT INTO Dist_Transformer (Transformer_Name, Room_ID, Ledger_ID) VALUES (?, ?, ?)";
    }

    @Override
    protected void setInsertParameters(PreparedStatement ps, DistTransformer entity) throws SQLException {
        ps.setString(1, entity.getTransformerName());
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
        return "UPDATE Dist_Transformer SET Transformer_Name=?, Room_ID=?, Ledger_ID=? WHERE Transformer_ID=?";
    }

    @Override
    protected void setUpdateParameters(PreparedStatement ps, DistTransformer entity) throws SQLException {
        ps.setString(1, entity.getTransformerName());
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
        ps.setLong(4, entity.getTransformerId());
    }
}
