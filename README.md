# linter-pylint

This package will lint your opened Python-files in Atom, using [pylint](http://www.pylint.org/).

## Installation

* Install [pylint](http://www.pylint.org/#install).
* `$ apm install linter` (if you don't have [AtomLinter/Linter](https://github.com/AtomLinter/Linter) installed).
* `$ apm install linter-pylint`

## Settings
Linter-pylint offers currently no settings.

## Other available linters
There are other linters available - take a look at the linters [mainpage](https://github.com/AtomLinter/Linter).

## Changelog

### dev
 - Display pylint message ids
 - Fix debug mode [#9](https://github.com/AtomLinter/linter-pylint#9)
 - Use project directory as cwd (works better with Atom projects)

### 0.1.2
 - fix 'has no method getCmd' bug [#4](https://github.com/AtomLinter/linter-pylint#4)

### 0.1.0

 - Implemented first version of 'linter-pylint'
 - Added support for Errors and Warnings, "Refactor", "Convention and "Fatal"-messages are ignored due to missing display-capabilities.
