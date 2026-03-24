#!/bin/bash
set -euo pipefail

for test_file in tests/test_*.sh; do
    echo "Running $test_file"
    bash "$test_file"
done

echo "Running tests/test_cascade_packaging.py"
python3 -m unittest tests/test_cascade_packaging.py

echo "Running tests/test_catalog_parser.py"
python3 -m unittest tests/test_catalog_parser.py

echo "All tests passed"
