#!/usr/bin/env python3
import sys
sys.path.insert(0, 'src')

try:
    import hylang_migrations.config as config
    print("Available in config module:")
    for attr in dir(config):
        if not attr.startswith('_'):
            print(f"  - {attr}")
except Exception as e:
    print(f"Error: {e}")