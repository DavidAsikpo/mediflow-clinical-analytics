"""
S3 Loader — uploads flattened CSVs to S3
Reads CSVs from output_data/ and uploads them to S3 under:
  s3://your-bucket/mediflow/raw/{table_name}/YYYY/MM/DD/{file}.csv
 
Usage:
    python s3_loader.py
"""
 
import os
import boto3
from pathlib import Path
from datetime import datetime
from dotenv import load_dotenv
 
load_dotenv()
 
# ─────────────────────────────────────────────
# CONFIG — reads from .env file
# ─────────────────────────────────────────────
 
AWS_ACCESS_KEY_ID     = os.getenv("AWS_ACCESS_KEY_ID")
AWS_SECRET_ACCESS_KEY = os.getenv("AWS_SECRET_ACCESS_KEY")
AWS_REGION            = os.getenv("AWS_REGION", "us-east-1")
BUCKET_NAME           = os.getenv("AWS_BUCKET_NAME")
CSV_FOLDER            = Path("output_data")
 
# date partition — organises files by date in S3
TODAY = datetime.today()
DATE_PARTITION = f"year={TODAY.year}/month={TODAY.month:02d}/day={TODAY.day:02d}"
 
 
# ─────────────────────────────────────────────
# S3 CLIENT
# ─────────────────────────────────────────────
 
def get_s3_client():
    return boto3.client(
        "s3",
        aws_access_key_id=AWS_ACCESS_KEY_ID,
        aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
        region_name=AWS_REGION,
    )
 
 
# ─────────────────────────────────────────────
# UPLOAD
# ─────────────────────────────────────────────
 
def upload_csv(s3, filepath):
    """Upload one CSV file to S3 with date partitioning."""
    table_name = filepath.stem  # e.g. "encounter" from "encounter.csv"
 
    # s3 key = mediflow/raw/encounter/year=2024/month=06/day=07/encounter.csv
    s3_key = f"mediflow/raw/{table_name}/{DATE_PARTITION}/{filepath.name}"
 
    s3.upload_file(
        Filename=str(filepath),
        Bucket=BUCKET_NAME,
        Key=s3_key,
    )
 
    return s3_key
 
 
def upload_all(csv_folder):
    """Upload all CSVs in the output folder to S3."""
 
    # validate config
    if not BUCKET_NAME:
        raise ValueError("AWS_BUCKET_NAME not set in .env")
    if not AWS_ACCESS_KEY_ID:
        raise ValueError("AWS_ACCESS_KEY_ID not set in .env")
    if not AWS_SECRET_ACCESS_KEY:
        raise ValueError("AWS_SECRET_ACCESS_KEY not set in .env")
 
    # check folder exists
    if not csv_folder.exists():
        raise FileNotFoundError(f"CSV folder not found: {csv_folder}")
 
    csv_files = list(csv_folder.glob("*.csv"))
    if not csv_files:
        print(f"No CSV files found in {csv_folder}")
        return
 
    s3 = get_s3_client()
 
    print(f"Uploading {len(csv_files)} files to s3://{BUCKET_NAME}/mediflow/raw/")
    print(f"Date partition: {DATE_PARTITION}\n")
 
    success = 0
    failed  = 0
 
    for filepath in csv_files:
        try:
            s3_key = upload_csv(s3, filepath)
            size_kb = filepath.stat().st_size / 1024
            print(f"  ✓ {filepath.name} ({size_kb:.1f} KB) → s3://{BUCKET_NAME}/{s3_key}")
            success += 1
        except Exception as e:
            print(f"  ✗ {filepath.name} failed: {e}")
            failed += 1
 
    print(f"\nDone! {success} uploaded, {failed} failed.")
    print(f"\nS3 path: s3://{BUCKET_NAME}/mediflow/raw/")
 
 
# ─────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────
 
if __name__ == "__main__":
    upload_all(Path("output_data"))