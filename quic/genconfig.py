import common
import os
import json
import sys

############# Configuration section starting here

# This is where nginx is (to be) installed
BASEPATH="/usr/local/nginx/"

# This is the (relative to BASEPATH) path of all certificates
PKIPATH="certs"

# This is the port where all algorithms start to be present(ed)
STARTPORT=6000

# This is the local location of the OQS-enabled OpenSSL
OPENSSL="/opt/oqs-openssl-quic/.openssl/bin/openssl"

# This is the local OQS-OpenSSL config file
OPENSSL_CNF="/opt/oqs-openssl-quic/.openssl/openssl.cnf"

# This is the fully-qualified domain name of the server to be set up
# Ensure this is in sync with contents of ext-csr.conf file
TESTFQDN="nginx"

# This is the local folder where the root CA (key and cert) resides
CAROOTDIR="root"

# This contains all algorithm/port assignments
ASSIGNMENT_FILE = "assignments.json"

############# Functions starting here

# Generate cert chain (server and CA for a given sig alg:
# srv crt/key wind up in '<path>/<sigalg>_srv.crt|key
def gen_cert(sig_alg):
   # first check whether we already have a root CA; if not create it
   if not os.path.exists(CAROOTDIR):
           os.mkdir(CAROOTDIR)
           common.run_subprocess([OPENSSL, 'req', '-x509', '-new',
                                     '-newkey', "rsa:3072",
                                     '-keyout', os.path.join(CAROOTDIR, "CA.key"),
                                     '-out', os.path.join(CAROOTDIR, "CA.crt"),
                                     '-nodes',
                                         '-subj', '/CN=oqstest_CA',
                                         '-days', '500',
                                     '-config', OPENSSL_CNF])
           print("New root cert residing in %s." % (os.path.join(CAROOTDIR, "CA.crt")))

   # now generate suitable server keys signed by that root; adapt algorithm names to std ossl 
   if sig_alg == 'rsa3072':
       ossl_sig_alg_arg = 'rsa:3072'
   elif sig_alg == 'ecdsap256':
       common.run_subprocess([OPENSSL, "ecparam", "-name", "prime256v1", "-out", os.path.join(PKIPATH, "prime256v1.pem")])
       ossl_sig_alg_arg = 'ec:{}'.format(os.path.join(PKIPATH, "prime256v1.pem"))
   else:
       ossl_sig_alg_arg = sig_alg
   # generate server key and CSR
   common.run_subprocess([OPENSSL, 'req', '-new',
                              '-newkey', ossl_sig_alg_arg,
                              '-keyout', os.path.join(PKIPATH, '{}_srv.key'.format(sig_alg)),
                              '-out', os.path.join(PKIPATH, '{}_srv.csr'.format(sig_alg)),
                              '-nodes',
                              '-subj', '/CN='+TESTFQDN,
                              '-config', OPENSSL_CNF])
   # generate server cert off common root
   common.run_subprocess([OPENSSL, 'x509', '-req',
                                  '-in', os.path.join(PKIPATH, '{}_srv.csr'.format(sig_alg)),
                                  '-out', os.path.join(PKIPATH, '{}_srv.crt'.format(sig_alg)),
                                  '-CA', os.path.join(CAROOTDIR, 'CA.crt'),
                                  '-CAkey', os.path.join(CAROOTDIR, 'CA.key'),
                                  '-CAcreateserial',
                                  '-extfile', 'ext-csr.conf', 
                                  '-extensions', 'v3_req',
                                  '-days', '365'])

def write_nginx_config(f, port, sig, k):
           f.write("server {\n")
           f.write("    listen              0.0.0.0:"+str(port)+" quic reuseport;\n\n")
           f.write("    server_name         "+TESTFQDN+";\n")
           f.write("    access_log          "+BASEPATH+"logs/"+sig+"-access.log;\n")
           f.write("    error_log           "+BASEPATH+"logs/"+sig+"-error.log;\n\n")
           f.write("    ssl_certificate     "+BASEPATH+PKIPATH+"/"+sig+"_srv.crt;\n")
           f.write("    ssl_certificate_key "+BASEPATH+PKIPATH+"/"+sig+"_srv.key;\n\n")
           f.write("    ssl_protocols       TLSv1.3;\n")
           if k!="*" :  
              f.write("    ssl_ecdh_curve      "+k+";\n")
           f.write("}\n\n")


# generates nginx config
def gen_conf(filename):
   port = STARTPORT
   assignments={}

   with open(filename, "w") as f:
     # baseline config
     f.write("worker_processes  1;\n")
     f.write("worker_rlimit_nofile  5000;\n")
     f.write("events {\n")
     f.write("    worker_connections  32000;\n")
     f.write("}\n")
     f.write("\n")
     f.write("http {\n")
     f.write("        log_format quic '$remote_addr - $remote_user [$time_local] '\n")
     f.write("                   '\"$request\" $status $body_bytes_sent '\n")
     f.write("                   '\"$http_referer\" \"$http_user_agent\" \"$http3\"';\n")
     f.write("server {\n")
     f.write("    listen 5999 default_server;\n")
     f.write("    listen [::]:5999 default_server;\n")
     f.write("    root /usr/local/nginx/html;\n")
     f.write("    index index.html;\n")
     f.write("    server_name "+TESTFQDN+";\n")
     f.write("    location / {\n")
     f.write("       try_files $uri $uri/ =404;\n")
     f.write("    }\n")
     f.write("}\n\n")


     f.write("\n")
     for sig in common.signatures:
        assignments[sig]={}
        assignments[sig]["*"]=port
        write_nginx_config(f, port, sig, "*")
        port = port+1
        for kex in common.key_exchanges:
           # replace oqs_kem_default with X25519:
           k = "X25519" if kex=='oqs_kem_default' else kex
           write_nginx_config(f, port, sig, k)
           assignments[sig][k]=port
           port = port+1
     f.write("}\n")
   with open(ASSIGNMENT_FILE, 'w') as outfile:
      json.dump(assignments, outfile)


def main():
   global TESTFQDN
   # if a parameter is given, it's the FQDN for the server
   if len(sys.argv)>1:
      TESTFQDN = sys.argv[1]
   print("Generating for FQDN %s" % (TESTFQDN))
   # first generate certs for all supported sig algs:
   for sig in common.signatures:
      gen_cert(sig)
   # now do conf and HTML files
   gen_conf("oqs-nginx.conf")

main()
