package com.bjfu.energy.util;

import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;
import java.util.Map;

public class CSVExportUtil {

    public static void exportCSV(HttpServletResponse response, 
                                 String filename, 
                                 List<String> headers, 
                                 List<Map<String, Object>> data,
                                 Map<String, String> fieldMapping) throws IOException {
        
        // 1. 设置响应头
        response.setContentType("text/csv; charset=UTF-8");
        response.setCharacterEncoding("UTF-8");
        
        // 正确编码文件名
        String encodedFilename = new String(filename.getBytes("UTF-8"), "ISO-8859-1");
        response.setHeader("Content-Disposition", 
            "attachment; filename=\"" + encodedFilename + ".csv\"");
        
        // 【关键修改】使用 OutputStream 而不是 GetWriter
        ServletOutputStream out = response.getOutputStream();
        
        // 【关键修改】写入 BOM 头 (UTF-8 字节序)，让 Excel 能识别中文
        // 0xEF, 0xBB, 0xBF 是 UTF-8 BOM 的标准字节
        out.write(new byte[]{(byte) 0xEF, (byte) 0xBB, (byte) 0xBF});
        
        // 使用 StringBuilder 拼接字符串，然后统一转字节写入
        StringBuilder sb = new StringBuilder();
        
        // 2. 写入标题行
        for (int i = 0; i < headers.size(); i++) {
            sb.append(escapeCSV(headers.get(i)));
            if (i < headers.size() - 1) {
                sb.append(",");
            }
        }
        sb.append("\r\n"); // 换行
        
        // 将标题行转为 UTF-8 字节并写入流
        out.write(sb.toString().getBytes("UTF-8"));
        sb.setLength(0); // 清空 buffer，复用对象
        
        // 3. 写入数据行
        for (Map<String, Object> row : data) {
            for (int i = 0; i < headers.size(); i++) {
                String header = headers.get(i);
                String fieldName = fieldMapping.get(header);
                Object value = row.get(fieldName);
                
                String cellValue = value == null ? "" : String.valueOf(value);
                sb.append(escapeCSV(cellValue));
                
                if (i < headers.size() - 1) {
                    sb.append(",");
                }
            }
            sb.append("\r\n");
            
            // 每行写一次（或者每几行写一次），避免内存占用过大
            out.write(sb.toString().getBytes("UTF-8"));
            sb.setLength(0); // 清空
        }
        
        out.flush();
        out.close();
    }
    
    // 辅助方法保持不变
    private static String escapeCSV(String value) {
        if (value == null) {
            return "";
        }
        
        if (value.contains(",") || value.contains("\"") || 
            value.contains("\n") || value.contains("\r")) {
            value = value.replace("\"", "\"\"");
            return "\"" + value + "\"";
        }
        
        return value;
    }
}