import yaml
import sys

try:
    with open('config.yaml', 'r') as f:
        data = yaml.safe_load(f)
    print("YAML syntax validation: PASSED")
    print("Configuration loaded successfully")
    print(f"Found {len(data)} top-level keys: {list(data.keys())}")
except yaml.YAMLError as e:
    print("YAML syntax validation: FAILED")
    print(f"YAML Error: {e}")
    sys.exit(1)
except Exception as e:
    print("YAML syntax validation: FAILED")
    print(f"Error: {e}")
    sys.exit(1)
