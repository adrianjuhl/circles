package adrianjuhl.circles;

import org.apache.camel.CamelContext;
import org.apache.camel.Exchange;
import org.apache.camel.builder.RouteBuilder;
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

  @Value("${camel.context.shutdown.timeout}")
  private Long camelContextShutdownTimeout;

//  @Value("${uoa.application.properties.environment}")
//  private String uoaApplicationPropertiesEnvironment;

//  public static final Logger LOGGER = LoggerFactory.getLogger(ApplicationRouteBuilder.class);
//  public static final String LOGGER_NAME = LOGGER.getName();

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

  /**
   * The routes.
   */
  @Override
  public void configure() throws Exception {

//    LOGGER.trace(">>>>>>>>>>>>>>>>TRACE");
//    LOGGER.debug(">>>>>>>>>>>>>>>>DEBUG");
//    LOGGER.info(">>>>>>>>>>>>>>>>INFO");
//    LOGGER.warn(">>>>>>>>>>>>>>>>WARN");
//    LOGGER.error(">>>>>>>>>>>>>>>>ERROR");

    camelContext.getShutdownStrategy().setTimeout(camelContextShutdownTimeout);
    camelContext.setStreamCaching(true);

    from("cxfrs:bean:restServer?bindingStyle=SimpleConsumer")
      .toD("direct:${header.operationName}")
    ;

    from(RouteDefnInfo.READINESS_PROBE.getRouteUri())
      .routeId(RouteDefnInfo.READINESS_PROBE.getRouteId())
      //.log(LoggingLevel.INFO, LOGGER_NAME, "Start of route readinessprobe")
      .removeHeaders("*")
      //.setHeader(Exchange.HTTP_RESPONSE_CODE, constant(HttpStatus.SC_OK))
      //.setHeader(Exchange.CONTENT_TYPE, constant(MediaType.APPLICATION_JSON))
      .setBody(constant("{ \"ready\": \"ready\" }"))
      //.log(LoggingLevel.INFO, LOGGER_NAME, "End of route readinessprobe")
    ;

  }

}
