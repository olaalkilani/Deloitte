# GitHub Repository Code Guide

This document provides instructions on how to run the code from the GitHub repository and offers explanations for each file in the repository. Additionally, it offers a summary of what the code represents.

## Getting Started

### `main.py`

- **Description**: This Python file is responsible for extracting CSV files from the source and consolidating them into a single Unicode text file named 'output_all.txt.'

- **How to Run**: Execute this file to run the program.

### `output_all.txt`

- **Description**: This data file contains all CSV data in Unicode format.

### `DDL`

- **Description**: This directory contains DDL (Data Definition Language) scripts that will create all the necessary database schemas, tables, and sequences.

- **Instructions**: Run these scripts to set up the database structure and permissions.

### `CNTRL_DATA.ctl`

- **Description**: This control file is used to load data from 'output_all.txt' into an Oracle database.

- **Instructions**:
   1. Open your Oracle SQL*Loader Wizard.
   2. Navigate to the Database tab.
   3. Select Import.
   4. Choose SQL*Loader Wizard.
   5. Specify 'CNTRL_DATA.ctl' as the control file.
   6. Configure the control file directory to point to 'output_all.txt.'
   7. Execute the import.

### `SME_PKG.pkb`

- **Description**: This file contains an Oracle Package that includes all the necessary procedures needed for data processing.

- **Instructions**: Use `SME_PKG.pkb` to build the package and run it to obtain production-normalized and cleaned data. Execute the following command:

```sql
EXEC STG.SME_PKG.LOAD_ALL();

Feel free to replace the file names and descriptions with the actual names and details from your GitHub repository, and make any necessary modifications to the instructions to match your specific code and setup.
