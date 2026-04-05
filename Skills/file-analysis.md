# Skill: File Analysis

## Description
Analyze file structures, project layouts, codebases, and configurations to understand how a project is organized.

## When to use
- User wants to understand a project structure
- Need to find specific files or patterns in a codebase
- Analyzing dependencies, imports, or module relationships
- Reviewing configuration files for issues
- Understanding how different parts of a project connect

## Tools to use
- list_directory - explore directory structure
- glob_files - find files by pattern
- read_file - read file contents
- search_files - search for patterns across files
- execute_powershell - run analysis commands

## Workflow
1. Start with list_directory to understand top-level structure
2. Use glob_files to find specific file types (*.ps1, *.json, etc.)
3. Read key files (entry points, configs, manifests)
4. Use search_files to find patterns, imports, or references
5. Build a mental map of the project and present findings

## Tips
- Always read entry points first (main files, module manifests, package.json)
- Look for configuration files that reveal project type and dependencies
- Check for README or documentation files
- Use search_files to trace function calls or imports across files
- Present structure as a tree or summary, not raw file listings
