import boto3
import csv
import codecs
 
ec2 = boto3.client(
    'ec2',
    # Update access keys and region.
    aws_access_key_id="xxxx",
    aws_secret_access_key="xxxx",
    region_name='eu-central-1',
    )

response = ec2.describe_reserved_instances()
with open("reserved_ec2_fra.csv", "w", encoding="utf-8-sig", newline="") as csvf:
    writer = csv.writer(csvf)
    csv_head = ["Index", "ReservedInstancesID", "InstanceType", "Count", "StartTime", "EndTime", "Currency", "Price", "State", "Class", "OfferingType", "Platform", "Scope"]
    writer.writerow(csv_head)
 
    index = 0
    for i in response['ReservedInstances']:
        index = index + 1
        row_cvs = [index, i['ReservedInstancesId'], i['InstanceType'], i['InstanceCount'], i['Start'], i['End'], i['CurrencyCode'], i['FixedPrice'], i['State'], i['OfferingClass'], i['OfferingType'], i['ProductDescription'], i['Scope']]
        writer.writerow(row_cvs)
