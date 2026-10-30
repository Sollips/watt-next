"""watt-next ingestion: fetch the latest eCO2mix records and store them in S3 as JSON Lines."""
import json
import os
import urllib.parse
import urllib.request
from datetime import datetime, timezone

import boto3  # AWS SDK, pre-installed in the Lambda runtime

S3 = boto3.client("s3")                    # created once per container, reused across runs
BUCKET = os.environ["DATALAKE_BUCKET"]     # injected by Terraform (environment variable)
API_URL = ("https://odre.opendatasoft.com/api/explore/v2.1/"
           "catalog/datasets/eco2mix-national-tr/records")
PARAMS = {
    "where": "taux_co2 is not null",       # the newest rows may not have a CO2 value yet
    "order_by": "date_heure desc",         # newest first
    "limit": "96",                         # 96 x 15 min = the last 24 hours
}


def handler(event, context):               # Lambda calls this function on every run
    url = f"{API_URL}?{urllib.parse.urlencode(PARAMS)}"
    with urllib.request.urlopen(url, timeout=20) as response:  # HTTP error → exception → run fails
        payload = json.loads(response.read())                  # not JSON → exception → run fails

    records = payload.get("results", [])
    if not records:
        raise ValueError("API returned no records")            # fail loudly, never store empty files

    body = "\n".join(json.dumps(r, ensure_ascii=False) for r in records)  # JSON Lines for Athena

    now = datetime.now(timezone.utc)       # partitions use UTC ingestion time
    key = (f"raw/eco2mix/year={now:%Y}/month={now:%m}/day={now:%d}/"
           f"eco2mix_{now:%Y%m%dT%H%M%SZ}.jsonl")
    S3.put_object(Bucket=BUCKET, Key=key, Body=body.encode("utf-8"),
                  ContentType="application/x-ndjson")

    print(json.dumps({"stored": key, "records": len(records)}))  # print → CloudWatch Logs
    return {"stored": key, "records": len(records)}