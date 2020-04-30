
import boto3
import json

from terraform_external_data import terraform_external_data

@terraform_external_data
def public(query):
    ec2 = boto3.session.Session().resource("ec2")

    running_instances = ec2.instances.filter(Filters=[
        {
            "Name": "instance-state-name",
            "Values": ["running"],
        },
        {
            "Name": "vpc-id",
            "Values": [query["vpc_id"]],
        },
        {
            "Name": "tag:aws:autoscaling:groupName",
            "Values": [query["asg_id"]],
        },
    ])

    return {
        "json": json.dumps(sorted(
            instance.public_ip_address
            for instance in running_instances
            if instance.public_ip_address
        )),
    }

if __name__ == "__main__":
    public()

# vim:ts=4:sw=4:et:syn=python:
