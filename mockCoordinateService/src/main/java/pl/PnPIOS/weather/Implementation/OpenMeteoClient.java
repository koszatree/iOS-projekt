package pl.PnPIOS.weather.Implementation;

import com.fasterxml.jackson.databind.ObjectMapper;
import pl.PnPIOS.weather.DTO.DailyTemperaturePoint;
import pl.PnPIOS.weather.DTO.DailyTemperatureResponse;
import pl.PnPIOS.weather.DTO.HourlyTemperaturePoint;
import pl.PnPIOS.weather.DTO.HourlyTemperatureResponse;
import com.fasterxml.jackson.databind.JsonNode;
import pl.PnPIOS.common.DTO.ServicePingResponse;

import java.time.Duration;
import java.time.OffsetDateTime;
import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

public class OpenMeteoClient {
    private static final String BASE_URL = "https://api.open-meteo.com/v1/forecast";
    private static final String TIMEZONE = "Europe/Warsaw";

    private final HttpClient httpClient = HttpClient.newHttpClient();
    private final ObjectMapper objectMapper = new ObjectMapper();

    public ServicePingResponse ping() {
        String url = String.format(
                Locale.US,
                "%s?latitude=54.350000&longitude=18.650000&hourly=temperature_2m&forecast_days=1&timezone=Europe%%2FWarsaw",
                BASE_URL
        );

        ServicePingResponse result = new ServicePingResponse();

        result.setServiceName("WeatherService");
        result.setExternalServiceName("Open-Meteo");
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
            JsonNode json = objectMapper.readTree(body);

            boolean ok = response.statusCode() >= 200
                    && response.statusCode() < 300
                    && json.has("hourly");

            result.setOk(ok);
            result.setHttpStatusCode(response.statusCode());
            result.setResponseTimeMs(elapsed);

            if (ok) {
                result.setMessage("Open-Meteo is available.");
            } else {
                result.setMessage("Open-Meteo responded, but response does not contain expected weather data.");
            }

            return result;

        } catch (Exception e) {
            long elapsed = System.currentTimeMillis() - start;

            result.setOk(false);
            result.setResponseTimeMs(elapsed);
            result.setMessage("Open-Meteo ping failed: " + e.getMessage());

            return result;
        }
    }

    public OpenMeteoRawResponse getTemperatureForecast(
            double latitude,
            double longitude,
            int pastDays,
            int forecastDays
    ) {
        String url = String.format(
                Locale.US,
                "%s?latitude=%.6f&longitude=%.6f&hourly=temperature_2m&past_days=%d&forecast_days=%d&timezone=%s",
                BASE_URL,
                latitude,
                longitude,
                pastDays,
                forecastDays,
                encode(TIMEZONE)
        );

        return executeRequest(url);
    }

    public DailyTemperatureResponse getDailyAverageTemperature(
            double latitude,
            double longitude,
            int forecastDays
    ) {
        validateForecastDays(forecastDays);

        String url = String.format(
                Locale.US,
                "%s?latitude=%.6f&longitude=%.6f&daily=temperature_2m_mean&forecast_days=%d&timezone=%s",
                BASE_URL,
                latitude,
                longitude,
                forecastDays,
                encode(TIMEZONE)
        );

        OpenMeteoRawResponse rawResponse = executeRequest(url);

        return mapToDailyTemperatureResponse(rawResponse);
    }

    public DailyTemperatureResponse getLongRangeDailyAverageTemperature(
            double latitude,
            double longitude,
            int forecastDays
    ) {
        if (forecastDays > 16) {
            throw new IllegalArgumentException(
                    "Standard Open-Meteo /v1/forecast supports max 16 forecast days. " +
                            "For a real monthly forecast use Ensemble or Seasonal Forecast API."
            );
        }

        return getDailyAverageTemperature(latitude, longitude, forecastDays);
    }

    public HourlyTemperatureResponse getHourlyTemperatureForDay(
            double latitude,
            double longitude,
            String date
    ) {
        validateDate(date);

        String url = String.format(
                Locale.US,
                "%s?latitude=%.6f&longitude=%.6f&hourly=temperature_2m&start_date=%s&end_date=%s&timezone=%s",
                BASE_URL,
                latitude,
                longitude,
                encode(date),
                encode(date),
                encode(TIMEZONE)
        );

        OpenMeteoRawResponse rawResponse = executeRequest(url);

        return mapToHourlyTemperatureResponse(rawResponse, date);
    }

    private OpenMeteoRawResponse executeRequest(String url) {
        try {
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(url))
                    .GET()
                    .header("User-Agent", "PnPiOS-Platform-Service/1.0")
                    .build();

            HttpResponse<String> response = httpClient.send(
                    request,
                    HttpResponse.BodyHandlers.ofString()
            );

            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                throw new RuntimeException(
                        "Open-Meteo returned HTTP status: " + response.statusCode()
                );
            }

            return objectMapper.readValue(response.body(), OpenMeteoRawResponse.class);

        } catch (IOException e) {
            throw new RuntimeException("Cannot call Open-Meteo API: " + url, e);

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new RuntimeException("Open-Meteo request was interrupted: " + url, e);
        }
    }

    private DailyTemperatureResponse mapToDailyTemperatureResponse(OpenMeteoRawResponse rawResponse) {
        DailyTemperatureResponse response = new DailyTemperatureResponse();

        response.setLatitude(rawResponse.getLatitude());
        response.setLongitude(rawResponse.getLongitude());
        response.setTimezone(rawResponse.getTimezone());

        if (rawResponse.getDailyUnits() != null) {
            response.setUnit(rawResponse.getDailyUnits().getTemperature2mMean());
        }

        if (rawResponse.getDaily() == null
                || rawResponse.getDaily().getTime() == null
                || rawResponse.getDaily().getTemperature2mMean() == null) {
            return response;
        }

        List<String> dates = rawResponse.getDaily().getTime();
        List<Double> temperatures = rawResponse.getDaily().getTemperature2mMean();

        int size = Math.min(dates.size(), temperatures.size());

        List<DailyTemperaturePoint> days = new ArrayList<>();

        for (int i = 0; i < size; i++) {
            days.add(new DailyTemperaturePoint(
                    dates.get(i),
                    temperatures.get(i)
            ));
        }

        response.setDays(days);

        return response;
    }

    private HourlyTemperatureResponse mapToHourlyTemperatureResponse(
            OpenMeteoRawResponse rawResponse,
            String date
    ) {
        HourlyTemperatureResponse response = new HourlyTemperatureResponse();

        response.setLatitude(rawResponse.getLatitude());
        response.setLongitude(rawResponse.getLongitude());
        response.setTimezone(rawResponse.getTimezone());
        response.setDate(date);

        if (rawResponse.getHourlyUnits() != null) {
            response.setUnit(rawResponse.getHourlyUnits().getTemperature2m());
        }

        if (rawResponse.getHourly() == null
                || rawResponse.getHourly().getTime() == null
                || rawResponse.getHourly().getTemperature2m() == null) {
            return response;
        }

        List<String> times = rawResponse.getHourly().getTime();
        List<Double> temperatures = rawResponse.getHourly().getTemperature2m();

        int size = Math.min(times.size(), temperatures.size());

        List<HourlyTemperaturePoint> hours = new ArrayList<>();

        for (int i = 0; i < size; i++) {
            hours.add(new HourlyTemperaturePoint(
                    times.get(i),
                    temperatures.get(i)
            ));
        }

        response.setHours(hours);

        return response;
    }

    private String encode(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8);
    }

    private void validateForecastDays(int forecastDays) {
        if (forecastDays < 1 || forecastDays > 16) {
            throw new IllegalArgumentException("forecastDays must be between 1 and 16 for /v1/forecast");
        }
    }

    private void validateDate(String date) {
        try {
            LocalDate.parse(date);
        } catch (DateTimeParseException e) {
            throw new IllegalArgumentException("Date must use format yyyy-MM-dd, for example 2026-05-10", e);
        }
    }
}