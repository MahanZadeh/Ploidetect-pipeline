.PHONY: help
.DEFAULT_GOAL := help


VENV_PIP=venv
VENV_CONDA=venv_conda
# Many python versions should work.
PYTHON_VER=3.11
# Some kind of Pulp error with snakemake 8.27
SNAKEMAKE_VER='snakemake<8.2'


conda_venv:
	rm -rf $(VENV_CONDA)
	mkdir -p /tmp/$$USER
	export TMPDIR=/tmp/$$USER && \
	wget -4 https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -O miniconda.sh && \
	bash miniconda.sh -b -u -p $(VENV_CONDA) && \
	$(VENV_CONDA)/bin/conda install -y python=$(PYTHON_VER) pip

conda_snakemake:
	$(VENV_CONDA)/bin/conda install -y \
		-c conda-forge -c bioconda \
		$(SNAKEMAKE_VER) \
		snakefmt isort black flake8 mypy pylint pydocstyle samtools

	echo "installed conda venv with snakemake in $(VENV_CONDA)"
	echo "activate with:"
	echo "  source $(VENV_CONDA)/bin/activate"

pip_venv:  ## pip install is much faster and smaller, but missing some advanced snakemake features
	python -m venv $(VENV_PIP)
	# if the local python version is not installed/working use python from conda_venv
	# $(VENV_CONDA)/bin/python -m venv $(VENV_PIP)
	$(VENV_PIP)/bin/pip install -U pip

pip_snakemake:  ## python install
	$(VENV_PIP)/bin/pip install -U pip
	$(VENV_PIP)/bin/pip install -U $(SNAKEMAKE_VER) snakefmt

format-code:  ## apply standard formatter like snakefmt and black to scripts.
	# python script formatting
	$(VENV_PIP)/bin/pip install -U snakefmt isort black flake8 mypy pylint pydocstyle
	$(VENV_PIP)/bin/isort --profile black scripts
	$(VENV_PIP)/bin/black scripts *.py
	# Snakefile formatting
	$(VENV_PIP)/bin/snakefmt Snakefile* *.smk

lint: format-code  ## Code formatting and quality checkers
	$(VENV_PIP)/bin/flake8 --ignore E501 scripts
	$(VENV_PIP)/bin/mypy --ignore-missing-imports scripts/*.py

lint-snakefiles: format-code  ## snakemake linting suggestions
	snakemake Snakefile.gsc.smk --lint
# must be called individually on each Snakefile, but checks all imported rules
#	snakemake Snakefile --lint

help:  ## show this message and exit
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[32m%-13s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
