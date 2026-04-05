# Skill: Web Research

## Description
Search the web, fetch URLs, and gather current information to answer questions, find documentation, or solve problems that require up-to-date knowledge.

## When to use
- User asks about recent events, new technologies, or current versions
- Need to find documentation for a library, framework, or API
- Looking for best practices, tutorials, or examples online
- Need to verify information that may have changed
- Researching error messages or issues with known solutions online

## Tools to use
- web_search (primary) - search for information
- web_fetch (secondary) - read specific URLs found in search results
- save_learning - save useful URLs and findings for future reference

## Workflow
1. Check the current environment first before searching:
   - Run `execute_powershell` with `$PSVersionTable.PSVersion.ToString()` to get PowerShell version
   - Run `execute_powershell` with `[Environment]::OSVersion.Version.ToString()` to get Windows version
   - Use this info to make searches specific and relevant
2. Search with web_search using specific keywords that include the versions found (e.g., "PowerShell 5.1 Get-Content encoding" not "PowerShell read file")
3. If results are insufficient, try different search terms
4. Use web_fetch to read the most relevant URLs
5. Synthesize the information and provide a complete answer
6. Save important findings with save_learning

## Tips
- ALWAYS check PowerShell version ($PSVersionTable) and Windows version before searching - this ensures you find compatible solutions
- Use specific search terms with versions: "PowerShell 5.1 Get-Content encoding" instead of "PowerShell read file"
- Fetch documentation pages directly when you have the URL
- If web_search returns no results (no Brave API key), try DuckDuckGo-style searches
- Always cite sources when providing information from the web
- If the user's PS version is old (5.1), search for solutions compatible with that version, not PS 7+
