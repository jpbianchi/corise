#!/bin/bash
source ../venv/bin/activate
# lsof -i :8000   # if previous run didn't end, gives you PID still running
# kill -9 <PID>

PYTHONPATH=.. uvicorn server:app --workers 2