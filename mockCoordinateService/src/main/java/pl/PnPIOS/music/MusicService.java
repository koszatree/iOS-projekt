package pl.PnPIOS.music;

import pl.PnPIOS.music.DTO.RadioStationResponse;
import pl.PnPIOS.music.DTO.RadioStreamResponse;
import pl.PnPIOS.common.DTO.ServicePingResponse;

import javax.jws.WebMethod;
import javax.jws.WebParam;
import javax.jws.WebService;
import java.util.List;

@WebService(
        name = "MusicService",
        targetNamespace = "http://music.platformservice.pnpios.pl/"
)
public interface MusicService {
    @WebMethod
    ServicePingResponse ping();

    @WebMethod
    List<RadioStationResponse> searchStationsByName(
            @WebParam(name = "name") String name
    );

    @WebMethod
    RadioStreamResponse getStationStreamUrl(
            @WebParam(name = "stationUuid") String stationUuid
    );

    @WebMethod
    List<RadioStationResponse> getStationsInMapBounds(
            @WebParam(name = "minLat") double minLat,
            @WebParam(name = "minLon") double minLon,
            @WebParam(name = "maxLat") double maxLat,
            @WebParam(name = "maxLon") double maxLon,
            @WebParam(name = "limit") int limit
    );
}