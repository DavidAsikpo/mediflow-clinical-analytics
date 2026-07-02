"""
FHIR Bundle → CSV Parser
Reads all Synthea FHIR JSON files from a folder and flattens them into
separate CSVs per resource type, ready for S3 upload and Snowflake ingestion.

Usage:
    python fhir_to_csv.py --input ./fhir --output ./output/csv
"""

import json
import os
import argparse
import pandas as pd
from pathlib import Path


# ─────────────────────────────────────────────
# PARSERS — one function per resource type
# ─────────────────────────────────────────────

def parse_patient(resource):
    # extract race from extensions
    race = None
    ethnicity = None
    birth_place = None
    for ext in resource.get("extension", []):
        url = ext.get("url", "")
        if "us-core-race" in url:
            for sub in ext.get("extension", []):
                if sub.get("url") == "text":
                    race = sub.get("valueString")
        elif "us-core-ethnicity" in url:
            for sub in ext.get("extension", []):
                if sub.get("url") == "text":
                    ethnicity = sub.get("valueString")
        elif "birthPlace" in url:
            addr = ext.get("valueAddress", {})
            birth_place = f"{addr.get('city','')}, {addr.get('state','')}"

    name = resource.get("name", [{}])[0]
    address = resource.get("address", [{}])[0]

    return {
        "patient_id":    resource.get("id"),
        "first_name":    " ".join(name.get("given", [])),
        "last_name":     name.get("family"),
        "gender":        resource.get("gender"),
        "birth_date":    resource.get("birthDate"),
        "race":          race,
        "ethnicity":     ethnicity,
        "birth_place":   birth_place,
        "city":          address.get("city"),
        "state":         address.get("state"),
        "postal_code":   address.get("postalCode"),
        "country":       address.get("country"),
        "marital_status": resource.get("maritalStatus", {}).get("text"),
        "language":      resource.get("communication", [{}])[0]
                                  .get("language", {}).get("text"),
    }


def parse_encounter(resource, patient_id):
    enc_type = resource.get("type", [{}])[0]
    period = resource.get("period", {})
    participant = resource.get("participant", [{}])[0]
    provider = resource.get("serviceProvider", {})

    return {
        "encounter_id":    resource.get("id"),
        "patient_id":      patient_id,
        "status":          resource.get("status"),
        "class_code":      resource.get("class", {}).get("code"),
        "encounter_type":  enc_type.get("text"),
        "start_date":      period.get("start"),
        "end_date":        period.get("end"),
        "provider_name":   provider.get("display"),
        "practitioner":    participant.get("individual", {}).get("display"),
    }


def parse_claim(resource, patient_id):
    insurance = resource.get("insurance", [{}])[0]
    total = resource.get("total", {})
    item = resource.get("item", [{}])[0]
    encounter_ref = None
    for enc in item.get("encounter", []):
        encounter_ref = enc.get("reference", "").split(":")[-1]

    return {
        "claim_id":       resource.get("id"),
        "patient_id":     patient_id,
        "encounter_id":   encounter_ref,
        "status":         resource.get("status"),
        "claim_type":     resource.get("type", {})
                                  .get("coding", [{}])[0].get("code"),
        "created_date":   resource.get("created"),
        "provider_name":  resource.get("provider", {}).get("display"),
        "payer":          insurance.get("coverage", {}).get("display"),
        "total_amount":   total.get("value"),
        "currency":       total.get("currency"),
        "service_code":   item.get("productOrService", {})
                              .get("coding", [{}])[0].get("code"),
        "service_desc":   item.get("productOrService", {}).get("text"),
    }


def parse_condition(resource, patient_id):
    code = resource.get("code", {})
    coding = code.get("coding", [{}])[0]
    clinical_status = resource.get("clinicalStatus", {}) \
                               .get("coding", [{}])[0].get("code")
    encounter_ref = resource.get("encounter", {}) \
                            .get("reference", "").split(":")[-1]

    return {
        "condition_id":     resource.get("id"),
        "patient_id":       patient_id,
        "encounter_id":     encounter_ref,
        "clinical_status":  clinical_status,
        "condition_code":   coding.get("code"),
        "condition_system": coding.get("system"),
        "condition_name":   code.get("text"),
        "onset_date":       resource.get("onsetDateTime"),
        "recorded_date":    resource.get("recordedDate"),
    }


def parse_procedure(resource, patient_id):
    code = resource.get("code", {})
    coding = code.get("coding", [{}])[0]
    encounter_ref = resource.get("encounter", {}) \
                            .get("reference", "").split(":")[-1]
    performed = resource.get("performedPeriod", {})

    return {
        "procedure_id":     resource.get("id"),
        "patient_id":       patient_id,
        "encounter_id":     encounter_ref,
        "status":           resource.get("status"),
        "procedure_code":   coding.get("code"),
        "procedure_system": coding.get("system"),
        "procedure_name":   code.get("text"),
        "performed_start":  performed.get("start"),
        "performed_end":    performed.get("end"),
    }


def parse_observation(resource, patient_id):
    code = resource.get("code", {})
    coding = code.get("coding", [{}])[0]
    encounter_ref = resource.get("encounter", {}) \
                            .get("reference", "").split(":")[-1]
    value_qty = resource.get("valueQuantity", {})
    value_code = resource.get("valueCodeableConcept", {}).get("text")

    return {
        "observation_id":   resource.get("id"),
        "patient_id":       patient_id,
        "encounter_id":     encounter_ref,
        "status":           resource.get("status"),
        "obs_code":         coding.get("code"),
        "obs_system":       coding.get("system"),
        "obs_name":         code.get("text"),
        "effective_date":   resource.get("effectiveDateTime"),
        "value":            value_qty.get("value") or value_code,
        "unit":             value_qty.get("unit"),
    }


def parse_medication_request(resource, patient_id):
    med = resource.get("medicationCodeableConcept", {})
    coding = med.get("coding", [{}])[0]
    encounter_ref = resource.get("encounter", {}) \
                            .get("reference", "").split(":")[-1]

    return {
        "medication_id":    resource.get("id"),
        "patient_id":       patient_id,
        "encounter_id":     encounter_ref,
        "status":           resource.get("status"),
        "intent":           resource.get("intent"),
        "medication_code":  coding.get("code"),
        "medication_name":  med.get("text"),
        "authored_date":    resource.get("authoredOn"),
        "requester":        resource.get("requester", {}).get("display"),
    }


# ─────────────────────────────────────────────
# ROUTER — dispatch each entry to its parser
# ─────────────────────────────────────────────

PARSERS = {
    "Patient":           parse_patient,
    "Encounter":         parse_encounter,
    "Claim":             parse_claim,
    "Condition":         parse_condition,
    "Procedure":         parse_procedure,
    "Observation":       parse_observation,
    "MedicationRequest": parse_medication_request,
}


def parse_bundle(filepath):
    """Parse one FHIR bundle JSON file and return dict of resource lists."""
    with open(filepath, encoding="utf-8") as f:
        bundle = json.load(f)

    results = {k: [] for k in PARSERS}
    patient_id = None

    # first pass — get the patient_id
    for entry in bundle.get("entry", []):
        resource = entry.get("resource", {})
        if resource.get("resourceType") == "Patient":
            patient_id = resource.get("id")
            break

    # second pass — parse all resources
    for entry in bundle.get("entry", []):
        resource = entry.get("resource", {})
        rtype = resource.get("resourceType")

        if rtype not in PARSERS:
            continue

        try:
            if rtype == "Patient":
                row = parse_patient(resource)
            else:
                row = PARSERS[rtype](resource, patient_id)
            results[rtype].append(row)
        except Exception as e:
            print(f"  ⚠ Skipped {rtype} in {filepath.name}: {e}")

    return results


# ─────────────────────────────────────────────
# MAIN — loop all files, merge, save CSVs
# ─────────────────────────────────────────────

def main(input_dir, output_dir):
    input_path = Path(input_dir)
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    json_files = list(input_path.glob("*.json"))
    if not json_files:
        print(f"No JSON files found in {input_dir}")
        return

    print(f"Found {len(json_files)} FHIR files — parsing...")

    # accumulate rows per resource type across all files
    all_data = {k: [] for k in PARSERS}

    for i, filepath in enumerate(json_files, 1):
        print(f"  [{i}/{len(json_files)}] {filepath.name}")
        bundle_data = parse_bundle(filepath)
        for rtype, rows in bundle_data.items():
            all_data[rtype].extend(rows)

    # write one CSV per resource type
    print("\nWriting CSVs...")
    for rtype, rows in all_data.items():
        if not rows:
            continue
        df = pd.DataFrame(rows)
        out_file = output_path / f"{rtype.lower()}.csv"
        df.to_csv(out_file, index=False)
        print(f"  ✓ {out_file.name}  ({len(df):,} rows, {len(df.columns)} columns)")

    print(f"\nDone! CSVs saved to: {output_path.resolve()}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Parse Synthea FHIR bundles to CSV")
    parser.add_argument("--input",  default="./fhir",       help="Folder containing FHIR JSON files")
    parser.add_argument("--output", default="./output/csv", help="Folder to write CSV files")
    args = parser.parse_args()
    main(args.input, args.output)
