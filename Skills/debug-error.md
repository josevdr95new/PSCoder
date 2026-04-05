# Skill: Debug Error

## Description
Diagnose, analyze, and resolve errors in code, scripts, or system operations.

## When to use
- User reports an error message or unexpected behavior
- A script or command fails with an exception
- Need to trace the root cause of a problem
- Fixing bugs in existing code
- Troubleshooting system or permission issues

## Tools to use
- auto_heal - analyze error messages and get suggestions
- read_file - read the code that caused the error
- execute_powershell - test fixes and verify behavior
- search_files - find related error patterns in codebase
- find_solution - check if this error was solved before
- learn_from_error - save the solution for future reference

## Workflow
1. Get the exact error message from the user
2. Check environment context: run `$PSVersionTable.PSVersion.ToString()` to know the PowerShell version
3. Use auto_heal to classify the error and get suggestions
4. Use find_solution to check for previous solutions
5. Read the relevant code files to understand context
6. Identify the root cause (not just the symptom)
7. Apply the fix using edit_file or execute_powershell
8. Test the fix to confirm it works
9. Save the solution with learn_from_error

## Tips
- ALWAYS check the PowerShell version first - solutions for PS 7+ may not work on PS 5.1
- Always read the full error message, including stack traces
- Check file permissions and paths first for file-related errors
- Use execute_powershell to test small parts in isolation
- Try at least 3 different approaches before giving up
- Document what worked for future reference
