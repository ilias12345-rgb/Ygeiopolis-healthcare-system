# Data Generator Guide

`generate_data.py` creates reference and synthetic CSV data for the hospital database.

## What It Does

The script:

- cleans official reference data when source files are available;
- generates deterministic synthetic data with seed `42`;
- creates departments, personnel, patients, shifts, emergency visits, hospitalizations, procedures, lab tests, allergies, prescriptions, evaluations, and image metadata;
- writes a MySQL loader with the correct foreign-key load order;
- writes helper metadata files such as table-to-CSV mapping and query coverage notes.

## Main Command

```bash
python3 scripts/generate_data.py --source-dir . --output-dir hospital_dataset_bundle
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
- KEN data is currently synthetic fallback data unless replaced with an official source.
- Drug/substance data can use EMA Article 57 if provided; otherwise the script creates demo drug data so allergy and prescription logic can still be tested.
- The generated data is deterministic, so the same inputs and seed should produce the same result.
