#!/usr/bin/env python3
"""Health check for scorebot"""

import sys
import urllib.request

try:
    response = urllib.request.urlopen('http://localhost:7010/', timeout=5)
    if response.status == 200:
        sys.exit(0)
    else:
        print(f'Unhealthy status: {response.status}')
        sys.exit(1)
except Exception as e:
    print(f'Health check error: {e}')
    sys.exit(1)

