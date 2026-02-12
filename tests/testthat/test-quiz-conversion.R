test_that("Round-trip Leanpub to Coursera to Leanpub preserves structure", {
  testthat::skip_on_cran()
  lp <- good_quiz_path()[1]
  if (length(lp) == 0) skip("Good quiz fixture not found")
  td <- tempfile()
  dir.create(td, showWarnings = FALSE, recursive = TRUE)
  # Leanpub -> Coursera
  convert_quiz(lp, output_quiz_dir = td, verbose = FALSE)
  yml_file <- list.files(td, pattern = "\\.(yml|yaml)$", full.names = TRUE)[1]
  testthat::expect_true(length(yml_file) > 0 && file.exists(yml_file))
  # Coursera -> Leanpub
  out_md <- convert_quiz_to_leanpub(yml_file, output_quiz_dir = td, verbose = FALSE)
  testthat::expect_true(file.exists(out_md))
  # Parse resulting Leanpub (extract content inside {quiz} for parse_quiz_df)
  raw_lines <- readLines(out_md)
  extracted <- extract_quiz(raw_lines)
  quiz_df <- parse_quiz_df(extracted$quiz_lines, remove_tags = TRUE)
  n_questions <- max(quiz_df$question, 0)
  testthat::expect_equal(n_questions, 4)
  # Each question should have at least one correct and one wrong answer
  for (q in seq_len(n_questions)) {
    q_df <- quiz_df[quiz_df$question == q, ]
    n_correct <- sum(grepl("correct_answer", q_df$type))
    n_wrong <- sum(grepl("wrong_answer", q_df$type))
    testthat::expect_gte(n_correct, 1)
    testthat::expect_gte(n_wrong, 1)
  }
})

test_that("Coursera to Leanpub preserves question and option structure", {
  testthat::skip_on_cran()
  yml_fixture <- system.file("extdata", "quizzes", "quiz_coursera_sample.yml", package = "ottrpal")
  if (!nzchar(yml_fixture) || !file.exists(yml_fixture)) skip("Coursera sample fixture not found")
  td <- tempfile()
  dir.create(td, showWarnings = FALSE, recursive = TRUE)
  # Coursera -> Leanpub
  md_path <- convert_quiz_to_leanpub(yml_fixture, output_quiz_dir = td, verbose = FALSE)
  testthat::expect_true(file.exists(md_path))
  # Parse both: original Coursera and converted Leanpub
  orig <- parse_coursera_quiz(readLines(yml_fixture))
  raw_md <- readLines(md_path)
  extracted <- extract_quiz(raw_md)
  leanpub_df <- parse_quiz_df(extracted$quiz_lines, remove_tags = TRUE)
  n_questions_leanpub <- max(leanpub_df$question, 0)
  testthat::expect_equal(n_questions_leanpub, length(orig))
  for (i in seq_along(orig)) {
    q_df <- leanpub_df[leanpub_df$question == i, ]
    n_opts_leanpub <- sum(grepl("answer", q_df$type))
    testthat::expect_equal(n_opts_leanpub, nrow(orig[[i]]$options))
    testthat::expect_equal(sum(grepl("correct_answer", q_df$type)), sum(orig[[i]]$options$is_correct))
  }
})

test_that("convert_leanpub_quizzes batch converts directory", {
  testthat::skip_on_cran()
  yml_fixture <- system.file("extdata", "quizzes", "quiz_coursera_sample.yml", package = "ottrpal")
  if (!nzchar(yml_fixture) || !file.exists(yml_fixture)) skip("Coursera sample fixture not found")
  td_in <- tempfile()
  td_out <- tempfile()
  dir.create(td_in, showWarnings = FALSE, recursive = TRUE)
  dir.create(td_out, showWarnings = FALSE, recursive = TRUE)
  file.copy(yml_fixture, file.path(td_in, "quiz_one.yml"))
  file.copy(yml_fixture, file.path(td_in, "quiz_two.yml"))
  out_paths <- convert_leanpub_quizzes(
    input_quiz_dir = td_in,
    output_quiz_dir = td_out,
    verbose = FALSE
  )
  testthat::expect_length(out_paths, 2)
  md_files <- list.files(td_out, pattern = "\\.md$", full.names = TRUE)
  testthat::expect_length(md_files, 2)
  for (f in md_files) {
    raw <- readLines(f)
    extracted <- extract_quiz(raw)
    quiz_df <- parse_quiz_df(extracted$quiz_lines, remove_tags = TRUE)
    testthat::expect_gte(max(quiz_df$question, 0), 1)
  }
})

test_that("Coursera to Leanpub produces one ? and C) / a) for single question", {
  testthat::skip_on_cran()
  # Minimal Coursera YAML: one question, one correct, one wrong
  minimal_yml <- c(
    "- typeName: multipleChoice",
    "  prompt: Pick the right one?",
    "  shuffleOptions: true",
    "  options:",
    "    - answer: Yes",
    "      isCorrect: true",
    "    - answer: No",
    "      isCorrect: false"
  )
  td <- tempfile()
  dir.create(td, showWarnings = FALSE, recursive = TRUE)
  writeLines(minimal_yml, file.path(td, "minimal.yml"))
  out_md <- convert_quiz_to_leanpub(file.path(td, "minimal.yml"), output_quiz_dir = td, verbose = FALSE)
  content <- readLines(out_md)
  testthat::expect_true(any(grepl("^\\? ", content)))
  testthat::expect_true(any(grepl("^C\\) ", content)))
  testthat::expect_true(any(grepl("^a\\) ", content)))
  parsed <- parse_coursera_quiz(minimal_yml)
  testthat::expect_length(parsed, 1)
  testthat::expect_equal(nrow(parsed[[1]]$options), 2)
  testthat::expect_equal(sum(parsed[[1]]$options$is_correct), 1)
})

test_that("Round-trip Coursera to Leanpub to Coursera with minimal quiz", {
  testthat::skip_on_cran()
  minimal_yml <- c(
    "- typeName: multipleChoice",
    "  prompt: Pick the right one?",
    "  shuffleOptions: true",
    "  options:",
    "    - answer: Yes",
    "      isCorrect: true",
    "    - answer: No",
    "      isCorrect: false"
  )
  td <- tempfile()
  dir.create(td, showWarnings = FALSE, recursive = TRUE)
  writeLines(minimal_yml, file.path(td, "minimal.yml"))
  md_path <- convert_quiz_to_leanpub(file.path(td, "minimal.yml"), output_quiz_dir = td, verbose = FALSE)
  # Re-convert to Coursera; parse_quiz_df treats single-line prompts as single_line_prompt so convert_quiz works
  convert_quiz(md_path, output_quiz_dir = td, verbose = FALSE)
  yml_back <- file.path(td, "minimal.md.yml")
  testthat::expect_true(file.exists(yml_back))
  back <- parse_coursera_quiz(readLines(yml_back))
  testthat::expect_length(back, 1)
  testthat::expect_equal(nrow(back[[1]]$options), 2)
  testthat::expect_equal(sum(back[[1]]$options$is_correct), 1)
})
