package pl.PnPIOS.weather.DTO;

import java.util.ArrayList;
import java.util.List;

public class HourlyTemperatureResponse {

    private double latitude;
    private double longitude;
    private String timezone;
    private String unit;
    private String date;
    private List<HourlyTemperaturePoint> hours = new ArrayList<>();

    public HourlyTemperatureResponse() {
    }

    public HourlyTemperatureResponse(
            double latitude,
            double longitude,
            String timezone,
            String unit,
            String date,
            List<HourlyTemperaturePoint> hours
    ) {
        this.latitude = latitude;
        this.longitude = longitude;
        this.timezone = timezone;
        this.unit = unit;
        this.date = date;
        this.hours = hours;
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


    public String getDate() {
        return date;
    }

    public void setDate(String date) {
        this.date = date;
    }


    public List<HourlyTemperaturePoint> getHours() {
        return hours;
    }

    public void setHours(List<HourlyTemperaturePoint> hours) {
        this.hours = hours;
    }

    public void addHour(HourlyTemperaturePoint hour) {
        this.hours.add(hour);
    }
}