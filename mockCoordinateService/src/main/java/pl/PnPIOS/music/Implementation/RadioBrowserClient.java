package pl.PnPIOS.music.Implementation;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import pl.PnPIOS.music.DTO.RadioStationResponse;
import pl.PnPIOS.music.DTO.RadioStreamResponse;
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
import java.util.List;
import java.util.Locale;

public class RadioBrowserClient {

    private static final List<String> BASE_URLS = List.of(
            "https://de1.api.radio-browser.info/json",
            "https://nl1.api.radio-browser.info/json"
    );

    private final HttpClient httpClient = HttpClient.newBuilder()
            .followRedirects(HttpClient.Redirect.NORMAL)
            .connectTimeout(Duration.ofSeconds(5))
            .build();

    private final ObjectMapper objectMapper = new ObjectMapper();

    /*
        String pathAndQuery = "/url/" + encodePathSegment(stationUuid);
        JsonNode node = getJsonNodeFromAnyServer(pathAndQuery);
     */
    private JsonNode getJsonNodeFromAnyServer(String pathAndQuery) {
        RuntimeException lastException = null;

        for (String baseUrl : BASE_URLS) {
            String fullUrl = baseUrl + pathAndQuery;

            try {
                return getJsonNode(fullUrl);
            } catch (RuntimeException e) {
                lastException = e;
            }
        }

        throw new RuntimeException(
                "Cannot call Radio Browser API on any configured server",
                lastException
        );
    }

    private String encodePathSegment(String value) {
        if (value == null) {
            return "";
        }

        return URLEncoder
                .encode(value, StandardCharsets.UTF_8)
                .replace("+", "%20");
    }

    public ServicePingResponse ping() {
        ServicePingResponse result = new ServicePingResponse();

        result.setServiceName("MusicService");
        result.setExternalServiceName("Radio Browser");
        result.setCheckedAt(java.time.OffsetDateTime.now().toString());

        long totalStart = System.currentTimeMillis();

        Exception lastException = null;

        for (String baseUrl : BASE_URLS) {
            String url = baseUrl + "/stats";

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
                JsonNode json = objectMapper.readTree(body);

                boolean ok = response.statusCode() >= 200
                        && response.statusCode() < 300
                        && json.isObject();

                if (ok) {
                    result.setOk(true);
                    result.setCheckedUrl(url);
                    result.setHttpStatusCode(response.statusCode());
                    result.setResponseTimeMs(elapsed);
                    result.setMessage("Radio Browser is available on server: " + baseUrl);
                    return result;
                }

                lastException = new RuntimeException(
                        "Invalid Radio Browser response from " + url
                                + ", HTTP status: " + response.statusCode()
                );

            } catch (Exception e) {
                lastException = e;
            }
        }

        result.setOk(false);
        result.setCheckedUrl("Tried all configured Radio Browser servers.");
        result.setHttpStatusCode(-1);
        result.setResponseTimeMs(System.currentTimeMillis() - totalStart);

        if (lastException != null) {
            result.setMessage("Radio Browser ping failed on all servers: " + lastException.getMessage());
        } else {
            result.setMessage("Radio Browser ping failed on all servers.");
        }

        return result;
    }

    public List<RadioStationResponse> searchStationsByName(String name) {
        if (name == null || name.isBlank()) {
            return new ArrayList<>();
        }

        String pathAndQuery = "/stations/byname/"
                + encodePathSegment(name.trim())
                + "?hidebroken=true&limit=20&order=name";

        JsonNode arrayNode = getJsonNodeFromAnyServer(pathAndQuery);

        List<RadioStationResponse> stations = new ArrayList<>();

        if (arrayNode != null && arrayNode.isArray()) {
            for (JsonNode stationNode : arrayNode) {
                stations.add(mapToStationResponse(stationNode));
            }
        }

        return stations;
    }

    public RadioStreamResponse getStationStreamUrl(String stationUuid) {
        String pathAndQuery = "/url/" + encodePathSegment(stationUuid);

        JsonNode node = getJsonNodeFromAnyServer(pathAndQuery);

        String returnedUrl = readText(node, "url", null);
        boolean radioBrowserOk = node != null && node.path("ok").asBoolean(false);

        StreamInfo streamInfo = inspectStream(returnedUrl);

        RadioStreamResponse response = new RadioStreamResponse();

        response.setStationUuid(readText(node, "stationuuid", stationUuid));
        response.setStationName(readText(node, "name", null));

        response.setOriginalUrl(returnedUrl);
        response.setStreamUrl(returnedUrl);

        response.setOk(radioBrowserOk);
        response.setPlayable(radioBrowserOk && streamInfo.isPlayable());
        response.setLiveStream(streamInfo.isLiveStream());

        response.setStreamType(streamInfo.getStreamType());
        response.setContentType(streamInfo.getContentType());
        response.setContentLengthBytes(streamInfo.getContentLengthBytes());

        String radioBrowserMessage = readText(node, "message", null);

        if (radioBrowserMessage != null && !radioBrowserMessage.isBlank()) {
            response.setMessage(radioBrowserMessage + " | " + streamInfo.getMessage());
        } else {
            response.setMessage(streamInfo.getMessage());
        }

        return response;
    }

    public List<RadioStationResponse> getStationsInMapBounds(
            double minLat,
            double minLon,
            double maxLat,
            double maxLon,
            int limit
    ) {
        double south = Math.min(minLat, maxLat);
        double north = Math.max(minLat, maxLat);
        double west = Math.min(minLon, maxLon);
        double east = Math.max(minLon, maxLon);

        double centerLat = (south + north) / 2.0;
        double centerLon = (west + east) / 2.0;

        double radiusMeters = calculateMaxDistanceToCorners(
                centerLat,
                centerLon,
                south,
                west,
                north,
                east
        );

        int safeLimit = normalizeLimit(limit);
        int candidateLimit = Math.min(safeLimit * 3, 500);

        String pathAndQuery = String.format(
                Locale.US,
                "/stations/search?geo_lat=%.6f&geo_long=%.6f&geo_distance=%.0f&has_geo_info=true&hidebroken=true&limit=%d&order=name",
                centerLat,
                centerLon,
                radiusMeters,
                candidateLimit
        );

        JsonNode arrayNode = getJsonNodeFromAnyServer(pathAndQuery);

        List<RadioStationResponse> stations = new ArrayList<>();

        if (arrayNode != null && arrayNode.isArray()) {
            for (JsonNode stationNode : arrayNode) {
                Double geoLat = readDoubleOrNull(stationNode, "geo_lat");
                Double geoLon = readDoubleOrNull(stationNode, "geo_long");

                if (geoLat == null || geoLon == null) {
                    continue;
                }

                if (isInsideBounds(geoLat, geoLon, south, west, north, east)) {
                    stations.add(mapToStationResponse(stationNode));
                }

                if (stations.size() >= safeLimit) {
                    break;
                }
            }
        }

        return stations;
    }

    private RadioStationResponse mapToStationResponse(JsonNode node) {
        RadioStationResponse response = new RadioStationResponse();

        response.setStationUuid(readText(node, "stationuuid", null));
        response.setName(readText(node, "name", null));
        response.setCountry(readText(node, "country", null));
        response.setCountryCode(readText(node, "countrycode", null));
        response.setCodec(readText(node, "codec", null));
        response.setBitrate(readInt(node, "bitrate", 0));
        response.setFavicon(readText(node, "favicon", null));
        response.setHomepage(readText(node, "homepage", null));

        response.setHls(readInt(node, "hls", 0) == 1);
        response.setLastCheckOk(readInt(node, "lastcheckok", 0) == 1);

        response.setGeoLat(readDoubleOrNull(node, "geo_lat"));
        response.setGeoLon(readDoubleOrNull(node, "geo_long"));

        return response;
    }

    private StreamInfo inspectStream(String streamUrl) {
        StreamInfo info = new StreamInfo();

        if (streamUrl == null || streamUrl.isBlank()) {
            info.setStreamType("UNKNOWN");
            info.setPlayable(false);
            info.setLiveStream(false);
            info.setMessage("Empty stream URL");
            return info;
        }

        String urlBasedType = classifyByUrl(streamUrl);

        info.setStreamType(urlBasedType);
        info.setPlayable(isPlayableType(urlBasedType));
        info.setLiveStream(isLiveType(urlBasedType));
        info.setMessage("Classified by URL");

        try {
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(streamUrl))
                    .method("HEAD", HttpRequest.BodyPublishers.noBody())
                    .timeout(Duration.ofSeconds(5))
                    .header("User-Agent", "PnPiOS-Platform-Service/1.0")
                    .build();

            HttpResponse<Void> response = httpClient.send(
                    request,
                    HttpResponse.BodyHandlers.discarding()
            );

            String contentType = response.headers()
                    .firstValue("Content-Type")
                    .orElse(null);

            long contentLength = parseContentLength(
                    response.headers()
                            .firstValue("Content-Length")
                            .orElse(null)
            );

            boolean hasIcyHeaders = response.headers()
                    .map()
                    .keySet()
                    .stream()
                    .anyMatch(header -> header.toLowerCase(Locale.ROOT).startsWith("icy"));

            String transferEncoding = response.headers()
                    .firstValue("Transfer-Encoding")
                    .orElse("");

            String headerBasedType = classifyByHeadersAndUrl(
                    streamUrl,
                    contentType,
                    contentLength,
                    hasIcyHeaders,
                    transferEncoding
            );

            info.setStreamType(headerBasedType);
            info.setContentType(contentType);
            info.setContentLengthBytes(contentLength);
            info.setPlayable(isPlayableType(headerBasedType));
            info.setLiveStream(isLiveType(headerBasedType));
            info.setMessage("Classified by HTTP headers");

            return info;

        } catch (Exception e) {
            /*
             * Część serwerów radiowych nie obsługuje HEAD albo odpowiada nietypowo.
             * Wtedy zostawiamy klasyfikację po samym URL-u.
             */
            info.setMessage("Could not inspect headers, classified by URL only");
            return info;
        }
    }

    private String classifyByUrl(String streamUrl) {
        String cleanUrl = streamUrl.toLowerCase(Locale.ROOT);

        int queryIndex = cleanUrl.indexOf('?');
        if (queryIndex >= 0) {
            cleanUrl = cleanUrl.substring(0, queryIndex);
        }

        if (cleanUrl.endsWith(".m3u8")) {
            return "HLS";
        }

        if (cleanUrl.endsWith(".pls") || cleanUrl.endsWith(".m3u")) {
            return "PLAYLIST";
        }

        if (cleanUrl.endsWith(".mp3")
                || cleanUrl.endsWith(".aac")
                || cleanUrl.endsWith(".aacp")
                || cleanUrl.endsWith(".ogg")
                || cleanUrl.endsWith(".opus")) {
            return "AUDIO_FILE";
        }

        return "UNKNOWN";
    }

    private String classifyByHeadersAndUrl(
            String streamUrl,
            String contentType,
            long contentLength,
            boolean hasIcyHeaders,
            String transferEncoding
    ) {
        String urlType = classifyByUrl(streamUrl);

        String lowerContentType = contentType == null
                ? ""
                : contentType.toLowerCase(Locale.ROOT);

        String lowerTransferEncoding = transferEncoding == null
                ? ""
                : transferEncoding.toLowerCase(Locale.ROOT);

        if (urlType.equals("HLS")
                || lowerContentType.contains("application/vnd.apple.mpegurl")
                || lowerContentType.contains("application/x-mpegurl")
                || lowerContentType.contains("audio/x-mpegurl")) {
            return "HLS";
        }

        if (urlType.equals("PLAYLIST")) {
            return "PLAYLIST";
        }

        if (lowerContentType.startsWith("audio/")
                || lowerContentType.contains("audio/mpeg")
                || lowerContentType.contains("audio/aac")
                || lowerContentType.contains("audio/aacp")
                || lowerContentType.contains("audio/ogg")
                || lowerContentType.contains("audio/opus")) {

            /*
             * ICY headers / chunked / brak Content-Length często oznacza stream live.
             */
            if (hasIcyHeaders || lowerTransferEncoding.contains("chunked") || contentLength <= 0) {
                return "LIVE_STREAM";
            }

            return "AUDIO_FILE";
        }

        if (lowerContentType.contains("text/html")) {
            return "UNKNOWN";
        }

        return urlType;
    }

    private boolean isPlayableType(String streamType) {
        return "LIVE_STREAM".equals(streamType)
                || "HLS".equals(streamType)
                || "AUDIO_FILE".equals(streamType);
    }

    private boolean isLiveType(String streamType) {
        return "LIVE_STREAM".equals(streamType)
                || "HLS".equals(streamType);
    }

    private boolean isInsideBounds(
            double geoLat,
            double geoLon,
            double south,
            double west,
            double north,
            double east
    ) {
        return geoLat >= south
                && geoLat <= north
                && geoLon >= west
                && geoLon <= east;
    }

    private int normalizeLimit(int limit) {
        if (limit <= 0) {
            return 100;
        }

        return Math.min(limit, 500);
    }

    private double calculateMaxDistanceToCorners(
            double centerLat,
            double centerLon,
            double south,
            double west,
            double north,
            double east
    ) {
        double d1 = haversineMeters(centerLat, centerLon, south, west);
        double d2 = haversineMeters(centerLat, centerLon, south, east);
        double d3 = haversineMeters(centerLat, centerLon, north, west);
        double d4 = haversineMeters(centerLat, centerLon, north, east);

        return Math.max(Math.max(d1, d2), Math.max(d3, d4));
    }

    private double haversineMeters(
            double lat1,
            double lon1,
            double lat2,
            double lon2
    ) {
        final double earthRadiusMeters = 6371000.0;

        double lat1Rad = Math.toRadians(lat1);
        double lat2Rad = Math.toRadians(lat2);
        double deltaLat = Math.toRadians(lat2 - lat1);
        double deltaLon = Math.toRadians(lon2 - lon1);

        double a = Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2)
                + Math.cos(lat1Rad) * Math.cos(lat2Rad)
                * Math.sin(deltaLon / 2) * Math.sin(deltaLon / 2);

        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

        return earthRadiusMeters * c;
    }

    private JsonNode getJsonNode(String url) {
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

            validateResponse(response, url);

            return objectMapper.readTree(response.body());

        } catch (IOException e) {
            throw new RuntimeException("Cannot call Radio Browser API: " + url, e);

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new RuntimeException("Radio Browser request interrupted: " + url, e);
        }
    }

    private void validateResponse(HttpResponse<String> response, String url) {
        if (response.statusCode() < 200 || response.statusCode() >= 300) {
            throw new RuntimeException(
                    "Radio Browser returned HTTP status "
                            + response.statusCode()
                            + " for URL: "
                            + url
            );
        }
    }

    private String encode(String value) {
        if (value == null) {
            return "";
        }

        return URLEncoder.encode(value, StandardCharsets.UTF_8);
    }

    private String readText(JsonNode node, String fieldName, String defaultValue) {
        if (node == null || node.get(fieldName) == null || node.get(fieldName).isNull()) {
            return defaultValue;
        }

        String value = node.get(fieldName).asText();

        if (value == null || value.isBlank()) {
            return defaultValue;
        }

        return value;
    }

    private int readInt(JsonNode node, String fieldName, int defaultValue) {
        if (node == null || node.get(fieldName) == null || node.get(fieldName).isNull()) {
            return defaultValue;
        }

        return node.get(fieldName).asInt(defaultValue);
    }

    private Double readDoubleOrNull(JsonNode node, String fieldName) {
        if (node == null || node.get(fieldName) == null || node.get(fieldName).isNull()) {
            return null;
        }

        return node.get(fieldName).asDouble();
    }

    private long parseContentLength(String value) {
        if (value == null || value.isBlank()) {
            return -1;
        }

        try {
            return Long.parseLong(value);
        } catch (NumberFormatException e) {
            return -1;
        }
    }
}