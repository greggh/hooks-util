
# Security Policy

## Supported Versions

The following versions of Neovim Hooks Utilities are currently supported with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 0.2.x   | :white_check_mark: |
| 0.1.x   | :x:                |

## Reporting a Vulnerability

We take the security of Neovim Hooks Utilities seriously. If you believe you've found a security vulnerability, please follow these steps:

1. **Do not disclose the vulnerability publicly**
2. **Email [g@0v.org]** with details about the vulnerability
   - Include steps to reproduce
   - Include potential impact
   - If possible, include suggestions for remediation
3. **Allow time for response and remediation**
   - We aim to respond to security reports within 48 hours
   - We'll keep you updated on our progress addressing the issue

## Security Response Process

When a security vulnerability is reported:

1. We will confirm receipt of the vulnerability report
2. We will investigate and validate the reported issue
3. We will develop and test a fix
4. We will release a security update
5. We will publicly disclose the issue after a fix is available

## Security Best Practices for Users

- Keep Neovim Hooks Utilities updated to the latest supported version
- Apply security patches promptly
- Always inspect the output of hook operations when installing in a new project
- Be careful with custom configurations that might override security checks
- Review scripts sourced by hooks to ensure they don't contain malicious code
- Do not use hooks from untrusted sources without reviewing them

## Security Considerations

Since hooks execute as part of Git operations, they have the potential to run commands on your system. For this reason:

1. **Code Review**: Always review hook scripts before installing them
2. **Limited Permissions**: Hooks should operate with the minimum necessary permissions
3. **No Credentials**: Never store or handle credentials in hook scripts
4. **Command Safety**: The library implements safeguards against dangerous commands

## Security Updates

Security updates will be released as:

- Patch versions for supported releases
- Security advisories on GitHub
- Announcements in our release notes

## Past Security Advisories

No security advisories have been published for this project yet.
