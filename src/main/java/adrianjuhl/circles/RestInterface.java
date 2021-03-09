package adrianjuhl.circles;

import javax.ws.rs.GET;
import javax.ws.rs.Path;


/**
 * The Rest interface of the application.
 */
@Path("/")
public interface RestInterface {

  @GET
  @Path("readinessprobe")
  String readinessprobe();

}
