#!/usr/bin/env python3
import boto3
import time
import sys
from datetime import datetime

period = 2592000  # 30 days

AWS_REGION = 'eu-west-1'


def handler(event, context):

    session = boto3.session.Session(region_name=AWS_REGION)
    iam = session.client('iam')
    now = datetime.now().strftime("%s")
    then = (int(now) - period)

    def update_access_key_status(status):
        """
        Update key status
        """
        iam.update_access_key(
            UserName=name,
            AccessKeyId=keyid,
            Status=status
        )

    users = iam.get_paginator('list_users')

    for user in users.paginate():
        for u in user['Users']:

            name = u['UserName']
            for metadata in iam.list_access_keys(UserName=name)['AccessKeyMetadata']:
                status = metadata['Status']
                keyid = metadata['AccessKeyId']

                if status == "Active":
                    try:
                        last_used = iam.get_access_key_last_used(
                            AccessKeyId=keyid
                        )['AccessKeyLastUsed']['LastUsedDate'].strftime("%s")
                    except KeyError:
                        print("👮‍♀️ " + name + " (🗝: " + keyid +
                              ") key was never used. Disabling key.")
                        update_access_key_status("Inactive")

                    if int(last_used) <= then:
                        print("👮‍♀️ " + name + " (🗝: " + keyid + ") key was last used " +
                              str(datetime.fromtimestamp(int(last_used))) + ". Disabling key.")
                        update_access_key_status("Inactive")
                else:
                    print(name + " (🗝: " + keyid + ") already disabled.")

    return
