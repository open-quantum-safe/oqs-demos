import json
import sys
import subprocess
import os

# Parameter checks already done in shellscript

with open("assignments.json", "r") as f:
   jsoncontents = f.read();

assignments = json.loads(jsoncontents)
for sig in assignments:
    print("Testing %s:" % (sig))
    for kem in assignments[sig]:
       # assemble testing command
       cmd = "docker run -v "+os.path.abspath(os.getcwd())+"/ca:/ca -it "+sys.argv[1]+" curl --cacert /ca/CA.crt https://test.openquantumsafe.org:"+str(assignments[sig][kem])
       if kem!="*": # don't prescribe KEM
          cmd=cmd+" --curves "+kem
       dockerrun = subprocess.run(cmd.split(" "),stdout=subprocess.PIPE,stderr=subprocess.PIPE)
       if dockerrun.returncode != 0 or not (b"Successfully" in dockerrun.stdout):
          print("Error executing %s (Output: %s). Terminating." % (cmd, dockerrun.stdout))
          exit(1)
       else:
          print("    Tested KEM %s successfully." % (kem))
    print("  Successfully concluded testing "+sig) 
print("All tests successfully passed.")


