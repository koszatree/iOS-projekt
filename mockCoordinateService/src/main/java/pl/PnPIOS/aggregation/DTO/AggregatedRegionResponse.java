package pl.PnPIOS.aggregation.DTO;

import pl.PnPIOS.coordinates.DTO.MapTileResponse;
import pl.PnPIOS.music.DTO.RadioStationResponse;
import pl.PnPIOS.weather.DTO.DailyTemperatureResponse;

import java.util.ArrayList;
import java.util.List;

public class AggregatedRegionResponse {

    private boolean ok;
    private String message;

    private double minLat;
    private double minLon;
    private double maxLat;
    private double maxLon;

    private double centerLat;
    private double centerLon;

    private boolean weatherOk;
    private boolean musicOk;
    private boolean mapOk;

    private String weatherMessage;
    private String musicMessage;
    private String mapMessage;

    private DailyTemperatureResponse weather;
    private List<RadioStationResponse> radioStations = new ArrayList<>();
    private MapTileResponse mapTile;

    public AggregatedRegionResponse() {
    }

    public boolean isOk() {
        return ok;
    }

    public void setOk(boolean ok) {
        this.ok = ok;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public double getMinLat() {
        return minLat;
    }

    public void setMinLat(double minLat) {
        this.minLat = minLat;
    }

    public double getMinLon() {
        return minLon;
    }

    public void setMinLon(double minLon) {
        this.minLon = minLon;
    }

    public double getMaxLat() {
        return maxLat;
    }

    public void setMaxLat(double maxLat) {
        this.maxLat = maxLat;
    }

    public double getMaxLon() {
        return maxLon;
    }

    public void setMaxLon(double maxLon) {
        this.maxLon = maxLon;
    }

    public double getCenterLat() {
        return centerLat;
    }

    public void setCenterLat(double centerLat) {
        this.centerLat = centerLat;
    }

    public double getCenterLon() {
        return centerLon;
    }

    public void setCenterLon(double centerLon) {
        this.centerLon = centerLon;
    }

    public boolean isWeatherOk() {
        return weatherOk;
    }

    public void setWeatherOk(boolean weatherOk) {
        this.weatherOk = weatherOk;
    }

    public boolean isMusicOk() {
        return musicOk;
    }

    public void setMusicOk(boolean musicOk) {
        this.musicOk = musicOk;
    }

    public boolean isMapOk() {
        return mapOk;
    }

    public void setMapOk(boolean mapOk) {
        this.mapOk = mapOk;
    }

    public String getWeatherMessage() {
        return weatherMessage;
    }

    public void setWeatherMessage(String weatherMessage) {
        this.weatherMessage = weatherMessage;
    }

    public String getMusicMessage() {
        return musicMessage;
    }

    public void setMusicMessage(String musicMessage) {
        this.musicMessage = musicMessage;
    }

    public String getMapMessage() {
        return mapMessage;
    }

    public void setMapMessage(String mapMessage) {
        this.mapMessage = mapMessage;
    }

    public DailyTemperatureResponse getWeather() {
        return weather;
    }

    public void setWeather(DailyTemperatureResponse weather) {
        this.weather = weather;
    }

    public List<RadioStationResponse> getRadioStations() {
        return radioStations;
    }

    public void setRadioStations(List<RadioStationResponse> radioStations) {
        this.radioStations = radioStations;
    }

    public MapTileResponse getMapTile() {
        return mapTile;
    }

    public void setMapTile(MapTileResponse mapTile) {
        this.mapTile = mapTile;
    }
}