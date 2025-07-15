FROM maven:3.9.7-eclipse-temurin-17 AS builder
WORKDIR /src

# Copy the Maven project and resolve dependencies first (keeps cache warm)
COPY pom.xml .
RUN mvn -B dependency:go-offline

# Now copy everything else and build the WAR
COPY . .
RUN mvn -B clean package -DskipTests

# Tomcat 9 still supports the javax.* namespace used by the Benchmark app
FROM tomcat:9.0-jdk17-temurin

# The Benchmark build creates target/benchmark.war
COPY --from=builder /src/target/benchmark.war $CATALINA_HOME/webapps/benchmark.war

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s \
  CMD curl -fs http://localhost:8080/benchmark/ || exit 1

CMD ["catalina.sh", "run"]
