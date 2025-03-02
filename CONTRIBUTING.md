# Contributing to Neovim Hooks Utilities

Thank you for considering contributing to Neovim Hooks Utilities! Your contributions help improve the pre-commit experience for Neovim Lua projects across the community.

## Code of Conduct

This project follows our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to g@0v.org.

## Getting Started

1. Fork the repository
2. Clone your fork and create a new branch:
   ```bash
   git clone https://github.com/greggh/hooks-util.git
   cd hooks-util
   git checkout -b feature/my-feature-name
   ```
3. Set up your development environment following the instructions in [DEVELOPMENT.md](DEVELOPMENT.md)
4. Install the hooks in the project itself to ensure your changes follow our standards:
   ```bash
   ./install.sh --config
   ```
5. Make your changes
6. Test your changes (see [Testing Changes](#testing-changes) below)
7. Push to your fork and submit a pull request to the [greggh/hooks-util](https://github.com/greggh/hooks-util) repository

## Development Process

Please see [DEVELOPMENT.md](DEVELOPMENT.md) for detailed instructions on setting up your development environment and understanding the development workflow.

## Testing Changes

Before submitting a pull request, please test your changes:

1. **Shell Script Linting**:
   ```bash
   shellcheck lib/*.sh hooks/* install.sh
   ```

2. **Manual Testing**:
   ```bash
   # Test individual components
   bash -x lib/your-module.sh
   
   # Test the pre-commit hook
   bash -x hooks/pre-commit
   ```

3. **End-to-End Testing**:
   Install the hooks in a test repository:
   ```bash
   # From your test repository
   /path/to/hooks-util/install.sh --config --verbose
   
   # Make some changes and commit to test the hooks
   touch test.lua
   echo "print('Hello')" > test.lua
   git add test.lua
   git commit -m "Test commit"
   ```

## Pull Request Process

1. Update the README.md or relevant documentation with details of your changes
2. Update the CHANGELOG.md with your changes under the "Unreleased" section
3. Ensure your code works on all supported platforms (Linux, macOS, Windows)
4. Your PR needs approval from at least one maintainer before it can be merged

## Coding Standards

### Bash Script Style

- Use 2 spaces for indentation
- Follow [Google's Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- Include helpful comments for complex logic
- Use shellcheck to validate scripts before committing
- Make scripts executable with `chmod +x`
- All scripts should have a shebang line (`#!/bin/bash`)

### Documentation Style

- Use Markdown for documentation
- Keep line length reasonable (typically 80-100 characters)
- Use code blocks with language specifiers for examples
- Include examples for complex functionality

## Commit Messages

- Use clear, descriptive commit messages
- Follow the [Conventional Commits](https://www.conventionalcommits.org/) format:
  ```
  feat: add support for luacheck integration
  fix: correct path handling on Windows
  docs: improve installation instructions
  test: add shellcheck validation
  ```
- Reference issues and pull requests where appropriate

## Adding New Hook Types

When adding a new hook type:

1. Create the hook script in the `hooks/` directory
2. Add supporting functions in the `lib/` directory if needed
3. Update documentation to describe the new hook
4. Add configuration options to the template config files
5. Test the hook thoroughly across different environments

## License

By contributing to this project, you agree that your contributions will be licensed under the project's MIT License.

## Questions?

If you have any questions, please open an issue or refer to our [SUPPORT.md](SUPPORT.md) file for more information on how to get help.