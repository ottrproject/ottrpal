
<!-- badges: start -->

[![R-CMD-check](https://github.com/ottrproject/ottrpal/workflows/R-CMD-check/badge.svg)](https://github.com/ottrproject/ottrpal/actions) [![CRAN status](https://www.r-pkg.org/badges/version/ottrpal)](https://CRAN.R-project.org/package=ottrpal) [![Downloads](http://cranlogs.r-pkg.org/badges/grand-total/ottrpal)](https://cran.r-project.org/package=ottrpal) [![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable) <!-- [![GitHub release (latest by --> <!-- date)](https://img.shields.io/github/v/release/ottrproject/ottrpal?style=social)](https://github.com/ottrproject/ottrpal/releases/tag/v1.0.0) --> <!-- [![Codecov test --> <!-- coverage](https://codecov.io/gh/ottrproject/ottrpal/branch/main/graph/badge.svg)](https://codecov.io/gh/ottrproject/ottrpal?branch=main) -->

<!-- badges: end -->

<!-- README.md is generated from README.Rmd. Please edit that file -->

# ottrpal package

`ottrpal` is a companion R package for OTTR courses (Open-source Tools for Training Resources).

Go to [ottrproject.org](https://www.ottrproject.org/) to get started! :tada:

- Perform URL, spell, and formatting checks for your Quarto and R markdown, and markdown files.
- Prep your courses for upload to Massive Open Online Courses (MOOCs): [Coursera](https://www.coursera.org/) and [Leanpub](https://leanpub.com/).
- `ottrfy()` your course to make it ready for all the OTTR functionality. 

## Installing ottrpal:

You can install `ottrpal` from GitHub with:
```
install.packages("ottrpal")
```

If you want the development version (not advised) you can install using the `remotes` package to install from GitHub.
```
if (!("remotes" %in% installed.packages())) {
  install.packages("remotes")
}
remotes::install_github("ottrproject/ottrpal")
```

# Using ottrpal through docker 

There are a few options at this time. The ottrpal docker image will execute at the mount location so you can either have your working directory and use the commands below *or* you can point your volume to your specific OTTR repo by replacing `$PWD` with the relative file path tot the top of your directory (what should contain the `index.Rmd` or `index.qmd` etc). 

Using the executable docker image works like this: 
```
docker run -v $PWD:/home jhudsl/ottrpal:dev command_of_choice
```
You can run checks: "spelling", "urls", "quiz_format" by putting one of these options in there
```
docker run -v $PWD:/home jhudsl/ottrpal:dev spelling
```
Or you can render OTTR websites using "rmd", "quarto", "quarto_web", or "rmd_web"
```
docker run -v $PWD:/home jhudsl/ottrpal:dev rmd
```
