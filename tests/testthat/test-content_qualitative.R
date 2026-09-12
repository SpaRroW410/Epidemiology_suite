source(file.path("..", "..", "R", "content", "content_qualitative.R"))

# Unlike every other module in this app, the Qualitative & Mixed Methods
# Sample Size Guidance module has no calc_*.R function to unit-test --
# it is pure reference content, per the checklist's own explicit
# instruction for this section ("non-formula -- acknowledge, don't fake
# precision"). These tests instead verify the content data structure
# itself: every topic present, with a non-empty title, explanation, and
# citation, matching the three checklist items this module covers.

test_that("qualitative_content has all three expected topics", {
  expect_setequal(names(qualitative_content), c("saturation", "information_power", "purposive_theoretical"))
})

test_that("every qualitative_content topic has a non-empty title, explanation, and citation", {
  for (topic_name in names(qualitative_content)) {
    topic <- qualitative_content[[topic_name]]
    expect_true(is.character(topic$title) && nchar(topic$title) > 0, info = topic_name)
    expect_true(is.character(topic$explanation) && nchar(topic$explanation) > 0, info = topic_name)
    expect_true(is.character(topic$citation) && nchar(topic$citation) > 0, info = topic_name)
  }
})

test_that("the saturation topic reproduces Guest, Bunce & Johnson (2006)'s own quoted finding", {
  expect_true(grepl(
    "saturation occurred within the first twelve interviews",
    qualitative_content$saturation$explanation,
    fixed = TRUE
  ))
  expect_true(grepl("Guest", qualitative_content$saturation$citation, fixed = TRUE))
  expect_true(grepl("2006", qualitative_content$saturation$citation, fixed = TRUE))
})

test_that("the information_power topic covers all five of Malterud et al (2016)'s dimensions", {
  explanation <- qualitative_content$information_power$explanation
  expect_true(grepl("Study aim", explanation, fixed = TRUE))
  expect_true(grepl("Sample specificity", explanation, fixed = TRUE))
  expect_true(grepl("established theory", explanation, ignore.case = TRUE))
  expect_true(grepl("dialogue", explanation, ignore.case = TRUE))
  expect_true(grepl("Analysis strategy", explanation, fixed = TRUE))
  expect_true(grepl("Malterud", qualitative_content$information_power$citation, fixed = TRUE))
  expect_true(grepl("2016", qualitative_content$information_power$citation, fixed = TRUE))
})

test_that("the purposive_theoretical topic cites both Glaser & Strauss and Patton", {
  citation <- qualitative_content$purposive_theoretical$citation
  expect_true(grepl("Glaser", citation, fixed = TRUE))
  expect_true(grepl("Strauss", citation, fixed = TRUE))
  expect_true(grepl("Patton", citation, fixed = TRUE))
})
