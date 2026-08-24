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
RUN mv /srv/index.html /srv/app.html
COPY infrastructure/vps/web/landing/index.html /srv/landing.html
COPY infrastructure/vps/web/landing/robots.txt /srv/robots.txt
COPY infrastructure/vps/web/landing/sitemap.xml /srv/sitemap.xml
COPY mobile/assets/branding/app_icon.png /srv/landing-assets/app-icon.png
COPY mobile/assets/backgrounds/home-analysis-hero-v1.png /srv/landing-assets/analysis.png
COPY mobile/assets/backgrounds/home-online-hero-v1.png /srv/landing-assets/online.png
COPY mobile/assets/backgrounds/home-puzzles-hero-v1.png /srv/landing-assets/puzzles.png
COPY infrastructure/vps/web/legal/ /srv/
