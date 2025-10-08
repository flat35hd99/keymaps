#!/bin/bash

# Parse options
FORMAT_MODE=false
if [ "$1" = "-fmt" ]; then
    FORMAT_MODE=true
fi

# Configurable file extensions
JSON_EXTENSIONS="${JSON_EXTENSIONS:-json vil}"
YAML_EXTENSIONS="${YAML_EXTENSIONS:-yml yaml}"

# Check if tools are installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed"
    exit 1
fi

if ! command -v yq &> /dev/null; then
    echo "Error: yq is not installed"
    exit 1
fi

has_errors=false

# Check JSON files
if [ "$FORMAT_MODE" = true ]; then
    echo "Formatting JSON files..."
else
    echo "Checking JSON files..."
fi

for ext in $JSON_EXTENSIONS; do
    while IFS= read -r file; do
        if [ -f "$file" ]; then
            if [ "$FORMAT_MODE" = true ]; then
                echo "Formatting: $file"
                if ! jq . "$file" > "$file.tmp" 2>/dev/null; then
                    echo "Invalid JSON: $file"
                    rm -f "$file.tmp"
                    has_errors=true
                else
                    mv "$file.tmp" "$file"
                fi
            else
                echo "Checking: $file"
                if ! jq empty "$file" 2>/dev/null; then
                    echo "Invalid JSON: $file"
                    has_errors=true
                elif ! diff -q "$file" <(jq . "$file") > /dev/null 2>&1; then
                    echo "Not formatted: $file"
                    has_errors=true
                fi
            fi
        fi
    done < <(find . -name "*.$ext" -type f)
done

# Check YAML files
if [ "$FORMAT_MODE" = true ]; then
    echo "Formatting YAML files..."
else
    echo "Checking YAML files..."
fi

for ext in $YAML_EXTENSIONS; do
    while IFS= read -r file; do
        if [ -f "$file" ]; then
            if [ "$FORMAT_MODE" = true ]; then
                echo "Formatting: $file"
                if ! yq eval '.' "$file" > "$file.tmp" 2>/dev/null; then
                    echo "Invalid YAML: $file"
                    rm -f "$file.tmp"
                    has_errors=true
                else
                    mv "$file.tmp" "$file"
                fi
            else
                echo "Checking: $file"
                if ! yq eval '.' "$file" > /dev/null 2>&1; then
                    echo "Invalid YAML: $file"
                    has_errors=true
                else
                    original=$(cat "$file")
                    formatted=$(yq eval '.' "$file")
                    if [ "$original" != "$formatted" ]; then
                        echo "Not formatted: $file"
                        has_errors=true
                    fi
                fi
            fi
        fi
    done < <(find . -name "*.$ext" -type f)
done

if [ "$has_errors" = true ]; then
    if [ "$FORMAT_MODE" = true ]; then
        echo "Formatting completed with errors"
    fi
    exit 1
fi

if [ "$FORMAT_MODE" = true ]; then
    echo "All files formatted successfully"
else
    echo "All checks passed"
fi
exit 0