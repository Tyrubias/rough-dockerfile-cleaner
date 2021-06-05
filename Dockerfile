FROM nvidia/cuda:11.2.2-cudnn8-devel-ubuntu20.04 AS builder
LABEL authors="Christoph Schranz <christoph.schranz@salzburgresearch.at>, Mathematical Michael <consistentbayes@gmail.com>"
RUN chmod 1777 /tmp && chmod 1777 /var/tmp
FROM builder AS base
LABEL maintainer="Jupyter Project <jupyter@googlegroups.com>"
ARG NB_USER="jovyan"
ARG NB_UID="1000"
ARG NB_GID="100"
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
USER root
ARG conda_version="4.10.1"
ARG miniforge_patch_number="0"
ARG miniforge_arch="x86_64"
ARG miniforge_python="Mambaforge"
ARG miniforge_version="4.10.1-0"
ARG miniforge_installer="Mambaforge-${conda_version}-${miniforge_patch_number}-Linux-x86_64.sh"
ARG miniforge_checksum="d4065b376f81b83cfef0c7316f97bb83337e4ae27eb988828363a578226e3a62"
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update --yes && apt-get install --yes --no-install-recommends tini wget ca-certificates sudo locales fonts-liberation run-one && apt-get clean && rm -rf /var/lib/apt/lists/* && echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen
ENV CONDA_DIR=/opt/conda SHELL=/bin/bash NB_USER=$NB_USER NB_UID=$NB_UID NB_GID=$NB_GID LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8
ENV PATH=/opt/conda/bin:$PATH HOME=/home/$NB_USER CONDA_VERSION="4.10.1" MINIFORGE_VERSION="${conda_version}-${miniforge_patch_number}"
COPY fix-permissions /usr/local/bin/fix-permissions
RUN chmod a+rx /usr/local/bin/fix-permissions && sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc && echo 'eval "$(command conda shell.bash hook 2> /dev/null)"' >> /etc/skel/.bashrc && echo "auth requisite pam_deny.so" >> /etc/pam.d/su && sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers && sed -i.bak -e 's/^%sudo/#%sudo/' /etc/sudoers && useradd -l -m -s /bin/bash -N -u $NB_UID $NB_USER && mkdir -p /opt/conda && chown $NB_USER:$NB_GID /opt/conda && chmod g+w /etc/passwd && fix-permissions "/home/$NB_USER" && fix-permissions "/opt/conda"
USER $NB_UID
ARG PYTHON_VERSION=default
RUN mkdir "/home/$NB_USER/work" && fix-permissions "/home/$NB_USER"
WORKDIR /tmp
RUN wget --quiet "https://github.com/conda-forge/miniforge/releases/download/${conda_version}-${miniforge_patch_number}/${miniforge_python}-${miniforge_version}-Linux-${miniforge_arch}.sh" && echo "d4065b376f81b83cfef0c7316f97bb83337e4ae27eb988828363a578226e3a62 *${miniforge_python}-${miniforge_version}-Linux-${miniforge_arch}.sh" | sha256sum --check && /bin/bash "${miniforge_python}-${miniforge_version}-Linux-${miniforge_arch}.sh" -f -b -p /opt/conda && rm "${miniforge_python}-${miniforge_version}-Linux-${miniforge_arch}.sh" && echo "conda ${conda_version}" >> /opt/conda/conda-meta/pinned && conda config --system --set auto_update_conda false && conda config --system --set show_channel_urls true && if [ ! default = 'default' ]; then conda install --yes python=default; fi && conda list python | grep '^python ' | tr -s ' ' | cut -d '.' -f 1,2 | sed 's/$/.*/' >> /opt/conda/conda-meta/pinned && conda install --quiet --yes "conda=${conda_version}" 'pip' && conda update --all --quiet --yes && conda clean --all -f -y && rm -rf /home/$NB_USER/.cache/yarn && fix-permissions "/opt/conda" && fix-permissions "/home/$NB_USER" && conda install --quiet --yes 'notebook=6.3.0' 'jupyterhub=1.4.1' 'jupyterlab=3.0.15' && conda clean --all -f -y && npm cache clean --force && jupyter notebook --generate-config && jupyter lab clean && rm -rf /home/$NB_USER/.cache/yarn && fix-permissions "/opt/conda" && fix-permissions "/home/$NB_USER"
EXPOSE 8888
ENTRYPOINT ["tini", "-g", "--"]
CMD ["start-notebook.sh"]
COPY start.sh start-notebook.sh start-singleuser.sh /usr/local/bin/
COPY jupyter_notebook_config.py /etc/jupyter/
USER root
RUN sed -re "s/c.NotebookApp/c.ServerApp/g" /etc/jupyter/jupyter_notebook_config.py > /etc/jupyter/jupyter_server_config.py && fix-permissions /etc/jupyter/
USER $NB_UID
WORKDIR /home/$NB_USER
FROM base AS minimal
LABEL maintainer="Jupyter Project <jupyter@googlegroups.com>"
USER root
RUN apt-get update --yes && apt-get install --yes --no-install-recommends build-essential vim-tiny git inkscape libsm6 libxext-dev libxrender1 lmodern netcat texlive-xetex texlive-fonts-recommended texlive-plain-generic tzdata unzip nano-tiny && apt-get clean && rm -rf /var/lib/apt/lists/* && update-alternatives --install /usr/bin/nano nano /bin/nano-tiny 10
USER $NB_UID
FROM minimal AS scipy
LABEL maintainer="Jupyter Project <jupyter@googlegroups.com>"
USER root
RUN apt-get update --yes && apt-get install --yes --no-install-recommends ffmpeg dvipng cm-super && apt-get clean && rm -rf /var/lib/apt/lists/*
USER $NB_UID
RUN conda install --quiet --yes 'beautifulsoup4=4.9.*' 'bokeh=2.3.*' 'bottleneck=1.3.*' 'cloudpickle=1.6.*' 'conda-forge::blas=*=openblas' 'cython=0.29.*' 'dask=2021.4.*' 'dill=0.3.*' 'h5py=3.2.*' 'ipympl=0.7.*' 'ipywidgets=7.6.*' 'matplotlib-base=3.4.*' 'numba=0.53.*' 'numexpr=2.7.*' 'pandas=1.2.*' 'patsy=0.5.*' 'protobuf=3.15.*' 'pytables=3.6.*' 'scikit-image=0.18.*' 'scikit-learn=0.24.*' 'scipy=1.6.*' 'seaborn=0.11.*' 'sqlalchemy=1.4.*' 'statsmodels=0.12.*' 'sympy=1.8.*' 'vincent=0.4.*' 'widgetsnbextension=3.5.*' 'xlrd=2.0.*' && conda clean --all -f -y && fix-permissions "${CONDA_DIR}" && fix-permissions "/home/${NB_USER}"
WORKDIR /tmp
RUN git clone https://github.com/PAIR-code/facets.git && jupyter nbextension install facets/facets-dist/ --sys-prefix && rm -rf /tmp/facets && fix-permissions "${CONDA_DIR}" && fix-permissions "/home/${NB_USER}"
ENV XDG_CACHE_HOME="/home/${NB_USER}/.cache/"
RUN MPLBACKEND=Agg python -c "import matplotlib.pyplot" && fix-permissions "/home/${NB_USER}"
USER $NB_UID
WORKDIR $HOME
FROM scipy AS gpu
LABEL maintainer="Christoph Schranz <christoph.schranz@salzburgresearch.at>"
RUN pip install --no-cache-dir --upgrade pip && pip install --no-cache-dir "tensorflow==2.5.0" && pip install --no-cache-dir keras && conda install --quiet --yes pyyaml mkl mkl-include setuptools cmake cffi typing && conda clean --all -f -y && fix-permissions "$CONDA_DIR" && fix-permissions "/home/$NB_USER" && pip install --no-cache-dir torch==1.8.1+cu111 torchvision==0.9.1+cu111 torchaudio==0.8.1 -f https://download.pytorch.org/whl/torch_stable.html && pip install --no-cache-dir torchviz
USER root
RUN apt-get update && apt-get install --no-install-recommends -y cmake libncurses5-dev libncursesw5-dev git && rm -rf /var/lib/apt/lists/* && git clone https://github.com/Syllo/nvtop.git /run/nvtop && mkdir -p /run/nvtop/build && cd /run/nvtop/build && (cmake .. -DNVML_RETRIEVE_HEADER_ONLINE=True 2> /dev/null || echo "cmake was not successful") && (make 2> /dev/null || echo "make was not successful") && (make install 2> /dev/null || echo "make install was not successful") && cd /tmp && rm -rf /tmp/nvtop && fix-permissions "/home/$NB_USER"
USER $NB_UID
FROM gpu AS final
COPY jupyter_notebook_config.json /etc/jupyter/
COPY jupyterlab_theme.json "/home/${NB_USER}/jupyterlab_theme.json"
