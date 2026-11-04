FROM nousresearch/hermes-agent:v2026.7.1

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

RUN python3 -c "from pathlib import Path; p = Path('/opt/hermes/cron/scheduler.py'); s = p.read_text(); old = '[sys.executable, str(path)]'; new = '[\"/usr/local/bin/hermes-cron-python\", str(path)]'; assert old in s or new in s; p.write_text(s.replace(old, new, 1))"

RUN chmod 0755 /usr/local/bin/hermes-cron-python

RUN cd /opt/hermes && uv pip install "hindsight-client>=0.4.22"

RUN npm install -g @anthropic-ai/claude-code

RUN npm install -g opencode-ai@latest

# v0.22.7 base image bakes a prebuilt TUI bundle at /opt/hermes/ui-tui
# (dist/entry.js) and no longer ships the frontend build deps (esbuild),
# so an in-fork `npm run build` fails with "Missing prepared esbuild
# dependency" and is redundant.
ENV HERMES_TUI_DIR=/opt/hermes/ui-tui
