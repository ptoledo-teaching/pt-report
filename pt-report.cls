%%
%% pt-report.cls
%% Report document class for ptoledo-teaching
%%
%% Author: Pedro Toledo Correa
%% Repo: https://github.com/ptoledo-teaching/pt-report
%% License: LaTeX Project Public License 1.3c or later
%% Created: 2021-07-01
%% Updated: 2026-08-28
%% Version: v0.2
%%
%% -----------------------------------------------------------------
%% This work may be distributed and/or modified under
%% the conditions of the LaTeX Project Public License,
%% version 1.3c or later. The latest version is available at:
%%     https://www.latex-project.org/lppl.txt
%% -----------------------------------------------------------------
%%

\NeedsTeXFormat{LaTeX2e}[2023-06-01]
\ProvidesClass{pt-report}[2026/08/28 v0.2 PT Report Class]
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
\DeclareOption{layout}{\PassOptionsToPackage{\CurrentOption}{pt-commons}}
\DeclareOption{nolayout}{\PassOptionsToPackage{\CurrentOption}{pt-commons}}
\DeclareOption{content}{\PassOptionsToPackage{\CurrentOption}{pt-commons}}
\DeclareOption{nocontent}{\PassOptionsToPackage{\CurrentOption}{pt-commons}}
\DeclareOption{runtime}{\PassOptionsToPackage{\CurrentOption}{pt-commons}}
\DeclareOption{noruntime}{\PassOptionsToPackage{\CurrentOption}{pt-commons}}
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
% Load pt-commons package
\RequirePackage{pt-commons}

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
% Line spacing
\sloppy
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
\pretocmd{\section}{\clearpage}{}{}
% Page numbering
\pagestyle{fancy}
\ifpt@loadlayout\else
    % Keep a quiet, useful page style when PT's optional layout is disabled.
    \fancyhf{}
    \cfoot{\thepage}
    \renewcommand{\headrulewidth}{0pt}
\fi

% Title page %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Custom titlepage
\renewcommand{\maketitle}{
    \edef\temp{\pt@logo}%
    \begin{titlepage}
        \newpage
        \vbox to 30pt{%
                \ifx\temp\@empty
                    \vfil % nothing, just stretch inside
                \else
                    \noindent\includegraphics[height=30pt]{\pt@logo}%
                \fi
            }%
        \vfill
        \vfill
        \begin{center}
            \ifdefined\pt@classsemester%
                \ifdefined\pt@classcode%
                    \pt@classcode \ - \pt@classsemester\par%
                \else%
                    \pt@classsemester\par%
                \fi%
            \else%
                \ifdefined\pt@classcode%
                    \pt@classcode\par%
                \fi%
            \fi%
            \ifdefined\pt@classname%
                \pt@classname\par%
            \fi
        \end{center}
        \vfill
        \begin{center}
            {\Huge\pt@title}\\%
            \ifdefined\pt@titlesub%
                \vspace{14pt}{\LARGE\pt@titlesub}\\%
            \fi%
            \ifdefined\pt@titlesubsub%
                \vspace{14pt}%
                \ifdefined\pt@watermark%
                    \pt@watermark\ -%
                \fi%
                \pt@titlesubsub\\%
            \fi%
        \end{center}
        \vfill
        \begin{center}
            % Date and version
            \ifdefined\pt@date%
                \edef\temp@date{\pt@date}%
                \ifx\temp@date\@empty%
                \else%
                    \pt@date%
                    \def\pt@dateprinted{true}%
                    \def\pt@dateversionprinted{true}%
                \fi%
            \else%
                \@date%
                \def\pt@dateprinted{true}%
                \def\pt@dateversionprinted{true}%
            \fi%
            \ifdefined\pt@version%
                \edef\temp@version{\pt@version}%
                \ifx\temp@version\@empty%
                \else%
                    \ifdefined\pt@dateprinted%
                        \ -\ %
                    \fi%
                    v\pt@version%
                    \def\pt@dateversionprinted{true}%
                \fi%
            \fi%
            \undef\pt@dateprinted%
            \ifdefined\pt@dateversionprinted%
                \par\vspace{21pt}%
                \undef\pt@dateversionprinted%
            \fi%
            % Institution information
            \ifdefined\pt@workgroup%
                \pt@workgroup\par%
            \fi%
            \ifdefined\pt@department%
                \pt@department\par%
            \fi%
            \ifdefined\pt@school%
                \pt@school\par%
            \fi%
            \ifdefined\pt@university%
                \pt@university\par%
            \fi%
            % Corporate information
            \ifdefined\pt@corporationdepartment%
                \pt@corporationdepartment\par%
            \fi%
            \ifdefined\pt@corporation%
                \pt@corporation\par%
            \fi%
        \end{center}
        \vfill
        \vfill
        \begin{flushright}
            \titleauthorstable
        \end{flushright}
    \end{titlepage}
    \addtocounter{page}{1}
}

% Hooks %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\ifpt@loadcontent
    \AtBeginEnvironment{tblr}{\footnotesize}
\fi

\makeatother
