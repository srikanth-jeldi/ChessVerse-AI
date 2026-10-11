FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /workspace
COPY pom.xml .
COPY src ./src
RUN mvn -q test package

FROM eclipse-temurin:21-jre
WORKDIR /app
RUN apt-get update \
    && apt-get install --yes --no-install-recommends curl stockfish \
    && rm -rf /var/lib/apt/lists/*
ENV STOCKFISH_PATH=/usr/games/stockfish
RUN groupadd --system --gid 10001 chessverse \
    && useradd --system --uid 10001 --gid 10001 --create-home chessverse \
    && mkdir -p /app/data/chat-attachments \
    && mkdir -p /app/data/profile-photos \
    && chown -R chessverse:chessverse /app/data
USER chessverse
COPY --from=build /workspace/target/chessverse-ai-backend-*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
