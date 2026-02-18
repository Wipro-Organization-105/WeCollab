FROM codercom/enterprise-base:ubuntu

USER root
ARG DEBIAN_FRONTEND=noninteractive

# OS deps + Python tooling
RUN set -eux \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
         python3 \
         python3-venv \
         python3-pip \
         git \
         curl \
         ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Make "python" & "pip" available (alias to python3/pip3)
# (This is optional; many folks just call python3/pip3 explicitly.)
RUN set -eux \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3 1 \
    && update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

# Create a virtual environment and use it by default
RUN python3 -m venv /opt/venvs/base
ENV VIRTUAL_ENV=/opt/venvs/base
ENV PATH="/opt/venvs/base/bin:${PATH}"

# Upgrade pip INSIDE the venv and install packages there
RUN set -eux \
    && pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir \
         wheel \
         setuptools \
         ipython \
         requests

# Switch back to non-root "coder" user from base image
USER coder
WORKDIR /home/coder

# Optional: a default workspace directory
RUN mkdir -p /home/coder/workspace
WORKDIR /home/coder/workspace

# Simple runtime check
CMD ["/bin/bash", "-lc", "python --version && pip --version && echo 'Python (venv) ready for Coder' && sleep infinity"]
