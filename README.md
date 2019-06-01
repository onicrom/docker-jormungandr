# docker-jormungandr

Dockerfile and some scripts to build a container to run a one or multiple jormungandr (https://github.com/input-output-hk/jormungandr) node cluster

## Instructions

How to build

```bash
git clone https://github.com/onicrom/docker-jormungandr.git
cd docker-jormungandr
docker build -t a-fun-name:0.1 .
```

How to run

```bash
docker run --name woo a-fun-name:0.1
```

## Options

The default build options are
- jormungandr branch: master
- number of nodes: 1
- number of pre-funded wallets: 1

These can be overridden during the docker build process:
```bash
docker build -t a-fun-name:0.1 \
  --build-arg NODES=3 \
  --build-arg ACCTS=3 \
  --build-arg BRANCH=aweseom-new-branch .
  ```
