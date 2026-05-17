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

## Refresh The Repository Data

```bash
python3 scripts/generate_data.py --source-dir data_sources --output-dir .
```

The `--source-dir` folder should contain the official ICD-10, KEN, procedure, and optional EMA files. With `--output-dir .`, the script refreshes the repository-level `data/reference` and `data/generated` folders that `sql/load.sql` reads from.

The current defaults are intentionally larger than the assignment minimums:
5000 patients, 12000 hospitalizations, 18000 emergency visits, 6000 procedures,
12000 lab tests, 12000 prescriptions, and a three-year operational date
window. Shift coverage is generated as a full week per month across that
window so `LOAD DATA` remains practical while still showing multi-year rosters.

```bash
python3 scripts/generate_data.py \
  --source-dir data_sources \
  --output-dir . \
  --patient-count 5000 \
  --emergency-count 18000 \
  --hospitalization-count 12000 \
  --lab-test-count 12000 \
  --procedure-count 6000 \
  --prescription-count 12000 \
  --shift-days 1096 \
  --shift-sample-days-per-month 7
```

Optional EMA Article 57 drug source:

```bash
python3 scripts/generate_data.py \
  --source-dir data_sources \
  --output-dir . \
  --ema-xlsx /path/to/article-57-product-data_en.xlsx
```

To generate a separate test bundle without changing the repository data, pass a separate output directory:

```bash
python3 scripts/generate_data.py --source-dir data_sources --output-dir hospital_dataset_bundle
```

## Output

The output bundle contains:

- `data/reference/`: cleaned official reference CSVs;
- `data/generated/`: synthetic transactional CSVs;
- `sql/install.sql`: schema installer copied from the project;
- `sql/load.sql`: relative-path loader for MySQL;
- `sql/validation.sql`: post-load validation script copied from the project;
- `TABLE_TO_CSV_MAP.csv`: table-to-file mapping;
- `QUERY_COVERAGE.csv`: notes explaining how generated data supports the exercise queries;
- `dataset_summary.json`: row-count summary.

## Important Assumptions

- ICD-10 and procedure catalogs should come from official source files.
- KEN data comes from an improved/official source. The generator fails clearly if no official KEN data can be found.
- `icd10_ken_map.csv` is rebuilt from the official map when compatible with `ken.csv`; otherwise it is generated from the active KEN codes.
- Procedure events are generated only from `procedure_catalog.csv`, with `place_id` chosen from a matching `operating_place.place_type`.
- Procedure catalog codes/names come from the official procedure source; standard duration and cost are deterministic estimates by category when the source lacks clean values for every row.
- Hospitalizations are generated without overlapping stays for the same patient or same bed.
- Shift assignments are generated across a multi-year window while respecting monthly limits, rest windows, night-shift limits, and senior-doctor coverage.
- Drug, active-substance, allergy, and prescription rows are validated against their reference CSVs before the bundle is accepted.
- Drug/substance data uses EMA Article 57 when provided. Without that official file, the medication-related CSVs remain empty.
- The generated data is deterministic, so the same inputs, seed, and count options should produce the same result.

## Recommended Use

Use the generator for repeatable testing and demonstration. For final submission, keep a short note explaining which CSV files came from official sources and which were generated synthetically.
