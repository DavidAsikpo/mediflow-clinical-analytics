import os
import subprocess
from prefect import task, flow, get_run_logger
from scripts.fhir_to_csv import main  
from scripts.s3_load import upload_all        

@task(retries=2, retry_delay_seconds=30)
def run_fhir_parsing():
    logger = get_run_logger()
    logger.info("Starting Stage 1: Parsing raw Synthea FHIR JSON bundles...")
    # Calls your existing script logic
    main(fhir,output_data) 
    logger.info("FHIR parsing complete. Local structured CSVs generated.")

@task(retries=1)
def run_s3_upload()
    logger = get_run_logger()
    logger.info("Starting Stage 2: Uploading CSVs to AWS S3 storage...")
    upload_all()
    logger.info("Upload complete. Files successfully partitioned in S3.")

@task
def run_snowflake_copy():
    logger = get_run_logger()
    logger.info("Starting Stage 3: Executing Snowflake COPY INTO raw schema...")
    
    # You can execute this via Snowflake's Python Connector or a bash command
    import snowflake.connector
    ctx = snowflake.connector.connect(
        user=os.getenv("SF_USER"),
        password=os.getenv("SF_PASSWORD"),
        account=os.getenv("SF_ACCOUNT"),
        warehouse=os.getenv("SF_WAREHOUSE"),
        database="MEDIFLOW",
        schema="RAW"
    )
    cs = ctx.cursor()

    pipeline_tables = {
                    "PATIENTS": "patients",
                    "ENCOUNTERS": "encounters",
                    "CONDITIONS": "conditions",
                    "MEDICATIONS": "medications",
                    "PROCEDURES": "procedures",
                    "OBSERVATIONS": "observations",
                    "CLAIMS": "claims"
                     }
    for table_name, csv_file in pipeline_tables.items():
        try:
            # Example copy command for your encounters
            cs.execute("""
                COPY INTO MEDIFLOW.RAW.{{table_name}}
                FROM @MEDIFLOW_S3_STAGE/year=2024/month=06/day=07/{{csv_file}}.csv
                FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1);
            """)
            # Repeat execution blocks for your remaining 6 CSV tables...
        finally:
            cs.close()
            ctx.close()
        logger.info("Snowflake ingestion successfully completed.")

@task
def run_dbt_pipeline():
    logger = get_run_logger()
    logger.info("Starting Stages 4-6: Triggering dbt Medallion Transformations...")
    
    # Execute dbt clean and run synchronously within the project environment
    subprocess.run(["dbt", "deps"], check=True)
    subprocess.run(["dbt", "build"], check=True) # 'build' runs seed, run, and test sequentially
    
    logger.info("dbt compilation, incremental models, and data mart builds completed successfully.")

@flow(name="MediFlow End-to-End Pipeline")
def mediflow_orchestrator_flow():
    # Strict sequential dependency mapping
    parsing_res = run_fhir_parsing()
    upload_res = run_s3_upload(wait_for=[parsing_res])
    snowflake_res = run_snowflake_copy(wait_for=[upload_res])
    dbt_res = run_dbt_pipeline(wait_for=[snowflake_res])

if __name__ == "__main__":
    # Ensure your local environment variables are sourced before executing
    mediflow_orchestrator_flow()