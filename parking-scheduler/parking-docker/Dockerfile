# Parking automation — Node/Playwright SSO + Java booking + cron
# Playwright base matches package-lock Chromium deps (see resource-scheduler-sso-login).
FROM mcr.microsoft.com/playwright:v1.61.1-jammy

USER root
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Asia/Manila \
    HOME=/data/home \
    PARKING_ROOT=/app/parking \
    AWS_SHARED_CREDENTIALS_FILE=/data/aws/credentials \
    AWS_CONFIG_FILE=/data/aws/config

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    openjdk-17-jdk-headless \
    python3 \
    cron \
    unzip \
    curl \
    ca-certificates \
    tzdata \
  && ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime \
  && echo "${TZ}" >/etc/timezone \
  && curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip \
  && unzip -q /tmp/awscliv2.zip -d /tmp \
  && /tmp/aws/install \
  && rm -rf /tmp/aws /tmp/awscliv2.zip /var/lib/apt/lists/*

WORKDIR /app/parking
COPY . .

RUN cd resource-scheduler-sso-login \
  && npm ci \
  && npx playwright install chromium \
  && cd /app/parking/resource-scheduler \
  && mkdir -p target/classes logs/responses \
  && javac -cp "lib/*" -d target/classes src/main/java/com/apitest/reservation/*.java \
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
  && mkdir -p /data/home/.config/resource-scheduler /data/aws /data/config \
  && touch /var/log/parking-cron.log

# Cron jobs need a predictable PATH (nvm is not used in the image).
ENV PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

ENTRYPOINT ["/app/parking/docker/entrypoint.sh"]
CMD ["cron"]
