import boto3
from botocore.config import Config

#Author: Jone Ma
#Date: 2023-07-05
#Function: Add tags for all EC2 volumes according to EC2 instance tags(Name, project, group, app) in each AWS region,
#such as ap-southeast-1, eu-central-1 and ap-east-1.
#Note: 1, Python3 and module boto3 is required, and boto3 can be installed by command: pip3 install boto3.
#2, please update AWS access keys and regions.

access_key = ""
secret_access_key = ""
regions = ["ap-east-1", "eu-central-1", "ap-southeast-1"]

config = Config(proxies={})
for region in regions:
    print('******************* '+region+' *******************')
    client = boto3.client(
        'ec2',
        aws_access_key_id=access_key,
        aws_secret_access_key=secret_access_key,
        region_name=region,
        config=config,
        )

    response = client.describe_instances()
    index = 0
    for i in response['Reservations']:
        for j in i['Instances']:
            index = index + 1
            if 'Tags' not in j:
                j['Tags'] = []
            if 'BlockDeviceMappings' not in j:
                j['BlockDeviceMappings'] = []
            
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
            print(str(index)+': Name: '+name+'   project: '+project+'  group: '+group+'  app: '+app)
            
            for disk in j['BlockDeviceMappings']:
                volId = disk['Ebs']['VolumeId']
                response = client.create_tags(
                    Resources=[
                        volId,
                    ],
                    Tags=[
                        {
                            'Key': 'Name',
                            'Value': name
                        },
                        {
                            'Key': 'project',
                            'Value': project
                        },
                        {
                            'Key': 'group',
                            'Value': group
                        },
                        {
                            'Key': 'app',
                            'Value': app
                        },
                    ]
                )
