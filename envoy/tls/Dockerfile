 # Define global arguments
ARG DEBIAN_FRONTEND=noninteractive

#FROM openquantumsafe/envoy:latest
#FROM drouhana/envoy-oqs:envoy
FROM envoy-oqs:latest

# copy certs
COPY ./certs/servercert.pem /etc/example/servercert.pem
COPY ./certs/serverkey.pem /etc/example/serverkey.pem
COPY ./certs/CA_cert.pem /etc/example/CA_cert.pem
COPY ./envoy-https-http.yaml /etc/envoy.yaml


WORKDIR /etc/example
RUN chown "$USER" -R *

RUN chmod go+r /etc/example/servercert.pem
RUN chmod go+r /etc/example/serverkey.pem
RUN chmod go+r /etc/example/CA_cert.pem
RUN chmod go+r /etc/envoy.yaml


CMD ["envoy", "-c /etc/envoy.yaml"]
