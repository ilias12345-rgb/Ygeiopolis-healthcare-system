# Data Generator Guide

`generate_data.py` creates reference and synthetic CSV data for the Ygeiopolis hospital database.

## What It Does

The script:

- cleans official reference data when source files are available;
- prefers improved/official KEN data and filters ICD10-KEN mappings against the active `ken.csv`;
- generates deterministic synthetic data with seed `42`;
- creates departments, personnel, patients, shifts, emergency visits, hospitalizations, procedures, lab tests, allergies, prescriptions, evaluations, and image metadata;
- validates generated clinical rows before finishing so procedure, KEN, drug, substance, and allergy references stay synchronized;
- writes a MySQL loader with the correct foreign-key load order;
- writes helper metadata files such as table-to-CSV mapping and query coverage notes.

## Main Command

```bash
python3 scripts/generate_data.py --source-dir . --output-dir hospital_dataset_bundle
```

Local exercise bundle:

```bash
python3 scripts/generate_data.py \
  --source-dir /Users/euangeloseuangelou/Desktop/sxoli/6_εξάμηνο/rdbms1/εργασια/data \
  --output-dir /Users/euangeloseuangelou/Desktop/sxoli/6_εξάμηνο/rdbms1/rdbms_final_data
```

Optional EMA Article 57 drug source:

```bash
python3 scripts/generate_data.py \
  --source-dir . \
  --output-dir hospital_dataset_bundle \
  --ema-xlsx /path/to/article-57-product-data_en.xlsx
```

## Output

The output bundle contains:

- `data/reference/`: cleaned or fallback reference CSVs;
- `data/generated/`: synthetic transactional CSVs;
- `sql/load.sql`: relative-path loader for MySQL;
- `TABLE_TO_CSV_MAP.csv`: table-to-file mapping;
- `QUERY_COVERAGE.csv`: notes explaining how generated data supports the exercise queries;
- `dataset_summary.json`: row-count summary.

## Important Assumptions

- ICD-10 and procedure catalogs should come from official source files.
- KEN data comes from an improved/official source when available. Demo `DKEN...` rows are used only when no official KEN data can be found.
- `icd10_ken_map.csv` is rebuilt from the official map when compatible with `ken.csv`; otherwise it is generated from the active KEN codes.
- Procedure events are generated only from `procedure_catalog.csv`, with `place_id` chosen from a matching `operating_place.place_type`.
- Drug, active-substance, allergy, and prescription rows are validated against their reference CSVs before the bundle is accepted.
- Drug/substance data can use EMA Article 57 if provided; otherwise the script creates demo drug data so allergy and prescription logic can still be tested.
- The generated data is deterministic, so the same inputs and seed should produce the same result.

## Recommended Use

Use the generator for repeatable testing and demonstration. For final submission, keep a short note explaining which CSV files came from official sources and which were generated synthetically.
