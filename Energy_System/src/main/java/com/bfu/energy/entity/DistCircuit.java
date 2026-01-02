package com.bfu.energy.entity;

import java.io.Serializable;

public class DistCircuit implements Serializable {
    private Long circuitId;
    private String circuitName;
    private Long roomId;
    private Long ledgerId;

    public DistCircuit() {
    }

    public Long getCircuitId() {
        return circuitId;
    }

    public void setCircuitId(Long circuitId) {
        this.circuitId = circuitId;
    }

    public String getCircuitName() {
        return circuitName;
    }

    public void setCircuitName(String circuitName) {
        this.circuitName = circuitName;
    }

    public Long getRoomId() {
        return roomId;
    }

    public void setRoomId(Long roomId) {
        this.roomId = roomId;
    }

    public Long getLedgerId() {
        return ledgerId;
    }

    public void setLedgerId(Long ledgerId) {
        this.ledgerId = ledgerId;
    }

    @Override
    public String toString() {
        return "DistCircuit{" +
                "circuitId=" + circuitId +
                ", circuitName='" + circuitName + '\'' +
                ", roomId=" + roomId +
                ", ledgerId=" + ledgerId +
                '}';
    }
}
