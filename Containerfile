FROM debian:trixie-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      bubblewrap=0.12.0-1~deb13u1 \
      ca-certificates=20250419 \
      curl=8.14.1-2+deb13u5 \
      gnupg=2.4.7-21+deb13u1 \
      jq=1.7.1-6+deb13u3 \
      nodejs=20.19.2+dfsg-1+deb13u2 \
      npm=9.2.0~ds1-3 \
      python3=3.13.5-1 \
      ripgrep=14.1.1-1+b4 \
      socat=1.8.0.3-1+deb13u1 \
 && rm -rf /var/lib/apt/lists/*

COPY --from=golang:1.27.1-trixie /usr/local/go /usr/local/go
ENV PATH=/home/claude/go/bin:/usr/local/go/bin:$PATH

RUN install -d -m 0755 /etc/apt/keyrings \
 && curl -fsSL https://downloads.claude.ai/keys/claude-code.asc -o /etc/apt/keyrings/claude-code.asc \
 && gpg --show-keys --with-colons /etc/apt/keyrings/claude-code.asc \
    | grep -qx "fpr:::::::::31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE:" \
 && echo "deb [signed-by=/etc/apt/keyrings/claude-code.asc] https://downloads.claude.ai/claude-code/apt/latest latest main" > /etc/apt/sources.list.d/claude-code.list

RUN apt-get update \
      -o Dir::Etc::sourcelist=/etc/apt/sources.list.d/claude-code.list \
      -o Dir::Etc::sourceparts=/dev/null \
 && apt-get install -y --no-install-recommends claude-code=2.1.278-1 \
 && rm -rf /var/lib/apt/lists/*

# renovate: datasource=npm depName=@anthropic-ai/sandbox-runtime
ARG SANDBOX_RUNTIME_VERSION=0.0.77
RUN npm install -g --no-fund "@anthropic-ai/sandbox-runtime@${SANDBOX_RUNTIME_VERSION}" \
 && rm -rf /root/.npm

RUN useradd --create-home --uid 1000 --shell /bin/bash claude

COPY rootfs/ /
RUN chown -R claude:claude /home/claude

USER claude
WORKDIR /workspace

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
