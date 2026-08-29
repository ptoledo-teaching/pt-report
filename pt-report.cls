%%
%% pt-report.cls
%% Report document class for ptoledo-teaching
%%
%% Author: Pedro Toledo Correa
%% Repo: https://github.com/ptoledo-teaching/pt-report
%% License: LaTeX Project Public License 1.3c or later
%% Created: 2021-07-01
%% Updated: 2026-08-29
%% Version: v0.3
%%
%% -----------------------------------------------------------------
%% This work may be distributed and/or modified under
%% the conditions of the LaTeX Project Public License,
%% version 1.3c or later. The latest version is available at:
%%     https://www.latex-project.org/lppl.txt
%% -----------------------------------------------------------------
%%

\NeedsTeXFormat{LaTeX2e}[2023-06-01]
\ProvidesClass{pt-report}[2026/08/29 v0.3 PT Report Class]
\makeatletter

% Class handling %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Declare language options for pt-commons
\DeclareOption{spanish}{\PassOptionsToPackage{\CurrentOption}{pt-commons}}
\DeclareOption{english}{\PassOptionsToPackage{\CurrentOption}{pt-commons}}
\DeclareOption{portuguese}{\PassOptionsToPackage{\CurrentOption}{pt-commons}}
\DeclareOption{french}{\PassOptionsToPackage{\CurrentOption}{pt-commons}}
\DeclareOption{nominted}{\PassOptionsToPackage{\CurrentOption}{pt-commons}}
\DeclareOption{coreonly}{\PassOptionsToPackage{\CurrentOption}{pt-commons}}
\DeclareOption{minimal}{\PassOptionsToPackage{\CurrentOption}{pt-commons}}
\DeclareOption{full}{\PassOptionsToPackage{\CurrentOption}{pt-commons}}
% Individual module controls are namespaced at class level so generic options
% such as `layout` cannot be consumed accidentally by unrelated packages.
\DeclareOption{ptlayout}{\PassOptionsToPackage{layout}{pt-commons}}
\DeclareOption{ptnolayout}{\PassOptionsToPackage{nolayout}{pt-commons}}
\DeclareOption{ptcontent}{\PassOptionsToPackage{content}{pt-commons}}
\DeclareOption{ptnocontent}{\PassOptionsToPackage{nocontent}{pt-commons}}
\DeclareOption{ptruntime}{\PassOptionsToPackage{runtime}{pt-commons}}
\DeclareOption{ptnoruntime}{\PassOptionsToPackage{noruntime}{pt-commons}}
% The report layout is deliberately single-column and always uses a title page.
\DeclareOption{twocolumn}{%
    \ClassError{pt-report}{The twocolumn option is not supported}{%
        Use pt-article for a two-column document.}%
}
\DeclareOption{notitlepage}{%
    \ClassError{pt-report}{The notitlepage option is not supported}{%
        PT Report always creates a dedicated title page.}%
}
% Apply the 12pt default only when the user did not request another size.
\newif\ifpt@reportsizeoption
\pt@reportsizeoptionfalse
\DeclareOption{10pt}{%
    \pt@reportsizeoptiontrue
    \PassOptionsToClass{\CurrentOption}{article}%
}
\DeclareOption{11pt}{%
    \pt@reportsizeoptiontrue
    \PassOptionsToClass{\CurrentOption}{article}%
}
\DeclareOption{12pt}{%
    \pt@reportsizeoptiontrue
    \PassOptionsToClass{\CurrentOption}{article}%
}
% Pass all other options to base article class
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}
% Default options
\ProcessOptions*\relax
\ifpt@reportsizeoption\else
    \PassOptionsToClass{12pt}{article}
\fi
% Load base class
\LoadClass{article}
% Load the matching PT Commons semester release.
\RequirePackage{pt-commons}[2026/08/29]

% Direct class dependencies remain available when Commons modules are disabled.
\RequirePackage{enumitem}
\RequirePackage{fancyhdr}
\RequirePackage{geometry}
\RequirePackage{graphicx}

% Page and text formatting %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Page geometry
\geometry{
    left=63pt,
    right=63pt,
    top=63pt,
    bottom=63pt,
    includefoot
}
% Paragraph indentation
\setlength{\parindent}{42pt}
% Allow a controlled final line-breaking pass without globally enabling \sloppy.
\setlength{\emergencystretch}{3em}
% Lists spacing (use enumitem rather than redefining LaTeX internals)
\setlist[itemize,1]{
    leftmargin=42pt,
    labelsep=6pt,
    topsep=8pt,
    parsep=0pt,
    itemsep=0pt
}
\setlist[itemize,2]{
    leftmargin=12pt,
    topsep=0pt
}
\setlist[enumerate,1]{
    leftmargin=42pt,
    labelsep=6pt,
    topsep=8pt,
    parsep=0pt,
    itemsep=0pt
}
\setlist[enumerate,2]{
    leftmargin=12pt,
    topsep=0pt
}
% Section breaks - each section starts on a new page
\AddToHook{cmd/section/before}{\clearpage}
% Page numbering
\pagestyle{fancy}
\ptiflayoutloaded{}{%
    % Keep a quiet, useful page style when PT's optional layout is disabled.
    \fancyhf{}
    \cfoot{\thepage}
    \renewcommand{\headrulewidth}{0pt}
}

% Title page %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\newcommand{\pt@report@renderlogo}{%
    \vbox to 30pt{%
        \ptifmetadata{logo}{%
            \noindent\includegraphics[height=30pt]{\ptmetadata{logo}}%
        }{%
            \vfil
        }%
    }%
}

\newcommand{\pt@report@renderclassinfo}{%
    \ptifmetadata{classcode}{%
        \ptifmetadata{classsemester}{%
            \ptmetadata{classcode}\space-\space
            \ptmetadata{classsemester}\par
        }{%
            \ptmetadata{classcode}\par
        }%
    }{%
        \ptifmetadata{classsemester}{%
            \ptmetadata{classsemester}\par
        }{}%
    }%
    \ptifmetadata{classname}{\ptmetadata{classname}\par}{}%
}

\newcommand{\pt@report@missingtitle}{%
    \ClassError{pt-report}{No \string\title\space was provided}{%
        Define \string\title\string{...\string} in the preamble before
        \string\maketitle.}%
}

\newcommand{\pt@report@rendertitle}{%
    \ptifmetadata{title}{%
        {\Huge\ptmetadata{title}\par}%
    }{%
        \pt@report@missingtitle
    }%
    \ptifmetadata{titlesub}{%
        \vspace{14pt}%
        {\LARGE\ptmetadata{titlesub}\par}%
    }{}%
    \ptifmetadata{titlesubsub}{%
        \vspace{14pt}%
        \ptifmetadata{watermark}{%
            \ptmetadata{watermark}\space-\space
        }{}%
        \ptmetadata{titlesubsub}\par
    }{}%
}

\newif\ifpt@report@dateprinted
\newif\ifpt@report@dateversionprinted
\newcommand{\pt@report@renderdateversion}{%
    \pt@report@dateprintedfalse
    \pt@report@dateversionprintedfalse
    \ptifmetadatadefined{date}{%
        \ptifmetadata{date}{%
            \ptmetadata{date}
            \pt@report@dateprintedtrue
            \pt@report@dateversionprintedtrue
        }{}%
    }{%
        \ifx\@date\@empty\else
            \@date
            \pt@report@dateprintedtrue
            \pt@report@dateversionprintedtrue
        \fi
    }%
    \ptifmetadata{version}{%
        \ifpt@report@dateprinted
            \space-\space
        \fi
        v\ptmetadata{version}
        \pt@report@dateversionprintedtrue
    }{}%
    \ifpt@report@dateversionprinted
        \par\vspace{21pt}%
    \fi
}

\newcommand{\pt@report@renderinstitution}{%
    \ptifmetadata{workgroup}{\ptmetadata{workgroup}\par}{}%
    \ptifmetadata{department}{\ptmetadata{department}\par}{}%
    \ptifmetadata{school}{\ptmetadata{school}\par}{}%
    \ptifmetadata{university}{\ptmetadata{university}\par}{}%
    \ptifmetadata{corporationdepartment}{%
        \ptmetadata{corporationdepartment}\par
    }{}%
    \ptifmetadata{corporation}{\ptmetadata{corporation}\par}{}%
}

\newcommand{\pt@report@renderauthors}{%
    \ptifauthors{%
        \begingroup
        \raggedleft
        \titleauthorstable\par
        \endgroup
    }{}%
}

% In two-sided documents the page following the cover is its blank verso. The
% report body therefore begins on the next recto page. In one-sided documents
% the body follows the cover immediately and is numbered page 2.
\newcommand{\pt@report@finishcover}{%
    \if@twoside
        \clearpage
        \ifodd\c@page\else
            \hbox{}%
            \thispagestyle{empty}%
            \newpage
        \fi
    \else
        \setcounter{page}{2}%
    \fi
}

% Custom title page
\renewcommand{\maketitle}{%
    \begin{titlepage}
        \pt@report@renderlogo
        \vfill
        \vfill
        \begin{center}
            \pt@report@renderclassinfo
        \end{center}
        \vfill
        \begin{center}
            \pt@report@rendertitle
        \end{center}
        \vfill
        \begin{center}
            \pt@report@renderdateversion
            \pt@report@renderinstitution
        \end{center}
        \vfill
        \vfill
        \pt@report@renderauthors
    \end{titlepage}
    \pt@report@finishcover
}

% Hooks %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% A tblr used directly in the report body is a display and needs its own
% vertical separation. A tblr inside a table float must not add another layer
% of space: the float and caption mechanisms already provide it.
\newif\ifpt@report@tablefloat
\pt@report@tablefloatfalse
\newcommand{\pt@report@addtblrspace}{%
    \ifpt@report@tablefloat\else
        \par\addvspace{\medskipamount}%
    \fi
}
\ptifcontentloaded{%
    \AddToHook{env/table/begin}{\pt@report@tablefloattrue}
    \AddToHook{env/table*/begin}{\pt@report@tablefloattrue}
    \AddToHook{env/tblr/before}{\pt@report@addtblrspace}
    \AddToHook{env/tblr/begin}{\footnotesize}
    \AddToHook{env/tblr/after}{\pt@report@addtblrspace}
}{}

\makeatother
\endinput
