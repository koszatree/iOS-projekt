package pl.PnPIOS.music.DTO;

public class RadioStreamResponse {

    private String stationUuid;
    private String stationName;

    private String streamUrl;
    private String originalUrl;

    private boolean ok;
    private boolean playable;
    private boolean liveStream;

    private String streamType;
    private String contentType;
    private long contentLengthBytes;

    private String message;

    public RadioStreamResponse() {
        this.contentLengthBytes = -1;
        this.streamType = "UNKNOWN";
        this.playable = false;
        this.liveStream = false;
    }

    public String getStationUuid() {
        return stationUuid;
    }

    public void setStationUuid(String stationUuid) {
        this.stationUuid = stationUuid;
    }

    public String getStationName() {
        return stationName;
    }

    public void setStationName(String stationName) {
        this.stationName = stationName;
    }

    public String getStreamUrl() {
        return streamUrl;
    }

    public void setStreamUrl(String streamUrl) {
        this.streamUrl = streamUrl;
    }

    public String getOriginalUrl() {
        return originalUrl;
    }

    public void setOriginalUrl(String originalUrl) {
        this.originalUrl = originalUrl;
    }

    public boolean isOk() {
        return ok;
    }

    public void setOk(boolean ok) {
        this.ok = ok;
    }

    public boolean isPlayable() {
        return playable;
    }

    public void setPlayable(boolean playable) {
        this.playable = playable;
    }

    public boolean isLiveStream() {
        return liveStream;
    }

    public void setLiveStream(boolean liveStream) {
        this.liveStream = liveStream;
    }

    public String getStreamType() {
        return streamType;
    }

    public void setStreamType(String streamType) {
        this.streamType = streamType;
    }

    public String getContentType() {
        return contentType;
    }

    public void setContentType(String contentType) {
        this.contentType = contentType;
    }

    public long getContentLengthBytes() {
        return contentLengthBytes;
    }

    public void setContentLengthBytes(long contentLengthBytes) {
        this.contentLengthBytes = contentLengthBytes;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }
}