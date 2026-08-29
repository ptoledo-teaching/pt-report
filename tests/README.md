# PT Report regression suite

Run the complete contract against the three supported engines:

```bash
./tests/check-regressions.sh
```

For a focused local run, pass one or more engine names explicitly:

```bash
./tests/check-regressions.sh pdflatex
./tests/check-regressions.sh xelatex lualatex
```

The runner uses an isolated `mktemp` directory and leaves its path in the final
message so failed PDFs, logs, console output, extracted text, and bounding boxes
can be inspected. It requires `pdfinfo` and `pdftotext` in addition to the TeX
engines.

The mandatory template smoke test forces `nominted` and disables shell escape,
so the default run is self-contained. To additionally compile the checked-in
template exactly as shipped, enable the optional Minted smoke test:

```bash
PT_TEST_MINTED=1 ./tests/check-regressions.sh
```

That optional check requires the Minted Python/Pygments toolchain and enables
shell escape only for the checked-in template.

The suite checks the full template, page-numbering and blank-verso behavior,
empty optional metadata, the required-title diagnostic, wrapping of long author
data, right alignment without a trailing author row, rejection of `twocolumn`
and `notitlepage`, module composition, all four
languages, 10/11/12pt sizes, and the public `L`/`C`/`R`/`X` table-column
contract. PDF bounding boxes also verify that a standalone `tblr` has vertical
separation while the same environment inside a `table` float does not receive
duplicate internal spacing.

Module composition covers `coreonly`, `minimal`, `full`, the namespaced negative
options `ptnolayout`/`ptnocontent`/`ptnoruntime`, and restoration from
`coreonly` with `ptlayout`/`ptcontent`/`ptruntime`.
