import boto3
import csv
import codecs
import datetime
 
client = boto3.client(
    'rds',
    # Update access keys and region.
    aws_access_key_id="xxxx",
    aws_secret_access_key="xxxx",
    region_name='ap-southeast-1',
    )

response = client.describe_reserved_db_instances()
with open("reserved_rds_sgp.csv", "w", encoding="utf-8-sig", newline="") as csvf:
    writer = csv.writer(csvf)
    csv_head = ["Index", "ReservedDBInstanceID", "LeaseID", "Class", "Count", "StartTime", "Duration", "EndTime", "Product", "OfferingType", "MultiAZ", "State", "Currency", "Price"]
    writer.writerow(csv_head)
 
    index = 0
    for i in response['ReservedDBInstances']:
        index = index + 1
        # utcstart = datetime.datetime.strptime(i['StartTime'], "%Y-%m-%d %H:%M:%S.%f%z").replace(tzinfo=None)
        endtime = i['StartTime'] + datetime.timedelta(seconds=i['Duration'])
        
        row_cvs = [index, i['ReservedDBInstanceId'], i['LeaseId'], i['DBInstanceClass'], i['DBInstanceCount'], i['StartTime'], i['Duration']/86400, endtime, i['ProductDescription'], i['OfferingType'], i['MultiAZ'], i['State'], i['CurrencyCode'], i['FixedPrice']]
        writer.writerow(row_cvs)
