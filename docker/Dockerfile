# --- Build stage: Elm + pandoc ---
FROM alpine:3.19 AS build

RUN apk add --no-cache curl gzip bash

# Install Elm 0.19.1
RUN curl -L -o elm.gz https://github.com/elm/compiler/releases/download/0.19.1/binary-for-linux-64-bit.gz \
    && gunzip elm.gz \
    && chmod +x elm \
    && mv elm /usr/local/bin/

WORKDIR /app
COPY . .

# Build Elm
RUN cd elm && elm make src/Main.elm --optimize --output=/app/public/app.js


# Generate version.json (local build, no git hash available)
RUN echo '{"hash":"local","date":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}' > public/version.json

# Copy LICENSE
RUN cp LICENSE public/ 2>/dev/null || true

# --- Serve stage: nginx ---
FROM nginx:alpine

COPY --from=build /app/public /usr/share/nginx/html
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

