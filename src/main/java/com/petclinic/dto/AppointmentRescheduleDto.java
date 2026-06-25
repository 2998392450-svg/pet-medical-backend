package com.petclinic.dto;

public class AppointmentRescheduleDto {
    private String newDate;
    private String newTimeSlot;

    public AppointmentRescheduleDto() {
    }

    public String getNewDate() {
        return newDate;
    }

    public void setNewDate(String newDate) {
        this.newDate = newDate;
    }

    public String getNewTimeSlot() {
        return newTimeSlot;
    }

    public void setNewTimeSlot(String newTimeSlot) {
        this.newTimeSlot = newTimeSlot;
    }
}