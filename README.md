# Ygeiopolis Healthcare System

Relational database project for the General Hospital **Ygeiopolis** semester assignment, academic year 2025-2026.

The repository contains the final MySQL/MariaDB schema, CSV data, validation script, 15 assignment queries with saved outputs, ER/relational diagrams, the report, and an optional read-only Streamlit demo UI.

## Repository Structure

```text
.
├── data/
│   ├── reference/
│   └── generated/
├── diagrams/
│   ├── er.pdf
│   └── relational.pdf
├── docs/
|   ├── Report_Ygeiopolis.pdf
│   └── exercise-brief-2025-2026.pdf
├── sql/
│   ├── install.sql
│   ├── load.sql
│   ├── validation.sql
│   ├── Q01.sql ... Q15.sql
│   └── Q01_out.txt ... Q15_out.txt
├── scripts/
│   └── generate_data.py
├── app.py
├── ui.py
├── queries.py
├── run_database.sh
├── run_database_windows.bat
├── run_query_windows.bat
├── requirements.txt
└── README.md
```

## Get The Project

```bash
git clone -b main https://github.com/ilias12345-rgb/Ygeiopolis-healthcare-system.git
cd Ygeiopolis-healthcare-system
```

If the repository is already cloned:

```bash
git pull --rebase origin main
```

## Run The Database

Run from the repository root after MySQL/MariaDB is installed.

### Windows

Use Command Prompt:

```bat
run_database_windows.bat
```

If your database user is not `root`, pass the user name:

```bat
run_database_windows.bat my_mysql_user
```

### macOS / Linux

```bash
bash run_database.sh
```

The runner scripts create the `ygeiopolis` database, load the included CSV files, and run validation.

## Run Queries

The final queries are stored in `sql/Q01.sql` through `sql/Q15.sql`.

On Windows, use the UTF-8 query runner for any query:

```bat
run_query_windows.bat Q01
run_query_windows.bat Q02
run_query_windows.bat Q15
```

On macOS/Linux, run any query by changing the file name:

```bash
mysql --default-character-set=utf8mb4 -t -u root < sql/Q01.sql
mysql --default-character-set=utf8mb4 -t -u root < sql/Q15.sql
```

To regenerate all saved outputs on macOS/Linux:

```bash
for n in $(seq -w 1 15); do
  mysql --default-character-set=utf8mb4 -t -u root < "sql/Q${n}.sql" > "sql/Q${n}_out.txt"
done
```

Saved outputs are included as `sql/Q01_out.txt` through `sql/Q15_out.txt`.

## Main SQL Files

- `sql/install.sql`: creates tables, constraints, indexes, views, triggers, and stored procedures.
- `sql/load.sql`: loads the included CSV data from `data/reference` and `data/generated`.
- `sql/validation.sql`: prints row counts and consistency checks after loading.
- `sql/Q01.sql` through `sql/Q15.sql`: final assignment queries.
- `sql/Q01_out.txt` through `sql/Q15_out.txt`: saved query outputs.

## Optional UI Demo

The Streamlit app is read-only and is used only for demonstration.

Install dependencies:

```bash
python3 -m pip install -r requirements.txt
```

Run:

```bash
streamlit run app.py
```

Windows alternative:

```powershell
py -3 -m streamlit run app.py
```

## Final Submission Checklist

- `README.md`
- `Report_Ygeiopolis.pdf`
- `diagrams/er.pdf`
- `diagrams/relational.pdf`
- `sql/install.sql`
- `sql/load.sql`
- `sql/validation.sql`
- `sql/Q01.sql` through `sql/Q15.sql`
- `sql/Q01_out.txt` through `sql/Q15_out.txt`
- `data/reference/*.csv`
- `data/generated/*.csv`
- `scripts/generate_data.py`
- `requirements.txt`
- optional UI files: `app.py`, `ui.py`, `queries.py`, `streamlit_app.py`, `.streamlit/config.toml`
