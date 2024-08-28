import streamlit as st
import boto3
import pandas as pd
import matplotlib.pyplot as plt
import json
from botocore.exceptions import ClientError
from io import StringIO

# Initialize AWS resources
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
s3 = boto3.client('s3', region_name='us-east-1')

# Replace with your DynamoDB table name
dynamodb_table_name = 'sample-dynamodb-table'
table = dynamodb.Table(dynamodb_table_name)

def create_record(record_id, attribute_value):
    try:
        item = json.loads(attribute_value)
        item["PrimaryKey"] = record_id
    except:
        item = {
            "PrimaryKey":record_id,
            "value":attribute_value
        }
    try:
        table.put_item(
            Item=item
        )
        return "Record created successfully!"
    except ClientError as e:
        return f"Error creating record: {e.response['Error']['Message']}"

def list_records():
    try:
        response = table.scan()
        items = response.get('Items', [])
        df = pd.DataFrame(items)
        df.set_index("PrimaryKey",inplace=True)
        return df
    except ClientError as e:
        return f"Error listing records: {e.response['Error']['Message']}"

def create_replication_rule(source_bucket, destination_bucket, rule_id, prefix):
    try:
        response = s3.put_bucket_replication(
            Bucket=source_bucket,
            ReplicationConfiguration={
                'Role': "arn:aws:iam::562178332708:role/ecs-task-role", 
                'Rules': [
                    {
                        'ID': rule_id,
                        'Prefix': prefix,
                        'Status': 'Enabled',
                        'Destination': {
                            'Bucket': f'arn:aws:s3:::{destination_bucket}'
                        }
                    }
                ]
            }
        )
        return "Replication rule created successfully!"
    except ClientError as e:
        return f"Error creating replication rule: {e.response['Error']['Message']}"

def get_glue_job_runs(job_name):
    client = boto3.client('glue')
    response = client.get_job_runs(JobName=job_name)
    runs = response['JobRuns']
    data = []
    for run in runs:
        data.append({
            'JobRunId': run['Id'],
            'State': run['JobRunState'],
            'StartTime': run['StartedOn'],
            'EndTime': run.get('CompletedOn', None)
        })
    df = pd.DataFrame(data)
    return df

def get_s3_html(bucket_name, object_key):
    s3 = boto3.client('s3')
    response = s3.get_object(Bucket=bucket_name, Key=object_key)
    html_content = response['Body'].read().decode('utf-8')
    return html_content

# Streamlit UI with sidebar menu 
st.sidebar.title('Navigation')
selection = st.sidebar.radio("Go to", ["Create DynamoDB Record", "List DynamoDB Records", "Create S3 Replication Rule","Glue Job Runs","Display HTML from S3"])

if selection == "Create DynamoDB Record":
    st.title('Create DynamoDB Record')
    record_id = st.text_input('Record ID')
    attribute_value = st.text_input('Attribute Value')
    if st.button('Create Record'):
        result = create_record(record_id, attribute_value)
        st.write(result)

elif selection == "List DynamoDB Records":
    st.title('List DynamoDB Records')
    if st.button('List Records'):
        records = list_records()
        if isinstance(records, str):
            st.dataframe(records)
        else:
            st.dataframe(records)

elif selection == "Create S3 Replication Rule":
    st.title('Create S3 Replication Rule')
    rule_id = st.text_input('Set a unique name for the rule')
    prefix = st.text_input('Prefix to replicate')
    source_bucket = st.text_input('Source Bucket Name')
    destination_bucket = st.text_input('Destination Bucket Name')
    if st.button('Create Replication Rule'):
        result = create_replication_rule(source_bucket, destination_bucket, rule_id, prefix)
        st.write(result)

elif selection == "Glue Job Runs":
    st.title('AWS Glue Job Runs')
    job_name = st.text_input('Enter the Glue job name:')
    if job_name:
        # Fetch the job runs data
        df = get_glue_job_runs(job_name)
        
        if not df.empty:
            # Count the number of job runs by state
            status_counts = df['State'].value_counts()
            
            # Define colors for the pie chart
            colors = ['lightgray', '#800020']  # Light gray and burgundy

            # Create the pie chart
            fig, ax = plt.subplots()
            wedges, texts, autotexts = ax.pie(
                status_counts,
                labels=status_counts.index,
                colors=colors,
                autopct='%1.1f%%',
                startangle=90
            )

            # Beautify the plot
            plt.setp(autotexts, size=10, weight="bold", color='white')
            plt.setp(texts, size=12, weight="bold", color='white')
            ax.axis('equal')  # Equal aspect ratio ensures that pie is drawn as a circle.

            # Remove the background color
            fig.patch.set_alpha(0)  # Transparent background
            ax.patch.set_alpha(0)   # Transparent background for pie chart

            # Add a legend at the bottom
            legend = ax.legend(
                wedges, 
                status_counts.index, 
                loc="lower center", 
                bbox_to_anchor=(0.5, -0.05), 
                ncol=2, 
                frameon=False,
                fontsize='10',
                labelcolor = "white"
            )

            # Add job name at the top
            plt.title(f'Job Runs for {job_name}', pad=20, color='white')

            # Set background color of the plot to transparent
            plt.gca().patch.set_facecolor('none')
            plt.gca().spines['top'].set_visible(False)
            plt.gca().spines['right'].set_visible(False)
            plt.gca().spines['left'].set_visible(False)
            plt.gca().spines['bottom'].set_visible(False)

            st.pyplot(fig)
        else:
            st.write('No job runs found for this Glue job name.')
    else:
        st.write('Please enter a Glue job name to see the data.')
elif selection == 'Display HTML from S3':
    # Input for S3 bucket name and object key
    bucket_name = st.text_input('Enter the S3 bucket name:')
    object_key = st.text_input('Enter the S3 object key (path to HTML file):')

    if bucket_name and object_key:
        # Fetch and display the HTML content
        try:
            html_content = get_s3_html(bucket_name, object_key)
            st.components.v1.html(html_content, height=600, scrolling=True)
        except Exception as e:
            st.write(f'Error fetching HTML from S3: {e}')
    else:
        st.write('Please enter both the S3 bucket name and object key to see the HTML content.')