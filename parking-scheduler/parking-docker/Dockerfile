# Parking automation — Node/Playwright SSO + Java booking + cron
# Playwright base matches package-lock Chromium deps (see resource-scheduler-sso-login).
# Unraid migration: local RS_PASSWORD only (no AWS CLI / SSM).
FROM mcr.microsoft.com/playwright:v1.61.1-jammy

USER root
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Manila \
    HOME=/data/home \
    PARKING_ROOT=/app/parking \
    PARKING_LOCAL_CREDENTIALS_ONLY=1

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    openjdk-17-jdk-headless \
    python3 \
    cron \
    curl \
    ca-certificates \
    tzdata \
  && ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime \
  && echo "${TZ}" >/etc/timezone \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app/parking
COPY . .

RUN cd resource-scheduler-sso-login \
  && npm ci \
  && npx playwright install chromium \
  && cd /app/parking/resource-scheduler \
  && mkdir -p target/classes logs/responses \
  && javac -cp "lib/*" -d target/classes src/main/java/com/apitest/reservation/*.java \
  && cd /app/parking \
  && chmod +x \
    docker/entrypoint.sh \
    bin/parking \
    install.sh \
    uninstall-schedules.sh \
    scripts/*.sh \
    resource-scheduler/*.sh \
    resource-scheduler/scripts/*.sh \
    resource-scheduler-sso-login/*.sh \
    resource-scheduler-sso-login/scripts/*.sh \
  && ln -sf /app/parking/bin/parking /usr/local/bin/parking \
  && mkdir -p /data/home /data/config \
  && touch /var/log/parking-cron.log

# Cron jobs need a predictable PATH (nvm is not used in the image).
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

ENTRYPOINT ["/app/parking/docker/entrypoint.sh"]
CMD ["cron"]
