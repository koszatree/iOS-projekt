package org.example.mockcoordinateservice;

import javax.jws.WebMethod;
import javax.jws.WebParam;
import javax.jws.WebService;

@WebService
public interface CoordinateService {
    @WebMethod
    String sayHello(String name);

    @WebMethod(operationName = "sendCoordinates")
    String sendCoordinates(@WebParam(name = "upperLeftLong") String upperLeftLong,
                           @WebParam(name = "upperLeftLat") String upperLeftLat,
                           @WebParam(name = "lowerRightLong") String lowerRightLong,
                           @WebParam(name = "lowerRightLat") String lowerRightLat
    );
}