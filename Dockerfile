# ========================================================
# Stage: Builder
# ========================================================
FROM --platform=$BUILDPLATFORM golang:1.21-alpine AS builder
WORKDIR /app
ARG TARGETARCH
ENV CGO_ENABLED=1
ENV CGO_CFLAGS="-D_LARGEFILE64_SOURCE"

RUN apk --no-cache --update add \
  build-base \
  gcc \
  wget \
  unzip

COPY . .

RUN go build -o build/x-ui main.go
RUN ./DockerInit.sh "$TARGETARCH"

# ========================================================
# Stage: Final Image of 3x-ui
# ========================================================
FROM alpine
ENV TZ=Asia/Tehran
ENV XUI_ADMIN_USERNAME=adminn
ENV XUI_ADMIN_PASSWORD=Adminn12345
WORKDIR /app

RUN apk add --no-cache --update \
  ca-certificates \
  tzdata \
  fail2ban

COPY --from=builder  /app/build/ /app/
COPY --from=builder  /app/DockerEntrypoint.sh /app/
COPY --from=builder  /app/x-ui.sh /usr/bin/x-ui

RUN apk upgrade --update-cache --available && \
    apk add openssl && \
    rm -rf /var/cache/apk/*
    
RUN openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -sha256 -days 3650 -nodes -subj "/C=fa/ST=k/L=k/O=vm/OU=m/CN=vp"

# Configure fail2ban
RUN rm -f /etc/fail2ban/jail.d/alpine-ssh.conf \
  && cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local \
  && sed -i "s/^\[ssh\]$/&\nenabled = false/" /etc/fail2ban/jail.local \
  && sed -i "s/^\[sshd\]$/&\nenabled = false/" /etc/fail2ban/jail.local \
  && sed -i "s/#allowipv6 = auto/allowipv6 = auto/g" /etc/fail2ban/fail2ban.conf

RUN chmod +x \
  /app/DockerEntrypoint.sh \
  /app/x-ui \
  /usr/bin/x-ui

VOLUME [ "/etc/x-ui" ]
ENTRYPOINT [ "/app/DockerEntrypoint.sh" ]
