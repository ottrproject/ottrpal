#' Download Google Slides pptx file
#'
#' @param id Identifier of Google slides presentation, passed to
#' \code{\link{get_slide_id}}
#'
#' @note This downloads presentations if they are public and also try to make
#' sure it does not fail on large files
#' @return Downloaded file (in temporary directory)
#' @export
get_gs_pptx <- function(id) {
  id <- as.character(id)
  pres_id <- get_slide_id(id)
  url <- export_url(id = pres_id)

  pptx_file <- file.path(paste0(pres_id, ".pptx"))

  # Only download it if it isn't yet present
  if (!file.exists(pptx_file)) {
    result <- httr::GET(url, httr::write_disk(pptx_file))
    warn_them <- FALSE
    fr_header <- result$headers$`x-frame-options`
    if (!is.null(fr_header)) {
      if (all(fr_header == "DENY")) {
        warn_them <- TRUE
      }
    }
    if (httr::status_code(result) >= 300) {
      warn_them <- TRUE
    }
    # don't write something if not really a pptx
    ctype <- result$headers$`content-type`
    if (httr::status_code(result) >= 400 &&
      !is.null(ctype) && grepl("html", ctype)) {
      file.remove(pptx_file)
    }
    if (grepl("ServiceLogin", result$url)) {
      warn_them <- TRUE
    }
    if (warn_them) {
      warning(
        paste0(
          "This presentation may not be available, ",
          "did you turn link sharing on?"
        )
      )
    }
  }
  pptx_file
}


export_url <- function(id, page_id = NULL, type = "pptx") {
  url <- paste0(
    "https://docs.google.com/presentation/d/",
    id, "/export/", type, "?id=", id
  )
  if (!is.null(page_id)) {
    url <- paste0(url, "&pageid=", page_id)
  }
  url
}

#' Get Notes from a PowerPoint (usually from Google Slides)
#'
#' @param file Character. Path for `PPTX` file
#' @param ... additional arguments to pass to \code{\link{xml_notes}},
#' particularly \code{xpath}
#'
#' @return Either a character vector or `NULL`
#' @export
#'
#' @importFrom utils unzip
#' @examples
#' \dontrun{
#' pptx_notes(ex_file)
#' pptx_slide_note_df(ex_file)
#' pptx_slide_text_df(ex_file)
#' }
pptx_notes <- function(file, ...) {
  df <- pptx_slide_note_df(file, ...)
  if (is.null(df)) {
    return(NULL)
  }
  # factorize file names
  fac <- basename(df$file)
  fac <- factor(fac, levels = unique(fac))
  # split df by file names
  # (notesSlide1.xml, notesSlide2.xml, ...)
  ss <- split(df, fac)
  # concatenate all notes in each slide
  res <- sapply(ss, function(x) {
    paste(x$text, collapse = " ")
  })
  if (any(trimws(res) %in% "")) {
    warning("Slides with no notes exists")
  }
  # if notes don't exist, put semicolon
  res[res == ""] <- ";"

  res
}

#' @export
#' @rdname pptx_notes
pptx_slide_text_df <- function(file, ...) {
  L <- unzip_pptx(file)
  slides <- L$slides

  if (length(slides) > 0) {
    # in case empty notes
    res <- lapply(slides, function(x) {
      xx <- xml_notes(x, collapse_text = FALSE, ...)
      if (length(xx) == 0) {
        return(NULL)
      }
      snum <- sub("[.]xml", "", sub("slide", "", basename(x)))
      snum <- as.numeric(snum)
      data.frame(
        file = x,
        slide = snum,
        text = xx,
        index = 1:length(xx),
        stringsAsFactors = FALSE
      )
    })
    res <- do.call(rbind, res)
    return(res)
  } else {
    return(NULL)
  }
}

#' @export
#' @rdname pptx_notes
pptx_slide_note_df <- function(file, ...) {
  L <- unzip_pptx(file)
  notes <- L$notes
  slides <- L$slides
  note_dir <- L$note_dir

  if (length(notes) > 0) {
    # in case empty notes
    assoc_notes <- sub("slide", "", basename(slides))
    assoc_notes <- paste0("notesSlide", assoc_notes)
    assoc_notes <- file.path(note_dir, assoc_notes)
    no_fe <- !file.exists(assoc_notes)
    # if assoc_notes don't exist
    if (any(no_fe)) {
      file.create(assoc_notes[no_fe])
      notes <- assoc_notes
    }
    res <- lapply(notes, function(x) {
      if (file.size(x) == 0) {
        xx <- ""
      } else {
        xx <- xml_notes(x, collapse_text = FALSE, ...)
      }
      if (length(xx) == 0) {
        xx <- ""
      }
      snum <- sub("[.]xml", "", sub("notesSlide", "", basename(x)))
      snum <- as.numeric(snum)
      data.frame(
        file = x,
        slide = snum,
        text = xx,
        index = 1:length(xx),
        stringsAsFactors = FALSE
      )
    })
    res <- do.call(rbind, res)
    return(res)
  } else {
    return(NULL)
  }
}


pptx_reorder_xml <- function(files) {
  if (length(files) == 0) {
    return(files)
  }
  nums <- basename(files)
  # nums = gsub(pattern = paste0(pattern, "(\\d*)[.]xml"),
  #             replacement = "\\1", nums)
  nums <- sub("[[:alpha:]]*(\\d.*)[.].*", "\\1", nums)
  nums <- as.numeric(nums)
  if (any(is.na(nums))) {
    warning(paste0(
      "Trying to parse set of files (example: ", files[1],
      ") from PPTX, failed"
    ))
    return(files)
  }
  files[order(nums)]
}

#' @export
#' @rdname pptx_notes
unzip_pptx <- function(file) {
  # return a file path that can be used for temporary files
  tdir <- tempfile()
  # create tdir (temporary file path)
  dir.create(tdir)
  # extract file
  unzip(file, exdir = tdir)

  # file path to xml files of slides
  slide_dir <- file.path(tdir, "ppt", "slides")
  slides <- list.files(
    path = slide_dir, pattern = "[.]xml$",
    full.names = TRUE
  )
  # order xml files (slide1.xml, slide2.xml, ...)
  slides <- pptx_reorder_xml(slides)

  # file path to xml files of notes
  note_dir <- file.path(tdir, "ppt", "notesSlides")
  notes <- list.files(
    path = note_dir, pattern = "[.]xml$",
    full.names = TRUE
  )
  # order xml files (notesSlide1.xml, notesSlide2.xml, ...)
  notes <- pptx_reorder_xml(notes)

  # create core.xml file path
  tdir <- normalizePath(tdir)
  props_dir <- file.path(tdir, "docProps")
  props_file <- file.path(props_dir, "core.xml")
  ari_core_file <- system.file("extdata", "docProps",
    "core.xml",
    package = "ariExtra"
  )
  # copy core.xml from ariExtra to props_file
  if (!dir.exists(props_file)) {
    dir.create(props_dir, recursive = TRUE)
    file.copy(ari_core_file, props_file,
      overwrite = TRUE
    )
  }

  L <- list(
    slides = slides,
    notes = notes,
    slide_dir = slide_dir,
    note_dir = note_dir,
    props_dir = props_dir,
    props_file = props_file,
    root_dir = tdir
  )
  return(L)
}

#' Get Notes from XML
#'
#' @param file XML file from a PPTX
#' @param collapse_text should text be collapsed by spaces?
#' @param xpath \code{xpath} to pass to [xml2::xml_find_all()]
#'
#' @return A character vector
#' @export
#'
#' @importFrom xml2 read_xml xml_text xml_find_all
xml_notes <- function(file, collapse_text = TRUE, xpath = "//a:r//a:t") {
  xdoc <- xml2::read_xml(file)
  # probably need to a:p//a:t and collapse all text within a a:p
  txt <- xml2::xml_find_all(x = xdoc, xpath = xpath)
  txt <- xml2::xml_text(txt)
  if (collapse_text) {
    txt <- paste(txt, collapse = " ")
  }
  return(txt)
}

#' Extract Object IDs using Google Slides API
#'
#' Performs a HTTP GET method to request the IDs of every slide in a Google
#' Slides presentation. The ID of the first slide is always 'p'.
#'
#' @param slide_url URL whose 'General access' is set to 'Anyone with the link'
#' @param token OAuth 2.0 Access Token. If you don't have a token, use
#'   [authorize()] to obtain an access token from Google's OAuth 2.0 server.
#' @param access_token Access token can be obtained from running authorize()
#'   interactively (token <-authorize(); token$credentials$access_token). This
#'   allows it to be passed in using two secrets.
#' @param refresh_token Refresh token can be obtained from running authorize()
#'   interactively (token <-authorize(); token$credentials$refresh_token). This
#'   allows it to be passed in using two secrets.
#' @return Character vector of object ID(s)
#' @importFrom httr config
#' @importFrom httr GET
#' @importFrom httr accept_json
#' @importFrom httr content
#' @export
#' @examples
#' \dontrun{
#' # First, obtain access token and store token for extract_object_id() to use
#' authorize(client_id = "MY_CLIENT_ID", client_secret = "MY_CLIENT_SECRET")
#' # Use stored token to talk to Google Slides API
#' extract_object_id(slide_url = "https://docs.google.com/presentation/d/1H5aF_ROKVxE-H
#'                                FHhoOy9vU2Y-y2M_PiV0q-JBL17Gss/edit?usp=sharing")
#' }
extract_object_id <- function(slide_url, token = NULL, access_token = NULL, refresh_token = NULL) {
  # Get Slide ID from URL
  id <- get_slide_id(slide_url)
  # Using Slide ID, create url that we'll send to GET
  get_url <- gsub("{presentationId}", id,
    "https://slides.googleapis.com/v1/presentations/{presentationId}",
    fixed = TRUE
  )

  # if token not provided, fetch token
  if (is.null(token)) {
    token_try <- try(get_token(), silent = TRUE)

    # We will supply credentials if none can be grabbed by get_token()
    if (is.null(token_try)) {
      auth_from_secret(
        access_token = access_token,
        refresh_token = refresh_token
      )
    }
    token <- get_token()
  } # else user provides token

  # Perform GET HTTP request
  config <- httr::config(token = token)
  result <- httr::GET(get_url, config = config, httr::accept_json())
  # Read in result
  result_content <- httr::content(result, "application/json")

  result_list$slides$objectId
}

#' Retrieve Speaker Notes and their corresponding Object (Slide) IDs from a Google Slides presentation
#'
#' Google Slides API calls a presentation slide ID as an 'object ID'.
#'
#' @param slide_url URL whose 'General access' is set to 'Anyone with the link'
#'
#' @return Data frame of Object IDs and Speaker notes.
#' @export
#'
#' @examples
#' \dontrun{
#' get_object_id_notes("https://docs.google.com/presentation/d/
#'                       1H5aF_ROKVxE-HFHhoOy9vU2Y-y2M_PiV0q-JBL17Gss/edit?usp=sharing")
#' }
get_object_id_notes <- function(slide_url) {
  # page ids
  object_ids <- extract_object_id(slide_url)
  # download as pptx
  pptx_file <- get_gs_pptx(slide_url)
  # Extract speaker notes
  speaker_notes <- pptx_notes(pptx_file)
  # Get rid of filenames in name
  names(speaker_notes) <- NULL

  data.frame(id = object_ids, notes = speaker_notes)
}
