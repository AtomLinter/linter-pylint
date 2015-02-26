# linter-pylint

This package will lint your opened Python-files in Atom, using [pylint](http://www.pylint.org/).

## Installation

* Install [pylint](http://www.pylint.org/#install).
* `$ apm install linter` (if you don't have [AtomLinter/Linter](https://github.com/AtomLinter/Linter) installed).
* `$ apm install linter-pylint`

## Configuration
* **Executable** Path to your pylint executable. This is useful if you have different versions of pylint for Python 2 and 3 or if you are using a virtualenv
* **RC File** Path to a custom pylintrc

## Other available linters
There are other linters available - take a look at the linters [mainpage](https://github.com/AtomLinter/Linter).

## Changelog

### 0.2.1
 - Use new API for project path

### 0.2.0
 - Settings to configure rcfile, executable name [#24](https://github.com/AtomLinter/linter-pylint/pull/24)

### 0.1.5
 - Fix lint message display on Windows [#15](https://github.com/AtomLinter/linter-pylint/issues/15)
 - Fix temporary file leak when pylint isn't present

### 0.1.3
 - Display pylint message ids
 - Fix debug mode [#9](https://github.com/AtomLinter/linter-pylint/issues/9)
 - Use project directory as cwd (works better with Atom projects)

### 0.1.2
 - fix 'has no method getCmd' bug [#4](https://github.com/AtomLinter/linter-pylint/issues/4)

### 0.1.0

 - Implemented first version of 'linter-pylint'
 - Added support for Errors and Warnings, "Refactor", "Convention and "Fatal"-messages are ignored due to missing display-capabilities.

## Donation
[![Share the love!](https://chewbacco-stuff.s3.amazonaws.com/donate.png)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=KXUYS4ARNHCN8)
