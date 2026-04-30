package org.example.mockcoordinateservice;

import javax.jws.WebService;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@WebService(endpointInterface = "org.example.mockcoordinateservice.CoordinateService",
serviceName = "CoordinateService",
portName = "CoordinateServicePort"
        )
public class CoordinateServiceImpl implements CoordinateService {
    @Override
    public String sayHello(String name) {
        return "Hello, " + name + "!";
    }

@Override
    public String sendCoordinates(String upperLeftLong, String upperLeftLat, String lowerRightLong, String lowerRightLat)
    {
        return Base64.getEncoder().encodeToString(
                generatePngForBounds(Double.parseDouble(upperLeftLat),
                                    Double.parseDouble(upperLeftLong),
                                    Double.parseDouble(lowerRightLat),
                                    Double.parseDouble(lowerRightLong),
                                    1000,1000));
    }

    private byte[] loadResourceBytes(String classpathResource) {
        try (InputStream is = getClass().getResourceAsStream(classpathResource)) {
            if (is == null) return new byte[0];
            return is.readAllBytes();
        } catch (IOException e) {
            throw new RuntimeException("Cannot read resource: " + classpathResource, e);
        }
    }

    private static final String BASE =
            "https://mapy.geoportal.gov.pl/wss/service/PZGIK/ORTO/WMS/StandardResolution";

    private static volatile String CACHED_LAYER = null;
    private static volatile long CACHED_LAYER_TS = 0L;
    private static final long LAYER_TTL_MS = 24L * 60L * 60L * 1000L;

    public byte[] generatePngForBounds(
            double minLat, double minLon,
            double maxLat, double maxLon,
            int widthPx, int heightPx
    )
    {
        HttpURLConnection conn = null;

        try {
            double aMinLat = Math.min(minLat, maxLat);
            double aMaxLat = Math.max(minLat, maxLat);
            double aMinLon = Math.min(minLon, maxLon);
            double aMaxLon = Math.max(minLon, maxLon);

            if (!isValidLatLon(aMinLat, aMinLon) || !isValidLatLon(aMaxLat, aMaxLon)) {
                System.out.println("INVALID COORDS: minLat=" + aMinLat + ", minLon=" + aMinLon
                        + ", maxLat=" + aMaxLat + ", maxLon=" + aMaxLon);
                return new byte[0];
            }

            String layer = resolveLayerFromCapabilitiesCached();
            if (layer == null || layer.isBlank()) {
                System.out.println("NO LAYER RESOLVED - cannot render.");
                return new byte[0];
            }

            String wmsUrl = BASE
                    + "?SERVICE=WMS"
                    + "&VERSION=1.1.1"
                    + "&REQUEST=GetMap"
                    + "&LAYERS=" + URLEncoder.encode(layer, StandardCharsets.UTF_8)
                    + "&STYLES="
                    + "&FORMAT=image/png"
                    + "&TRANSPARENT=true"
                    + "&SRS=EPSG:4326"
                    + "&BBOX=" + aMinLon + "," + aMinLat + "," + aMaxLon + "," + aMaxLat
                    + "&WIDTH=" + widthPx
                    + "&HEIGHT=" + heightPx;

            System.out.println("WMS REQUEST:");
            System.out.println(wmsUrl);

            conn = (HttpURLConnection) new URL(wmsUrl).openConnection();
            conn.setInstanceFollowRedirects(true);
            conn.setRequestMethod("GET");
            conn.setConnectTimeout(7000);
            conn.setReadTimeout(20000);
            conn.setRequestProperty("Accept", "image/png,*/*");
            conn.setRequestProperty("User-Agent", "Mozilla/5.0");

            int httpCode = conn.getResponseCode();
            String contentType = conn.getContentType();

            System.out.println("HTTP CODE: " + httpCode);
            System.out.println("CONTENT TYPE: " + contentType);

            InputStream is = (httpCode >= 200 && httpCode < 300)
                    ? conn.getInputStream()
                    : conn.getErrorStream();

            byte[] body = readAllBytes(is);

            boolean xmlError =
                    (contentType != null && contentType.toLowerCase().contains("xml")) ||
                            (body.length > 0 && body[0] == '<');

            if (httpCode < 200 || httpCode >= 300 || xmlError)
            {
                System.out.println("WMS ERROR RESPONSE:");
                System.out.println(new String(body, StandardCharsets.UTF_8));

                if (new String(body, StandardCharsets.UTF_8).contains("LayerNotDefined"))
                {
                    System.out.println("LayerNotDefined -> clearing cached layer.");
                    clearLayerCache();
                }
                return new byte[0];
            }

            System.out.println("WMS OK, image size = " + body.length + " bytes");
            return body;

        } catch (Exception e) {
            System.out.println("WMS RENDER FAILED (EXCEPTION)");
            e.printStackTrace();
            return new byte[0];

        } finally {
            if (conn != null) conn.disconnect();
        }
    }

    private static String resolveLayerFromCapabilitiesCached() {
        long now = System.currentTimeMillis();
        String cached = CACHED_LAYER;

        if (cached != null && !cached.isBlank() && (now - CACHED_LAYER_TS) < LAYER_TTL_MS) {
            return cached;
        }

        String resolved = resolveLayerFromCapabilities();

        if (resolved == null || resolved.isBlank()) {
            resolved = "Raster";
            System.out.println("Capabilities failed -> using fallback layer: Raster");
        }

        CACHED_LAYER = resolved;
        CACHED_LAYER_TS = now;
        return resolved;
    }

    private static void clearLayerCache() {
        CACHED_LAYER = null;
        CACHED_LAYER_TS = 0L;
    }

    private static String resolveLayerFromCapabilities() {
        HttpURLConnection conn = null;
        try {
            String capUrl = BASE
                    + "?SERVICE=WMS"
                    + "&VERSION=1.1.1"
                    + "&REQUEST=GetCapabilities";

            System.out.println("CAPABILITIES REQUEST:");
            System.out.println(capUrl);

            conn = (HttpURLConnection) new URL(capUrl).openConnection();
            conn.setInstanceFollowRedirects(true);
            conn.setRequestMethod("GET");
            conn.setConnectTimeout(7000);
            conn.setReadTimeout(20000);
            conn.setRequestProperty("User-Agent", "Mozilla/5.0");

            int httpCode = conn.getResponseCode();
            System.out.println("CAP HTTP CODE: " + httpCode);

            InputStream is = (httpCode >= 200 && httpCode < 300)
                    ? conn.getInputStream()
                    : conn.getErrorStream();

            byte[] body = readAllBytes(is);
            String xml = new String(body, StandardCharsets.UTF_8);

            if (httpCode < 200 || httpCode >= 300) {
                System.out.println("CAPABILITIES ERROR:");
                System.out.println(xml);
                return null;
            }

            Pattern p = Pattern.compile("<Name>([^<]+)</Name>");
            Matcher m = p.matcher(xml);

            while (m.find()) {
                String name = m.group(1).trim();
                if (name.equalsIgnoreCase("Raster")) {
                    System.out.println("WMS layer resolved (exact): " + name);
                    return name;
                }
            }

            m.reset();
            while (m.find()) {
                String name = m.group(1).trim();
                if (isAcceptableGenericLayer(name)) {
                    System.out.println("WMS layer resolved (fallback-from-XML): " + name);
                    return name;
                }
            }

            System.out.println("No usable layer found in capabilities.");
            return null;

        } catch (Exception e) {
            System.out.println("Failed to resolve WMS layer from capabilities (exception)");
            e.printStackTrace();
            return null;
        } finally {
            if (conn != null) conn.disconnect();
        }
    }

    private static boolean isAcceptableGenericLayer(String name) {
        String n = name.toLowerCase();
        if (n.contains("group")) return false;
        if (n.contains("legend")) return false;
        if (n.contains("query")) return false;
        if (n.equals("wms") || n.equals("default")) return false;
        return name.length() >= 2;
    }

    private static boolean isValidLatLon(double lat, double lon) {
        return lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180;
    }

    private static byte[] readAllBytes(InputStream in) throws IOException {
        if (in == null) return new byte[0];
        try (ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            byte[] buf = new byte[8192];
            int r;
            while ((r = in.read(buf)) != -1) {
                out.write(buf, 0, r);
            }
            return out.toByteArray();
        }
    }
}
