package com.petclinic.dto;

public class SmsCodeDto {
    private String phone;
    private String type;

    public SmsCodeDto() {
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }
}