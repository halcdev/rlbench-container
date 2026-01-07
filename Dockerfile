FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu20.04

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-lc"]

# 1) OS deps: python build, git, and the GUI/EGL/X libs that Qt/OpenGL stacks often need
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-dev \
    build-essential cmake \
    git wget ca-certificates \
    libglib2.0-0 libsm6 libxext6 libxrender1 \
    libxkbcommon-x11-0 libxcb-xinerama0 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 \
    libxcb-randr0 libxcb-render-util0 libxcb-xfixes0 libxcb-shape0 libxcb-sync1 \
    libx11-xcb1 libxcb1 \
    libgl1-mesa-glx libegl1-mesa libgl1-mesa-dri mesa-utils \
    xvfb \
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

# 6) RLBench (from source)
RUN cd /opt && \
    git clone https://github.com/stepjam/RLBench.git && \
    cd /opt/RLBench && \
    pip3 install -e . --no-deps

# 7) Runtime env vars for CoppeliaSim
ENV LD_LIBRARY_PATH=${COPPELIASIM_ROOT}:${LD_LIBRARY_PATH}
ENV QT_QPA_PLATFORM_PLUGIN_PATH=${COPPELIASIM_ROOT}

WORKDIR /workspace
