package pl.PnPIOS.weather;

import javax.jws.WebService;
import pl.PnPIOS.weather.DTO.DailyTemperatureResponse;
import pl.PnPIOS.weather.DTO.HourlyTemperatureResponse;
import pl.PnPIOS.common.DTO.ServicePingResponse;

@WebService(endpointInterface = "pl.PnPIOS.weather.WeatherService",
        serviceName = "WeatherService",
        portName = "WeatherServicePort",
        targetNamespace = "http://weather.platformservice.pnpios.pl/"
)
public class WeatherServiceImpl implements WeatherService {

    private final WeatherApplicationService weatherApplicationService =
        new WeatherApplicationService();

    @Override
    public ServicePingResponse ping() {
        return weatherApplicationService.ping();
    }

    @Override
    public DailyTemperatureResponse getDailyAverageTemperatureWeek( double latitude, double longitude )
    {
        return weatherApplicationService.getDailyAverageTemperatureWeek(latitude, longitude);
    }

    @Override
    public DailyTemperatureResponse getDailyAverageTemperatureMonth(double latitude, double longitude)
    {
        return weatherApplicationService.getDailyAverageTemperatureMonth(latitude, longitude);
    }

    @Override
    public HourlyTemperatureResponse getHourlyTemperatureForDay(double latitude, double longitude, String date)
    {
        return weatherApplicationService.getHourlyTemperatureForDay(latitude, longitude, date);
    }

}

