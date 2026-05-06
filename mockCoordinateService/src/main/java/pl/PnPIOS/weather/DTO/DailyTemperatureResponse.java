package pl.PnPIOS.weather.DTO;

import java.util.ArrayList;
import java.util.List;

public class DailyTemperatureResponse {

    private double latitude;
    private double longitude;
    private String timezone;
    private String unit;
    private List<DailyTemperaturePoint> days = new ArrayList<>();

    public DailyTemperatureResponse() {
    }

    public DailyTemperatureResponse(
            double latitude,
            double longitude,
            String timezone,
            String unit,
            List<DailyTemperaturePoint> days
    ) {
        this.latitude = latitude;
        this.longitude = longitude;
        this.timezone = timezone;
        this.unit = unit;
        this.days = days;
    }

    public double getLatitude() {
        return latitude;
    }

    public void setLatitude(double latitude) {
        this.latitude = latitude;
    }


    public double getLongitude() {
        return longitude;
    }

    public void setLongitude(double longitude) {
        this.longitude = longitude;
    }


    public String getTimezone() {
        return timezone;
    }

    public void setTimezone(String timezone) {
        this.timezone = timezone;
    }


    public String getUnit() {
        return unit;
    }

    public void setUnit(String unit) {
        this.unit = unit;
    }


    public List<DailyTemperaturePoint> getDays() {
        return days;
    }

    public void setDays(List<DailyTemperaturePoint> days) {
        this.days = days;
    }

    public void addDay(DailyTemperaturePoint day) {
        this.days.add(day);
    }
}