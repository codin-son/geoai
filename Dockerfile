FROM quay.io/jupyter/base-notebook:latest

# -------------------------------------------------------
# 1. Install system-level packages (minimal, just git)
# -------------------------------------------------------
USER root
RUN apt-get update && \
    apt-get install -y git && \
    rm -rf /var/lib/apt/lists/*

# -------------------------------------------------------
# 2. Install geospatial Python packages via conda (base env)
# -------------------------------------------------------
RUN mamba install -n base -c conda-forge \
    geoai \
    overturemaps -y && \
    fix-permissions "${CONDA_DIR}"

# -------------------------------------------------------
# 3. Environment variables
# -------------------------------------------------------
ENV PROJ_LIB=/opt/conda/share/proj
ENV GDAL_DATA=/opt/conda/share/gdal
ENV LOCALTILESERVER_CLIENT_PREFIX='proxy/{port}'

# -------------------------------------------------------
# 4. Copy source code (do this *after* package installs to improve caching)
# -------------------------------------------------------
COPY . /home/jovyan/geoai
WORKDIR /home/jovyan/geoai


# -------------------------------------------------------
# 5. Build and install geoai from source
# -------------------------------------------------------
# Prevent setuptools_scm issues if .git is missing
ENV SETUPTOOLS_SCM_PRETEND_VERSION_FOR_GEOAI=0.0.0

RUN rm -rf /home/jovyan/geoai/geoai.egg-info && \
    pip install . && \
    mkdir -p /home/jovyan/work && \
    fix-permissions /home/jovyan

# -------------------------------------------------------
# 6. Set back to default user
# -------------------------------------------------------
WORKDIR /home/jovyan
USER jovyan


# -------------------------------------------------------
# 7. Run the docker container
# -------------------------------------------------------
# docker run -it -p 8888:8888 -v $(pwd):/home/jovyan/work giswqs/geoai:latest