# --- Build stage ---
FROM maven:3.9-amazoncorretto-25 AS build
WORKDIR /app

# Copy only the POM first to leverage Docker layer caching for dependencies.
# As long as pom.xml doesn't change, this layer (and the downloaded deps)
# is reused on subsequent builds, even if source code changes.
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Now copy the source and build.
COPY src ./src
RUN mvn clean package -DskipTests -B

# --- Runtime stage ---
FROM amazoncorretto:25-alpine
WORKDIR /app

# Run as non-root user (security best practice)
RUN addgroup -S bizno && adduser -S bizno -G bizno
USER bizno

COPY --from=build /app/target/*.jar app.jar

# Main application port
EXPOSE 8761
# Actuator / management port (metrics, health)
EXPOSE 9761

ENTRYPOINT ["java", "-jar", "app.jar"]