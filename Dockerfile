FROM debian:wheezy
ENV TERRAFORM_VERSION=0.10.2
ENV TERRAFORM_URL=https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip

RUN apt-get update && apt-get install -yq unzip curl python-pip

RUN curl ${TERRAFORM_URL} > terraform.zip&& \
    unzip terraform.zip && \
    mv terraform /usr/local/bin/terraform

RUN pip install awscli
RUN mkdir terraform/
ADD . terraform

WORKDIR terraform

CMD scripts/bootstrap.sh
