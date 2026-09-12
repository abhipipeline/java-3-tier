FROM maven:3.9-eclipse-temurin-11 AS build
WORKDIR /workspace
COPY pom.xml ./
COPY src ./src
RUN mvn -B package -DskipTests

FROM eclipse-temurin:11-jre
WORKDIR /app
COPY --from=build /workspace/target/*.war app.war
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.war"]