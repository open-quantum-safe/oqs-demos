import logging
import os
import subprocess
import time

from locust import HttpUser, task, between
from urllib.parse import urlparse


url = str(os.environ.get("HOST"))
parsed_url = urlparse(url)
host = parsed_url.hostname
port = parsed_url.port

logger_level = str(os.environ.get("LOGGER_LEVEL"))
logger = logging.getLogger(__name__)
logger.setLevel(logger_level)

group = str(os.environ.get("GROUP"))

class QscNginxUser(HttpUser):
    wait_time = between(1, 2)

    def on_start(self):
        self.client.base_url = host
        logger.info("Starting Locust test using OpenSSL for TLS connection")

    def make_post_quantum_request_with_openssl(self, endpoint):
        try:
            logger.debug(f"Making request to {url}{endpoint} with group {group}")
            host_and_port = host + ":" + str(port)
            http_headers="Post-quantum"
            request_name = f"Group {group} {endpoint}"

            start = time.time()
            result = subprocess.run(
                ["openssl", "s_client", "-groups", group, "-connect", host_and_port, "-ign_eof"],
                input=f"GET {endpoint} HTTP/1.1\r\n"
                      f"Host: {host}\r\n"
                      f"User-Agent: {http_headers}\r\n"
                      f"Connection: close\r\n\r\n",
                capture_output=True, text=True
            )
            total = int((time.time() - start) * 1000)
            logger.debug(f"result: {result.stdout}")
            response_output = result.stdout
            content_length = 0
            headers, _, body = response_output.partition("\r\n\r\n")
            for line in headers.splitlines():
                if line.lower().startswith("content-length:"):
                    content_length = int(line.split(":")[1].strip())
                    break
            if result.returncode == 0:
                logger.debug(f"Request to {endpoint} succeeded")
                logger.debug(f"Response:\n{result.stdout}")
                self.environment.events.request.fire(
                    request_type="GET",
                    name=request_name,
                    response_time=total,
                    response_length=content_length,
                    exception=None,
                )
            else:
                logger.error(f"Request to {endpoint} failed with return code {result.returncode}")
                logger.error(f"Error:\n{result.stderr}")
                self.environment.events.request.fire(
                    request_type="GET",
                    name=host+endpoint,
                    response_time=total,
                    response_length=content_length,
                    exception=f"Error Code: {result.returncode} - {result.stderr}"
                )

        except subprocess.CalledProcessError as e:
            logger.error(f"Error executing OpenSSL command: {e}")

    # Change the following methods to use the make_post_quantum_request_with_openssl method where
    # first parameter is the endpoint and the second parameter is the group (kyber768 by default)
    @task(1)
    def post_quantum_customers(self):
        self.make_post_quantum_request_with_openssl("/customers")

    @task(1)
    def post_quantum_devices(self):
        self.make_post_quantum_request_with_openssl("/devices")



