# The built-in Word writer (R/docx_writer.R) and the Word file of a study (study_docx() in R/mod_studies.R).

test_that("CRC-32 gives the standard check value and agrees with another implementation", {
  hex <- function(v) paste(rev(sprintf("%02x", as.integer(.u32(v)))), collapse = "")
  expect_equal(hex(.crc32(charToRaw("123456789"))), "cbf43926")
  expect_equal(.crc32(raw(0)), 0)
  skip_if_not_installed("digest")
  set.seed(1)
  for (n in c(1, 7, 1000)) {
    x <- as.raw(sample(0:255, n, TRUE))
    expect_equal(hex(.crc32(x)), digest::digest(x, algo = "crc32", serialize = FALSE))
  }
})

test_that("base64 matches jsonlite's (which adds a line break every 76 characters) and decodes back", {
  skip_if_not_installed("jsonlite")
  set.seed(2)
  for (s in list(charToRaw("a"), charToRaw("ab"), charToRaw("abc"), as.raw(sample(0:255, 301, TRUE)))) {
    expect_equal(.base64(s), gsub("\n", "", jsonlite::base64_enc(s)))
    expect_identical(jsonlite::base64_dec(.base64(s)), s)
  }
  expect_equal(.base64(raw(0)), "")
})

test_that("a document is a valid zip with valid XML, and officer reads back its headings, text and table", {
  body <- c(docx_p("Title <&>", style = "Title"), docx_p(docx_run("Bold ", bold = TRUE), "and plain"), docx_p("Part", style = "Heading1"),
            docx_table(data.frame(a = c("1", "2"), `b c` = c("x", "y"), check.names = FALSE)), docx_p(docx_run("\\frac{a}{b}", mono = TRUE)))
  f <- tempfile(fileext = ".docx"); on.exit(unlink(f))
  writeBin(docx_document(body, "Test"), f)
  parts <- utils::unzip(f, list = TRUE)$Name
  expect_setequal(parts, c("[Content_Types].xml", "_rels/.rels", "docProps/core.xml", "word/_rels/document.xml.rels", "word/document.xml", "word/styles.xml",
                          "word/settings.xml"))
  if (nzchar(Sys.which("unzip"))) expect_match(paste(system2("unzip", c("-t", shQuote(f)), stdout = TRUE), collapse = "\n"), "No errors detected")
  skip_if_not_installed("xml2")
  d <- tempfile(); on.exit(unlink(d, recursive = TRUE), add = TRUE)
  utils::unzip(f, exdir = d)
  for (p in parts) expect_s3_class(xml2::read_xml(file.path(d, p)), "xml_document")
  skip_if_not_installed("officer")
  s <- officer::docx_summary(officer::read_docx(f))
  expect_equal(s$text[s$style_name %in% "Title"], "Title <&>")
  expect_equal(s$text[s$style_name %in% "heading 1"], "Part")
  expect_true("Bold and plain" %in% s$text)
  expect_setequal(s$text[s$content_type == "table cell"], c("a", "b c", "1", "2", "x", "y"))
})

test_that("LaTeX gets a plain-text form only when every command is known, with fractions bracketed so the order is kept", {
  expect_equal(latex_plain("PAF=\\frac{ad-bc}{(a+c)(c+d)}"), "PAF=(ad-bc)/((a+c)(c+d))")
  expect_equal(latex_plain("n = \\frac{n_0}{1 + \\dfrac{n_0 - 1}{N}}"), "n = (n_0)/(1 + (n_0 - 1)/N)")
  expect_equal(latex_plain("d = t\\sqrt{\\frac{1}{n_1}+\\frac{1}{n_2}}\\;\\text{(two groups)}"), "d = t sqrt(1/(n_1)+1/(n_2)) (two groups)")
  expect_equal(latex_plain("n = \\left(\\frac{Z_{1-\\alpha/2} + Z_{1-\\beta}}{h}\\right)^2"), "n = ((Z_(1-\u03b1/2) + Z_(1-\u03b2))/h)^2")
  expect_equal(latex_plain("x = \\frac{(a)}{(b)(c)}"), "x = (a)/((b)(c))")
  expect_true(is.na(latex_plain("\\hat{\\theta} = \\mathbb{E}[x]")))
  expect_true(is.na(latex_plain("")))
  expect_equal(.latex_blocks("$$a$$$$b = c$$"), c("a", "b = c"))
})

test_that("a study's Word file has the study name, a table for repeated use, the formula, and numbered references with the suite's own citation", {
  mk <- function(d, id) { e <- study_entry("proportion", "Proportions", calc_proportion_precision(p = 0.05, d = d), proportion_content[["precision"]]); e$id <- id; e }
  m <- study_entry("means", "Means", calc_means_1s(mu0 = 120, mu1 = 125, sd = 15), means_content[["single"]]); m$id <- "e3"
  f <- tempfile(fileext = ".docx"); on.exit(unlink(f))
  writeBin(study_docx(list(id = "s1", name = "Anaemia survey", entries = list(mk(0.03, "e1"), mk(0.02, "e2"), m))), f)
  skip_if_not_installed("officer")
  s <- officer::docx_summary(officer::read_docx(f))
  txt <- s$text
  expect_equal(txt[s$style_name %in% "Title"], "Anaemia survey")
  expect_match(txt[2], "3 result\\(s\\) from 2 calculator design\\(s\\)")
  h1 <- txt[s$style_name %in% "heading 1"]
  expect_equal(h1[3], "References")
  expect_match(h1[1], "^1\\. Proportions: ")
  expect_true("2 calculations" %in% txt)
  cells <- txt[s$content_type == "table cell"]
  expect_true(all(c("Margin of error (absolute) (d)", "0.03", "0.02", "Sample size (n)") %in% cells))   # readable names, short name kept
  expect_true(any(grepl("\\frac", txt, fixed = TRUE)))                       # the LaTeX of the formula
  expect_true(any(grepl("^Plain text: ", txt)))
  expect_true(any(grepl("^Source: .*\\[1\\]$", txt)))
  expect_true(any(grepl("^3\\. Maheshwari M\\. Epidemiological suite", txt)))  # two design references, then the suite
  expect_true(any(grepl("doi:10.5281/zenodo.23794230", txt, fixed = TRUE)))
})

test_that("an empty study still makes a file, and the file name is safe", {
  raw <- study_docx(list(id = "s2", name = "Study 2", entries = list()))
  expect_gt(length(raw), 1000)
  expect_equal(.study_file_name("Anaemia survey, Bhopal / 2026", as.Date("2026-11-03")), "Anaemia_survey_Bhopal_2026_2026-11-03.docx")
  expect_equal(.study_file_name("***", as.Date("2026-11-03")), "study_2026-11-03.docx")
})

test_that("LibreOffice opens the study file (when installed)", {
  soffice <- Sys.which("soffice")
  skip_if(!nzchar(soffice), "LibreOffice not installed")
  skip_on_cran()
  e <- study_entry("proportion", "Proportions", calc_proportion_precision(p = 0.3, d = 0.05), proportion_content[["precision"]]); e$id <- "e1"
  d <- tempfile(); dir.create(d); on.exit(unlink(d, recursive = TRUE))
  f <- file.path(d, "s.docx"); writeBin(study_docx(list(id = "s1", name = "Survey", entries = list(e))), f)
  # R's own LD_LIBRARY_PATH can stop LibreOffice from finding its libraries; a separate profile avoids clashing with a running copy
  system2(soffice, c(paste0("-env:UserInstallation=file://", d, "/profile"), "--headless", "--convert-to", "txt:Text", "--outdir", shQuote(d), shQuote(f)),
          stdout = FALSE, stderr = FALSE, env = "LD_LIBRARY_PATH=", timeout = 120)
  out <- file.path(d, "s.txt")
  expect_true(file.exists(out))
  expect_true(any(grepl("Survey", readLines(out, warn = FALSE))))
})
