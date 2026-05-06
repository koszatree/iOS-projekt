package pl.PnPIOS.weather.Implementation;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

@JsonIgnoreProperties(ignoreUnknown = true)
public class OpenMeteoDailyUnits {

    private String time;

    @JsonProperty("temperature_2m_mean")
    private String temperature2mMean;

    public OpenMeteoDailyUnits() {
    }

    public String getTime() {
        return time;
    }

    public void setTime(String time) {
        this.time = time;
    }


    public String getTemperature2mMean() {
        return temperature2mMean;
    }

    public void setTemperature2mMean(String temperature2mMean) {
        this.temperature2mMean = temperature2mMean;
    }
}
