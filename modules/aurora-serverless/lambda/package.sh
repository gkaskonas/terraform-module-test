#!/bin/bash
set -e

cd "$(dirname "$0")"
rm -rf package db_users.zip

# Install dependencies directly (no Docker needed)
pip install -r requirements.txt -t package/

cp db_users.py package/
cd package && zip -r9 ../db_users.zip . && cd .. 