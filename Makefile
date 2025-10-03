.PHONY: setup clean test run-analysis install-deps serve-app run-pipeline

# Complete pipeline
run-pipeline:
	Rscript scripts/run_analysis.R all

# Individual steps
setup:
	Rscript scripts/00_setup.R

load-data:
	Rscript scripts/01_data_loading.R

clean-data:
	Rscript scripts/02_data_cleaning.R

train-models:
	Rscript scripts/03_modeling.R

# Utilities
clean:
	rm -rf output/plots/*
	rm -rf output/reports/*
	rm -rf models/trained/*
	rm -rf data/processed/*
	rm -rf data/cleaned/*
	rm -rf logs/*

test:
	Rscript tests/test_runner.R

run-analysis:
	Rscript scripts/run_analysis.R

install-deps:
	Rscript -e "renv::restore()"

serve-app:
	Rscript app/run_app.R

# Help
help:
	@echo "Available targets:"
	@echo "  run-pipeline  - Run complete analysis pipeline"
	@echo "  setup         - Setup project environment"
	@echo "  load-data     - Load and validate data"
	@echo "  clean-data    - Clean and preprocess data"
	@echo "  train-models  - Train prediction models"
	@echo "  test          - Run test suite"
	@echo "  serve-app     - Start Shiny dashboard"
	@echo "  clean         - Clean output files"
	@echo "  install-deps  - Install dependencies"
	@echo "  help          - Show this help"