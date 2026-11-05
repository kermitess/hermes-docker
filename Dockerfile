FROM nousresearch/hermes-agent:v0.22.7

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    gh \
    jq \
    vim \
    curl \
    unzip \
    tmux \
    && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# Run user cron scripts outside Hermes' own /opt/hermes/.venv. The wrapper
# creates $HERMES_HOME/cron/venv on demand and installs user requirements there.
COPY docker/hermes-cron-python /usr/local/bin/hermes-cron-python
COPY docker/patch-cron-python /usr/local/bin/patch-cron-python

# v0.22.6 moved cron script execution into cron/scheduler_script.py; the patch
# script handles both that layout and the older cron/scheduler.py one.
RUN python3 /usr/local/bin/patch-cron-python

RUN chmod 0755 /usr/local/bin/hermes-cron-python

RUN cd /opt/hermes && uv pip install "hindsight-client>=0.4.22"

RUN npm install -g @anthropic-ai/claude-code

RUN npm install -g opencode-ai@latest

# v0.22.7 base image bakes a prebuilt TUI bundle at /opt/hermes/ui-tui
# (dist/entry.js) and no longer ships the frontend build deps (esbuild),
# so an in-fork `npm run build` fails with "Missing prepared esbuild
# dependency" and is redundant.
ENV HERMES_TUI_DIR=/opt/hermes/ui-tui
