ARG ALPINE_VERSION=3.22
ARG PYTHON_VERSION=3.13

FROM python:${PYTHON_VERSION}-alpine${ALPINE_VERSION}

ARG NUM_WORKERS

WORKDIR /usr/src/webapp

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY webapp .

WORKDIR /usr/src/webapp/src
CMD [ "gunicorn", "-b 0.0.0.0:7000", "-w 1", "run:server" ]
