package com.bjfu.energy.dao;

import com.bjfu.energy.util.DBUtil;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

public class RoleDispatcherDaoImpl implements RoleDispatcherDao {
    @Override
    public Long findDispatcherIdByUserId(Long userId) throws Exception {
        String sql = "SELECT TOP 1 Dispatcher_ID FROM Role_Dispatcher WHERE User_ID = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    long id = rs.getLong("Dispatcher_ID");
                    return rs.wasNull() ? null : id;
                }
            }
        }
        return null;
    }
}
