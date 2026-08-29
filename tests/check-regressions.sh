#!/usr/bin/env bash
set -Eeuo pipefail

export LC_ALL=C.UTF-8

test_script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
test_repo_dir=$(dirname -- "$test_script_dir")
test_workspace_dir=$(dirname -- "$test_repo_dir")
test_fixture_dir="$test_script_dir/fixtures"
test_template_dir="$test_repo_dir/template"
test_commons_dir="$test_workspace_dir/pt-commons"
test_output_dir=$(mktemp -d "${TMPDIR:-/tmp}/pt-report-regressions.XXXXXX")
test_cache_dir="$test_output_dir/texmf-cache"
test_problem_pattern='(^!|LaTeX Error|Package .* Error|Class .* Error|Undefined control sequence|Overfull \\[hv]box|Missing character:|Emergency stop|Fatal error|Runaway argument|Missing number|Extra \})'

mkdir -p "$test_cache_dir"

die() {
    printf 'pt-report regression failure: %s\n' "$*" >&2
    printf 'Test artifacts: %s\n' "$test_output_dir" >&2
    exit 1
}

show_failure_context() {
    local test_log=$1
    local test_console=$2

    if [[ -f "$test_log" ]]; then
        printf '%s\n' '--- TeX log tail ---' >&2
        tail -n 80 "$test_log" >&2
    elif [[ -f "$test_console" ]]; then
        printf '%s\n' '--- TeX console tail ---' >&2
        tail -n 80 "$test_console" >&2
    fi
}

for test_tool in pdfinfo pdftocairo pdftotext awk grep tail mktemp tr; do
    command -v "$test_tool" >/dev/null 2>&1 ||
        die "required command not found: $test_tool"
done

case ${PT_TEST_MINTED:-0} in
    0|1) ;;
    *) die 'PT_TEST_MINTED must be either 0 or 1' ;;
esac

if (( $# == 0 )); then
    test_engines=(pdflatex xelatex lualatex)
else
    test_engines=("$@")
fi

for test_engine in "${test_engines[@]}"; do
    command -v "$test_engine" >/dev/null 2>&1 ||
        die "TeX engine not found: $test_engine"
done

COMPILED_LOG=
COMPILED_PDF=

compile_success() {
    local test_engine=$1
    local test_input=$2
    local test_case=$3
    local test_job=$4
    local test_passes=$5
    local test_work_dir=$6
    local test_shell_mode=${7:--no-shell-escape}
    local test_engine_name=${test_engine##*/}
    local test_case_dir="$test_output_dir/$test_engine_name/$test_case"
    local test_log="$test_case_dir/$test_job.log"
    local test_pdf="$test_case_dir/$test_job.pdf"
    local test_pass
    local test_console

    mkdir -p "$test_case_dir"
    printf '[%s] %s\n' "$test_engine_name" "$test_case"

    for (( test_pass = 1; test_pass <= test_passes; test_pass++ )); do
        test_console="$test_case_dir/pass-$test_pass.console"
        if ! (
            cd "$test_work_dir"
            env \
                TEXINPUTS="$test_fixture_dir:$test_template_dir:$test_repo_dir:$test_commons_dir:" \
                TEXMFCACHE="$test_cache_dir" \
                TEXMFVAR="$test_cache_dir" \
                XDG_CACHE_HOME="$test_cache_dir" \
                "$test_engine" \
                -interaction=nonstopmode \
                -halt-on-error \
                -file-line-error \
                "$test_shell_mode" \
                -recorder \
                -output-directory="$test_case_dir" \
                -jobname="$test_job" \
                "$test_input"
        ) >"$test_console" 2>&1; then
            show_failure_context "$test_log" "$test_console"
            die "$test_engine failed in $test_case on pass $test_pass"
        fi
    done

    [[ -s "$test_log" ]] || die "$test_case did not produce a TeX log"
    [[ -s "$test_pdf" ]] || die "$test_case did not produce a PDF"

    if grep -Eq "$test_problem_pattern" "$test_log"; then
        grep -En "$test_problem_pattern" "$test_log" >&2 || true
        die "$test_case produced a fatal diagnostic or an overfull box"
    fi

    COMPILED_LOG=$test_log
    COMPILED_PDF=$test_pdf
}

compile_expected_title_failure() {
    local test_engine=$1
    local test_engine_name=${test_engine##*/}
    local test_case=missing-title
    local test_job=missing-title
    local test_case_dir="$test_output_dir/$test_engine_name/$test_case"
    local test_log="$test_case_dir/$test_job.log"
    local test_console="$test_case_dir/pass-1.console"

    mkdir -p "$test_case_dir"
    printf '[%s] %s (expected failure)\n' "$test_engine_name" "$test_case"

    if (
        cd "$test_fixture_dir"
        env \
            TEXINPUTS="$test_fixture_dir:$test_repo_dir:$test_commons_dir:" \
            TEXMFCACHE="$test_cache_dir" \
            TEXMFVAR="$test_cache_dir" \
            XDG_CACHE_HOME="$test_cache_dir" \
            "$test_engine" \
            -interaction=nonstopmode \
            -halt-on-error \
            -file-line-error \
            -no-shell-escape \
            -output-directory="$test_case_dir" \
            -jobname="$test_job" \
            missing-title.tex
    ) >"$test_console" 2>&1; then
        die "$test_engine accepted \\maketitle without \\title"
    fi

    [[ -f "$test_log" ]] || {
        show_failure_context "$test_log" "$test_console"
        die "$test_engine failed without producing a log for missing-title"
    }

    grep -Eiq 'Class pt-report Error:.*title' "$test_log" || {
        show_failure_context "$test_log" "$test_console"
        die "missing-title did not report a clear pt-report class error"
    }

    if grep -Fq 'Undefined control sequence' "$test_log"; then
        show_failure_context "$test_log" "$test_console"
        die "missing-title leaked an internal undefined control sequence"
    fi
}

compile_expected_option_failure() {
    local test_engine=$1
    local test_option=$2
    local test_engine_name=${test_engine##*/}
    local test_case="rejected-$test_option"
    local test_job=$test_case
    local test_case_dir="$test_output_dir/$test_engine_name/$test_case"
    local test_log="$test_case_dir/$test_job.log"
    local test_console="$test_case_dir/pass-1.console"

    mkdir -p "$test_case_dir"
    printf '[%s] %s (expected failure)\n' "$test_engine_name" "$test_case"

    if (
        cd "$test_fixture_dir"
        env \
            TEXINPUTS="$test_fixture_dir:$test_repo_dir:$test_commons_dir:" \
            TEXMFCACHE="$test_cache_dir" \
            TEXMFVAR="$test_cache_dir" \
            XDG_CACHE_HOME="$test_cache_dir" \
            "$test_engine" \
            -interaction=nonstopmode \
            -halt-on-error \
            -file-line-error \
            -no-shell-escape \
            -output-directory="$test_case_dir" \
            -jobname="$test_job" \
            "$test_case.tex"
    ) >"$test_console" 2>&1; then
        die "$test_engine accepted the unsupported $test_option option"
    fi

    [[ -f "$test_log" ]] || {
        show_failure_context "$test_log" "$test_console"
        die "$test_engine failed without producing a log for $test_case"
    }

    grep -Fq "Error: The $test_option option is not supported." "$test_log" || {
        show_failure_context "$test_log" "$test_console"
        die "$test_case did not report the expected pt-report class error"
    }

    if grep -Fq 'Undefined control sequence' "$test_log"; then
        show_failure_context "$test_log" "$test_console"
        die "$test_case leaked an internal undefined control sequence"
    fi
}

pdf_page_count() {
    local test_pdf=$1
    pdfinfo "$test_pdf" |
        awk '/^Pages:[[:space:]]*/ { pages = $2; found = 1 }
             END { if (!found) exit 1; print pages }'
}

assert_page_count() {
    local test_pdf=$1
    local test_expected=$2
    local test_actual

    test_actual=$(pdf_page_count "$test_pdf") ||
        die "could not read page count from $test_pdf"
    [[ "$test_actual" == "$test_expected" ]] ||
        die "$test_pdf has $test_actual physical pages; expected $test_expected"
}

assert_minimum_page_count() {
    local test_pdf=$1
    local test_expected_minimum=$2
    local test_actual

    test_actual=$(pdf_page_count "$test_pdf") ||
        die "could not read page count from $test_pdf"
    (( test_actual >= test_expected_minimum )) ||
        die "$test_pdf has $test_actual pages; expected at least $test_expected_minimum"
}

extract_pdf_page() {
    local test_pdf=$1
    local test_page=$2
    local test_text="${test_pdf%.pdf}.page-$test_page.txt"

    pdftotext -f "$test_page" -l "$test_page" -layout \
        "$test_pdf" "$test_text" ||
        die "could not extract page $test_page from $test_pdf"
    printf '%s\n' "$test_text"
}

extract_pdf_text() {
    local test_pdf=$1
    local test_text="${test_pdf%.pdf}.txt"

    pdftotext -layout "$test_pdf" "$test_text" ||
        die "could not extract text from $test_pdf"
    printf '%s\n' "$test_text"
}

assert_pdf_contains() {
    local test_pdf=$1
    local test_expected=$2
    local test_text

    test_text=$(extract_pdf_text "$test_pdf")
    grep -Fq -- "$test_expected" "$test_text" ||
        die "$test_pdf does not contain '$test_expected'"
}

assert_page_contains() {
    local test_pdf=$1
    local test_page=$2
    local test_expected=$3
    local test_text

    test_text=$(extract_pdf_page "$test_pdf" "$test_page")
    grep -Fq -- "$test_expected" "$test_text" ||
        die "page $test_page of $test_pdf does not contain '$test_expected'"
}

assert_page_number() {
    local test_pdf=$1
    local test_page=$2
    local test_expected=$3
    local test_text

    test_text=$(extract_pdf_page "$test_pdf" "$test_page")
    grep -Eq "^[[:space:]]*$test_expected[[:space:]]*$" "$test_text" ||
        die "physical page $test_page of $test_pdf is not numbered $test_expected"
}

assert_page_empty() {
    local test_pdf=$1
    local test_page=$2
    local test_text
    local test_non_space

    test_text=$(extract_pdf_page "$test_pdf" "$test_page")
    test_non_space=$(tr -d '[:space:]' <"$test_text")
    [[ -z "$test_non_space" ]] ||
        die "physical page $test_page of $test_pdf is not empty"
}

assert_page_lacks_empty_metadata_artifacts() {
    local test_pdf=$1
    local test_page=$2
    local test_text

    test_text=$(extract_pdf_page "$test_pdf" "$test_page")
    if grep -Eq '^[[:space:]]*(-|v)[[:space:]]*$' "$test_text"; then
        die "empty optional metadata left a visible separator on page $test_page"
    fi
}

assert_log_contains() {
    local test_log=$1
    local test_expected=$2

    grep -Fq -- "$test_expected" "$test_log" ||
        die "$test_log does not contain '$test_expected'"
}

assert_text_inside_title_block() {
    local test_pdf=$1
    local test_page=$2
    local test_bbox="${test_pdf%.pdf}.page-$test_page.bbox.html"

    pdftotext -f "$test_page" -l "$test_page" -bbox \
        "$test_pdf" "$test_bbox" ||
        die "could not extract bounding boxes from $test_pdf"

    awk -F'"' '
        /<word xMin=/ {
            seen = 1
            x_min = $2 + 0
            y_min = $4 + 0
            x_max = $6 + 0
            y_max = $8 + 0
            if (x_min < 60 || x_max > 552 || y_min < 55 || y_max > 737) {
                print "Text outside title-page bounds: " $0 > "/dev/stderr"
                bad = 1
            }
        }
        END {
            if (!seen) {
                print "No words found while checking title-page bounds" > "/dev/stderr"
                exit 2
            }
            exit bad
        }
    ' "$test_bbox" ||
        die "title-page text escaped the 63pt page margins in $test_pdf"
}

assert_author_table_right_aligned() {
    local test_pdf=$1
    local test_page=$2
    local test_email=$3
    local test_details=$4
    local test_bbox="${test_pdf%.pdf}.page-$test_page.author.bbox.html"

    pdftotext -f "$test_page" -l "$test_page" -bbox \
        "$test_pdf" "$test_bbox" ||
        die "could not extract author-table bounds from $test_pdf"

    awk -F'"' -v email="$test_email" -v details="$test_details" '
        /<page width=/ { page_width = $2 + 0 }
        index($0, ">" email "</word>") {
            email_x_min = $2 + 0
            have_email = 1
        }
        index($0, ">" details "</word>") {
            details_x_max = $6 + 0
            have_details = 1
        }
        END {
            if (!page_width || !have_email || !have_details) {
                print "Could not locate author-table markers" > "/dev/stderr"
                exit 2
            }
            if (email_x_min <= page_width * 0.45 ||
                details_x_max <= page_width * 0.85) {
                printf "Author table is not right-aligned: email x=%.3f, details xMax=%.3f\n", \
                    email_x_min, details_x_max > "/dev/stderr"
                exit 3
            }
        }
    ' "$test_bbox" ||
        die "author table is not aligned to the right in $test_pdf"
}

assert_author_rule_rows() {
    local test_pdf=$1
    local test_page=$2
    local test_expected=$3
    local test_svg="${test_pdf%.pdf}.page-$test_page.author.svg"
    local test_actual

    pdftocairo -f "$test_page" -l "$test_page" -svg \
        "$test_pdf" "$test_svg" ||
        die "could not extract author-table vectors from $test_pdf"

    test_actual=$(awk '
        /<path fill="none".*stroke=.* d="M / {
            vector = $0
            sub(/^.* d="M /, "", vector)
            split(vector, coordinate, /[ "]+/)
            x_delta = coordinate[1] - coordinate[4]
            if (x_delta < 0) x_delta = -x_delta
            if (x_delta < 0.01) vertical_count++
        }
        END { print vertical_count + 0 }
    ' "$test_svg")

    [[ "$test_actual" == "$test_expected" ]] ||
        die "author divider has $test_actual row segments; expected $test_expected"
}

create_page_bbox() {
    local test_pdf=$1
    local test_page=$2
    local test_bbox="${test_pdf%.pdf}.page-$test_page.wrap.bbox.html"

    pdftotext -f "$test_page" -l "$test_page" -bbox \
        "$test_pdf" "$test_bbox" ||
        die "could not extract table bounding boxes from $test_pdf"
    printf '%s\n' "$test_bbox"
}

assert_markers_wrap() {
    local test_bbox=$1
    local test_start=$2
    local test_end=$3

    awk -F'"' -v start="$test_start" -v finish="$test_end" '
        index($0, ">" start "</word>") {
            start_y = $4 + 0
            have_start = 1
        }
        index($0, ">" finish "</word>") {
            finish_y = $4 + 0
            have_finish = 1
        }
        END {
            if (!have_start || !have_finish) {
                printf "Missing wrap markers %s/%s\n", start, finish > "/dev/stderr"
                exit 2
            }
            if (finish_y <= start_y + 2) {
                printf "%s and %s remained on one line\n", start, finish > "/dev/stderr"
                exit 3
            }
        }
    ' "$test_bbox" ||
        die "column content did not wrap between $test_start and $test_end"
}

assert_marker_gap_at_least() {
    local test_bbox=$1
    local test_upper=$2
    local test_lower=$3
    local test_minimum=$4

    awk -F'"' \
        -v upper="$test_upper" \
        -v lower="$test_lower" \
        -v minimum="$test_minimum" '
        index($0, ">" upper "</word>") {
            upper_y_max = $8 + 0
            have_upper = 1
        }
        index($0, ">" lower "</word>") {
            lower_y_min = $4 + 0
            have_lower = 1
        }
        END {
            if (!have_upper || !have_lower) {
                printf "Missing vertical-gap markers %s/%s\n", upper, lower > "/dev/stderr"
                exit 2
            }
            gap = lower_y_min - upper_y_max
            if (gap < minimum) {
                printf "Vertical gap %s -> %s is %.3fpt; expected at least %.3fpt\n", \
                    upper, lower, gap, minimum > "/dev/stderr"
                exit 3
            }
        }
    ' "$test_bbox" ||
        die "vertical gap between $test_upper and $test_lower is too small"
}

assert_marker_gap_at_most() {
    local test_bbox=$1
    local test_upper=$2
    local test_lower=$3
    local test_maximum=$4

    awk -F'"' \
        -v upper="$test_upper" \
        -v lower="$test_lower" \
        -v maximum="$test_maximum" '
        index($0, ">" upper "</word>") {
            upper_y_max = $8 + 0
            have_upper = 1
        }
        index($0, ">" lower "</word>") {
            lower_y_min = $4 + 0
            have_lower = 1
        }
        END {
            if (!have_upper || !have_lower) {
                printf "Missing vertical-gap markers %s/%s\n", upper, lower > "/dev/stderr"
                exit 2
            }
            gap = lower_y_min - upper_y_max
            if (gap > maximum) {
                printf "Vertical gap %s -> %s is %.3fpt; expected at most %.3fpt\n", \
                    upper, lower, gap, maximum > "/dev/stderr"
                exit 3
            }
        }
    ' "$test_bbox" ||
        die "vertical gap between $test_upper and $test_lower is too large"
}

declare -a option_fixtures=(
    options-coreonly-spanish-10pt
    options-minimal-english-11pt
    options-ptnolayout-french-12pt
    options-ptnocontent-portuguese-10pt
    options-ptnoruntime-spanish-11pt
    options-restore-ptlayout-english-12pt
    options-restore-ptcontent-french-10pt
    options-restore-ptruntime-portuguese-11pt
)

declare -A option_modules=(
    [options-coreonly-spanish-10pt]=000
    [options-minimal-english-11pt]=000
    [options-ptnolayout-french-12pt]=011
    [options-ptnocontent-portuguese-10pt]=101
    [options-ptnoruntime-spanish-11pt]=110
    [options-restore-ptlayout-english-12pt]=100
    [options-restore-ptcontent-french-10pt]=010
    [options-restore-ptruntime-portuguese-11pt]=001
)

declare -A option_font_sizes=(
    [options-coreonly-spanish-10pt]=10
    [options-minimal-english-11pt]=10.95
    [options-ptnolayout-french-12pt]=12
    [options-ptnocontent-portuguese-10pt]=10
    [options-ptnoruntime-spanish-11pt]=10.95
    [options-restore-ptlayout-english-12pt]=12
    [options-restore-ptcontent-french-10pt]=10
    [options-restore-ptruntime-portuguese-11pt]=10.95
)

declare -A option_languages=(
    [options-coreonly-spanish-10pt]=spanish
    [options-minimal-english-11pt]=english
    [options-ptnolayout-french-12pt]=french
    [options-ptnocontent-portuguese-10pt]=portuguese
    [options-ptnoruntime-spanish-11pt]=spanish
    [options-restore-ptlayout-english-12pt]=english
    [options-restore-ptcontent-french-10pt]=french
    [options-restore-ptruntime-portuguese-11pt]=portuguese
)

for test_engine in "${test_engines[@]}"; do
    compile_success \
        "$test_engine" \
        '\PassOptionsToClass{nominted}{pt-report}\input{template.tex}' \
        template-smoke \
        template \
        3 \
        "$test_template_dir"
    assert_minimum_page_count "$COMPILED_PDF" 5
    assert_pdf_contains "$COMPILED_PDF" 'Informe Técnico del Proyecto'
    assert_pdf_contains "$COMPILED_PDF" 'Reflexión Final'

    if [[ ${PT_TEST_MINTED:-0} == 1 ]]; then
        compile_success \
            "$test_engine" \
            template.tex \
            template-minted-smoke \
            template \
            3 \
            "$test_template_dir" \
            -shell-escape
        assert_minimum_page_count "$COMPILED_PDF" 5
        assert_pdf_contains "$COMPILED_PDF" 'Informe Técnico del Proyecto'
        assert_pdf_contains "$COMPILED_PDF" 'Reflexión Final'
    fi

    compile_success \
        "$test_engine" page-oneside.tex page-oneside page-oneside 1 \
        "$test_fixture_dir"
    assert_page_count "$COMPILED_PDF" 2
    assert_page_contains "$COMPILED_PDF" 2 PTREPORTONESIDECONTENT
    assert_page_number "$COMPILED_PDF" 2 2

    compile_success \
        "$test_engine" page-twoside.tex page-twoside page-twoside 1 \
        "$test_fixture_dir"
    assert_page_count "$COMPILED_PDF" 3
    assert_page_empty "$COMPILED_PDF" 2
    assert_page_contains "$COMPILED_PDF" 3 PTREPORTTWOSIDECONTENT
    assert_page_number "$COMPILED_PDF" 3 3

    compile_success \
        "$test_engine" metadata-empty.tex metadata-empty metadata-empty 1 \
        "$test_fixture_dir"
    assert_page_count "$COMPILED_PDF" 2
    assert_page_contains "$COMPILED_PDF" 1 'Optional Metadata'
    assert_page_contains "$COMPILED_PDF" 2 PTREPORTEMPTYMETADATACONTENT
    assert_page_lacks_empty_metadata_artifacts "$COMPILED_PDF" 1

    compile_expected_title_failure "$test_engine"
    compile_expected_option_failure "$test_engine" twocolumn
    compile_expected_option_failure "$test_engine" notitlepage

    compile_success \
        "$test_engine" author-long.tex author-long author-long 1 \
        "$test_fixture_dir"
    assert_page_count "$COMPILED_PDF" 2
    assert_page_contains "$COMPILED_PDF" 1 FINALAFFILIATIONMARKER
    assert_page_contains "$COMPILED_PDF" 2 PTREPORTLONGAUTHORCONTENT
    assert_text_inside_title_block "$COMPILED_PDF" 1

    compile_success \
        "$test_engine" author-layout.tex author-layout author-layout 1 \
        "$test_fixture_dir"
    assert_page_count "$COMPILED_PDF" 2
    assert_page_contains "$COMPILED_PDF" 2 PTREPORTAUTHORLAYOUTCONTENT
    assert_author_table_right_aligned \
        "$COMPILED_PDF" 1 \
        wedge.antilles@rebellion.example \
        123456789-K
    assert_author_rule_rows "$COMPILED_PDF" 1 2

    compile_success \
        "$test_engine" table-columns.tex table-columns table-columns 1 \
        "$test_fixture_dir"
    assert_page_count "$COMPILED_PDF" 2
    test_table_bbox=$(create_page_bbox "$COMPILED_PDF" 2)
    assert_markers_wrap "$test_table_bbox" LSTART LEND
    assert_markers_wrap "$test_table_bbox" CSTART CEND
    assert_markers_wrap "$test_table_bbox" RSTART REND
    assert_markers_wrap "$test_table_bbox" XSTART XEND
    assert_markers_wrap "$test_table_bbox" XFLEXSTART XFLEXEND

    compile_success \
        "$test_engine" table-spacing.tex table-spacing table-spacing 1 \
        "$test_fixture_dir"
    assert_page_count "$COMPILED_PDF" 2
    test_standalone_table_bbox=$(create_page_bbox "$COMPILED_PDF" 1)
    assert_marker_gap_at_least \
        "$test_standalone_table_bbox" \
        PTSTANDALONEBEFORE \
        PTSTANDALONECELL \
        7.5
    assert_marker_gap_at_least \
        "$test_standalone_table_bbox" \
        PTSTANDALONECELL \
        PTSTANDALONEAFTER \
        7.5
    test_float_table_bbox=$(create_page_bbox "$COMPILED_PDF" 2)
    assert_marker_gap_at_most \
        "$test_float_table_bbox" \
        PTFLOATBEFORE \
        PTFLOATCELL \
        18
    assert_marker_gap_at_most \
        "$test_float_table_bbox" \
        PTFLOATCELL \
        PTFLOATCAPTION \
        18

    for test_option_fixture in "${option_fixtures[@]}"; do
        compile_success \
            "$test_engine" \
            "$test_option_fixture.tex" \
            "$test_option_fixture" \
            "$test_option_fixture" \
            1 \
            "$test_fixture_dir"
        assert_log_contains \
            "$COMPILED_LOG" \
            "PT-TEST-MODULES=${option_modules[$test_option_fixture]}"
        assert_log_contains \
            "$COMPILED_LOG" \
            "PT-TEST-FONTSIZE=${option_font_sizes[$test_option_fixture]}"
        assert_log_contains \
            "$COMPILED_LOG" \
            "PT-TEST-LANGUAGE=${option_languages[$test_option_fixture]}"
        assert_pdf_contains "$COMPILED_PDF" PTLANGUAGEMARKER
    done
done

printf 'PT Report regression checks passed: %s\n' "${test_engines[*]}"
printf 'Test artifacts: %s\n' "$test_output_dir"
