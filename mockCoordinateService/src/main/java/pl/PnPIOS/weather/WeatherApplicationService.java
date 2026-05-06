package pl.PnPIOS.weather;

import pl.PnPIOS.weather.Implementation.OpenMeteoClient;
import pl.PnPIOS.weather.DTO.DailyTemperatureResponse;
import pl.PnPIOS.weather.DTO.HourlyTemperatureResponse;
import pl.PnPIOS.common.DTO.ServicePingResponse;

public class WeatherApplicationService {

    private static final int WEEK_FORECAST_DAYS = 7;
    private static final int LONG_RANGE_FORECAST_DAYS = 16;

    private final OpenMeteoClient openMeteoClient = new OpenMeteoClient();

    public ServicePingResponse ping() {
        return openMeteoClient.ping();
    }

    public DailyTemperatureResponse getDailyAverageTemperatureWeek(
            double latitude,
            double longitude
    ) {
        return openMeteoClient.getDailyAverageTemperature(
                latitude,
                longitude,
                WEEK_FORECAST_DAYS
        );
    }

    public DailyTemperatureResponse getDailyAverageTemperatureMonth(
            double latitude,
            double longitude
    ) {
        return openMeteoClient.getLongRangeDailyAverageTemperature(
                latitude,
                longitude,
                LONG_RANGE_FORECAST_DAYS
        );
    }

    public HourlyTemperatureResponse getHourlyTemperatureForDay(
            double latitude,
            double longitude,
            String date
    ) {
        return openMeteoClient.getHourlyTemperatureForDay(
                latitude,
                longitude,
                date
        );
    }
}