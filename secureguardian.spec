Name:           secureguardian
Version:        1.0.0
Release:        1
Summary:        SecureGuardian Security Checks Tool
License:        Mulan PSL v2
URL:            https://secureguardian.example.com 
Source0:        secureguardian-%{version}.tar.gz
BuildArch:      noarch
Requires:       jq

%description
SecureGuardian is a comprehensive security checks tool for Linux systems.
It includes a set of scripts for checking, fixing, and restoring security settings.

%prep
%autosetup

%build
# Nothing to build, scripts are ready to use

%install
# Creating directories
mkdir -p %{buildroot}/usr/bin
mkdir -p %{buildroot}/usr/local/secureguardian

# Copying the scripts and other necessary files
cp -a scripts %{buildroot}/usr/local/secureguardian
cp -a baseline %{buildroot}/usr/local/secureguardian
cp -a conf %{buildroot}/usr/local/secureguardian
cp -a reports %{buildroot}/usr/local/secureguardian
cp -a tools %{buildroot}/usr/local/secureguardian
cp -a README.md %{buildroot}/usr/local/secureguardian

# Creating relative symlinks for tools scripts to be accessible system-wide
ln -s ../local/secureguardian/tools/run_checks.sh %{buildroot}/usr/bin/run_checks
ln -s ../local/secureguardian/tools/run_fixes.sh %{buildroot}/usr/bin/run_fixes
ln -s ../local/secureguardian/tools/run_restores.sh %{buildroot}/usr/bin/run_restores

%files
/usr/bin/run_checks
/usr/bin/run_fixes
/usr/bin/run_restores
/usr/local/secureguardian

%changelog
* Mon Apr 01 2024 mengchaoming <mengchaoming@example.com> - 1.0.0-1
- Initial package

