package com.bjfu.energy.dao;

import com.bjfu.energy.entity.SysPermission;
import com.bjfu.energy.util.DBUtil;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;

public class PermissionDaoImpl implements PermissionDao {

    @Override
    public List<SysPermission> findByUserId(Long userId) throws Exception {
        String sql = "SELECT DISTINCT p.Perm_Code, p.Perm_Name, p.Module, p.Uri_Pattern, p.Is_Enabled " +
                     "FROM Sys_Role_Assignment a " +
                     "JOIN Sys_Role_Permission rp ON a.Role_Type = rp.Role_Type " +
                     "JOIN Sys_Permission p ON rp.Perm_Code = p.Perm_Code " +
                     "WHERE a.User_ID = ? AND p.Is_Enabled = 1";
        List<SysPermission> list = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    SysPermission p = new SysPermission();
                    p.setPermCode(rs.getString("Perm_Code"));
                    p.setPermName(rs.getString("Perm_Name"));
                    p.setModule(rs.getString("Module"));
                    p.setUriPattern(rs.getString("Uri_Pattern"));
                    int enabled = rs.getInt("Is_Enabled");
                    if (rs.wasNull()) {
                        p.setEnabled(null);
                    } else {
                        p.setEnabled(enabled);
                    }
                    list.add(p);
                }
            }
        }
        return list;
    }
}
