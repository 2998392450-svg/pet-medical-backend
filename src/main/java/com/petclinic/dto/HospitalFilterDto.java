package com.petclinic.dto;

public class HospitalFilterDto {
    private Double latitude;
    private Double longitude;
    private Integer radius = 5;
    
    private Boolean nightService;
    private Boolean exoticAccept;
    private Boolean emergencySupport;
    
    private Double minRating;
    private String keyword;
    
    private String sortBy;
    private Integer page = 0;
    private Integer size = 20;

    public HospitalFilterDto() {
    }

    public Double getLatitude() {
        return latitude;
    }

    public void setLatitude(Double latitude) {
        this.latitude = latitude;
    }

    public Double getLongitude() {
        return longitude;
    }

    public void setLongitude(Double longitude) {
        this.longitude = longitude;
    }

    public Integer getRadius() {
        return radius;
    }

    public void setRadius(Integer radius) {
        this.radius = radius;
    }

    public Boolean getNightService() {
        return nightService;
    }

    public void setNightService(Boolean nightService) {
        this.nightService = nightService;
    }

    public Boolean getExoticAccept() {
        return exoticAccept;
    }

    public void setExoticAccept(Boolean exoticAccept) {
        this.exoticAccept = exoticAccept;
    }

    public Boolean getEmergencySupport() {
        return emergencySupport;
    }

    public void setEmergencySupport(Boolean emergencySupport) {
        this.emergencySupport = emergencySupport;
    }

    public Double getMinRating() {
        return minRating;
    }

    public void setMinRating(Double minRating) {
        this.minRating = minRating;
    }

    public String getKeyword() {
        return keyword;
    }

    public void setKeyword(String keyword) {
        this.keyword = keyword;
    }

    public String getSortBy() {
        return sortBy;
    }

    public void setSortBy(String sortBy) {
        this.sortBy = sortBy;
    }

    public Integer getPage() {
        return page;
    }

    public void setPage(Integer page) {
        this.page = page;
    }

    public Integer getSize() {
        return size;
    }

    public void setSize(Integer size) {
        this.size = size;
    }
}