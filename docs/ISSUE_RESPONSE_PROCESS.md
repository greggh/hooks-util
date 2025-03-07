
# Issue and Pull Request Response Process

This document outlines the standard process for responding to issues and pull requests in the hooks-util project. Following these guidelines ensures consistent, timely, and helpful interactions with contributors.

## Issue Response Guidelines

### Initial Response (Within 72 Hours)

All new issues should receive an initial response within 72 hours:

1. **Thank the contributor** for taking the time to report an issue
2. **Label the issue** appropriately
   - `bug`: For confirmed bugs
   - `enhancement`: For feature requests
   - `documentation`: For documentation issues
   - `good first issue`: For simple issues suitable for new contributors
   - `help wanted`: For issues where community help is particularly welcome
   - `question`: For general questions

1. **Request more information** if needed (see saved replies)
2. **Reproduce the issue** locally if possible, or ask for clarification if not reproducible

### Issue Classification

After initial assessment, classify the issue:

- **Quick fix**: Can be resolved immediately
- **Needs investigation**: Requires deeper debugging
- **Needs design discussion**: Requires broader consideration of the approach
- **Low priority**: Minor issue that can wait
- **High priority**: Critical bug or important enhancement

### Ongoing Communication

- Provide updates at least once a week for active issues
- If an issue becomes stale (no activity for 30 days):
  - Ask if the issue is still relevant
  - Close with an appropriate message if no response after another 14 days

### Closing Issues

When closing issues, always:

1. Explain why the issue is being closed
2. Link to any relevant PRs or documentation
3. Thank the contributor again
4. Use a saved reply template when appropriate

## Pull Request Guidelines

### Initial Response (Within 72 Hours)

1. **Thank the contributor** for their submission
2. **Run automated checks** (CI should run automatically)
3. **Perform an initial review** of the code
4. **Label the PR** appropriately

### Review Process

1. **Be constructive and specific** in feedback
2. **Focus on important issues** rather than style preferences (StyLua should handle most style issues)
3. **Suggest alternatives** when requesting changes
4. **Link to relevant documentation or examples** when possible

### Merge Requirements

Before merging, ensure:

1. CI checks pass
2. Code has been reviewed and approved
3. Tests have been added for new functionality
4. Documentation has been updated if needed
5. CHANGELOG.md has been updated

### After Merging

1. Thank the contributor for their work
2. Close any related issues
3. Consider creating a new release if appropriate

## Saved Replies

The project maintains a set of [saved replies](../.github/saved_replies.md) for common interactions. Use these templates as a starting point, but personalize them as appropriate.

## Response Time Expectations

- **Initial response**: Within 72 hours
- **Follow-up responses**: Within 72 hours
- **PR reviews**: Within one week
- **Issue resolution**: Based on priority and complexity

## Special Case: First-time Contributors

For first-time contributors:

1. Be extra welcoming and patient
2. Provide more detailed guidance
3. Consider offering to pair on complex issues
4. Use the "Welcome First-time Contributors" saved reply

## Regular Maintenance

- Review and triage issues weekly
- Close stale issues after 30 days of inactivity
- Create a new release after significant changes or fixes

---

Remember that every interaction with contributors is an opportunity to build a stronger community around hooks-util. Being responsive, respectful, and helpful encourages more participation and better outcomes for everyone.

