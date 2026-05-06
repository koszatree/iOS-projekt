package pl.PnPIOS.aggregation;

import pl.PnPIOS.aggregation.DTO.AggregatedPingResponse;
import pl.PnPIOS.aggregation.DTO.AggregatedRegionResponse;

import javax.jws.WebMethod;
import javax.jws.WebParam;
import javax.jws.WebService;

@WebService(
        name = "AggregationService",
        targetNamespace = "http://aggregation.platformservice.pnpios.pl/"
)
public interface AggregationService {

    @WebMethod
    AggregatedPingResponse pingAll();

    @WebMethod
    AggregatedRegionResponse getRegionOverview(
            @WebParam(name = "minLat") double minLat,
            @WebParam(name = "minLon") double minLon,
            @WebParam(name = "maxLat") double maxLat,
            @WebParam(name = "maxLon") double maxLon,
            @WebParam(name = "mapWidth") int mapWidth,
            @WebParam(name = "mapHeight") int mapHeight,
            @WebParam(name = "stationLimit") int stationLimit
    );
}