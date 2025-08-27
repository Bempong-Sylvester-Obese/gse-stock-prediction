# Project-specific R configuration
options(
  repos = c(CRAN = "https://cloud.r-project.org/"),
  browserNLdisabled = TRUE,
  deparse.max.lines = 2
)

# Load renv for package management
if (file.exists("renv/activate.R")) {
  source("renv/activate.R")
}

# Set working directory helpers
.project_root <- here::here()