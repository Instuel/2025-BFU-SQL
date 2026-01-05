package com.bjfu.energy.dao;

import com.bjfu.energy.entity.DeviceLedger;
import com.bjfu.energy.util.DBUtil;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;

public class DeviceLedgerDaoImpl implements DeviceLedgerDao {

    private DeviceLedger mapRow(ResultSet rs) throws Exception {
        DeviceLedger ledger = new DeviceLedger();
        ledger.setLedgerId(rs.getLong("Ledger_ID"));
        ledger.setDeviceName(rs.getString("Device_Name"));
        ledger.setDeviceType(rs.getString("Device_Type"));
        ledger.setModelSpec(rs.getString("Model_Spec"));
        Date install = rs.getDate("Install_Time");
        if (install != null) {
            ledger.setInstallTime(install.toLocalDate());
        }
        ledger.setScrapStatus(rs.getString("Scrap_Status"));
        int warrantyYears = rs.getInt("Warranty_Years");
        if (rs.wasNull()) {
            ledger.setWarrantyYears(null);
        } else {
            ledger.setWarrantyYears(warrantyYears);
        }
        Timestamp calibration = rs.getTimestamp("Calibration_Time");
        if (calibration != null) {
            ledger.setCalibrationTime(calibration.toLocalDateTime());
        }
        ledger.setCalibrationPerson(rs.getString("Calibration_Person"));
        long factoryId = rs.getLong("Factory_ID");
        if (rs.wasNull()) {
            ledger.setFactoryId(null);
        } else {
            ledger.setFactoryId(factoryId);
        }
        return ledger;
    }

    @Override
    public List<DeviceLedger> findAll(String deviceType, String scrapStatus) throws Exception {
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT Ledger_ID, Device_Name, Device_Type, Model_Spec, Install_Time, Scrap_Status, ")
           .append("Warranty_Years, Calibration_Time, Calibration_Person, Factory_ID ")
           .append("FROM Device_Ledger WHERE 1=1 ");
        List<Object> params = new ArrayList<>();
        if (deviceType != null && !deviceType.trim().isEmpty()) {
            sql.append("AND Device_Type = ? ");
            params.add(deviceType.trim());
        }
        if (scrapStatus != null && !scrapStatus.trim().isEmpty()) {
            sql.append("AND Scrap_Status = ? ");
            params.add(scrapStatus.trim());
        }
        sql.append("ORDER BY Ledger_ID DESC");

        List<DeviceLedger> list = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRow(rs));
                }
            }
        }
        return list;
    }

    @Override
    public List<DeviceLedger> findByFactory(Long factoryId, String deviceType, String scrapStatus) throws Exception {
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT Ledger_ID, Device_Name, Device_Type, Model_Spec, Install_Time, Scrap_Status, ")
           .append("Warranty_Years, Calibration_Time, Calibration_Person, Factory_ID ")
           .append("FROM Device_Ledger WHERE Factory_ID = ? ");
        List<Object> params = new ArrayList<>();
        params.add(factoryId);
        
        if (deviceType != null && !deviceType.trim().isEmpty()) {
            sql.append("AND Device_Type = ? ");
            params.add(deviceType.trim());
        }
        if (scrapStatus != null && !scrapStatus.trim().isEmpty()) {
            sql.append("AND Scrap_Status = ? ");
            params.add(scrapStatus.trim());
        }
        sql.append("ORDER BY Ledger_ID DESC");

        List<DeviceLedger> list = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRow(rs));
                }
            }
        }
        return list;
    }

    @Override
    public DeviceLedger findById(Long ledgerId) throws Exception {
        String sql = "SELECT TOP 1 Ledger_ID, Device_Name, Device_Type, Model_Spec, Install_Time, Scrap_Status, " +
                     "Warranty_Years, Calibration_Time, Calibration_Person, Factory_ID FROM Device_Ledger WHERE Ledger_ID = ?";
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setLong(1, ledgerId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
            }
        }
        return null;
    }
}
