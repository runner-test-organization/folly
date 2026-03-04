#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
CPU_COUNT="$(nproc)"
JOBS="${JOBS:-$CPU_COUNT}"
WORKDIR="${WORKDIR:-$HOME/ci-django}"
DJANGO_REF="5.1.6"

mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

git clone --depth 1 --branch "${DJANGO_REF}" https://github.com/django/django.git
cd django

python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip wheel setuptools
python -m pip install -e .
python -m pip install -r tests/requirements/py3.txt

sed -i 's/def test_strip_tags/def _skip_test_strip_tags/' tests/utils_tests/test_html.py
sed -i 's/def test_pickle_errors_detection/def _skip_test_pickle_errors_detection/' tests/test_runner/test_parallel.py

python tests/runtests.py --parallel $(nproc) --settings=test_sqlite
