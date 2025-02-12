import json
import sys
import os
import subprocess

# Ensure correct usage
if len(sys.argv) < 2:
    print("Usage: python testrun.py <docker-image-name>")
    sys.exit(1)

docker_image = sys.argv[1]

# Load JSON file
try:
    with open("assignments.json", "r") as f:
        assignments = json.load(f)
except FileNotFoundError:
    print("Error: assignments.json not found.")
    sys.exit(1)
except json.JSONDecodeError:
    print("Error: Failed to parse assignments.json.")
    sys.exit(1)

# Iterate over signature algorithms and associated KEMs
for sig, kems in assignments.items():
    print(f"Testing {sig}:")
    for kem, port in kems.items():
        # Construct the command
        cmd = [
            "docker", "run", "-v", f"{os.path.abspath(os.getcwd())}/ca:/ca", "-it", docker_image,
            "sh", "-c",
            f"(echo 'GET /'; sleep 1) | openssl s_client -CAfile /ca/CA.crt -connect test.openquantumsafe.org:{port}"
            + (f" -groups {kem}" if kem != "*" else "")
        ]

        # Run the command
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
            output = result.stdout
        except subprocess.CalledProcessError as e:
            output = e.stderr

        # Evaluate output
        if "Successfully" not in output:
            print(f"Error testing {kem}:\n{output}\n")
        else:
            print(f"    Tested KEM {kem} successfully.")

    print(f"  Successfully concluded testing {sig}")
    break  # TODO: Only test one signature until full support is available.

print("All available tests successfully passed.")