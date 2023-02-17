#!/usr/bin/python3.6
# -*- coding: UTF-8 -*-
 
import boto3
import csv
import codecs
 
ec2 = boto3.client(
    'ec2',
    # Update access keys and region.
    aws_access_key_id="xxxx",
    aws_secret_access_key="xxxx",
    region_name='ap-southeast-1',
    )

response = ec2.describe_instances()
with open("/root/ec2.csv", "w", encoding="utf-8-sig", newline="") as csvf:
    writer = csv.writer(csvf)
    csv_head = ["Index", "InstanceName", "Project", "Group", "APP", "LaunchTime", "InstanceID", "InstanceType", "PublicIP", "PrivateIP", "State", "KeyName", "ImageID", "Zone", "Archi", "Platform"]
    writer.writerow(csv_head)
    
    index = 0
    for i in response['Reservations']:
        for j in i['Instances']:
            index = index + 1
            if 'PublicIpAddress' not in j:
                j['PublicIpAddress'] = ""
            if 'Tags' not in j:
                j['Tags'] = []
            if 'KeyName' not in j:
                j['KeyName'] = []
            
            name = ""
            project = ""
            group = ""
            app = ""
            for dic in j['Tags']:
                #Default tag for instance name.
                if dic['Key'] == 'Name':
                    name = dic['Value']
                # Customized tag project, case sensitive.
                if dic['Key'] == 'project':
                    project = dic['Value']
                if dic['Key'] == 'group':
                    group = dic['Value']
                if dic['Key'] == 'app':
                    app = dic['Value']
                    
            row_cvs = [index, name, project, group, app, j['LaunchTime'], j['InstanceId'], j['InstanceType'], j['PublicIpAddress'], j['PrivateIpAddress'], j['State']['Name'], j['KeyName'], j['ImageId'], j['Placement']['AvailabilityZone'], j['Architecture'], j['PlatformDetails']]
            writer.writerow(row_cvs)
