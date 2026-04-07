%%
%% pt-report.cls
%% Report document class for ptoledo-teaching
%%
%% Author: Pedro Toledo Correa
%% Repo: https://github.com/ptoledo-teaching/pt-commons
%% License: LaTeX Project Public License 1.3c or later
%% Created: 2021-07-01
%% Updated: 2025-10-18
%% Version: v0.1
%%
%% -----------------------------------------------------------------
%% This work may be distributed and/or modified under
%% the conditions of the LaTeX Project Public License,
%% version 1.3c or later. The latest version is available at:
%%     https://www.latex-project.org/lppl.txt
%% -----------------------------------------------------------------
%%

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{pt-report}[2025/10/18 v0.1 PT Report Class]
\makeatletter

% Class handling %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Declare language options for pt-commons
\DeclareOption{spanish}{\PassOptionsToPackage{\CurrentOption}{pt-commons}}
\DeclareOption{english}{\PassOptionsToPackage{\CurrentOption}{pt-commons}}
\DeclareOption{portuguese}{\PassOptionsToPackage{\CurrentOption}{pt-commons}}
\DeclareOption{french}{\PassOptionsToPackage{\CurrentOption}{pt-commons}}
\DeclareOption{nominted}{\PassOptionsToPackage{\CurrentOption}{pt-commons}}
% Pass all other options to base article class
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}
% Default options
\PassOptionsToClass{letterpaper,12pt}{article}
\ProcessOptions\relax
% Load base class
\LoadClass{article}
% Load pt-commons package
\RequirePackage{pt-commons}

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

% Watermark %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\renewcommand{\setupwatermark}[1]{%
    \newlength{\@watermarkheight}
    \newlength{\@watermarklen}
    \newlength{\@watermarktargetlen}
    \newlength{\@watermarkwidth}
    \newlength{\@watermarkfinal}
    \begingroup
    % Calculate the watermark size
    \fontsize{5cm}{6cm}\selectfont
    \settowidth{\@watermarkwidth}{#1}%
    \settoheight{\@watermarkheight}{#1}%
    % Choose the smaller dimension between watermark width and height
    \ifdim\@watermarkwidth>\@watermarkheight
        \global\setlength{\@watermarklen}{\@watermarkwidth}%
    \else
        \global\setlength{\@watermarklen}{\@watermarkheight}%
    \fi
    \endgroup
    % Calculate the watermark target size
    \ifdim\paperwidth<\paperheight
        \setlength{\@watermarktargetlen}{1.2\paperwidth}%
    \else
        \setlength{\@watermarktargetlen}{1.2\paperheight}%
    \fi
    \setlength{\@watermarkfinal}{\dimexpr 4cm * \@watermarktargetlen / \@watermarklen \relax}
    % Set watermark properties
    \SetWatermarkText{#1}%
    \SetWatermarkFontSize{\@watermarkfinal}%
    \SetWatermarkAngle{45}%
    \SetWatermarkColor{ptred!21}
    \SetWatermarkHorCenter{0.5\paperwidth}
}

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
            \ifdefined\pt@titlesub\vspace{6pt}{\LARGE\pt@titlesub}\\%
            \fi%
            \ifdefined\pt@titlesubsub%
                \vspace{10pt}%
                \ifdefined\pt@watermark%
                    \pt@watermark\ -%
                \fi%
                \pt@titlesubsub\\%
            \fi%
        \end{center}
        \vfill
        \begin{center}
            \ifdefined\pt@date%
                \edef\temp@date{\pt@date}%
                \ifx\temp@date\@empty%
                \else%
                    \pt@date%
                    \def\pt@dateprinted{true}%
                \fi%
            \else%
                \insertdate%
                \def\pt@dateprinted{true}%
            \fi%
            \ifdefined\pt@version%
                \ifdefined\pt@dateprinted%
                    \ -\ %
                \fi%
                \undef\pt@dateprinted%
                v\pt@version%
                \par%
            \fi%
            \ifdefined\pt@workgroup%
                \def\pt@spacing{true}%
            \fi%
            \ifdefined\pt@department%
                \def\pt@spacing{true}%
            \fi%
            \ifdefined\pt@school%
                \def\pt@spacing{true}%
            \fi%
            \ifdefined\pt@university%
                \def\pt@spacing{true}%
            \fi%
            \ifdefined\pt@spacing%
                \vspace{0.42cm}%
                \undef\pt@spacing
            \fi%
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

\AtBeginEnvironment{tblr}{\footnotesize}

\makeatother
