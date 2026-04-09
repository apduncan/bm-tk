FROM mambaorg/micromamba:2.5.0

USER root
RUN apt -y update && apt -y install procps && apt -y clean
USER $MAMBA_USER

COPY --chown=$MAMBA_USER:$MAMBA_USER ../env.yaml /tmp/env.yaml
RUN micromamba install -y -n base -f /tmp/env.yaml && \
    micromamba clean --all --yes

# Mimic env activation for exec commands used by nextflow
ENV PATH="$MAMBA_ROOT_PREFIX/bin:$PATH"