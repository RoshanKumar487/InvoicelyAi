# ==============================================================================
# InvoicelyAi Backend - Production Multi-Stage Dockerfile
# Framework: Spring Boot 3.3.4 | Runtime: Java 17 | Database: Supabase PostgreSQL
# ==============================================================================

# ------------------------------------------------------------------------------
# Stage 1: Build stage (compile & package using Maven + JDK 17)
# ------------------------------------------------------------------------------
FROM maven:3.9.9-eclipse-temurin-17-alpine AS builder

WORKDIR /build

# Copy Maven descriptor first to leverage Docker layer caching for dependencies
COPY pom.xml .

# Download project dependencies (cached unless pom.xml changes)
RUN mvn dependency:go-offline -B || true

# Copy source code
COPY src ./src

# Package production executable fat JAR (skipping unit tests during Docker build)
RUN mvn clean package -DskipTests -B

# ------------------------------------------------------------------------------
# Stage 2: Runtime stage (Minimal, secure Alpine JRE 17 container)
# ------------------------------------------------------------------------------
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Install curl for container health check and tzdata for proper timezone resolution
RUN apk add --no-cache curl tzdata

# Create dedicated unprivileged user and group for security compliance
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy compiled JAR from builder stage
COPY --from=builder /build/target/*.jar /app/app.jar

# Set ownership of application files
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser:appgroup

# Expose default HTTP port
EXPOSE 8080

# Environment variables with production-ready defaults
ENV PORT=8080 \
    SPRING_PROFILES_ACTIVE=prod \
    JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:InitialRAMPercentage=50.0 -Djava.security.egd=file:/dev/./urandom"

# Health check to monitor application readiness and container liveness
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:${PORT}/api/v1/health || curl -f http://localhost:${PORT}/v3/api-docs || exit 1

# Execute the Spring Boot application using exec to properly handle termination signals (SIGTERM)
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -Dserver.port=${PORT} -jar /app/app.jar"]
