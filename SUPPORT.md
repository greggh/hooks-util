
# Support for Neovim Hooks Utilities

This document outlines the various ways you can get help with Neovim Hooks Utilities.

## GitHub Discussions

For general questions, ideas, or community discussions, please use [GitHub Discussions](https://github.com/greggh/hooks-util/discussions).

Categories:

- **Q&A**: For specific questions about using the hooks
- **Ideas**: For suggesting new features or improvements
- **Show and Tell**: For sharing how you've customized or extended the hooks
- **General**: For general conversation about Git hooks in Neovim projects

## Issue Tracker

For reporting bugs or requesting features, please use the [GitHub issue tracker](https://github.com/greggh/hooks-util/issues).

Before creating a new issue:

1. Search existing issues to avoid duplicates
2. Use the appropriate issue template
3. Provide as much detail as possible, including:
   - Your operating system
   - Your shell environment
   - Versions of Bash, StyLua, Luacheck, and Neovim
   - Any relevant configuration files

## Documentation

For help with using the hooks:

- Read the [README.md](README.md) for basic usage and installation
- Check the [examples/](examples/) directory for usage examples
- Review the [templates/](templates/) directory for configuration templates

## Community Resources

Neovim Hooks Utilities is part of a broader ecosystem of Neovim tools. These resources may also be helpful:

- [Neovim Discord Server](https://discord.gg/neovim)
- [Neovim Reddit](https://www.reddit.com/r/neovim/)
- [StyLua Documentation](https://github.com/JohnnyMorganz/StyLua)
- [Luacheck Documentation](https://github.com/lunarmodules/luacheck)

## Common Issues

For quick solutions to common problems:

1. **Hooks not running**
   - Check that Git is using the hooks: `git config core.hooksPath`
   - Ensure hooks have execute permission: `chmod +x .githooks/*`

1. **StyLua/Luacheck not found**
   - Follow the installation instructions in [DEVELOPMENT.md](DEVELOPMENT.md)
   - Set custom tool paths in your `.hooksrc.local` file

1. **Path issues (especially on Windows)**
   - Use WSL for a more consistent experience
   - Set environment variables in your `.hooksrc.local` file

## Contributing

If you're interested in contributing to the project, please read our [CONTRIBUTING.md](CONTRIBUTING.md) guide.

## Security Issues

For security-related issues, please refer to our [SECURITY.md](SECURITY.md) document for proper disclosure procedures.

