FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /workspace
COPY mobile/pubspec.yaml mobile/pubspec.lock ./
RUN flutter pub get

COPY mobile/ ./
ARG API_BASE_URL
RUN test -n "${API_BASE_URL}" \
    && flutter build web --release --dart-define=API_BASE_URL="${API_BASE_URL}"

FROM caddy:2-alpine
COPY infrastructure/vps/web/Caddyfile /etc/caddy/Caddyfile
COPY --from=build /workspace/build/web /srv
