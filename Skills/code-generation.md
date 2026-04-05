# Skill: Code Generation

## Description
Create new code files, scripts, functions, or modules from scratch based on user requirements.

## When to use
- User asks to create a new script, function, or module
- Need to generate boilerplate code
- Creating configuration files or templates
- Building complete files with specific functionality
- Writing automation scripts

## Tools to use
- write_file - create new files with generated code
- execute_powershell - test the generated code
- list_directory - check where to place new files
- read_file - read existing code for style reference

## Workflow
1. Understand the requirements clearly
2. Check existing code for style conventions (read similar files)
3. Determine the best location for new files
4. Write the code using write_file
5. Test the code with execute_powershell
6. Fix any issues and re-test
7. Verify the file exists and has correct content

## Tips
- Match the existing code style of the project
- Add comments explaining complex logic
- Include error handling for robustness
- Test immediately after writing
- Follow language-specific best practices
- Never invent APIs or functions that don't exist
