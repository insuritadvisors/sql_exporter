package com.insurit.instrument.boundary;

import javax.annotation.Resource;
import javax.enterprise.concurrent.ManagedExecutorService;
import javax.inject.Inject;
import javax.ws.rs.Consumes;
import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.container.AsyncResponse;
import javax.ws.rs.container.Suspended;
import javax.ws.rs.core.MediaType;
import javax.ws.rs.core.Response;

/**
 *
 * @author Vasilis Stergioulis
 */
@Path("metrics")
public class MetricsResource {

    @Inject
    DataExtractor dataExtractor;

    @Resource
    ManagedExecutorService executorService;

    @GET
    @Produces(value = MediaType.TEXT_PLAIN)
    public void get(@Suspended final AsyncResponse asyncResponse) {
        executorService.submit(() -> {
            asyncResponse.resume(doGet());
        });
    }

    private Response doGet() {
        StringBuilder sb = new StringBuilder();
        dataExtractor.getAllMetrics().forEach((im) -> {
            sb.append(im.getMetric()).append(" ").append(im.getValue().toPlainString()).append('\n');
        });
        return Response.ok(sb.toString()).build();
    }

}
