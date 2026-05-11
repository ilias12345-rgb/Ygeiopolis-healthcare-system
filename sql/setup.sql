-- Portable setup script. Run from the project or generated bundle root:
-- mysql --local-infile=1 -u root -p < sql/setup.sql
--
-- The relative LOAD DATA paths in sql/load.sql expect this structure:
-- data/reference/*.csv
-- data/generated/*.csv

SOURCE sql/install.sql;
SOURCE sql/load.sql;
SOURCE sql/validation.sql;
