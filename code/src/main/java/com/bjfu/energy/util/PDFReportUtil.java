package com.bjfu.energy.util;

import com.itextpdf.text.*;
import com.itextpdf.text.pdf.*;

import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.OutputStream;
import java.util.List;
import java.util.Map;

/**
 * PDF报告生成工具类
 * 使用iText库生成PDF文档
 */
public class PDFReportUtil {

    // 中文字体 - 需要引入iTextAsian.jar支持中文
    private static Font titleFont;
    private static Font headerFont;
    private static Font contentFont;
    private static Font smallFont;

    static {
        try {
            // 使用iText内置的中文字体
            BaseFont bfChinese = BaseFont.createFont("STSong-Light", "UniGB-UCS2-H", BaseFont.NOT_EMBEDDED);
            titleFont = new Font(bfChinese, 18, Font.BOLD);
            headerFont = new Font(bfChinese, 14, Font.BOLD);
            contentFont = new Font(bfChinese, 10, Font.NORMAL);
            smallFont = new Font(bfChinese, 8, Font.NORMAL);
        } catch (Exception e) {
            e.printStackTrace();
            // 如果中文字体加载失败，使用默认字体
            titleFont = new Font(Font.FontFamily.HELVETICA, 18, Font.BOLD);
            headerFont = new Font(Font.FontFamily.HELVETICA, 14, Font.BOLD);
            contentFont = new Font(Font.FontFamily.HELVETICA, 10, Font.NORMAL);
            smallFont = new Font(Font.FontFamily.HELVETICA, 8, Font.NORMAL);
        }
    }

    /**
     * 导出PDF报告
     */
    public static void exportPDF(HttpServletResponse response,
                                 String filename,
                                 Map<String, Object> summary,
                                 List<Map<String, Object>> data) throws IOException {
        
        // 设置响应头
        response.setContentType("application/pdf; charset=UTF-8");
        response.setCharacterEncoding("UTF-8");
        response.setHeader("Content-Disposition",
                "attachment; filename=\"" + new String(filename.getBytes("UTF-8"), "ISO-8859-1") + ".pdf\"");

        OutputStream out = response.getOutputStream();
        Document document = new Document(PageSize.A4);

        try {
            PdfWriter.getInstance(document, out);
            document.open();

            // 添加标题
            Paragraph title = new Paragraph("日能耗成本报告", titleFont);
            title.setAlignment(Element.ALIGN_CENTER);
            title.setSpacingAfter(20);
            document.add(title);

            // 添加报告信息
            document.add(createInfoTable(summary));
            document.add(new Paragraph(" ")); // 空行

            // 添加统计摘要
            document.add(createSummaryTable(summary));
            document.add(new Paragraph(" ")); // 空行

            // 添加数据表格
            if (data != null && !data.isEmpty()) {
                Paragraph dataTitle = new Paragraph("厂区能耗成本明细", headerFont);
                dataTitle.setSpacingBefore(10);
                dataTitle.setSpacingAfter(10);
                document.add(dataTitle);
                document.add(createDataTable(data));
            }

            // 添加节能建议
            if (summary.containsKey("suggestion")) {
                document.add(new Paragraph(" ")); // 空行
                Paragraph suggestionTitle = new Paragraph("节能建议", headerFont);
                suggestionTitle.setSpacingBefore(10);
                suggestionTitle.setSpacingAfter(10);
                document.add(suggestionTitle);
                
                Paragraph suggestionContent = new Paragraph(
                    summary.get("suggestion").toString(), contentFont);
                suggestionContent.setAlignment(Element.ALIGN_LEFT);
                document.add(suggestionContent);
            }

        } catch (DocumentException e) {
            throw new IOException("生成PDF失败: " + e.getMessage(), e);
        } finally {
            if (document.isOpen()) {
                document.close();
            }
        }
    }

    /**
     * 创建报告信息表格
     */
    private static PdfPTable createInfoTable(Map<String, Object> summary) throws DocumentException {
        PdfPTable table = new PdfPTable(2);
        table.setWidthPercentage(100);
        table.setSpacingAfter(10);

        // 设置列宽
        table.setWidths(new int[]{1, 2});

        addCell(table, "统计周期:", contentFont, false);
        addCell(table, summary.getOrDefault("period", "日").toString(), contentFont, false);

        addCell(table, "统计日期:", contentFont, false);
        addCell(table, summary.getOrDefault("date", "-").toString(), contentFont, false);

        addCell(table, "生成时间:", contentFont, false);
        addCell(table, summary.getOrDefault("generateTime", "-").toString(), contentFont, false);

        addCell(table, "数据条数:", contentFont, false);
        addCell(table, summary.getOrDefault("itemCount", "0").toString(), contentFont, false);

        return table;
    }

    /**
     * 创建统计摘要表格
     */
    private static PdfPTable createSummaryTable(Map<String, Object> summary) throws DocumentException {
        PdfPTable table = new PdfPTable(4);
        table.setWidthPercentage(100);
        table.setSpacingAfter(10);

        // 表头
        addCell(table, "总能耗", headerFont, true);
        addCell(table, "总成本(元)", headerFont, true);
        addCell(table, "峰时能耗", headerFont, true);
        addCell(table, "低谷能耗", headerFont, true);

        // 数据
        addCell(table, summary.getOrDefault("totalConsumption", "-").toString(), contentFont, false);
        addCell(table, summary.getOrDefault("totalCost", "-").toString(), contentFont, false);
        addCell(table, summary.getOrDefault("peakConsumption", "-").toString(), contentFont, false);
        addCell(table, summary.getOrDefault("valleyConsumption", "-").toString(), contentFont, false);

        return table;
    }

    /**
     * 创建数据明细表格
     */
    private static PdfPTable createDataTable(List<Map<String, Object>> data) throws DocumentException {
        PdfPTable table = new PdfPTable(5);
        table.setWidthPercentage(100);
        table.setWidths(new int[]{2, 2, 2, 2, 2});

        // 表头
        addCell(table, "厂区", headerFont, true);
        addCell(table, "能源类型", headerFont, true);
        addCell(table, "统计日期", headerFont, true);
        addCell(table, "总能耗", headerFont, true);
        addCell(table, "总成本(元)", headerFont, true);

        // 数据行
        for (Map<String, Object> row : data) {
            addCell(table, getStringValue(row, "factoryName"), contentFont, false);
            addCell(table, getStringValue(row, "energyType"), contentFont, false);
            addCell(table, getStringValue(row, "statDate"), contentFont, false);
            addCell(table, getStringValue(row, "totalConsumption"), contentFont, false);
            addCell(table, getStringValue(row, "totalCost"), contentFont, false);
        }

        return table;
    }

    /**
     * 添加表格单元格
     */
    private static void addCell(PdfPTable table, String text, Font font, boolean isHeader) {
        PdfPCell cell = new PdfPCell(new Phrase(text, font));
        cell.setHorizontalAlignment(Element.ALIGN_CENTER);
        cell.setVerticalAlignment(Element.ALIGN_MIDDLE);
        cell.setPadding(8);
        
        if (isHeader) {
            cell.setBackgroundColor(new BaseColor(240, 240, 240));
        }
        
        table.addCell(cell);
    }

    /**
     * 从Map中获取字符串值
     */
    private static String getStringValue(Map<String, Object> map, String key) {
        Object value = map.get(key);
        return value != null ? value.toString() : "-";
    }

    /**
     * 导出月度报告PDF
     */
    public static void exportMonthlyReportPDF(HttpServletResponse response,
                                              String filename,
                                              Map<String, Object> summary,
                                              List<Map<String, Object>> data) throws IOException {
        
        // 设置响应头
        response.setContentType("application/pdf; charset=UTF-8");
        response.setCharacterEncoding("UTF-8");
        response.setHeader("Content-Disposition",
                "attachment; filename=\"" + new String(filename.getBytes("UTF-8"), "ISO-8859-1") + ".pdf\"");

        OutputStream out = response.getOutputStream();
        Document document = new Document(PageSize.A4);

        try {
            PdfWriter.getInstance(document, out);
            document.open();

            // 添加标题
            Paragraph title = new Paragraph("月度能耗报告", titleFont);
            title.setAlignment(Element.ALIGN_CENTER);
            title.setSpacingAfter(20);
            document.add(title);

            // 添加报告信息
            document.add(createMonthlyInfoTable(summary));
            document.add(new Paragraph(" ")); // 空行

            // 添加统计摘要
            document.add(createMonthlySummaryTable(summary));
            document.add(new Paragraph(" ")); // 空行

            // 添加数据表格
            if (data != null && !data.isEmpty()) {
                Paragraph dataTitle = new Paragraph("月度能耗明细", headerFont);
                dataTitle.setSpacingBefore(10);
                dataTitle.setSpacingAfter(10);
                document.add(dataTitle);
                document.add(createMonthlyDataTable(data));
            }

            // 添加分析建议
            if (summary.containsKey("analysis")) {
                document.add(new Paragraph(" ")); // 空行
                Paragraph analysisTitle = new Paragraph("分析建议", headerFont);
                analysisTitle.setSpacingBefore(10);
                analysisTitle.setSpacingAfter(10);
                document.add(analysisTitle);
                
                Paragraph analysisContent = new Paragraph(
                    summary.get("analysis").toString(), contentFont);
                analysisContent.setAlignment(Element.ALIGN_LEFT);
                document.add(analysisContent);
            }

        } catch (DocumentException e) {
            throw new IOException("生成PDF失败: " + e.getMessage(), e);
        } finally {
            if (document.isOpen()) {
                document.close();
            }
        }
    }

    /**
     * 创建月度报告信息表格
     */
    private static PdfPTable createMonthlyInfoTable(Map<String, Object> summary) throws DocumentException {
        PdfPTable table = new PdfPTable(2);
        table.setWidthPercentage(100);
        table.setSpacingAfter(10);

        // 设置列宽
        table.setWidths(new int[]{1, 2});

        addCell(table, "最新月份:", contentFont, false);
        addCell(table, summary.getOrDefault("latestMonth", "-").toString(), contentFont, false);

        addCell(table, "生成时间:", contentFont, false);
        addCell(table, summary.getOrDefault("generateTime", "-").toString(), contentFont, false);

        addCell(table, "数据条数:", contentFont, false);
        addCell(table, summary.getOrDefault("itemCount", "0").toString(), contentFont, false);

        return table;
    }

    /**
     * 创建月度统计摘要表格
     */
    private static PdfPTable createMonthlySummaryTable(Map<String, Object> summary) throws DocumentException {
        PdfPTable table = new PdfPTable(4);
        table.setWidthPercentage(100);
        table.setSpacingAfter(10);

        // 第一行表头
        addCell(table, "总能耗", headerFont, true);
        addCell(table, "总成本(元)", headerFont, true);
        addCell(table, "峰时能耗", headerFont, true);
        addCell(table, "低谷能耗", headerFont, true);

        // 第一行数据
        addCell(table, summary.getOrDefault("totalConsumption", "-").toString(), contentFont, false);
        addCell(table, summary.getOrDefault("totalCost", "-").toString(), contentFont, false);
        addCell(table, summary.getOrDefault("peakConsumption", "-").toString(), contentFont, false);
        addCell(table, summary.getOrDefault("valleyConsumption", "-").toString(), contentFont, false);

        // 第二行表头
        addCell(table, "峰谷差值", headerFont, true);
        addCell(table, "峰谷比", headerFont, true);
        addCell(table, "", headerFont, true);
        addCell(table, "", headerFont, true);

        // 第二行数据
        addCell(table, summary.getOrDefault("peakValleyGap", "-").toString(), contentFont, false);
        addCell(table, summary.getOrDefault("peakValleyRatio", "-").toString(), contentFont, false);
        addCell(table, "", contentFont, false);
        addCell(table, "", contentFont, false);

        return table;
    }

    /**
     * 创建月度数据明细表格
     */
    private static PdfPTable createMonthlyDataTable(List<Map<String, Object>> data) throws DocumentException {
        PdfPTable table = new PdfPTable(8);
        table.setWidthPercentage(100);
        table.setWidths(new int[]{2, 2, 2, 2, 2, 2, 2, 2});

        // 表头
        addCell(table, "月份", headerFont, true);
        addCell(table, "厂区", headerFont, true);
        addCell(table, "能源类型", headerFont, true);
        addCell(table, "峰时能耗", headerFont, true);
        addCell(table, "低谷能耗", headerFont, true);
        addCell(table, "峰谷差值", headerFont, true);
        addCell(table, "总能耗", headerFont, true);
        addCell(table, "成本(元)", headerFont, true);

        // 数据行
        for (Map<String, Object> row : data) {
            addCell(table, getStringValue(row, "reportMonth"), smallFont, false);
            addCell(table, getStringValue(row, "factoryName"), smallFont, false);
            addCell(table, getStringValue(row, "energyType"), smallFont, false);
            addCell(table, getStringValue(row, "peakConsumption"), smallFont, false);
            addCell(table, getStringValue(row, "valleyConsumption"), smallFont, false);
            addCell(table, getStringValue(row, "peakValleyGap"), smallFont, false);
            addCell(table, getStringValue(row, "totalConsumption"), smallFont, false);
            addCell(table, getStringValue(row, "totalCost"), smallFont, false);
        }

        return table;
    }
}
