# Result cache for the Monte Carlo calculators (ROADMAP Phase 6, "bindCache() for repeated results"). Given the same arguments,
# seed included, a simulation-based calc_*() returns the same result, and one run can take several seconds. The app asks for the
# same result again whenever a user goes back to a calculator, presses Calculate twice or returns to earlier inputs, and on a shared
# server different users often start from the same defaults. memo_calc() keeps the last results in memory, shared by every session
# of the R process, so a repeat is immediate.
#
# The closed-form calculators are not cached: they take microseconds, less than building the cache key. shiny::bindCache() was not
# used because the slow modules compute inside one reactive for several designs, and caching the call itself is simpler and also
# covers the power curves. No new dependency: the store is an environment and the key is the deparsed call.
#
# Turn it off with options(epidemiologysuite.cache = FALSE). Errors are not cached (the call simply fails again).

.memo_cache <- new.env(parent = emptyenv())
.memo_cache$store <- new.env(parent = emptyenv())
.memo_cache$order <- character()   # keys, oldest first; the oldest is dropped when the cache is full

.memo_max_entries <- 200L

# The cache key of a call: the function name and the deparsed arguments (names, exact values, attributes).
.memo_key <- function(fn_name, args) {
  paste0(fn_name, "|", paste(deparse(args, control = c("keepNA", "keepInteger", "niceNames", "showAttributes", "digits17")), collapse = ""))
}

.memo_enabled <- function() isTRUE(getOption("epidemiologysuite.cache", TRUE))

# list(found = TRUE/FALSE, value = the stored result)
memo_lookup <- function(key) {
  if (.memo_enabled() && exists(key, envir = .memo_cache$store, inherits = FALSE)) {
    list(found = TRUE, value = get(key, envir = .memo_cache$store, inherits = FALSE))
  } else {
    list(found = FALSE, value = NULL)
  }
}

memo_store <- function(key, value) {
  force(value)   # a failing calculation must fail here, before anything is recorded
  if (!.memo_enabled()) return(invisible(value))
  if (!exists(key, envir = .memo_cache$store, inherits = FALSE)) .memo_cache$order <- c(.memo_cache$order, key)
  assign(key, value, envir = .memo_cache$store)
  if (length(.memo_cache$order) > .memo_max_entries) {
    drop <- .memo_cache$order[seq_len(length(.memo_cache$order) - .memo_max_entries)]
    rm(list = drop, envir = .memo_cache$store)
    .memo_cache$order <- setdiff(.memo_cache$order, drop)
  }
  invisible(value)
}

# Calls the calculation function named `fn_name` with the arguments in `...`, or returns the stored result of an identical earlier call.
memo_calc <- function(fn_name, ...) {
  fn <- get(fn_name, envir = environment(memo_calc), mode = "function")
  if (!.memo_enabled()) return(fn(...))
  args <- list(...)
  key <- .memo_key(fn_name, args)
  hit <- memo_lookup(key)
  if (hit$found) return(hit$value)
  memo_store(key, do.call(fn, args))
}

# Empties the cache (used by the tests).
memo_clear <- function() {
  rm(list = ls(.memo_cache$store, all.names = TRUE), envir = .memo_cache$store)
  .memo_cache$order <- character()
  invisible(NULL)
}

memo_size <- function() length(.memo_cache$order)
