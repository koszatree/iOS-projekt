package pl.PnPIOS.coordinates;

import pl.PnPIOS.common.DTO.ServicePingResponse;
import pl.PnPIOS.coordinates.DTO.MapTileResponse;
import pl.PnPIOS.coordinates.Implementation.GeoportalClient;

import javax.jws.WebService;

@WebService(
        endpointInterface = "pl.PnPIOS.coordinates.CoordinateService",
        serviceName = "CoordinateService",
        portName = "CoordinateServicePort",
        targetNamespace = "http://coordinate.platformservice.pnpios.pl/"
)
public class CoordinateServiceImpl implements CoordinateService {

    private final GeoportalClient geoportalClient = new GeoportalClient();

    @Override
    public ServicePingResponse ping() {
        return geoportalClient.ping();
    }

    @Override
    public MapTileResponse getMapTile(
            double minLon,
            double minLat,
            double maxLon,
            double maxLat,
            int width,
            int height
    ) {
        return geoportalClient.getMapTile(
                minLon,
                minLat,
                maxLon,
                maxLat,
                width,
                height
        );
    }
}