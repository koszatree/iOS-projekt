package pl.PnPIOS.coordinates;

import pl.PnPIOS.coordinates.DTO.MapTileResponse;
import pl.PnPIOS.common.DTO.ServicePingResponse;

import javax.jws.WebMethod;
import javax.jws.WebParam;
import javax.jws.WebService;

@WebService(
        name = "CoordinateService",
        targetNamespace = "http://coordinate.platformservice.pnpios.pl/"
)
public interface CoordinateService {

    @WebMethod
    ServicePingResponse ping();

    @WebMethod
    MapTileResponse getMapTile(
            @WebParam(name = "minLon") double minLon,
            @WebParam(name = "minLat") double minLat,
            @WebParam(name = "maxLon") double maxLon,
            @WebParam(name = "maxLat") double maxLat,
            @WebParam(name = "width") int width,
            @WebParam(name = "height") int height
    );
}