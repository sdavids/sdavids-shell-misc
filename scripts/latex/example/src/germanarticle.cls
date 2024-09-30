% SPDX-FileCopyrightText: © 2024 Sebastian Davids <sdavids@gmx.de>
% SPDX-License-Identifier: Apache-2.0

\ProvidesClass{germanarticle}[German article]
\NeedsTeXFormat{LaTeX2e}

\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}} % pass through any options to the base class
\ProcessOptions\relax % process given options

\LoadClass[a4paper]{article} % load the base class

\RequirePackage[bottom=2cm,left=2.5cm,right=1.5cm,top=2cm]{geometry} % DIN 5008
\RequirePackage[utf8]{inputenc} % allow UTF-8 source encoding
\RequirePackage[ngerman]{babel} % use German terminology
\RequirePackage[strict]{csquotes} % use appropriate German quotes
\RequirePackage[useregional=numeric]{datetime2} % date formatting
\RequirePackage[document]{ragged2e} % required for non-justified text

\RequirePackage{titlesec} % customize section styles
% https://tug.ctan.org/macros/latex/contrib/titlesec/titlesec.pdf#subsection.8.2
\titleformat{\section}
{\normalfont\Large\bfseries\sffamily}{\thesection}{1em}{}
\titleformat{\subsection}
{\normalfont\large\bfseries\sffamily}{\thesubsection}{1em}{}
\titleformat{\subsubsection}
{\normalfont\normalsize\bfseries\sffamily}{\thesubsubsection}{1em}{}

\RequirePackage{fontspec} % font support
\setmainfont{SourceSerif4}[
  Path=./fonts/,
  Extension=.ttf,
  UprightFont=*-Regular,
  BoldFont=*-Bold,
  ItalicFont=*-Italic,
  BoldItalicFont=*-BoldItalic,
]

\setsansfont{SourceSans3}[
  Path=./fonts/,
  Extension=.ttf,
  UprightFont=*-Regular,
  BoldFont=*-Bold,
  ItalicFont=*-Italic,
  BoldItalicFont=*-BoldItalic,
]

\setmonofont{SourceCodePro}[
  Path=./fonts/,
  Extension=.ttf,
  UprightFont=*-Regular,
  BoldFont=*-Bold,
  ItalicFont=*-Italic,
  BoldItalicFont=*-BoldItalic,
]

\newcommand{\range}[2]{%
  #1\,\textendash\,#2%
}
