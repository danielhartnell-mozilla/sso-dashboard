#!/bin/bash

python3 -m gunicorn.app.wsgiapp app:app --worker-class gevent --bind 0.0.0.0:8000 --workers=5 --reload
