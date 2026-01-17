# Hytale Server - Local Development
# Server binaries and user data are mounted at runtime, not baked in.

FROM eclipse-temurin:25-jdk

# Create hytale user (non-root)
RUN groupadd -r hytale && useradd -r -g hytale -d /opt/hytale -s /sbin/nologin hytale

# Create working directory
WORKDIR /opt/hytale
RUN chown hytale:hytale /opt/hytale

# Expose Hytale port (UDP for QUIC protocol)
EXPOSE 5520/udp

# Default JVM settings (can be overridden via environment)
ENV JAVA_OPTS="-Xmx3G -Xms1G -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200"
ENV HYTALE_OPTS=""

USER hytale

# Server binaries mounted at /opt/hytale/server
# User data mounted at /opt/hytale (working directory)
# Use AOT cache if present for faster startup
ENTRYPOINT ["sh", "-c", "AOT_FLAG=''; [ -f server/HytaleServer.aot ] && AOT_FLAG='-XX:AOTCache=server/HytaleServer.aot'; exec java $AOT_FLAG $JAVA_OPTS -jar server/HytaleServer.jar --assets server/Assets.zip $HYTALE_OPTS"]
