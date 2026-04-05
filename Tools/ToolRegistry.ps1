# ToolRegistry.ps1 - Tool registry for PSCoder

$Script:ToolSchemas = @(
    @{ type = "function"; function = @{
        name = "execute_powershell"
        description = "Executes a PowerShell command or script on the user's local machine."
        parameters = @{ type = "object"
            properties = @{ command = @{ type = "string"; description = "The PowerShell command or script to execute" } }
            required = @("command")
        }
    }}
    @{ type = "function"; function = @{
        name = "read_file"
        description = "Reads the complete contents of a file."
        parameters = @{ type = "object"
            properties = @{ path = @{ type = "string"; description = "Path of the file to read" } }
            required = @("path")
        }
    }}
    @{ type = "function"; function = @{
        name = "write_file"
        description = "Creates a new file or overwrites an existing one."
        parameters = @{ type = "object"
            properties = @{
                path = @{ type = "string"; description = "File path" }
                content = @{ type = "string"; description = "Content to write" }
            }
            required = @("path", "content")
        }
    }}
    @{ type = "function"; function = @{
        name = "edit_file"
        description = "Searches and replaces text in an existing file."
        parameters = @{ type = "object"
            properties = @{
                path = @{ type = "string"; description = "File path" }
                oldText = @{ type = "string"; description = "Exact text to find" }
                newText = @{ type = "string"; description = "New text" }
            }
            required = @("path", "oldText", "newText")
        }
    }}
    @{ type = "function"; function = @{
        name = "search_files"
        description = "Searches a regex pattern in files of a directory. Equivalent to grep."
        parameters = @{ type = "object"
            properties = @{
                pattern = @{ type = "string"; description = "Regex pattern to search" }
                path = @{ type = "string"; description = "Directory to search (default: current)" }
                filePattern = @{ type = "string"; description = "File filter e.g.: *.ps1 (default: *.*)" }
            }
            required = @("pattern")
        }
    }}
    @{ type = "function"; function = @{
        name = "glob_files"
        description = "Searches files by wildcard pattern (*.ps1, test-*, **/*.json)."
        parameters = @{ type = "object"
            properties = @{
                pattern = @{ type = "string"; description = "File search pattern" }
                path = @{ type = "string"; description = "Base directory (default: current)" }
            }
            required = @("pattern")
        }
    }}
    @{ type = "function"; function = @{
        name = "list_directory"
        description = "Lists files and subdirectories with info (size, date)."
        parameters = @{ type = "object"
            properties = @{
                path = @{ type = "string"; description = "Directory to list (default: current)" }
                showHidden = @{ type = "boolean"; description = "Include hidden files (default: false)" }
            }
            required = @()
        }
    }}
    @{ type = "function"; function = @{
        name = "get_current_dir"
        description = "Returns the current working directory."
        parameters = @{ type = "object"; properties = @{}; required = @() }
    }}
    @{ type = "function"; function = @{
        name = "web_search"
        description = "Searches the internet using Brave Search API (primary) with DuckDuckGo fallback. Returns titles, descriptions, URLs, and page content. Set BRAVE_SEARCH_API_KEY env var or braveSearchApiKey in config for full results."
        parameters = @{ type = "object"
            properties = @{
                query = @{ type = "string"; description = "Search term" }
                maxResults = @{ type = "integer"; description = "Maximum number of results (default: 8, max: 20)" }
                fetchTopPages = @{ type = "integer"; description = "Fetch and extract content from top N result pages (default: 2)" }
            }
            required = @("query")
        }
    }}
    @{ type = "function"; function = @{
        name = "web_fetch"
        description = "Gets the content of a URL and returns it CLEAN as plain text (no HTML, no code, only readable content). Ideal for reading web pages, documentation, JSON APIs."
        parameters = @{ type = "object"
            properties = @{
                url = @{ type = "string"; description = "URL to fetch (e.g.: https://example.com)" }
                maxChars = @{ type = "integer"; description = "Maximum characters (default: 15000)" }
            }
            required = @("url")
        }
    }}
    @{ type = "function"; function = @{
        name = "auto_heal"
        description = "Analyzes an error and suggests automatic corrections. Can also apply safe fixes."
        parameters = @{ type = "object"
            properties = @{
                errorMessage = @{ type = "string"; description = "Error message to analyze" }
                command = @{ type = "string"; description = "Command that caused the error (optional)" }
            }
            required = @("errorMessage")
        }
    }}
    @{ type = "function"; function = @{
        name = "learn_from_error"
        description = "Registers an error and its solution for future learning. The agent learns from its errors."
        parameters = @{ type = "object"
            properties = @{
                category = @{ type = "string"; description = "Error category" }
                problem = @{ type = "string"; description = "Problem description" }
                solution = @{ type = "string"; description = "How it was resolved" }
            }
            required = @("category", "problem", "solution")
        }
    }}
    @{ type = "function"; function = @{
        name = "find_solution"
        description = "Searches solutions to previously solved problems. The agent remembers how to solve past problems."
        parameters = @{ type = "object"
            properties = @{
                problem = @{ type = "string"; description = "Problem to search" }
            }
            required = @("problem")
        }
    }}
    @{ type = "function"; function = @{
        name = "ocr_image"
        description = "Extracts text from images using Windows OCR (built into Windows 10/11). Use when user provides a screenshot, photo of text, scanned document, or any image containing readable text. Supports png, jpg, bmp, gif, tiff, webp."
        parameters = @{ type = "object"
            properties = @{
                path = @{ type = "string"; description = "Path to the image file" }
                language = @{ type = "string"; description = "OCR language code (e.g., 'en-US', 'es-ES', 'ja-JP'). Default: system language." }
            }
            required = @("path")
        }
    }}
    @{ type = "function"; function = @{
        name = "create_plan"
        description = "Creates a structured step-by-step plan for complex tasks. Use when the task requires multiple steps, file operations, or coordination between tools. Each step will have a suggested tool, success criteria, and alternative."
        parameters = @{ type = "object"
            properties = @{
                task = @{ type = "string"; description = "Description of the task to plan" }
                context = @{ type = "string"; description = "Additional context about the task (optional)" }
            }
            required = @("task")
        }
    }}
    @{ type = "function"; function = @{
        name = "verify_step"
        description = "Verifies that a step in the current plan was executed correctly. Checks the result against success criteria and reports status. Use after each step execution."
        parameters = @{ type = "object"
            properties = @{
                stepNumber = @{ type = "integer"; description = "The step number to verify" }
                result = @{ type = "string"; description = "The actual result from executing the step" }
                success = @{ type = "boolean"; description = "Whether the step succeeded (true) or failed (false)" }
            }
            required = @("stepNumber", "result", "success")
        }
    }}
    @{ type = "function"; function = @{
        name = "verify_task"
        description = "Verifies the final outcome of a complete task. Checks all files were created/modified correctly, all steps completed, and expected outcomes were achieved. Use at the end of a multi-step task."
        parameters = @{ type = "object"
            properties = @{
                expectedOutcome = @{ type = "string"; description = "What the final result should look like (optional pattern to match)" }
            }
            required = @()
        }
    }}
    @{ type = "function"; function = @{
        name = "save_learning"
        description = "Automatically saves a learning, pattern, or piece of information to memory for future use. Use when something new was discovered, an error was resolved, or user preferences were mentioned."
        parameters = @{ type = "object"
            properties = @{
                category = @{ type = "string"; description = "Category: error_resolution, user_preference, project_context, success_pattern, command_workflow" }
                information = @{ type = "string"; description = "The information to save" }
                context = @{ type = "string"; description = "Context about when/why this was learned (optional)" }
            }
            required = @("category", "information")
        }
    }}
    @{ type = "function"; function = @{
        name = "list_skills"
        description = "Lists all available skills with their names, descriptions, and when to use them. Use this BEFORE starting any task to see what specialized workflows are available. The AI should check this to find relevant skills for the current task."
        parameters = @{ type = "object"; properties = @{}; required = @() }
    }}
    @{ type = "function"; function = @{
        name = "read_skill"
        description = "Reads the full content of a specific skill file. Use after list_skills to load a relevant skill. The skill contains detailed instructions, tools, and workflows for specialized tasks. Load skills that match your current task type."
        parameters = @{ type = "object"
            properties = @{
                skillName = @{ type = "string"; description = "The name of the skill (without .md extension). Use exact name from list_skills." }
            }
            required = @("skillName")
        }
    }}
    @{ type = "function"; function = @{
        name = "add_plan_step"
        description = "Adds a step to the current plan. Use after create_plan to define each step of the plan. Each step should have a description, the tool to use, and optional success criteria."
        parameters = @{ type = "object"
            properties = @{
                description = @{ type = "string"; description = "What this step does" }
                tool = @{ type = "string"; description = "The tool to use for this step (e.g., write_file, execute_powershell)" }
                successCriteria = @{ type = "string"; description = "How to verify this step succeeded (optional)" }
                alternative = @{ type = "string"; description = "Alternative tool if primary fails (optional)" }
            }
            required = @("description")
        }
    }}
)

function Get-ToolSchemas { return $Script:ToolSchemas }
function Get-ToolNameList { return $Script:ToolSchemas | ForEach-Object { $_.function.name } }

