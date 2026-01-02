package com.bfu.energy.dao;

import com.bfu.energy.dao.BaseDAO;
import com.bfu.energy.entity.BaseFactory;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class BaseFactoryDAO extends BaseDAO<BaseFactory, Long> {

    @Override
    protected String getTableName() {
        return "Base_Factory";
    }

    @Override
    protected String getIdColumnName() {
        return "Factory_ID";
    }

    @Override
    protected BaseFactory mapRow(ResultSet rs) throws SQLException {
        BaseFactory factory = new BaseFactory();
        factory.setFactoryId(rs.getLong("Factory_ID"));
        factory.setFactoryName(rs.getString("Factory_Name"));
        factory.setAreaDesc(rs.getString("Area_Desc"));
        factory.setManagerUserId(rs.getObject("Manager_User_ID", Long.class));
        return factory;
    }

    @Override
    protected String buildInsertSQL() {
        return "INSERT INTO Base_Factory (Factory_Name, Area_Desc, Manager_User_ID) VALUES (?, ?, ?)";
    }

    @Override
    protected void setInsertParameters(PreparedStatement ps, BaseFactory entity) throws SQLException {
        ps.setString(1, entity.getFactoryName());
        ps.setString(2, entity.getAreaDesc());
        if (entity.getManagerUserId() != null) {
            ps.setLong(3, entity.getManagerUserId());
        } else {
            ps.setNull(3, java.sql.Types.BIGINT);
        }
    }

    @Override
    protected String buildUpdateSQL() {
        return "UPDATE Base_Factory SET Factory_Name=?, Area_Desc=?, Manager_User_ID=? WHERE Factory_ID=?";
    }

    @Override
    protected void setUpdateParameters(PreparedStatement ps, BaseFactory entity) throws SQLException {
        ps.setString(1, entity.getFactoryName());
        ps.setString(2, entity.getAreaDesc());
        if (entity.getManagerUserId() != null) {
            ps.setLong(3, entity.getManagerUserId());
        } else {
            ps.setNull(3, java.sql.Types.BIGINT);
        }
        ps.setLong(4, entity.getFactoryId());
    }

    public BaseFactory findByFactoryName(String factoryName) {
        String sql = "SELECT * FROM Base_Factory WHERE Factory_Name = ?";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setString(1, factoryName);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return mapRow(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    public List<BaseFactory> findByManagerUserId(Long managerUserId) {
        String sql = "SELECT * FROM Base_Factory WHERE Manager_User_ID = ?";
        List<BaseFactory> list = new ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setLong(1, managerUserId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<BaseFactory> findAll() {
        String sql = "SELECT * FROM Base_Factory ORDER BY Factory_ID";
        List<BaseFactory> list = new ArrayList<>();
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

    public boolean updateManager(Long factoryId, Long newManagerUserId) {
        String sql = "UPDATE Base_Factory SET Manager_User_ID = ? WHERE Factory_ID = ?";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            if (newManagerUserId != null) {
                ps.setLong(1, newManagerUserId);
            } else {
                ps.setNull(1, java.sql.Types.BIGINT);
            }
            ps.setLong(2, factoryId);
            int rows = ps.executeUpdate();
            return rows > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public List<BaseFactory> findByAreaDesc(String areaDesc) {
        String sql = "SELECT * FROM Base_Factory WHERE Area_Desc LIKE ?";
        List<BaseFactory> list = new ArrayList<>();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setString(1, "%" + areaDesc + "%");
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return list;
    }

    public int countAll() {
        String sql = "SELECT COUNT(*) FROM Base_Factory";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getInt(1);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }

    public boolean existsFactoryName(String factoryName) {
        String sql = "SELECT COUNT(*) FROM Base_Factory WHERE Factory_Name = ?";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setString(1, factoryName);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }
}
