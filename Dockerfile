FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        ripgrep \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --uid 1000 --shell /bin/bash claude

USER claude
WORKDIR /home/claude

ENV PATH=/home/claude/.local/bin:$PATH
RUN curl -fsSL https://claude.ai/install.sh | bash \
    && claude --version

WORKDIR /workspace
CMD ["claude"]
