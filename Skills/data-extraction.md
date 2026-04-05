# Skill: Data Extraction

## Description
Extract, parse, and transform data from files, APIs, web pages, logs, or any structured/unstructured source.

## When to use
- Extracting data from JSON, XML, CSV, or log files
- Scraping information from web pages
- Parsing API responses
- Converting data between formats
- Filtering or aggregating data from large files
- Extracting text from images (OCR)

## Tools to use
- read_file - read source files
- web_fetch - get data from URLs
- web_search - find data sources
- execute_powershell - parse and transform data
- ocr_image - extract text from images
- write_file - save extracted data

## Workflow
1. Identify the data source (file, URL, API, image)
2. Read or fetch the source data
3. Parse and extract the needed information
4. Clean and format the data
5. Save results or present to user

## Tips
- Always check the raw format before parsing
- Handle encoding issues (UTF-8, BOM, etc.)
- Use regex for pattern-based extraction
- For JSON/XML, use ConvertFrom-Json/ConvertFrom-Xml
- Save intermediate results for large datasets
- Handle errors gracefully when data format varies
