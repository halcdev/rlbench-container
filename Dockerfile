FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu20.04

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-lc"]

# 1) OS deps: python build, git, and the GUI/EGL/X libs that Qt/OpenGL stacks often need
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-dev \
    build-essential cmake \
    git wget ca-certificates \
    libglib2.0-0 \
    libgl1-mesa-glx libegl1-mesa libgl1-mesa-dri mesa-utils \
 && rm -rf /var/lib/apt/lists/*

# 2) Python tooling
RUN python3 -m pip install --upgrade pip setuptools wheel

# 3) Install Python deps
COPY requirements.txt /tmp/requirements.txt
RUN pip3 install -r /tmp/requirements.txt

# 4) Install CoppeliaSim 4.1.0 (Edu) for Ubuntu 20.04
# NOTE: If this URL ever changes, we’ll update it—this is the “paper exact” requirement.
ENV COPPELIASIM_ROOT=/opt/CoppeliaSim
RUN mkdir -p ${COPPELIASIM_ROOT} && cd /opt && \
    wget -q https://downloads.coppeliarobotics.com/V4_1_0/CoppeliaSim_Edu_V4_1_0_Ubuntu20_04.tar.xz && \
    tar -xf CoppeliaSim_Edu_V4_1_0_Ubuntu20_04.tar.xz -C ${COPPELIASIM_ROOT} --strip-components 1 && \
    rm -f CoppeliaSim_Edu_V4_1_0_Ubuntu20_04.tar.xz

# 5) PyRep (from source, pinned to repo default branch)
RUN cd /opt && \
    git clone https://github.com/stepjam/PyRep.git && \
    cd /opt/PyRep && \
    pip3 install .

# 6) RLBench (install as regular package, NOT editable)
RUN cd /opt && \
    git clone https://github.com/stepjam/RLBench.git && \
    cd /opt/RLBench && \
    pip3 install .

# 7) Runtime env vars for CoppeliaSim
ENV LD_LIBRARY_PATH=${COPPELIASIM_ROOT}:${LD_LIBRARY_PATH}
# ---- Force safe headless Qt ----
ENV QT_QPA_PLATFORM=offscreen
ENV QT_PLUGIN_PATH=
ENV QT_QPA_PLATFORM_PLUGIN_PATH=

WORKDIR /workspace
