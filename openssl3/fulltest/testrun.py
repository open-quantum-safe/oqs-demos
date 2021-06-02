import json
import sys
import subprocess
import os
import time

# Parameter checks already done in shellscript

with open("assignments.json", "r") as f:
   jsoncontents = f.read();

assignments = json.loads(jsoncontents)
ok=True
for sig in assignments:
    print("Testing %s:" % (sig))
    for kem in assignments[sig]:
    # if not "_" in kem: # hybrids not yet supported in OSSL3-oqsprovider: TBD
       # assemble testing command
       cmd = "docker run -v "+os.path.abspath(os.getcwd())+"/ca:/ca -it "+sys.argv[1]+" sh -c \"(echo \'GET /\'; sleep 1) | openssl s_client -CAfile /ca/CA.crt -connect test.openquantumsafe.org:"+str(assignments[sig][kem])
       if kem!="*": # don't prescribe KEM
          cmd=cmd+" -groups "+kem
       cmd=cmd+"\""
       output = os.popen(cmd).read()
       if not ("Successfully" in output):
           print("Error: " +output)
           print("    Failure testing KEM %s." % (kem))
           ok=False
       else:
          print("    Tested KEM %s successfully." % (kem))
    print("  Concluded testing "+sig)
    break # only a single sig round makes sense until all OQS sigs are supported by OSSL3-oqsprovider (TBD)
if (ok):
   print("All available tests successfully passed.")
else:
   print("Some failures.")


