# circles

A journey into continuous integration, continuous deployment, and DevOps.

# Development

## Local development

### Running the application

To run the application:

```
$ mvn clean package && java -DSPRING_APPLICATION_JSON='{"logging.level.root":"INFO","spring.main.banner-mode":"off"}' -jar target/circles.jar
```

### Verify

To verify this application, run the application as above and then run the following:

```
$ curl -v http://127.0.0.1:8080/actuator/health
Should respond with a HTTP 200 status and content: {"status":"UP"}
```

# License

MIT

# Author

[Adrian Juhl](http://github.com/adrianjuhl)

# Source Code

[https://github.com/adrianjuhl/circles](https://github.com/adrianjuhl/circles)

