FROM apache/skywalking-base:6.6.0-es7 as skywalking
FROM mydocker-registry.com/centos7-jre8
VOLUME /tmp
ARG profile
ENV SPRING_PROFILES_ACTIVE ${profile}

ARG JAR_FILE

COPY ${JAR_FILE} /app.jar
COPY --from=skywalking /skywalking/agent /skywalking/agent

ENTRYPOINT ["java","-Djava.security.egd=file:/dev/./urandom", "-jar", "-javaagent:/skywalking/agent/skywalking-agent.jar", "-jar","/app.jar"]
