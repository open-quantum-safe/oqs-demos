## Transport Layer Security (TLS) Demo

### Generate Certificates:

All necessary commands are encapsulated in gen_cert.sh. In order to change the encryption algorithm, change the term following "-newkey" flag in lines 3 and 5. All paths in the shell script assume a standard installation of the OpenQuantumSafe OpenSSL fork in /usr/local. To execute, navigate to ./certs and run the following command:

    ./gen_cert.sh

If local installation differs in location, the individual commands can be ran with paths corrected.

### Startup TLS Server:

Open one terminal and run the following command:

    ./init.sh

The following commands will be run by the shell script:

    sudo docker-compose pull
    sudo docker-compose up --build -d
    sudo docker-compose ps

### Query TLS Server:

In a second terminal, run the following command:
	
    sudo docker run --network host -it openquantumsafe/curl curl -v -k https://localhost:10000 -e SIG_ALG=dilithium3

### Terminate TLS Server:

In a second terminal, run the following command:
    
    ./kill.sh

The following commands will be run by the shell script:

    sudo docker kill $(sudo docker ps -q)
    sudo docker container prune -f
