package com.bfu.energy.dao;

import com.bfu.energy.dao.BaseDAO;
import com.bfu.energy.entity.PVGridPoint;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class PVGridPointDAO extends BaseDAO<PVGridPoint, Long> {

    @Override
    protected String getTableName() {
        return "PV_Grid_Point";
    }

    @Override
    protected String getIdColumnName() {
        return "Point_ID";
    }

    @Override
    protected PVGridPoint mapRow(ResultSet rs) throws SQLException {
        PVGridPoint point = new PVGridPoint();
        point.setPointId(rs.getLong("Point_ID"));
        point.setPointName(rs.getString("Point_Name"));
        point.setLocation(rs.getString("Location"));
        return point;
    }

    @Override
    protected String buildInsertSQL() {
        return "INSERT INTO PV_Grid_Point (Point_Name, Location) VALUES (?, ?)";
    }

    @Override
    protected void setInsertParameters(PreparedStatement ps, PVGridPoint entity) throws SQLException {
        ps.setString(1, entity.getPointName());
        ps.setString(2, entity.getLocation());
    }

    @Override
    protected String buildUpdateSQL() {
        return "UPDATE PV_Grid_Point SET Point_Name=?, Location=? WHERE Point_ID=?";
    }

    @Override
    protected void setUpdateParameters(PreparedStatement ps, PVGridPoint entity) throws SQLException {
        ps.setString(1, entity.getPointName());
        ps.setString(2, entity.getLocation());
        ps.setLong(3, entity.getPointId());
    }

    public List<PVGridPoint> findAll() {
        String sql = "SELECT * FROM PV_Grid_Point ORDER BY Point_ID";
        List<PVGridPoint> list = new ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public PVGridPoint findByPointName(String pointName) {
        String sql = "SELECT * FROM PV_Grid_Point WHERE Point_Name = ?";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setString(1, pointName);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return mapRow(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }
}
