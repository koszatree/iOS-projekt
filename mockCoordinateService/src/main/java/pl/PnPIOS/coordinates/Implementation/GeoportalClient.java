package pl.PnPIOS.coordinates.Implementation;

import pl.PnPIOS.coordinates.DTO.MapTileResponse;
import pl.PnPIOS.common.DTO.ServicePingResponse;

import java.time.OffsetDateTime;
import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.Locale;

public class GeoportalClient {

    private static final String BASE_URL =
            "https://mapy.geoportal.gov.pl/wss/service/PZGIK/ORTO/WMS/StandardResolution";

    private static final String SERVICE = "WMS";
    private static final String VERSION = "1.1.1";
    private static final String REQUEST = "GetMap";
    private static final String FORMAT = "image/png";
    private static final String SRS = "EPSG:4326";

    private static final int MIN_DIMENSION = 1;
    private static final int MAX_DIMENSION = 4096;

    private static final List<String> LAYER_CANDIDATES = List.of(
            "raster",
            "Raster"
    );

    private static volatile String cachedWorkingLayer = "raster";

    private final HttpClient httpClient = HttpClient.newBuilder()
            .followRedirects(HttpClient.Redirect.NORMAL)
            .connectTimeout(Duration.ofSeconds(7))
            .build();

    public ServicePingResponse ping() {
        String url = BASE_URL
                + "?SERVICE=WMS"
                + "&VERSION=1.1.1"
                + "&REQUEST=GetCapabilities";

        ServicePingResponse result = new ServicePingResponse();

        result.setServiceName("CoordinateService");
        result.setExternalServiceName("Geoportal WMS");
        result.setCheckedUrl(url);
        result.setCheckedAt(OffsetDateTime.now().toString());

        long start = System.currentTimeMillis();

        try {
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(url))
                    .GET()
                    .timeout(Duration.ofSeconds(10))
                    .header("User-Agent", "PnPiOS-Platform-Service/1.0")
                    .build();

            HttpResponse<String> response = httpClient.send(
                    request,
                    HttpResponse.BodyHandlers.ofString()
            );

            long elapsed = System.currentTimeMillis() - start;

            String body = response.body() == null ? "" : response.body();

            boolean ok = response.statusCode() >= 200
                    && response.statusCode() < 300
                    && (body.contains("WMS")
                    || body.contains("Layer")
                    || body.contains("GetMap"));

            result.setOk(ok);
            result.setHttpStatusCode(response.statusCode());
            result.setResponseTimeMs(elapsed);

            if (ok) {
                result.setMessage("Geoportal WMS is available.");
            } else {
                result.setMessage("Geoportal WMS responded, but response does not look valid.");
            }

            return result;

        } catch (Exception e) {
            long elapsed = System.currentTimeMillis() - start;

            result.setOk(false);
            result.setResponseTimeMs(elapsed);
            result.setMessage("Geoportal WMS ping failed: " + e.getMessage());

            return result;
        }
    }

    public MapTileResponse getMapTile(
            double lon1,
            double lat1,
            double lon2,
            double lat2,
            int width,
            int height
    ) {
        double minLon = Math.min(lon1, lon2);
        double maxLon = Math.max(lon1, lon2);
        double minLat = Math.min(lat1, lat2);
        double maxLat = Math.max(lat1, lat2);

        if (!isValidLatLon(minLat, minLon) || !isValidLatLon(maxLat, maxLon)) {
            return errorResponse(
                    minLon,
                    minLat,
                    maxLon,
                    maxLat,
                    width,
                    height,
                    null,
                    "Invalid coordinates. Latitude must be between -90 and 90, longitude between -180 and 180."
            );
        }

        if (minLon == maxLon || minLat == maxLat) {
            return errorResponse(
                    minLon,
                    minLat,
                    maxLon,
                    maxLat,
                    width,
                    height,
                    null,
                    "Invalid bounding box. Area cannot have zero width or zero height."
            );
        }

        if (!isValidDimension(width) || !isValidDimension(height)) {
            return errorResponse(
                    minLon,
                    minLat,
                    maxLon,
                    maxLat,
                    width,
                    height,
                    null,
                    "Invalid image size. Width and height must be between "
                            + MIN_DIMENSION + " and " + MAX_DIMENSION + "."
            );
        }

        MapTileResponse lastError = null;

        for (String layer : getLayerAttemptOrder()) {
            MapTileResponse response = requestMapTile(
                    minLon,
                    minLat,
                    maxLon,
                    maxLat,
                    width,
                    height,
                    layer
            );

            if (response.isOk()) {
                cachedWorkingLayer = layer;
                return response;
            }

            lastError = response;
        }

        if (lastError != null) {
            return lastError;
        }

        return errorResponse(
                minLon,
                minLat,
                maxLon,
                maxLat,
                width,
                height,
                null,
                "Could not generate map image."
        );
    }

    private MapTileResponse requestMapTile(
            double minLon,
            double minLat,
            double maxLon,
            double maxLat,
            int width,
            int height,
            String layer
    ) {
        String url = buildGetMapUrl(
                minLon,
                minLat,
                maxLon,
                maxLat,
                width,
                height,
                layer
        );

        try {
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(url))
                    .GET()
                    .timeout(Duration.ofSeconds(20))
                    .header("Accept", "image/png,*/*")
                    .header("User-Agent", "PnPiOS-Platform-Service/1.0")
                    .build();

            HttpResponse<byte[]> response = httpClient.send(
                    request,
                    HttpResponse.BodyHandlers.ofByteArray()
            );

            int statusCode = response.statusCode();

            String contentType = response.headers()
                    .firstValue("Content-Type")
                    .orElse(null);

            byte[] body = response.body() == null
                    ? new byte[0]
                    : response.body();

            boolean httpOk = statusCode >= 200 && statusCode < 300;
            boolean imageResponse = isImagePng(contentType, body);
            boolean xmlError = looksLikeXml(body);

            if (!httpOk || !imageResponse || xmlError) {
                String errorMessage = "Geoportal WMS error. HTTP status: "
                        + statusCode
                        + ", contentType: "
                        + contentType
                        + ", body: "
                        + toSafeText(body);

                return errorResponse(
                        minLon,
                        minLat,
                        maxLon,
                        maxLat,
                        width,
                        height,
                        layer,
                        errorMessage
                );
            }

            MapTileResponse result = baseResponse(
                    minLon,
                    minLat,
                    maxLon,
                    maxLat,
                    width,
                    height,
                    layer
            );

            result.setOk(true);
            result.setContentType(contentType == null ? FORMAT : contentType);
            result.setImageBase64(Base64.getEncoder().encodeToString(body));
            result.setImageSizeBytes(body.length);
            result.setMessage("Geoportal WMS image generated successfully.");

            return result;

        } catch (IOException e) {
            return errorResponse(
                    minLon,
                    minLat,
                    maxLon,
                    maxLat,
                    width,
                    height,
                    layer,
                    "Geoportal WMS request failed: " + e.getMessage()
            );

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();

            return errorResponse(
                    minLon,
                    minLat,
                    maxLon,
                    maxLat,
                    width,
                    height,
                    layer,
                    "Geoportal WMS request was interrupted."
            );

        } catch (Exception e) {
            return errorResponse(
                    minLon,
                    minLat,
                    maxLon,
                    maxLat,
                    width,
                    height,
                    layer,
                    "Geoportal WMS unexpected error: " + e.getMessage()
            );
        }
    }

    private String buildGetMapUrl(
            double minLon,
            double minLat,
            double maxLon,
            double maxLat,
            int width,
            int height,
            String layer
    ) {
        String bbox = String.format(
                Locale.US,
                "%.8f,%.8f,%.8f,%.8f",
                minLon,
                minLat,
                maxLon,
                maxLat
        );

        return BASE_URL
                + "?SERVICE=" + encode(SERVICE)
                + "&VERSION=" + encode(VERSION)
                + "&REQUEST=" + encode(REQUEST)
                + "&LAYERS=" + encode(layer)
                + "&STYLES="
                + "&FORMAT=" + encode(FORMAT)
                + "&TRANSPARENT=true"
                + "&SRS=" + encode(SRS)
                + "&BBOX=" + bbox
                + "&WIDTH=" + width
                + "&HEIGHT=" + height;
    }

    private List<String> getLayerAttemptOrder() {
        List<String> layers = new ArrayList<>();

        if (cachedWorkingLayer != null && !cachedWorkingLayer.isBlank()) {
            layers.add(cachedWorkingLayer);
        }

        for (String layer : LAYER_CANDIDATES) {
            if (!layers.contains(layer)) {
                layers.add(layer);
            }
        }

        return layers;
    }

    private MapTileResponse baseResponse(
            double minLon,
            double minLat,
            double maxLon,
            double maxLat,
            int width,
            int height,
            String layer
    ) {
        MapTileResponse response = new MapTileResponse();

        response.setMinLon(minLon);
        response.setMinLat(minLat);
        response.setMaxLon(maxLon);
        response.setMaxLat(maxLat);
        response.setWidth(width);
        response.setHeight(height);
        response.setLayer(layer);
        response.setImageSizeBytes(0);

        return response;
    }

    private MapTileResponse errorResponse(
            double minLon,
            double minLat,
            double maxLon,
            double maxLat,
            int width,
            int height,
            String layer,
            String message
    ) {
        MapTileResponse response = baseResponse(
                minLon,
                minLat,
                maxLon,
                maxLat,
                width,
                height,
                layer
        );

        response.setOk(false);
        response.setContentType(null);
        response.setImageBase64(null);
        response.setImageSizeBytes(0);
        response.setMessage(message);

        return response;
    }

    private boolean isValidLatLon(double lat, double lon) {
        return lat >= -90.0
                && lat <= 90.0
                && lon >= -180.0
                && lon <= 180.0;
    }

    private boolean isValidDimension(int value) {
        return value >= MIN_DIMENSION && value <= MAX_DIMENSION;
    }

    private boolean isImagePng(String contentType, byte[] body) {
        if (contentType != null
                && contentType.toLowerCase(Locale.ROOT).contains("image/png")) {
            return true;
        }

        return hasPngSignature(body);
    }

    private boolean hasPngSignature(byte[] body) {
        return body != null
                && body.length >= 8
                && (body[0] & 0xff) == 0x89
                && body[1] == 0x50
                && body[2] == 0x4E
                && body[3] == 0x47
                && body[4] == 0x0D
                && body[5] == 0x0A
                && body[6] == 0x1A
                && body[7] == 0x0A;
    }

    private boolean looksLikeXml(byte[] body) {
        if (body == null || body.length == 0) {
            return false;
        }

        int index = 0;

        while (index < body.length && Character.isWhitespace((char) body[index])) {
            index++;
        }

        return index < body.length && body[index] == '<';
    }

    private String toSafeText(byte[] body) {
        if (body == null || body.length == 0) {
            return "";
        }

        String text = new String(body, StandardCharsets.UTF_8);

        if (text.length() > 1000) {
            return text.substring(0, 1000) + "...";
        }

        return text;
    }

    private String encode(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8);
    }
}