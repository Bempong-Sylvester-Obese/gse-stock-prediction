.PHONY: setup clean test run-analysis

setup:
	Rscript scripts/00_setup.R

clean:
	rm -rf output/plots/*
	rm -rf output/reports/*
	rm -rf models/trained/*

test:
	Rscript tests/test_runner.R

run-analysis:
	Rscript scripts/run_analysis.R

install-deps:
	Rscript -e "renv::restore()"

serve-app:
	Rscript app/run_app.R