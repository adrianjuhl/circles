package adrianjuhl.circles;

import org.apache.camel.component.cxf.jaxrs.CxfRsEndpoint;
import org.apache.cxf.Bus;
import org.apache.cxf.jaxrs.JAXRSServerFactoryBean;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;


/**
 * Application configuration.
 */
@Configuration
public class ApplicationConfiguration {

  @Autowired
  private Bus bus;

  @Value("${rest.service.resource:}")
  private String restServiceAddress;
//
//
//  /**
//   * REST Local Service.
//   *
//   * @return the CXFRS rest server bean.
//   */

  
  
  @Bean
  JAXRSServerFactoryBean restServer() {
    CxfRsEndpoint endpoint = new CxfRsEndpoint();
    JAXRSServerFactoryBean rsServer = endpoint.createJAXRSServerFactoryBean();

    rsServer.setBus(bus);
    rsServer.setServiceClass(RestInterface.class);
    rsServer.setAddress(restServiceAddress);
    //rsServer.setProvider(jsonProvider());

    return rsServer;
  }

//  @Bean
//  JacksonJsonProvider jsonProvider(){
//    return new JacksonJsonProvider();
//  }

}
