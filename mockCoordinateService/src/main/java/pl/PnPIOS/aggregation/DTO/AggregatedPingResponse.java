package pl.PnPIOS.aggregation.DTO;

import pl.PnPIOS.common.DTO.ServicePingResponse;

public class AggregatedPingResponse {

    private boolean ok;
    private String message;
    private String checkedAt;
    private long responseTimeMs;

    private ServicePingResponse coordinateService;
    private ServicePingResponse musicService;
    private ServicePingResponse weatherService;

    public AggregatedPingResponse() {
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

    public String getCheckedAt() {
        return checkedAt;
    }

    public void setCheckedAt(String checkedAt) {
        this.checkedAt = checkedAt;
    }

    public long getResponseTimeMs() {
        return responseTimeMs;
    }

    public void setResponseTimeMs(long responseTimeMs) {
        this.responseTimeMs = responseTimeMs;
    }

    public ServicePingResponse getCoordinateService() {
        return coordinateService;
    }

    public void setCoordinateService(ServicePingResponse coordinateService) {
        this.coordinateService = coordinateService;
    }

    public ServicePingResponse getMusicService() {
        return musicService;
    }

    public void setMusicService(ServicePingResponse musicService) {
        this.musicService = musicService;
    }

    public ServicePingResponse getWeatherService() {
        return weatherService;
    }

    public void setWeatherService(ServicePingResponse weatherService) {
        this.weatherService = weatherService;
    }
}