import common
import os
import json

# Script assumes nginx to have been built for this platform using build-ubuntu.sh

############# Configuration section starting here

# This is where the explanation HTML code is
TEMPLATE_FILE="index-template"
CHROMIUM_TEMPLATE_FILE="chromium-template"

# This is where nginx is (to be) installed
BASEPATH="/opt/nginx/"

# This is the (relative to BASEPATH) path of all certificates
PKIPATH="pki"

# This is the port where all algorithms start to be present(ed)
STARTPORT=6000

# This is the local location of the OQS-enabled OpenSSL
OPENSSL="/tmp/opt/openssl/apps/openssl"

# This is the local OQS-OpenSSL config file
OPENSSL_CNF="/tmp/opt/openssl/apps/openssl.cnf"

# This is the fully-qualified domain name of the server to be set up
# Ensure this is in sync with contents of ext-csr.conf file
TESTFQDN="test.openquantumsafe.org"

# This is the local folder where the root CA (key and cert) resides
CAROOTDIR="root"

# This is the file containing the SIG/KEM/port assignments
ASSIGNMENT_FILE="assignments.json"

# The list of chromium-supported KEMs:
chromium_algs = ["p256_bikel1", "p256_frodo640aes", "p256_kyber90s512", "p256_ntru_hps2048509", "p256_lightsaber", "p256_sidhp434", "p256_sikep434"]

############# Functions starting here

# Generate cert chain (server and CA for a given sig alg:
# srv crt/key wind up in '<path>/<sigalg>_srv.crt|key
def gen_cert(sig_alg):
   # first check whether we already have a root CA; if not create it
   if not os.path.exists(CAROOTDIR):
           os.mkdir(CAROOTDIR)
           common.run_subprocess([OPENSSL, 'req', '-x509', '-new',
                                     '-newkey', "rsa:4096",
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

def write_nginx_config(f, i, cf, port, sig, k):
           f.write("server {\n")
           f.write("    listen              0.0.0.0:"+str(port)+" ssl;\n\n")
           f.write("    server_name         "+TESTFQDN+";\n")
           f.write("    access_log          "+BASEPATH+"logs/"+sig+"-access.log;\n")
           f.write("    error_log           "+BASEPATH+"logs/"+sig+"-error.log;\n\n")
           f.write("    ssl_certificate     "+BASEPATH+PKIPATH+"/"+sig+"_srv.crt;\n")
           f.write("    ssl_certificate_key "+BASEPATH+PKIPATH+"/"+sig+"_srv.key;\n\n")
           f.write("    ssl_protocols       TLSv1.3;\n")
           if k!="*" :  
              f.write("    ssl_ecdh_curve      "+k+";\n")
           f.write("    location / {\n")
           f.write("            ssi    on;\n")
           if k!="*" :  
              f.write("            set    $oqs_alg_name \""+sig+"-"+k+"\";\n")
           f.write("            root   html;\n")
           f.write("            index  success.html;\n")
           f.write("    }\n\n")

           f.write("}\n\n")
           # activate for more boring links-only display:
           #i.write("<li><a href=https://"+TESTFQDN+":"+str(port)+">"+sig+"/"+k+" ("+str(port)+")</a></li>\n")
           #if k in chromium_algs:
           #   cf.write("<li><a href=https://"+TESTFQDN+":"+str(port)+">"+sig+"/"+k+" ("+str(port)+")</a></li>\n")

           # deactivate if you don't like tables:
           i.write("<tr><td>"+sig+"</td><td>"+k+"</td><td>"+str(port)+"</td><td><a href=https://"+TESTFQDN+":"+str(port)+">"+sig+"/"+k+"</a></td></tr>\n")
           if k in chromium_algs and not ("_" in sig and (sig.startswith("p") or (sig.startswith("rsa")))):
               cf.write("<tr><td>"+sig+"</td><td>"+k+"</td><td>"+str(port)+"</td><td><a href=https://"+TESTFQDN+":"+str(port)+">"+sig+"/"+k+"</a></td></tr>\n")


# generates nginx config
def gen_conf(filename, indexbasefilename, chromiumfilename):
   port = STARTPORT
   assignments={}
   i = open(indexbasefilename, "w")
   cf = open(chromiumfilename, "w")
   # copy baseline templates
   with open(TEMPLATE_FILE, "r") as tf:
     for line in tf:
       i.write(line)
   with open(CHROMIUM_TEMPLATE_FILE, "r") as ctf:
     for line in ctf:
       cf.write(line)

   with open(filename, "w") as f:
     # baseline config
     f.write("worker_processes  auto;\n")
     f.write("worker_rlimit_nofile  10000;\n")
     f.write("events {\n")
     f.write("    worker_connections  32000;\n")
     f.write("}\n")
     f.write("\n")
     f.write("http {\n")
     f.write("    include       conf/mime.types;\n");
     f.write("    default_type  application/octet-stream;\n")
     f.write("    keepalive_timeout  65;\n\n")
     # plain server for base information
     f.write("server {\n")
     f.write("    listen      80;\n")
     f.write("    server_name "+TESTFQDN+";\n")
     f.write("    access_log  /opt/nginx/logs/80-access.log;\n")
     f.write("    error_log   /opt/nginx/logs/80-error.log;\n\n")
     f.write("    location / {\n")
     f.write("            root   html;\n")
     f.write("            index  "+indexbasefilename+";\n")
     f.write("    }\n")
     f.write("}\n")
     f.write("server {\n")
     f.write("    listen      443 ssl;\n")
     f.write("    server_name "+TESTFQDN+";\n")
     f.write("    access_log  /opt/nginx/logs/443-access.log;\n")
     f.write("    error_log   /opt/nginx/logs/443-error.log;\n\n")
     f.write("    ssl_certificate     /etc/letsencrypt/live/"+TESTFQDN+"/fullchain.pem;\n")
     f.write("    ssl_certificate_key /etc/letsencrypt/live/"+TESTFQDN+"/privkey.pem;\n\n")
     f.write("    location / {\n")
     f.write("            root   html;\n")
     f.write("            index  "+indexbasefilename+";\n")
     f.write("    }\n")
     f.write("}\n")

     f.write("\n")
     for sig in common.signatures:
        assignments[sig]={}
        assignments[sig]["*"]=port
        write_nginx_config(f, i, cf, port, sig, "*")
        port = port+1
        for kex in common.key_exchanges:
           # replace oqs_kem_default with X25519:
           k = "X25519" if kex=='oqs_kem_default' else kex
           write_nginx_config(f, i, cf, port, sig, k)
           assignments[sig][k]=port
           port = port+1
     f.write("}\n")
   # deactivate if you don't like tables:
   i.write("</table>\n")
   i.write("</body></html>\n")
   i.close()
   cf.write("</table>\n")
   cf.write("</body></html>\n")
   cf.close()
   with open(ASSIGNMENT_FILE, 'w') as outfile:
      json.dump(assignments, outfile)

def main():
   # first generate certs for all supported sig algs:
   for sig in common.signatures:
      gen_cert(sig)
   # now do conf and HTML files
   gen_conf("interop.conf", "index-base.html", "chromium-base.html")

main()
