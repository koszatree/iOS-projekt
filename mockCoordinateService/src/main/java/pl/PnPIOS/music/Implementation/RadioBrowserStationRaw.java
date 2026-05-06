package pl.PnPIOS.music.Implementation;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

@JsonIgnoreProperties(ignoreUnknown = true)
public class RadioBrowserStationRaw {

    @JsonProperty("stationuuid")
    private String stationUuid;

    private String name;
    private String country;

    @JsonProperty("countrycode")
    private String countryCode;

    private String codec;
    private int bitrate;
    private String favicon;
    private String homepage;

    private int hls;

    @JsonProperty("lastcheckok")
    private int lastCheckOk;

    @JsonProperty("geo_lat")
    private Double geoLat;

    @JsonProperty("geo_long")
    private Double geoLon;

    public RadioBrowserStationRaw() {
    }

    public String getStationUuid() {
        return stationUuid;
    }

    public void setStationUuid(String stationUuid) {
        this.stationUuid = stationUuid;
    }

    public String getName() {
        return name;
    }

    public String getCountry() {
        return country;
    }

    public String getCountryCode() {
        return countryCode;
    }

    public String getCodec() {
        return codec;
    }

    public int getBitrate() {
        return bitrate;
    }

    public String getFavicon() {
        return favicon;
    }

    public String getHomepage() {
        return homepage;
    }

    public int getHls() {
        return hls;
    }

    public int getLastCheckOk() {
        return lastCheckOk;
    }

    public Double getGeoLat() {
        return geoLat;
    }

    public Double getGeoLon() {
        return geoLon;
    }
}