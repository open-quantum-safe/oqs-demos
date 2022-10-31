## Transport Layer Security (TLS) Demo

### Generate Certificates:

All necessary commands are encapsulated in gen_cert.sh. In order to change the encryption algorith, change the term following "-newkey" flag in lines 3 and 5. To execute, navigate to ./certs and run the following command:

    ./gen_cert.sh

### Startup TLS Server:

Open one terminal and run the following command:

    ./init.sh

The following commands will be run by the shell script:

    sudo docker-compose pull
    sudo docker-compose up --build -d
    sudo docker-compose ps

### Query TLS Server:

In a second terminal, run the following command:
	
    curl -k https://localhost:10000

### Terminate TLS Server:

In a second terminal, run the following command:
    
    ./kill.sh

The following commands will be run by the shell script:

    sudo docker kill $(sudo docker ps -q)
    sudo docker container prune -f
