# Skill: Refactor

## Description
Improve existing code quality, structure, performance, or readability without changing functionality.

## When to use
- User asks to clean up, optimize, or restructure code
- Need to fix code smells or anti-patterns
- Improving readability or maintainability
- Consolidating duplicate code
- Updating code to follow best practices

## Tools to use
- read_file - read the code to refactor
- edit_file - make targeted improvements
- execute_powershell - test after changes
- search_files - find all instances of patterns to update

## Workflow
1. Read the existing code thoroughly
2. Identify specific issues (duplication, complexity, style)
3. Plan the changes needed
4. Apply changes incrementally with edit_file
5. Test after each significant change
6. Verify functionality is preserved
7. Show a summary of what was changed and why

## Tips
- Only refactor what was asked - don't over-engineer
- Make small, testable changes
- Preserve existing functionality
- Explain what was improved and why
- Keep a backup of original code if changes are significant
