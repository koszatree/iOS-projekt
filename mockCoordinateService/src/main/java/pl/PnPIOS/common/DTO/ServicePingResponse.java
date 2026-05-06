package pl.PnPIOS.common.DTO;

public class ServicePingResponse {

    private boolean ok;
    private String serviceName;
    private String externalServiceName;
    private String checkedUrl;
    private int httpStatusCode;
    private long responseTimeMs;
    private String checkedAt;
    private String message;

    public ServicePingResponse() {
        this.httpStatusCode = -1;
        this.responseTimeMs = -1;
    }

    public boolean isOk() {
        return ok;
    }

    public void setOk(boolean ok) {
        this.ok = ok;
    }

    public String getServiceName() {
        return serviceName;
    }

    public void setServiceName(String serviceName) {
        this.serviceName = serviceName;
    }

    public String getExternalServiceName() {
        return externalServiceName;
    }

    public void setExternalServiceName(String externalServiceName) {
        this.externalServiceName = externalServiceName;
    }

    public String getCheckedUrl() {
        return checkedUrl;
    }

    public void setCheckedUrl(String checkedUrl) {
        this.checkedUrl = checkedUrl;
    }

    public int getHttpStatusCode() {
        return httpStatusCode;
    }

    public void setHttpStatusCode(int httpStatusCode) {
        this.httpStatusCode = httpStatusCode;
    }

    public long getResponseTimeMs() {
        return responseTimeMs;
    }

    public void setResponseTimeMs(long responseTimeMs) {
        this.responseTimeMs = responseTimeMs;
    }

    public String getCheckedAt() {
        return checkedAt;
    }

    public void setCheckedAt(String checkedAt) {
        this.checkedAt = checkedAt;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }
}