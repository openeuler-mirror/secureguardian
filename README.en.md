# SecureGuardian User Guide

  SecureGuardian is a Linux system security check tool developed based on the "openEuler Security Configuration Baseline", aimed at helping system administrators evaluate and improve the security of their systems.

## Architectural Design

The architecture of SecureGuardian is designed to systematically assess the security of Linux system configurations. It operates through a modular script approach, allowing for extensive customization and expansion. The main components include:

- **Check Scripts**: Individual scripts provided for each security check, easy to update to adapt to new standards or findings.
- **Configuration Files**: Define which checks to execute, their parameters, and manage exceptions, allowing assessments to be tailored to different environments.
- **Execution Engine**: Coordinates the running of check scripts, collects results, and manages output formats, supporting detailed reports for analysis and summaries for quick overviews.
- **User Interface**: Command-line based, allowing users to specify checks, view reports, and configure settings.

This structure supports a flexible and expandable security auditing method, adaptable to a wide range of system environments and security requirements.

## Features

- Supports flexible configurations, allowing specific checks to be enabled or disabled as needed.
- Provides detailed security check reports, including successful checks, failed items and reasons for failure. 
- Automatically generates HTML reports for easy viewing in web browsers.
- Supports specifying a particular configuration file for checking through command-line parameters.
- The results of check scripts are stored in JSON files and used to generate HTML reports.

## Installation

You can install it with the following commands:

```sh
sudo yum install jq
sudo rpm -i secureguardian-<version>.rpm
```

## Usage

- **To execute all checks**: Running the command without any parameters

```sh
run_checks
```
will perform all checks enabled in the configuration file and generate a report.

- **To specify a configuration file for the check: Use the -c or --config parameter to specify a particular configuration file for the check.

```sh
run_checks -c <configuration file name>
```

- **To only execute "required" checks: Use the -r parameter
```sh
run_checks -r
```
## Configuration Details

   The configuration files are located in the /usr/local/secureguardian/conf directory, where you can edit these files to enable or disable specific checks. Check scripts are stored in the /usr/local/secureguardian/scripts/checks directory, organized into different subdirectories based on the different checks.

## Viewing Reports

  After the checks are completed, you can find the HTML format report files in the /usr/local/secureguardian/reports directory, which can be directly opened with a browser to view.

## License
secureguardian is licensed under the Mulan PSL v2 protocol.


