#!/usr/bin/env python3
import yaml
import sys
import pathlib

def validate_yaml(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            yaml.safe_load(file)
        print("YAML syntax validation: PASSED")
        return True
    except yaml.YAMLError as e:
        print(f"YAML syntax validation: FAILED")
        print(f"Error: {e}")
        return False
    except Exception as e:
        print(f"File read error: {e}")
        return False

if __name__ == "__main__":
    file_path = "config.yaml"
    success = validate_yaml(file_path)
    sys.exit(0 if success else 1)
