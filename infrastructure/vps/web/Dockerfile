FROM ghcr.io/cirruslabs/flutter:stable AS build

# The registry does not publish every Flutter patch-version tag. Pin the
# official SDK revision inside the isolated build stage instead.
ARG FLUTTER_VERSION=3.47.2
RUN sdk_dir="$(dirname "$(dirname "$(readlink -f "$(command -v flutter)")")")" \
    && git -C "$sdk_dir" fetch --depth 1 origin "refs/tags/${FLUTTER_VERSION}:refs/tags/${FLUTTER_VERSION}" \
    && git -C "$sdk_dir" checkout --detach "$FLUTTER_VERSION" \
    && flutter --version

WORKDIR /workspace
COPY mobile/pubspec.yaml mobile/pubspec.lock ./
COPY mobile/third_party/ ./third_party/
RUN flutter pub get

COPY mobile/ ./
ARG API_BASE_URL
ARG FACEBOOK_APP_ID
ARG FACEBOOK_CLIENT_TOKEN
RUN test -n "${API_BASE_URL}" \
    && test -n "${FACEBOOK_APP_ID}" \
    && test -n "${FACEBOOK_CLIENT_TOKEN}" \
    && flutter build web --release --base-href /play/ \
      --dart-define=API_BASE_URL="${API_BASE_URL}" \
      --dart-define=FACEBOOK_APP_ID="${FACEBOOK_APP_ID}" \
      --dart-define=FACEBOOK_CLIENT_TOKEN="${FACEBOOK_CLIENT_TOKEN}"

FROM caddy:2-alpine
COPY infrastructure/vps/web/Caddyfile /etc/caddy/Caddyfile
COPY --from=build /workspace/build/web /srv/play
COPY infrastructure/vps/web/landing/index.html /srv/index.html
COPY infrastructure/vps/web/landing/flutter_service_worker.js /srv/flutter_service_worker.js
COPY infrastructure/vps/web/landing/robots.txt /srv/robots.txt
COPY infrastructure/vps/web/landing/sitemap.xml /srv/sitemap.xml
COPY infrastructure/vps/web/landing/app-ads.txt /srv/app-ads.txt
COPY mobile/assets/branding/app_icon.png /srv/landing-assets/app-icon.png
COPY mobile/assets/backgrounds/home-analysis-hero-v1.png /srv/landing-assets/analysis.png
COPY mobile/assets/backgrounds/home-online-hero-v1.png /srv/landing-assets/online.png
COPY mobile/assets/backgrounds/home-puzzles-hero-v1.png /srv/landing-assets/puzzles.png
COPY infrastructure/vps/web/legal/ /srv/
