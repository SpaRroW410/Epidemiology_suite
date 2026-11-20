# A small Word (.docx) writer in base R (Studies, decision S2 of 3 Nov 2026: no new runtime package, and it has to work in the browser
# build, where there is no zip program). A .docx is a zip archive of a few XML files (ECMA-376 / ISO/IEC 29500 "Office Open XML"):
# [Content_Types].xml, _rels/.rels, word/document.xml, word/styles.xml, word/settings.xml and word/_rels/document.xml.rels (settings
# marks the file as current Word format, so Word does not open it in compatibility mode; officer >= 0.7 requires the part). The archive is written with
# "stored" (uncompressed) entries, which every zip reader accepts; that needs only the CRC-32 of each part (the zip format's own check,
# polynomial 0xEDB88320, written here and checked against the standard check value CRC-32("123456789") = 0xCBF43926).
# What it supports is what a study needs: headings, paragraphs with bold / italic / monospace runs, and tables with a header row.
# The tests read the file back with `officer` and unzip it with the system's unzip; LibreOffice converts it when it is installed.

# --- bytes -------------------------------------------------------------------------------------------------------------------

.le_bytes <- function(x, n) {
  x <- as.numeric(x)
  as.raw(vapply(seq_len(n) - 1, function(i) (x %/% 256^i) %% 256, numeric(1)))
}
.u16 <- function(x) .le_bytes(x, 2)
.u32 <- function(x) .le_bytes(x, 4)

# CRC-32 lookup table, kept as two 16-bit halves so that every value fits R's signed 32-bit integers
.crc32_table <- local({
  tab <- NULL
  function() {
    if (!is.null(tab)) return(tab)
    hi <- integer(256); lo <- integer(256)
    for (n in 0:255) {
      h <- 0L; l <- n
      for (k in 1:8) {
        odd <- bitwAnd(l, 1L) == 1L
        l <- bitwOr(bitwShiftR(l, 1L), bitwShiftL(bitwAnd(h, 1L), 15L))
        h <- bitwShiftR(h, 1L)
        if (odd) { h <- bitwXor(h, 0xEDB8L); l <- bitwXor(l, 0x8320L) }
      }
      hi[n + 1] <- h; lo[n + 1] <- l
    }
    tab <<- list(hi = hi, lo = lo)
    tab
  }
})

# CRC-32 of a raw vector, as a number (0 .. 2^32 - 1)
.crc32 <- function(bytes) {
  t <- .crc32_table()
  h <- 0xFFFFL; l <- 0xFFFFL
  b <- as.integer(bytes)
  for (x in b) {
    i <- bitwAnd(bitwXor(l, x), 0xFFL) + 1L
    l <- bitwXor(bitwOr(bitwShiftR(l, 8L), bitwShiftL(bitwAnd(h, 0xFFL), 8L)), t$lo[i])
    h <- bitwXor(bitwShiftR(h, 8L), t$hi[i])
  }
  h <- bitwXor(h, 0xFFFFL); l <- bitwXor(l, 0xFFFFL)
  h * 65536 + l
}

# A zip archive of stored (uncompressed) entries. `files`: named list of raw vectors, the names being the paths in the archive.
.zip_stored <- function(files, time = Sys.time()) {
  lt <- as.POSIXlt(time)
  dos_time <- lt$hour * 2048 + lt$min * 32 + lt$sec %/% 2
  dos_date <- (max(lt$year + 1900, 1980) - 1980) * 512 + (lt$mon + 1) * 32 + lt$mday
  local <- list(); central <- list(); offset <- 0
  for (nm in names(files)) {
    data <- files[[nm]]; name <- charToRaw(enc2utf8(nm))
    crc <- .crc32(data); size <- length(data)
    common <- c(.u16(20), .u16(0x0800), .u16(0), .u16(dos_time), .u16(dos_date), .u32(crc), .u32(size), .u32(size), .u16(length(name)), .u16(0))
    head <- c(.u32(0x04034b50), common, name)
    local[[length(local) + 1]] <- c(head, data)
    central[[length(central) + 1]] <- c(.u32(0x02014b50), .u16(20), common, .u16(0), .u16(0), .u16(0), .u32(0), .u32(offset), name)
    offset <- offset + length(head) + size
  }
  cd <- unlist(central, use.names = FALSE)
  end <- c(.u32(0x06054b50), .u16(0), .u16(0), .u16(length(files)), .u16(length(files)), .u32(length(cd)), .u32(offset), .u16(0))
  c(unlist(local, use.names = FALSE), cd, end)
}

# Base64 of a raw vector (to hand a file to the browser, which saves it; nothing is written on the server)
.base64 <- function(bytes) {
  if (length(bytes) == 0) return("")
  chars <- strsplit("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/", "")[[1]]
  b <- as.integer(bytes)
  pad <- (3 - length(b) %% 3) %% 3
  b <- c(b, integer(pad))
  m <- matrix(b, nrow = 3)
  n <- m[1, ] * 65536 + m[2, ] * 256 + m[3, ]
  idx <- rbind(n %/% 262144, (n %/% 4096) %% 64, (n %/% 64) %% 64, n %% 64) + 1
  out <- chars[as.vector(idx)]
  if (pad) out[(length(out) - pad + 1):length(out)] <- "="
  paste(out, collapse = "")
}

# --- Word XML ------------------------------------------------------------------------------------------------------------------

# Text for XML: escaped, and without the control characters XML 1.0 does not allow
.xml_esc <- function(x) {
  x <- enc2utf8(as.character(x))
  x <- gsub("[\x01-\x08\x0B\x0C\x0E-\x1F]", "", x, useBytes = TRUE)
  x <- gsub("&", "&amp;", x, fixed = TRUE); x <- gsub("<", "&lt;", x, fixed = TRUE); x <- gsub(">", "&gt;", x, fixed = TRUE)
  gsub("\"", "&quot;", x, fixed = TRUE)
}

#' A run of text (part of a paragraph)
#' @noRd
docx_run <- function(text, bold = FALSE, italic = FALSE, mono = FALSE) {
  props <- paste0(if (bold) "<w:b/>" else "", if (italic) "<w:i/>" else "",
                  if (mono) "<w:rFonts w:ascii=\"Consolas\" w:hAnsi=\"Consolas\" w:cs=\"Consolas\"/><w:sz w:val=\"20\"/>" else "")
  paste0("<w:r>", if (nzchar(props)) paste0("<w:rPr>", props, "</w:rPr>") else "", "<w:t xml:space=\"preserve\">", .xml_esc(text), "</w:t></w:r>")
}

#' A paragraph: plain text, or runs from docx_run(); `style` is a paragraph style of .docx_styles ("Heading1", "Heading2", "Small")
#' @noRd
docx_p <- function(..., style = NULL) {
  parts <- unlist(list(...))
  runs <- vapply(parts, function(p) if (startsWith(p, "<w:r>")) p else docx_run(p), character(1))
  paste0("<w:p>", if (!is.null(style)) paste0("<w:pPr><w:pStyle w:val=\"", style, "\"/></w:pPr>") else "", paste(runs, collapse = ""), "</w:p>")
}

#' A table from a data frame of text, with a bold header row repeated on each page
#' @noRd
docx_table <- function(df) {
  cell <- function(x, bold = FALSE) paste0("<w:tc><w:p>", docx_run(x, bold = bold), "</w:p></w:tc>")
  border <- function(side) sprintf("<w:%s w:val=\"single\" w:sz=\"4\" w:space=\"0\" w:color=\"808080\"/>", side)
  head <- paste0("<w:tr><w:trPr><w:tblHeader/></w:trPr>", paste(vapply(names(df), cell, character(1), bold = TRUE), collapse = ""), "</w:tr>")
  rows <- vapply(seq_len(nrow(df)), function(i) paste0("<w:tr>", paste(vapply(as.character(unlist(df[i, ])), cell, character(1)), collapse = ""), "</w:tr>"), character(1))
  paste0("<w:tbl><w:tblPr><w:tblW w:w=\"0\" w:type=\"auto\"/><w:tblBorders>",
         paste(vapply(c("top", "left", "bottom", "right", "insideH", "insideV"), border, character(1)), collapse = ""),
         "</w:tblBorders><w:tblCellMar><w:left w:w=\"80\" w:type=\"dxa\"/><w:right w:w=\"80\" w:type=\"dxa\"/></w:tblCellMar></w:tblPr>",
         head, paste(rows, collapse = ""), "</w:tbl>", "<w:p/>")
}

.docx_styles <- '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:cs="Calibri" w:eastAsia="Calibri"/><w:sz w:val="22"/><w:lang w:val="en-GB"/></w:rPr></w:rPrDefault>
<w:pPrDefault><w:pPr><w:spacing w:after="120" w:line="264" w:lineRule="auto"/></w:pPr></w:pPrDefault></w:docDefaults>
<w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:qFormat/></w:style>
<w:style w:type="paragraph" w:styleId="Title"><w:name w:val="Title"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:qFormat/><w:pPr><w:spacing w:after="200"/></w:pPr><w:rPr><w:b/><w:sz w:val="40"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:qFormat/><w:pPr><w:keepNext/><w:spacing w:before="360" w:after="120"/><w:outlineLvl w:val="0"/></w:pPr><w:rPr><w:b/><w:sz w:val="30"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="heading 2"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:qFormat/><w:pPr><w:keepNext/><w:spacing w:before="240" w:after="80"/><w:outlineLvl w:val="1"/></w:pPr><w:rPr><w:b/><w:sz w:val="24"/></w:rPr></w:style>
<w:style w:type="paragraph" w:styleId="Small"><w:name w:val="Small"/><w:basedOn w:val="Normal"/><w:qFormat/><w:rPr><w:sz w:val="18"/><w:color w:val="595959"/></w:rPr></w:style>
</w:styles>'

#' A .docx file (raw bytes) from paragraphs and tables made with docx_p() / docx_table()
#' @param body Character vector of block XML (paragraphs, tables), in order.
#' @param title Document title (the file's properties).
#' @noRd
docx_document <- function(body, title = "Document", time = Sys.time()) {
  ns <- "xmlns:w=\"http://schemas.openxmlformats.org/wordprocessingml/2006/main\""
  document <- paste0('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<w:document ', ns, '><w:body>',
                     paste(body, collapse = ""),
                     '<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1134" w:right="1134" w:bottom="1134" w:left="1134" w:header="567" w:footer="567" w:gutter="0"/></w:sectPr>',
                     '</w:body></w:document>')
  stamp <- format(as.POSIXct(time), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  parts <- list(
    "[Content_Types].xml" = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/><Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/><Override PartName="/word/settings.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml"/><Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/></Types>',
    "_rels/.rels" = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/></Relationships>',
    "docProps/core.xml" = paste0('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><dc:title>',
      .xml_esc(title), '</dc:title><dc:creator>Epidemiological suite</dc:creator><dcterms:created xsi:type="dcterms:W3CDTF">', stamp,
      '</dcterms:created></cp:coreProperties>'),
    "word/_rels/document.xml.rels" = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings" Target="settings.xml"/></Relationships>',
    "word/document.xml" = document,
    "word/styles.xml" = .docx_styles,
    "word/settings.xml" = paste0('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n<w:settings ', ns, '>',
                                 '<w:defaultTabStop w:val="720"/><w:compat><w:compatSetting w:name="compatibilityMode" ',
                                 'w:uri="http://schemas.microsoft.com/office/word" w:val="15"/></w:compat></w:settings>')
  )
  .zip_stored(lapply(parts, function(x) charToRaw(enc2utf8(x))), time = time)
}
