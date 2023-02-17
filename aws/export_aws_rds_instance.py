import boto3
import csv
import codecs
 
client = boto3.client(
    'rds',
    # Update access keys and region.
    aws_access_key_id="xxxx",
    aws_secret_access_key="xxxx",
    region_name='ap-southeast-1',
    )

response = client.describe_db_instances()
with open("rds_sgp.csv", "w", encoding="utf-8-sig", newline="") as csvf:
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
            # Customized tag project, case sensitive.
            if dic['Key'] == 'project':
                project = dic['Value']
            if dic['Key'] == 'group':
                group = dic['Value']
            if dic['Key'] == 'app':
                app = dic['Value']
        
        row_cvs = [index, i['DBInstanceIdentifier'], project, group, app, role, i['DBInstanceClass'], i['Engine'], i['EngineVersion'], i['DBInstanceStatus'], i['AllocatedStorage'], i['InstanceCreateTime'], i['AvailabilityZone'], i['MultiAZ']]
        writer.writerow(row_cvs)
