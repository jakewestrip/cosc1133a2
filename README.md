
CONTENTS OF THIS FILE
---------------------
* Introduction
* Requirements
* Configuration
* FAQ
* Maintainers

INTRODUCTION
------------
LedConfigurator is a menu-driven bash script which provides an easy-to-use interface for manipulating system LEDs. Functions include:
* Manually turning LEDs on and off
* Associating LEDs with system events 
* Associating LEDs with the resource usage of a process via a background worker process

REQUIREMENTS
------------
This script relies on the following programs being installed and available on the current effective executable PATH:
* more
* sed
* ps
* grep
* sort
* wc
* awk
* bc

CONFIGURATION
-------------
The script has no modifiable settings or configuration.
As this script manipulates LEDs through the Linux kernel's sysfs, it is necessary to run this script under a superuser account.  

FAQ
-----------
Q. Does this script pass ShellCheck?
A. Yes! In both LedConfigurator.sh and BackgroundWorker.sh the only output from ShellCheck is the info severity message "[SC2009](https://github.com/koalaman/shellcheck/wiki/SC2009): Consider using pgrep instead of grepping ps output."

MAINTAINERS
-----------
Current maintainers:
* Jake Westrip (s3559660)