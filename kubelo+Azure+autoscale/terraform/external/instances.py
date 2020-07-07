
import subprocess
import textwrap
import json

from terraform_external_data import terraform_external_data

@terraform_external_data
def instances(query):
    command = textwrap.dedent("""
    az vmss list-instances \\
        --resource-group {rg_name} \\
        --name {vmss_name} \\
        --output json
    """.format(**query))

    output = json.loads(
        subprocess.check_output(command, shell=True).decode("utf-8"),
    )

    return {
        "json": json.dumps(sorted(
            item["osProfile"]["computerName"]
            for item in output
         ))
    }

if __name__ == "__main__":
    instances()

# vim:ts=4:sw=4:et:syn=python:
