# ========================================================
# Stage: Builder
# ========================================================
FROM golang:1.25-alpine AS builder
WORKDIR /app
ARG TARGETOS=linux
ARG TARGETARCH
ARG TARGETVARIANT
ARG BUILDPLATFORM
ARG BUILDOS
ARG BUILDARCH

RUN apk --no-cache --update add \
  build-base \
  gcc \
  curl \
  unzip

COPY . .

ENV CGO_ENABLED=1
ENV CGO_CFLAGS="-D_LARGEFILE64_SOURCE"
ENV GOOS=${TARGETOS}
ENV GOARCH=${TARGETARCH}

# 处理 ARM 架构变体并构建
RUN if [ "$TARGETARCH" = "arm" ]; then \
    GOARM=$(case "$TARGETVARIANT" in v6) echo 6;; v7) echo 7;; *) echo 7;; esac) && \
    GOARM=$GOARM go build -ldflags "-w -s" -o build/x-ui main.go; \
  else \
    go build -ldflags "-w -s" -o build/x-ui main.go; \
  fi

RUN ./DockerInit.sh "$TARGETARCH"

# ========================================================
# Stage: Final Image of 3x-ui
# ========================================================
FROM alpine:latest
ENV TZ=Asia/Tehran
WORKDIR /app

# 一次性安装所有依赖并配置，减少镜像层数
RUN apk add --no-cache --update \
  ca-certificates \
  tzdata \
  fail2ban \
  bash \
  curl \
  socat \
  openssl \
  && rm -rf /var/cache/apk/* \
  && rm -f /etc/fail2ban/jail.d/alpine-ssh.conf \
  && cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local \
  && sed -i "s/^\[ssh\]$/&\nenabled = false/" /etc/fail2ban/jail.local \
  && sed -i "s/^\[sshd\]$/&\nenabled = false/" /etc/fail2ban/jail.local \
  && sed -i "s/#allowipv6 = auto/allowipv6 = auto/g" /etc/fail2ban/fail2ban.conf

COPY --from=builder /app/build/ /app/
COPY --from=builder /app/DockerEntrypoint.sh /app/
COPY --from=builder /app/x-ui.sh /usr/bin/x-ui

# 设置执行权限并预安装 acme.sh（可选，失败不影响运行）
RUN chmod +x \
  /app/DockerEntrypoint.sh \
  /app/x-ui \
  /usr/bin/x-ui \
  && (curl -s https://get.acme.sh | sh || true)

ENV XUI_ENABLE_FAIL2BAN="true"
EXPOSE 2053
VOLUME [ "/etc/x-ui" ]
CMD [ "./x-ui" ]
ENTRYPOINT [ "/app/DockerEntrypoint.sh" ]
