package adrianjuhl.circles;

import org.apache.camel.CamelContext;
import org.apache.camel.LoggingLevel;
import org.apache.camel.builder.RouteBuilder;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * The RouteBuilder of the application.
 */
@Component
public class ApplicationRouteBuilder extends RouteBuilder {

  @Autowired
  CamelContext camelContext;

  @Value("${camel.context.shutdown.timeout:10}")
  private Long camelContextShutdownTimeout;

  enum RouteDefnInfo {
    READINESS_PROBE                                       ("direct:readinessprobe"),
    ;

    private String uri;
    RouteDefnInfo(final String uri) {
      this.uri = uri;
    }
    public String getRouteId() {
      return this.name();
    }
    public String getRouteUri() {
      return uri;
    }
  }

  public static final Logger LOGGER = LoggerFactory.getLogger(ApplicationRouteBuilder.class);
  public static final String LOGGER_NAME = LOGGER.getName();

  /**
   * The routes.
   */
  @Override
  public void configure() throws Exception {

    camelContext.getShutdownStrategy().setTimeout(camelContextShutdownTimeout);
    camelContext.setStreamCaching(true);

    from("cxfrs:bean:restServer?bindingStyle=SimpleConsumer")
      .toD("direct:${header.operationName}")
    ;

    from(RouteDefnInfo.READINESS_PROBE.getRouteUri())
      .routeId(RouteDefnInfo.READINESS_PROBE.getRouteId())
      .log(LoggingLevel.INFO, LOGGER_NAME, "Start of route readinessprobe")
      .removeHeaders("*")
      //.setHeader(Exchange.HTTP_RESPONSE_CODE, constant(HttpStatus.SC_OK))
      //.setHeader(Exchange.CONTENT_TYPE, constant(MediaType.APPLICATION_JSON))
      .setBody(constant("{ \"ready\": \"ready\" }"))
      .log(LoggingLevel.INFO, LOGGER_NAME, "End of route readinessprobe")
    ;

  }

}
