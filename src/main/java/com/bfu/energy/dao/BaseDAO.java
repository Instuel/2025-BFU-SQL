package com.bfu.energy.dao;

import com.bfu.energy.util.DbUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public abstract class BaseDAO<T, ID> {

    protected Connection connection;

    public BaseDAO() {
        try {
            this.connection = DbUtil.getConnection();
        } catch (SQLException e) {
            throw new RuntimeException("获取数据库连接失败", e);
        }
    }

    protected abstract String getTableName();

    protected abstract String getIdColumnName();

    protected abstract T mapRow(ResultSet rs) throws SQLException;

    protected abstract String buildInsertSQL();

    protected abstract void setInsertParameters(PreparedStatement ps, T entity) throws SQLException;

    protected abstract String buildUpdateSQL();

    protected abstract void setUpdateParameters(PreparedStatement ps, T entity) throws SQLException;

    public T findById(ID id) {
        String sql = "SELECT * FROM " + getTableName() + " WHERE " + getIdColumnName() + " = ?";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setObject(1, id);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return mapRow(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    public List<T> findAll() {
        String sql = "SELECT * FROM " + getTableName();
        List<T> list = new ArrayList<>();
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

    public boolean insert(T entity) {
        String sql = buildInsertSQL();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            setInsertParameters(ps, entity);
            int rows = ps.executeUpdate();
            return rows > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public boolean update(T entity) {
        String sql = buildUpdateSQL();
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            setUpdateParameters(ps, entity);
            int rows = ps.executeUpdate();
            return rows > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public boolean deleteById(ID id) {
        String sql = "DELETE FROM " + getTableName() + " WHERE " + getIdColumnName() + " = ?";
        try {
            PreparedStatement ps = connection.prepareStatement(sql);
            ps.setObject(1, id);
            int rows = ps.executeUpdate();
            return rows > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    public int count() {
        String sql = "SELECT COUNT(*) FROM " + getTableName();
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

    public void close() {
        DbUtil.close(connection);
    }
}
