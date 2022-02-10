import json
import sys
import subprocess
import os
import re

# Parameter checks already done in shellscript

if len(sys.argv) != 2:
   print("Usage: python3 testrun.py <path-to-assignments.json>. Exiting.")
   exit(-1)

with open(sys.argv[1], "r") as f:
   jsoncontents = f.read();

assignments = json.loads(jsoncontents)
print("signature algorithm (name), KEM algorithm (name), conn established (bool), InitialHandhake (ms), FullHandshakeFlight (ms), Handshake data (bytes), UDP packets received (count), UDP packets sent (count), UDP data received (bytes)")
for sig in assignments:
    for kem in assignments[sig]:
      if kem != "*":
       # assemble testing command
       cmd = "./reach.sh"
       env = os.environ.copy()
       env["OQS_QUIC_PORT"] = str(assignments[sig][kem])
       env["SSL_DEFAULT_GROUPS"] = kem
       run = subprocess.run(cmd.split(" "),env=env,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
       outstr = run.stdout.decode()
       #print(outstr)
       nrs = re.findall('\d+', outstr)
       if run.returncode != 0 or not (b"h3    reachable" in run.stdout):
           reached = "0,0,0,0,"+",".join(nrs[1:4])
       else:
           reached = "1,"+",".join(nrs[3:9])
       print("%s,%s,%s" % (sig, kem, reached))
    print("  Successfully concluded testing "+sig)
print("All tests successfully passed.")


