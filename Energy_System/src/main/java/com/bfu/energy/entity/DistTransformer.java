package com.bfu.energy.entity;

import java.io.Serializable;

public class DistTransformer implements Serializable {
    private Long transformerId;
    private String transformerName;
    private Long roomId;
    private Long ledgerId;

    public DistTransformer() {
    }

    public Long getTransformerId() {
        return transformerId;
    }

    public void setTransformerId(Long transformerId) {
        this.transformerId = transformerId;
    }

    public String getTransformerName() {
        return transformerName;
    }

    public void setTransformerName(String transformerName) {
        this.transformerName = transformerName;
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
        return "DistTransformer{" +
                "transformerId=" + transformerId +
                ", transformerName='" + transformerName + '\'' +
                ", roomId=" + roomId +
                ", ledgerId=" + ledgerId +
                '}';
    }
}
