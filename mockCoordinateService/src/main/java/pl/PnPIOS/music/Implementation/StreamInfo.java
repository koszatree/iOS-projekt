package pl.PnPIOS.music.Implementation;

public class StreamInfo {

    private String streamType;
    private String contentType;
    private long contentLengthBytes;
    private boolean playable;
    private boolean liveStream;
    private String message;

    public StreamInfo() {
        this.streamType = "UNKNOWN";
        this.contentType = null;
        this.contentLengthBytes = -1;
        this.playable = false;
        this.liveStream = false;
        this.message = "Unknown stream type";
    }

    public StreamInfo(
            String streamType,
            String contentType,
            long contentLengthBytes,
            boolean playable,
            boolean liveStream,
            String message
    ) {
        this.streamType = streamType;
        this.contentType = contentType;
        this.contentLengthBytes = contentLengthBytes;
        this.playable = playable;
        this.liveStream = liveStream;
        this.message = message;
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

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }
}