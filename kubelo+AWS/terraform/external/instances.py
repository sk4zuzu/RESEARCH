
import boto3
import json

from terraform_external_data import terraform_external_data

@terraform_external_data
def instances(query):
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
        "json": json.dumps([
            instance.private_dns_name
            for instance in running_instances
        ]),
    }

if __name__ == "__main__":
    instances()

# vim:ts=4:sw=4:et:syn=python:
