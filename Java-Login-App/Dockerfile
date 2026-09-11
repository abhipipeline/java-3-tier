FROM maven:3.9-eclipse-temurin-11 AS build
WORKDIR /workspace
COPY pom.xml settings.xml mvnw mvnw.cmd ./
RUN chmod +x mvnw
COPY src ./src
RUN ./mvnw -B package -DskipTests

FROM eclipse-temurin:11-jre
WORKDIR /app
COPY --from=build /workspace/target/*.war app.war
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.war"]