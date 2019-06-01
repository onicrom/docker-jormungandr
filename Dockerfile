FROM ubuntu:bionic
LABEL MAINTAINER Kyle O <kyleo[at]0b10[dot]mx>
LABEL description="Build or rebuild and run the IOHK Cardano rust node -- https://github.com/input-output-hk/jormungandr " 

ARG BRANCH=master
ARG NODES=1
ARG ACCTS=1
ARG PREFIX=/woo
ENV ENV_BRANCH=${BRANCH}
ENV ENV_NODES=${NODES}
ENV ENV_ACCTS=${ACCTS}
ENV ENV_PREFIX=${PREFIX}

# install ubuntu pre-reqs
RUN apt-get update && \
    apt-get install -y build-essential pkg-config git curl libssl-dev bash telnet netcat-openbsd tcpdump net-tools && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# install rust
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y && \
    /bin/bash -c "source $HOME/.cargo/env;rustup install stable;rustup default stable"

# create some dirs
RUN mkdir -p ${ENV_PREFIX}/src ${ENV_PREFIX}/bin ${ENV_PREFIX}/log ${ENV_PREFIX}/etc/cert ${ENV_PREFIX}/etc/key

# build jormungandr
RUN cd ${ENV_PREFIX}/src && \
    git clone https://github.com/input-output-hk/jormungandr.git && \
    cd jormungandr && \
    printf "####\n# building branch: ${ENV_BRANCH}\n####\n" && \
    git checkout ${ENV_BRANCH} && \
    git submodule update --init --recursive && \
    /bin/bash -c "source $HOME/.cargo/env;rustup update;cargo install --force"

# expose the rest ports
EXPOSE 4431-4439
# export the node ports
EXPOSE 8291-8299

# add create_network.sh -- creates keys and genesis
COPY scripts/create_network.sh ${ENV_PREFIX}/bin/
COPY scripts/start_network.sh ${ENV_PREFIX}/bin/
COPY templates/template_config_node.yaml ${ENV_PREFIX}/etc/
COPY templates/config_node1.yaml  ${ENV_PREFIX}/etc/
COPY templates/template_secret.yaml ${ENV_PREFIX}/etc/
RUN /bin/bash ${ENV_PREFIX}/bin/create_network.sh ${ENV_PREFIX} ${ENV_NODES} ${ENV_ACCTS}


ENTRYPOINT /bin/bash ${ENV_PREFIX}/bin/start_network.sh ${ENV_PREFIX}
CMD ["/bin/bash", "/woo/bin/start_network.sh", "/woo"]
#CMD ["sleep", "infinity"]
