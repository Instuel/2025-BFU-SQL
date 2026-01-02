package com.bfu.energy.util;

import java.util.List;

public class PageResult<T> {
    private List<T> data;
    private int currentPage;
    private int pageSize;
    private int totalRecords;
    private int totalPages;

    public PageResult(List<T> data, int currentPage, int pageSize, int totalRecords) {
        this.data = data;
        this.currentPage = currentPage;
        this.pageSize = pageSize;
        this.totalRecords = totalRecords;
        this.totalPages = (int) Math.ceil((double) totalRecords / pageSize);
    }

    public static <T> PageResult<T> of(List<T> data, int currentPage, 
                                       int pageSize, int totalRecords) {
        return new PageResult<>(data, currentPage, pageSize, totalRecords);
    }

    public List<T> getData() {
        return data;
    }

    public void setData(List<T> data) {
        this.data = data;
    }

    public int getCurrentPage() {
        return currentPage;
    }

    public void setCurrentPage(int currentPage) {
        this.currentPage = currentPage;
    }

    public int getPageSize() {
        return pageSize;
    }

    public void setPageSize(int pageSize) {
        this.pageSize = pageSize;
    }

    public int getTotalRecords() {
        return totalRecords;
    }

    public void setTotalRecords(int totalRecords) {
        this.totalRecords = totalRecords;
    }

    public int getTotalPages() {
        return totalPages;
    }

    public void setTotalPages(int totalPages) {
        this.totalPages = totalPages;
    }

    public boolean hasNextPage() {
        return currentPage < totalPages;
    }

    public boolean hasPreviousPage() {
        return currentPage > 1;
    }
}
