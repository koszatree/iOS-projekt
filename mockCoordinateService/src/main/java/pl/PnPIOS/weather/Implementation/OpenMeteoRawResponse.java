package pl.PnPIOS.weather.Implementation;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

@JsonIgnoreProperties(ignoreUnknown = true)
public class OpenMeteoRawResponse {

    private double latitude;
    private double longitude;
    private double elevation;
    private String timezone;

    @JsonProperty("hourly_units")
    private OpenMeteoHourlyUnits hourlyUnits;

    private OpenMeteoHourlyRawData hourly;

    @JsonProperty("daily_units")
    private OpenMeteoDailyUnits dailyUnits;

    private OpenMeteoDailyRawData daily;

    public OpenMeteoRawResponse() {
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

    public double getElevation() {
        return elevation;
    }

    public void setElevation(double elevation) {
        this.elevation = elevation;
    }

    public String getTimezone() {
        return timezone;
    }

    public void setTimezone(String timezone) {
        this.timezone = timezone;
    }

    public OpenMeteoHourlyUnits getHourlyUnits() {
        return hourlyUnits;
    }

    public void setHourlyUnits(OpenMeteoHourlyUnits hourlyUnits) {
        this.hourlyUnits = hourlyUnits;
    }

    public OpenMeteoHourlyRawData getHourly() {
        return hourly;
    }

    public void setHourly(OpenMeteoHourlyRawData hourly) {
        this.hourly = hourly;
    }

    public OpenMeteoDailyUnits getDailyUnits() {
        return dailyUnits;
    }

    public void setDailyUnits(OpenMeteoDailyUnits dailyUnits) {
        this.dailyUnits = dailyUnits;
    }

    public OpenMeteoDailyRawData getDaily() {
        return daily;
    }

    public void setDaily(OpenMeteoDailyRawData daily) {
        this.daily = daily;
    }
}