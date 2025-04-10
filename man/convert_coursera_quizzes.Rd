% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/quiz_formatting.R
\name{convert_coursera_quizzes}
\alias{convert_coursera_quizzes}
\title{Convert Leanpub md quiz to Coursera yaml quiz}
\usage{
convert_coursera_quizzes(
  input_quiz_dir = "quizzes",
  output_quiz_dir = "coursera_quizzes",
  verbose = TRUE
)
}
\arguments{
\item{input_quiz_dir}{A path to a directory of leanpub formatted quiz md files. By default assumes "quizzes" and looks in current directory.}

\item{output_quiz_dir}{A folder (existing or not) that the new coursera converted quizzes should be saved to. By default saves to "coursera_quizzes".}

\item{verbose}{Would you like the progress messages: TRUE/FALSE?}
}
\value{
A folder of coursera ready quiz files saved to the output directory specified as a yamls.
}
\description{
Convert Leanpub md quiz to Coursera yaml quiz
}
\examples{

# Set up a directory with a quiz in it for this example
tdir <- tempfile()
dir.create(tdir, showWarnings = FALSE, recursive = TRUE)

file.copy(
  from = good_quiz_path(),
  to = file.path(tdir, basename(good_quiz_path()))
)

# Provide path to directory of quizzes
convert_coursera_quizzes(tdir)

system("rm -r coursera_quizzes")
}
