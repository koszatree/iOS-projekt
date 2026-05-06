package pl.PnPIOS.weather.DTO;

public class HourlyTemperaturePoint {

    private String time;
    private Double temperature;

    public HourlyTemperaturePoint() {
    }

    public HourlyTemperaturePoint(String time, Double temperature) {
        this.time = time;
        this.temperature = temperature;
    }

    public String getTime() {
        return time;
    }

    public void setTime(String time) {
        this.time = time;
    }


    public Double getTemperature() {
        return temperature;
    }

    public void setTemperature(Double temperature) {
        this.temperature = temperature;
    }
}