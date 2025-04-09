if (Sys.getenv("GH_PAT") != "") {

test_that("Get base URL - Quarto", {

  # Authorize GitHub
  auth_from_secret("github",
                   token = Sys.getenv("GH_PAT"),
                   in_test = FALSE
  )
  ### Now run functions we will test
  base_url <- get_pages_url(repo_name = "ottrproject/OTTR_Quarto",
                            token = Sys.getenv("GH_PAT"))

  # TODO: Test that the URL can
  testthat::expect_true(base_url == "https://ottrproject.org/OTTR_Quarto/")
})

test_that("Get chapters - Quarto", {

  ### Set up the OTTR repo
  dir <- setup_ottr_template(dir = ".", type = "quarto")

  chapt_df <- get_chapters(path = dir,
                           html_page = file.path("docs", "index.html"))

  testthat::expect_named(chapt_df, c('chapt_title', 'data_level', 'url'))

})

test_that("Make screenshots - Quarto", {

  # We want to make screenshots from the course
  chapt_df_file <- make_screenshots(token = Sys.getenv("GH_PAT"),
                                    repo = "ottrproject/OTTR_Quarto",
                                    path = "OTTR_Quarto-main")

  testthat::expect_equal(chapt_df_file, "OTTR_Quarto-main/resources/chapt_screen_images/chapter_urls.tsv")

  chapt_df <- readr::read_tsv(file.path("OTTR_Quarto-main",
                                        "resources",
                                        "chapt_screen_images",
                                        "chapter_urls.tsv"))

  # Expect column names should still be the
  testthat::expect_named(chapt_df, c('chapt_title', 'data_level', 'url', 'img_path'))

})

test_that("Set Up Leanpub - ottrproject/OTTR_Quarto", {

  dir <- setup_ottr_template(dir = ".", type = "quarto")

  # We're going to delete this so we can test making it again
  unlink(file.path(dir, "manuscript"), recursive = TRUE)

  # Now run the iframe maker bit
  website_to_embed_leanpub(
    path = dir,
    chapt_img_key = file.path('resources', 'chapt_screen_images', 'chapter_urls.tsv'),
    make_book_txt = TRUE,
    quiz_dir = NULL)

  testthat::expect_true(
    file.exists(file.path(dir,
                          "manuscript",
                          "resources",
                          "chapt_screen_images",
                          "intro.png")))

  # Lets check what the file looks like
  intro <- readLines(file.path(dir, "manuscript", "Introduction-to-the-Course.md"))

  # Make sure the png is pointed to
  testthat::expect_true(any(grepl("poster:/Users/candacesavonen/Desktop/GitRepos/ottr-backend/ottrpal/tests/testthat/OTTR_Quarto-main/manuscript/resources/chapt_screen_images/intro.png", intro)))

  # Make sure we link to the page
  #testthat::expect_true(any(grepl("![](https://ottrproject.org/OTTR_Quarto/intro.html)", intro, fixed = TRUE)))

  clean_up()
})

}
