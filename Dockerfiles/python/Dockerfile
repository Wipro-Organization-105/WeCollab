FROM ubuntu:22.04

USER root
ARG DEBIAN_FRONTEND=noninteractive

# OS deps + Python tooling (+ add sudo here)
RUN set -eux \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
         python3 \
         python3-venv \
         python3-pip \
         git \
         curl \
         ca-certificates \
         sudo \
    && rm -rf /var/lib/apt/lists/*

# Make "python" & "pip" available
RUN set -eux \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3 1 \
    && update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

# Create venv
RUN python3 -m venv /opt/venvs/base
ENV VIRTUAL_ENV=/opt/venvs/base
ENV PATH="/opt/venvs/base/bin:${PATH}"

# Upgrade pip and base packages
RUN set -eux \
    && pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir wheel setuptools ipython requests

# Create non-root user 'dev' and grant passwordless sudo
RUN set -eux \
    && useradd -m -s /bin/bash dev \
    && echo "dev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/99_dev \
    && chmod 0440 /etc/sudoers.d/99_dev

# Prepare workspace and permissions
RUN set -eux \
    && mkdir -p /home/dev/workspace \
    && chown -R dev:dev /home/dev \
    && chown -R dev:dev /opt/venvs/base

# Switch to dev
USER dev
WORKDIR /home/dev/workspace

# Runtime check
CMD ["/bin/bash", "-lc", "python --version && pip --version && echo 'Python (venv) ready' && sleep infinity"]
