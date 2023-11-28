import boto3
from botocore.config import Config
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
resources = ["ec2", "rds", "elasticache", "elbv2"]

config = Config(proxies={})

for z in regions:
    for r in resources:
        client = boto3.client(
            r,
            aws_access_key_id=access_key,
            aws_secret_access_key=secret_access_key,
            region_name=z,
            config=config,
            )
        
        #Export ec2 instances and reserved ec2 instances
        if r == "ec2":
            #Export ec2 instances
            response = client.describe_instances()
            now = time.strftime("%Y%m%d%H%M%S", time.localtime())
            filename = now + "_" + account_owner + "_" + regions[z] + "_" + r + ".csv"
            print(filename)
            with open(filename, "w", encoding="utf-8-sig", newline="") as csvf:
                writer = csv.writer(csvf)
                csv_head = ["Index", "InstanceName", "Project", "Group", "APP", "Owner", "CreateTime", "LaunchTime", "InstanceID", "InstanceType", "PublicIP", "PrivateIP", "State", "KeyName", "ImageID", "Zone", "Archi", "Platform", "Location"]
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
                        owner = ""
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
                            if dic['Key'] == 'owner':
                                owner = dic['Value']
                        row_cvs = [index, name, project, group, app, owner, j['UsageOperationUpdateTime'], j['LaunchTime'], j['InstanceId'], j['InstanceType'], j['PublicIpAddress'], j['PrivateIpAddress'], j['State']['Name'], j['KeyName'], j['ImageId'], j['Placement']['AvailabilityZone'], j['Architecture'], j['PlatformDetails'], regions[z]]
                        writer.writerow(row_cvs)
            
            #Export reserved ec2 instances
            response = client.describe_reserved_instances()
            now = time.strftime("%Y%m%d%H%M%S", time.localtime())
            filename = now + "_" + account_owner + "_" + regions[z] + "_" + r + "_reserved.csv"
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
            filename = now + "_" + account_owner + "_" + regions[z] + "_" + r + ".csv"
            print(filename)
            with open(filename, "w", encoding="utf-8-sig", newline="") as csvf:
                writer = csv.writer(csvf)
                csv_head = ["Index", "DBInstanceIdentifier", "Project", "Group", "APP", "Owner", "Role", "DBInstanceClass", "Engine", "EngineVersion", "Status", "Storage", "CreateTime", "Zone", "MultiAZ", "Location"]
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
                    owner = ""
                    for dic in i['TagList']:
                        #Customized tags, case sensitive.
                        if dic['Key'] == 'project':
                            project = dic['Value']
                        if dic['Key'] == 'group':
                            group = dic['Value']
                        if dic['Key'] == 'app':
                            app = dic['Value']
                        if dic['Key'] == 'owner':
                            owner = dic['Value']
                    row_cvs = [index, i['DBInstanceIdentifier'], project, group, app, owner, role, i['DBInstanceClass'], i['Engine'], i['EngineVersion'], i['DBInstanceStatus'], i['AllocatedStorage'], i['InstanceCreateTime'], i['AvailabilityZone'], i['MultiAZ'], regions[z]]
                    writer.writerow(row_cvs)
            
            #Export reserved rds instances
            response = client.describe_reserved_db_instances()
            now = time.strftime("%Y%m%d%H%M%S", time.localtime())
            filename = now + "_" + account_owner + "_" + regions[z] + "_" + r + "_reserved.csv"
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
                    
        #Export elasticache instances and reserved elasticache instances
        elif r == "elasticache":
            #Export elasticache instances
            response = client.describe_replication_groups()
            now = time.strftime("%Y%m%d%H%M%S", time.localtime())
            filename = now + "_" + account_owner + "_" + regions[z] + "_" + r + ".csv"
            print(filename)
            with open(filename, "w", encoding="utf-8-sig", newline="") as csvf:
                writer = csv.writer(csvf)
                csv_head = ["Index", "ClusterName", "Project", "Group", "APP", "Owner", "NodeCount", "CacheNodeType", "Engine", "EngineVersion", "Status", "CreateTime", "MultiAZ", "Location"]
                writer.writerow(csv_head)
                
                index = 0
                for i in response['ReplicationGroups']:
                    index = index + 1
                    
                    response_tmp = client.describe_cache_clusters(CacheClusterId=i['MemberClusters'][0])
                    engine = response_tmp['CacheClusters'][0]['Engine']
                    engineVersion = response_tmp['CacheClusters'][0]['EngineVersion']
                    
                    try:
                        createTime = i['ReplicationGroupCreateTime']
                    except KeyError:
                        createTime = response_tmp['CacheClusters'][0]['CacheClusterCreateTime']
                    
                    response_tmp = client.list_tags_for_resource(ResourceName=i['ARN'],)
                    project = ""
                    group = ""
                    app = ""
                    owner = ""
                    for dic in response_tmp['TagList']:
                        # Customized tags, case sensitive.
                        if dic['Key'] == 'project':
                            project = dic['Value']
                        if dic['Key'] == 'group':
                            group = dic['Value']
                        if dic['Key'] == 'app':
                            app = dic['Value']
                        if dic['Key'] == 'owner':
                            owner = dic['Value']
                    
                    row_cvs = [index, i['ReplicationGroupId'], project, group, app, owner, len(i['MemberClusters']) ,i['CacheNodeType'], engine, engineVersion, i['Status'], createTime, i['MultiAZ'], regions[z]]
                    writer.writerow(row_cvs)
                    
            #Export reserved elasticache instances
            response = client.describe_reserved_cache_nodes()
            now = time.strftime("%Y%m%d%H%M%S", time.localtime())
            filename = now + "_" + account_owner + "_" + regions[z] + "_" + r + "_reserved.csv"
            print(filename)
            with open(filename, "w", encoding="utf-8-sig", newline="") as csvf:
                writer = csv.writer(csvf)
                csv_head = ["Index", "ReservedCacheNodeId", "CacheNodeType", "Count", "StartTime", "Duration", "EndTime", "Product", "OfferingType", "State", "Price"]
                writer.writerow(csv_head)
            
                index = 0
                for i in response['ReservedCacheNodes']:
                    index = index + 1
                    #utcstart = datetime.datetime.strptime(i['StartTime'], "%Y-%m-%d %H:%M:%S.%f%z").replace(tzinfo=None)
                    endtime = i['StartTime'] + datetime.timedelta(seconds=i['Duration'])
                    
                    row_cvs = [index, i['ReservedCacheNodeId'], i['CacheNodeType'], i['CacheNodeCount'], i['StartTime'], i['Duration']/86400, endtime, i['ProductDescription'], i['OfferingType'], i['State'], i['FixedPrice']]
                    writer.writerow(row_cvs)

        #Export elb instances
        elif r == "elbv2":
            #Export elb instances
            response = client.describe_load_balancers()
            now = time.strftime("%Y%m%d%H%M%S", time.localtime())
            filename = now + "_" + account_owner + "_" + regions[z] + "_" + r + ".csv"
            print(filename)
            with open(filename, "w", encoding="utf-8-sig", newline="") as csvf:
                writer = csv.writer(csvf)
                csv_head = ["Index", "Name", "Project", "Group", "APP", "Owner", "DNSName", "State", "Type", "CreateTime", "Location"]
                writer.writerow(csv_head)
                
                index = 0
                for i in response['LoadBalancers']:
                    index = index + 1
                    
                    project = ""
                    group = ""
                    app = ""
                    owner = ""
                    response_tmp = client.describe_tags(ResourceArns=[i['LoadBalancerArn'],])
                    for j in response_tmp['TagDescriptions'][0]['Tags']:
                        # Customized tags, case sensitive.
                        if j['Key'] == 'project':
                            project = j['Value']
                        if j['Key'] == 'group':
                            group = j['Value']
                        if j['Key'] == 'app':
                            app = j['Value']
                        if j['Key'] == 'owner':
                            owner = j['Value']
                    
                    row_cvs = [index, i['LoadBalancerName'], project, group, app, owner, i['DNSName'], i['State']['Code'], i['Type'], i['CreatedTime'], regions[z]]
                    writer.writerow(row_cvs)

#Get S3 Buckets
client = boto3.client(
    's3',
    aws_access_key_id=access_key,
    aws_secret_access_key=secret_access_key,
    config=config,
    )
response = client.list_buckets()
now = time.strftime("%Y%m%d%H%M%S", time.localtime())
filename = now + "_" + account_owner + "_s3_bucket.csv"
print(filename)
with open(filename, "w", encoding="utf-8-sig", newline="") as csvf:
    writer = csv.writer(csvf)
    csv_head = ["Index", "BucketName", "Project", "Group", "APP", "Owner", "CreateTime", "Location"]
    writer.writerow(csv_head)
    index = 0
    for i in response['Buckets']:
        index = index + 1
        name = i['Name']
        createtime = i['CreationDate']
        
        project = ""
        group = ""
        app = ""
        owner = ""
        
        try:
            response1 = client.get_bucket_tagging(
                Bucket=name,
            )
            for dic in response1['TagSet']:
                # Customized tags, case sensitive.
                if dic['Key'] == 'project':
                    project = dic['Value']
                if dic['Key'] == 'group':
                    group = dic['Value']
                if dic['Key'] == 'app':
                    app = dic['Value']
                if dic['Key'] == 'owner':
                    owner = dic['Value']
        except:
            pass
            
        location = ""
        try:
            response2 = client.get_bucket_location(
                    Bucket=name,
            )
            location = response2['LocationConstraint']
        except:
            pass
        
        print(index, name, project, group, app, owner, createtime, location)
        row_cvs = [index, name, project, group, app, owner, createtime, location]
        writer.writerow(row_cvs)
