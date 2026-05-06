package pl.PnPIOS.music;

import pl.PnPIOS.common.DTO.ServicePingResponse;
import pl.PnPIOS.music.DTO.RadioStationResponse;
import pl.PnPIOS.music.DTO.RadioStreamResponse;
import pl.PnPIOS.music.Implementation.RadioBrowserClient;

import javax.jws.WebService;
import java.util.List;

@WebService(
        endpointInterface = "pl.PnPIOS.music.MusicService",
        serviceName = "MusicService",
        portName = "MusicServicePort",
        targetNamespace = "http://music.platformservice.pnpios.pl/"
)
public class MusicServiceImpl implements MusicService {

    private final RadioBrowserClient radioBrowserClient = new RadioBrowserClient();

    @Override
    public ServicePingResponse ping() {
        return radioBrowserClient.ping();
    }

    @Override
    public List<RadioStationResponse> searchStationsByName(String name) {
        return radioBrowserClient.searchStationsByName(name);
    }

    @Override
    public RadioStreamResponse getStationStreamUrl(String stationUuid) {
        return radioBrowserClient.getStationStreamUrl(stationUuid);
    }

    @Override
    public List<RadioStationResponse> getStationsInMapBounds(
            double minLat,
            double minLon,
            double maxLat,
            double maxLon,
            int limit
    ) {
        return radioBrowserClient.getStationsInMapBounds(
                minLat,
                minLon,
                maxLat,
                maxLon,
                limit
        );
    }
}