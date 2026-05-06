package pl.PnPIOS.music.DTO;

public class RadioStationResponse {

    private String stationUuid;
    private String name;
    private String country;
    private String countryCode;
    private String codec;
    private int bitrate;
    private String favicon;
    private String homepage;
    private boolean hls;
    private boolean lastCheckOk;
    private Double geoLat;
    private Double geoLon;

    public RadioStationResponse() {
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

    public void setName(String name) {
        this.name = name;
    }


    public String getCountry() {
        return country;
    }

    public void setCountry(String country) {
        this.country = country;
    }


    public String getCountryCode() {
        return countryCode;
    }

    public void setCountryCode(String countryCode) {
        this.countryCode = countryCode;
    }


    public String getCodec() {
        return codec;
    }

    public void setCodec(String codec) {
        this.codec = codec;
    }


    public int getBitrate() {
        return bitrate;
    }

    public void setBitrate(int bitrate) {
        this.bitrate = bitrate;
    }


    public String getFavicon() {
        return favicon;
    }

    public void setFavicon(String favicon) {
        this.favicon = favicon;
    }


    public String getHomepage() {
        return homepage;
    }

    public void setHomepage(String homepage) {
        this.homepage = homepage;
    }


    public boolean isHls() {
        return hls;
    }

    public void setHls(boolean hls) {
        this.hls = hls;
    }


    public boolean isLastCheckOk() {
        return lastCheckOk;
    }

    public void setLastCheckOk(boolean lastCheckOk) {
        this.lastCheckOk = lastCheckOk;
    }


    public Double getGeoLat() {
        return geoLat;
    }

    public void setGeoLat(Double geoLat) {
        this.geoLat = geoLat;
    }


    public Double getGeoLon() {
        return geoLon;
    }

    public void setGeoLon(Double geoLon) {
        this.geoLon = geoLon;
    }
}