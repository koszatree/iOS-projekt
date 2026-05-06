package pl.PnPIOS.aggregation;

import pl.PnPIOS.aggregation.DTO.AggregatedRegionResponse;
import pl.PnPIOS.aggregation.DTO.AggregatedPingResponse;
import pl.PnPIOS.common.DTO.ServicePingResponse;
import pl.PnPIOS.coordinates.DTO.MapTileResponse;
import pl.PnPIOS.coordinates.Implementation.GeoportalClient;
import pl.PnPIOS.music.DTO.RadioStationResponse;
import pl.PnPIOS.music.Implementation.RadioBrowserClient;
import pl.PnPIOS.weather.DTO.DailyTemperatureResponse;
import pl.PnPIOS.weather.WeatherApplicationService;

import java.time.OffsetDateTime;
import javax.jws.WebService;
import java.util.ArrayList;
import java.util.List;

@WebService(
        endpointInterface = "pl.PnPIOS.aggregation.AggregationService",
        serviceName = "AggregationService",
        portName = "AggregationServicePort",
        targetNamespace = "http://aggregation.platformservice.pnpios.pl/"
)
public class AggregationServiceImpl implements AggregationService {

    private final WeatherApplicationService weatherApplicationService =
            new WeatherApplicationService();

    private final RadioBrowserClient radioBrowserClient =
            new RadioBrowserClient();

    private final GeoportalClient geoportalClient =
            new GeoportalClient();

    @Override
    public AggregatedPingResponse pingAll() {
        long start = System.currentTimeMillis();

        AggregatedPingResponse response = new AggregatedPingResponse();

        response.setCheckedAt(OffsetDateTime.now().toString());

        ServicePingResponse coordinatePing = geoportalClient.ping();
        ServicePingResponse musicPing = radioBrowserClient.ping();
        ServicePingResponse weatherPing = weatherApplicationService.ping();

        response.setCoordinateService(coordinatePing);
        response.setMusicService(musicPing);
        response.setWeatherService(weatherPing);

        boolean allOk = coordinatePing.isOk()
                && musicPing.isOk()
                && weatherPing.isOk();

        response.setOk(allOk);
        response.setResponseTimeMs(System.currentTimeMillis() - start);

        if (allOk) {
            response.setMessage("All services are available.");
        } else {
            response.setMessage("One or more services are unavailable.");
        }

        return response;
    }

    @Override
    public AggregatedRegionResponse getRegionOverview(
            double minLat,
            double minLon,
            double maxLat,
            double maxLon,
            int mapWidth,
            int mapHeight,
            int stationLimit
    ) {
        double normalizedMinLat = Math.min(minLat, maxLat);
        double normalizedMaxLat = Math.max(minLat, maxLat);
        double normalizedMinLon = Math.min(minLon, maxLon);
        double normalizedMaxLon = Math.max(minLon, maxLon);

        double centerLat = (normalizedMinLat + normalizedMaxLat) / 2.0;
        double centerLon = (normalizedMinLon + normalizedMaxLon) / 2.0;

        AggregatedRegionResponse response = new AggregatedRegionResponse();

        response.setMinLat(normalizedMinLat);
        response.setMinLon(normalizedMinLon);
        response.setMaxLat(normalizedMaxLat);
        response.setMaxLon(normalizedMaxLon);
        response.setCenterLat(centerLat);
        response.setCenterLon(centerLon);

        loadWeather(response, centerLat, centerLon);
        loadRadioStations(
                response,
                normalizedMinLat,
                normalizedMinLon,
                normalizedMaxLat,
                normalizedMaxLon,
                stationLimit
        );
        loadMapTile(
                response,
                normalizedMinLon,
                normalizedMinLat,
                normalizedMaxLon,
                normalizedMaxLat,
                mapWidth,
                mapHeight
        );

        boolean atLeastOnePartOk =
                response.isWeatherOk()
                        || response.isMusicOk()
                        || response.isMapOk();

        boolean allPartsOk =
                response.isWeatherOk()
                        && response.isMusicOk()
                        && response.isMapOk();

        response.setOk(atLeastOnePartOk);

        if (allPartsOk) {
            response.setMessage("Aggregated region data loaded successfully.");
        } else if (atLeastOnePartOk) {
            response.setMessage("Aggregated region data loaded partially.");
        } else {
            response.setMessage("Failed to load aggregated region data.");
        }

        return response;
    }

    private void loadWeather(
            AggregatedRegionResponse response,
            double centerLat,
            double centerLon
    ) {
        try {
            DailyTemperatureResponse weather =
                    weatherApplicationService.getDailyAverageTemperatureWeek(
                            centerLat,
                            centerLon
                    );

            response.setWeather(weather);
            response.setWeatherOk(true);
            response.setWeatherMessage("Weather data loaded successfully.");

        } catch (Exception e) {
            response.setWeather(null);
            response.setWeatherOk(false);
            response.setWeatherMessage("Weather data failed: " + e.getMessage());
        }
    }

    private void loadRadioStations(
            AggregatedRegionResponse response,
            double minLat,
            double minLon,
            double maxLat,
            double maxLon,
            int stationLimit
    ) {
        try {
            List<RadioStationResponse> stations =
                    radioBrowserClient.getStationsInMapBounds(
                            minLat,
                            minLon,
                            maxLat,
                            maxLon,
                            stationLimit
                    );

            if (stations == null) {
                stations = new ArrayList<>();
            }

            response.setRadioStations(stations);
            response.setMusicOk(true);
            response.setMusicMessage("Radio stations loaded successfully. Count: " + stations.size());

        } catch (Exception e) {
            response.setRadioStations(new ArrayList<>());
            response.setMusicOk(false);
            response.setMusicMessage("Radio stations failed: " + e.getMessage());
        }
    }

    private void loadMapTile(
            AggregatedRegionResponse response,
            double minLon,
            double minLat,
            double maxLon,
            double maxLat,
            int mapWidth,
            int mapHeight
    ) {
        try {
            MapTileResponse mapTile =
                    geoportalClient.getMapTile(
                            minLon,
                            minLat,
                            maxLon,
                            maxLat,
                            mapWidth,
                            mapHeight
                    );

            response.setMapTile(mapTile);

            boolean mapOk = mapTile != null && mapTile.isOk();

            response.setMapOk(mapOk);

            if (mapTile != null && mapTile.getMessage() != null) {
                response.setMapMessage(mapTile.getMessage());
            } else if (mapOk) {
                response.setMapMessage("Map tile loaded successfully.");
            } else {
                response.setMapMessage("Map tile failed.");
            }

        } catch (Exception e) {
            response.setMapTile(null);
            response.setMapOk(false);
            response.setMapMessage("Map tile failed: " + e.getMessage());
        }
    }
}