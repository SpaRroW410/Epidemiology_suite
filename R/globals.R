# Names that R CMD check's code analysis cannot resolve. They are the named arguments that R/background.R passes to
# mirai::mirai() and mirai::everywhere() (lib, pkg, rng_kind): mirai evaluates the expression in a background process where these
# names are bound to the values given, so they are not global variables of this package.
utils::globalVariables(c("lib", "pkg", "rng_kind"))
