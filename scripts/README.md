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
python3 scripts/generate_data.py --source-dir data_sources --output-dir hospital_dataset_bundle
```

The `--source-dir` folder should contain the official ICD-10, KEN, procedure, and optional EMA files. The output bundle is portable: it contains relative paths only, so it can be moved to another laptop and loaded from its root folder.

```bash
python3 scripts/generate_data.py \
  --source-dir data_sources \
  --output-dir hospital_dataset_bundle \
  --patient-count 500 \
  --emergency-count 1500 \
  --hospitalization-count 1200 \
  --lab-test-count 800 \
  --procedure-count 500 \
  --prescription-count 1000
```

Optional EMA Article 57 drug source:

```bash
python3 scripts/generate_data.py \
  --source-dir data_sources \
  --output-dir hospital_dataset_bundle \
  --ema-xlsx /path/to/article-57-product-data_en.xlsx
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
- Drug, active-substance, allergy, and prescription rows are validated against their reference CSVs before the bundle is accepted.
- Drug/substance data uses EMA Article 57 when provided. Without that official file, the medication-related CSVs remain empty.
- The generated data is deterministic, so the same inputs, seed, and count options should produce the same result.

## Recommended Use

Use the generator for repeatable testing and demonstration. For final submission, keep a short note explaining which CSV files came from official sources and which were generated synthetically.
