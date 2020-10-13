
SELF := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
NAME := azure

USERNAME ?= sk4zuzu
PASSWORD ?= asd123

VPN_GW_HOST ?= kek

define IPSEC_CONF
config setup
conn $(NAME)
    keyexchange=ikev2
    type=tunnel
    leftfirewall=yes
    left=%any
    leftauth=eap-tls
    leftid=%$(USERNAME)
    right=$(VPN_GW_HOST)
    rightid=%$(VPN_GW_HOST)
    rightsubnet=0.0.0.0/0
    leftsourceip=%config
    auto=add
endef

define IPSEC_SECRETS
: P12 .p12 '$(PASSWORD)'
endef

define DOCKERFILE
FROM ubuntu:18.04

RUN apt-get -q update \
 && DEBIAN_FRONTEND=noninteractive apt-get -q install -y \
    bash \
    curl \
    mc \
    vim \
    strongswan \
    strongswan-pki \
    libstrongswan-extra-plugins

ENTRYPOINT []
CMD exec /bin/bash
endef

export

.PHONY: all

all: pki

.PHONY: pki

pki: caCert.pem $(USERNAME).p12 ipsec.secrets
	openssl x509 -in $(word 1,$^) -outform der | base64 -w0; echo

caKey.pem:
	ipsec pki --gen --outform pem > $@

caCert.pem: caKey.pem
	ipsec pki --self --in $< --dn "CN=VPN CA" --ca --outform pem > $@

$(USERNAME)Key.pem:
	ipsec pki --gen --outform pem > $@

$(USERNAME)Cert.pem: $(USERNAME)Key.pem caCert.pem caKey.pem
	ipsec pki --pub --in $(word 1,$^) | ipsec pki --issue --cacert $(word 2,$^) --cakey $(word 3,$^) --dn "CN=$(USERNAME)" --san "$(USERNAME)" --flag clientAuth --outform pem > $@

$(USERNAME).p12: $(USERNAME)Key.pem $(USERNAME)Cert.pem caCert.pem
	openssl pkcs12 -inkey $(word 1,$^) -in $(word 2,$^) -certfile $(word 3,$^) -export -out $@ -password "pass:$(PASSWORD)"

ipsec.secrets: $(USERNAME).p12
	tee $@ <<< ": P12 $< '$(PASSWORD)'"

.PHONY: build

build:
	docker build -t $(NAME)-ipsec -f- $(SELF)/ <<< "$$DOCKERFILE"
	docker run --rm -it $(NAME)-ipsec

# vim:ts=4:sw=4:noet:syn=make:
