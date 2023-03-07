import boto3
import csv
import codecs
import time
import datetime

#Author: Jone Ma
#Date: 2023-02-17
#Function: Export all instances and reserved instances of each resource type in each AWS region,
#such as ec2 instances, reserved ec2 instances, rds instances and reserved rds instances in ap-southeast-1.
#Note: 1, Python3 and module boto3 is required, and boto3 can be installed with command: pip3 install boto3.
#2, please update AWS access keys, regions and names, and resource types.

account_owner="xx"
access_key = "xxxx"
secret_access_key = "xxxx"
#sgp, hk and fra are customized short names for each region.
regions = {"ap-southeast-1": "sgp", "ap-east-1": "hk", "eu-central-1": "fra"}
resources = ["ec2", "rds"]

for z in regions:
    for r in resources:
        client = boto3.client(
            r,
            aws_access_key_id=access_key,
            aws_secret_access_key=secret_access_key,
            region_name=z,
            )
        
        #Export ec2 instances and reserved ec2 instances
        if r == "ec2":
            #Export ec2 instances
            response = client.describe_instances()
            now = time.strftime("%Y%m%d%H%M%S", time.localtime())
            filename = account_owner + "_" + regions[z] + "_" + r + "_" + now + ".csv"
            print(filename)
            with open(filename, "w", encoding="utf-8-sig", newline="") as csvf:
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
                        
                        #Instance tags.
                        name = ""
                        project = ""
                        group = ""
                        app = ""
                        for dic in j['Tags']:
                            #Default tag for instance name.
                            if dic['Key'] == 'Name':
                                name = dic['Value']
                            # Customized tags, case sensitive.
                            if dic['Key'] == 'project':
                                project = dic['Value']
                            if dic['Key'] == 'group':
                                group = dic['Value']
                            if dic['Key'] == 'app':
                                app = dic['Value']
                                
                        row_cvs = [index, name, project, group, app, j['LaunchTime'], j['InstanceId'], j['InstanceType'], j['PublicIpAddress'], j['PrivateIpAddress'], j['State']['Name'], j['KeyName'], j['ImageId'], j['Placement']['AvailabilityZone'], j['Architecture'], j['PlatformDetails']]
                        writer.writerow(row_cvs)
            
            #Export reserved ec2 instances
            response = client.describe_reserved_instances()
            now = time.strftime("%Y%m%d%H%M%S", time.localtime())
            filename = account_owner + "_" + regions[z] + "_" + r + "_reserved_"+ now + ".csv"
            print(filename)
            with open(filename, "w", encoding="utf-8-sig", newline="") as csvf:
                writer = csv.writer(csvf)
                csv_head = ["Index", "ReservedInstancesID", "InstanceType", "Count", "StartTime", "EndTime", "Currency", "Price", "State", "Class", "OfferingType", "Platform", "Scope"]
                writer.writerow(csv_head)
                index = 0
                for i in response['ReservedInstances']:
                    index = index + 1                                  
                    row_cvs = [index, i['ReservedInstancesId'], i['InstanceType'], i['InstanceCount'], i['Start'], i['End'], i['CurrencyCode'], i['FixedPrice'], i['State'], i['OfferingClass'], i['OfferingType'], i['ProductDescription'], i['Scope']]
                    writer.writerow(row_cvs)
        
        #Export rds instances and reserved rds instances
        elif r == "rds":
            #Export rds instances
            response = client.describe_db_instances()
            now = time.strftime("%Y%m%d%H%M%S", time.localtime())
            filename = account_owner + "_" + regions[z] + "_" + r + "_" + now + ".csv"
            print(filename)
            with open(filename, "w", encoding="utf-8-sig", newline="") as csvf:
                writer = csv.writer(csvf)
                csv_head = ["Index", "DBInstanceIdentifier", "Project", "Group", "APP", "Role", "DBInstanceClass", "Engine", "EngineVersion", "Status", "Storage", "CreateTime", "Zone", "MultiAZ"]
                writer.writerow(csv_head)
                
                index = 0
                for i in response['DBInstances']:
                    index = index + 1
                    role = "Primary"
                    if 'ReadReplicaSourceDBInstanceIdentifier' in i:
                        role = "Replica"
                    
                    project = ""
                    group = ""
                    app = ""
                    for dic in i['TagList']:
                        #Customized tags, case sensitive.
                        if dic['Key'] == 'project':
                            project = dic['Value']
                        if dic['Key'] == 'group':
                            group = dic['Value']
                        if dic['Key'] == 'app':
                            app = dic['Value']
                    
                    row_cvs = [index, i['DBInstanceIdentifier'], project, group, app, role, i['DBInstanceClass'], i['Engine'], i['EngineVersion'], i['DBInstanceStatus'], i['AllocatedStorage'], i['InstanceCreateTime'], i['AvailabilityZone'], i['MultiAZ']]
                    writer.writerow(row_cvs)
            
            #Export reserved rds instances
            response = client.describe_reserved_db_instances()
            now = time.strftime("%Y%m%d%H%M%S", time.localtime())
            filename = account_owner + "_" + regions[z] + "_" + r + "_reserved_"+ now + ".csv"
            print(filename)
            with open(filename, "w", encoding="utf-8-sig", newline="") as csvf:
                writer = csv.writer(csvf)
                csv_head = ["Index", "ReservedDBInstanceID", "LeaseID", "Class", "Count", "StartTime", "Duration", "EndTime", "Product", "OfferingType", "MultiAZ", "State", "Currency", "Price"]
                writer.writerow(csv_head)
            
                index = 0
                for i in response['ReservedDBInstances']:
                    index = index + 1
                    #utcstart = datetime.datetime.strptime(i['StartTime'], "%Y-%m-%d %H:%M:%S.%f%z").replace(tzinfo=None)
                    endtime = i['StartTime'] + datetime.timedelta(seconds=i['Duration'])
                    
                    row_cvs = [index, i['ReservedDBInstanceId'], i['LeaseId'], i['DBInstanceClass'], i['DBInstanceCount'], i['StartTime'], i['Duration']/86400, endtime, i['ProductDescription'], i['OfferingType'], i['MultiAZ'], i['State'], i['CurrencyCode'], i['FixedPrice']]
                    writer.writerow(row_cvs)
