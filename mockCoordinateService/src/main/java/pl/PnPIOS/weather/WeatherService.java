package pl.PnPIOS.weather;


import pl.PnPIOS.weather.DTO.DailyTemperatureResponse;
import pl.PnPIOS.weather.DTO.HourlyTemperatureResponse;
import pl.PnPIOS.common.DTO.ServicePingResponse;

import javax.jws.WebMethod;
import javax.jws.WebParam;
import javax.jws.WebService;

@WebService(
        name = "WeatherService",
        targetNamespace = "http://weather.platformservice.pnpios.pl/"
)
public interface WeatherService {
    @WebMethod
    ServicePingResponse ping();

    @WebMethod
    DailyTemperatureResponse getDailyAverageTemperatureWeek(
            @WebParam(name = "latitude") double latitude,
            @WebParam(name = "longitude") double longitude
    );

    @WebMethod
    DailyTemperatureResponse getDailyAverageTemperatureMonth(
            @WebParam(name = "latitude") double latitude,
            @WebParam(name = "longitude") double longitude
    );

    @WebMethod
    HourlyTemperatureResponse getHourlyTemperatureForDay(
            @WebParam(name = "latitude") double latitude,
            @WebParam(name = "longitude") double longitude,
            @WebParam(name = "date") String date
    );
}
