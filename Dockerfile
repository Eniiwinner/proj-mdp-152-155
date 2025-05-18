# First stage: Build the application with Maven
FROM maven:3.8.4-openjdk-11 AS builder
WORKDIR /app
COPY . .
RUN mvn clean package

# Second stage: Setup Tomcat and deploy the application
FROM tomcat:9.0-jdk11
COPY --from=builder /app/target/WebAppCal-1.3.5.war /usr/local/tomcat/webapps/calculator.war
EXPOSE 8080
CMD ["catalina.sh", "run"]
