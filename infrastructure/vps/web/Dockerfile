FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /workspace
COPY mobile/pubspec.yaml mobile/pubspec.lock ./
RUN flutter pub get

COPY mobile/ ./
ARG API_BASE_URL
ARG FACEBOOK_APP_ID
ARG FACEBOOK_CLIENT_TOKEN
RUN test -n "${API_BASE_URL}" \
    && test -n "${FACEBOOK_APP_ID}" \
    && test -n "${FACEBOOK_CLIENT_TOKEN}" \
    && flutter build web --release \
      --dart-define=API_BASE_URL="${API_BASE_URL}" \
      --dart-define=FACEBOOK_APP_ID="${FACEBOOK_APP_ID}" \
      --dart-define=FACEBOOK_CLIENT_TOKEN="${FACEBOOK_CLIENT_TOKEN}"

FROM caddy:2-alpine
COPY infrastructure/vps/web/Caddyfile /etc/caddy/Caddyfile
COPY --from=build /workspace/build/web /srv
COPY infrastructure/vps/web/legal/ /srv/
