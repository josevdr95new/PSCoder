# Invoke-Tool.ps1 - Thin dispatcher that routes tool calls to individual tool files
# Each tool has its own file in Tools/ directory

function Invoke-PSCoderTool {
    param(
        [Parameter(Mandatory)][string]$ToolName,
        [Parameter(Mandatory)][hashtable]$Arguments,
        [string]$WorkingDir = (Get-Location).Path,
        [hashtable]$ReadFileState = @{}
    )
    switch ($ToolName) {
        "execute_powershell" {
            return Invoke-ToolExecutePowerShell -Command $Arguments.command -WorkingDir $WorkingDir
        }
        "read_file" {
            return Invoke-ToolReadFile -Path $Arguments.path -WorkingDir $WorkingDir
        }
        "write_file" {
            return Invoke-ToolWriteFile -Path $Arguments.path -Content $Arguments.content -WorkingDir $WorkingDir
        }
        "edit_file" {
            return Invoke-ToolEditFile -Path $Arguments.path -OldText $Arguments.oldText -NewText $Arguments.newText -WorkingDir $WorkingDir
        }
        "search_files" {
            return Invoke-ToolSearchFiles -Pattern $Arguments.pattern -Path $Arguments.path -FilePattern $Arguments.filePattern -WorkingDir $WorkingDir
        }
        "glob_files" {
            return Invoke-ToolGlobFiles -Pattern $Arguments.pattern -Path $Arguments.path -WorkingDir $WorkingDir
        }
        "list_directory" {
            return Invoke-ToolListDirectory -Path $Arguments.path -ShowHidden $Arguments.showHidden -WorkingDir $WorkingDir
        }
        "get_current_dir" {
            return Invoke-ToolGetCurrentDir -WorkingDir $WorkingDir
        }
        "web_search" {
            $query = $Arguments.query
            $maxResults = if ($Arguments.maxResults) { [int]$Arguments.maxResults } else { 8 }
            $fetchTopPages = if ($Arguments.fetchTopPages) { [int]$Arguments.fetchTopPages } else { 2 }
            if (-not $query) { return "ERROR: No search term provided" }
            return Invoke-WebSearch -Query $query -MaxResults $maxResults -FetchTopPages $fetchTopPages
        }
        "web_fetch" {
            $url = $Arguments.url
            $maxChars = if ($Arguments.maxChars) { [int]$Arguments.maxChars } else { 15000 }
            if (-not $url) { return "ERROR: No URL provided" }
            return Invoke-WebFetch -Url $url -MaxChars $maxChars
        }
        "auto_heal" {
            $errorMessage = $Arguments.errorMessage
            $command = $Arguments.command
            if (-not $errorMessage) { return "ERROR: No error message provided" }
            return Invoke-AutoHeal -ErrorMessage $errorMessage -Command $command
        }
        "learn_from_error" {
            $category = $Arguments.category
            $problem = $Arguments.problem
            $solution = $Arguments.solution
            if (-not $category -or -not $problem -or -not $solution) {
                return "ERROR: Missing parameters (category, problem, solution)"
            }
            return Add-Learning -Category $category -Problem $problem -Solution $solution
        }
        "find_solution" {
            $problem = $Arguments.problem
            if (-not $problem) { return "ERROR: No problem provided" }
            $result = Find-Solution -Problem $problem
            if ($result.found) {
                return "SOLUTION FOUND`nCategory: $($result.category)`nSolution: $($result.solution)"
            } else {
                return "No solution found. Use learn_from_error to register when you solve it."
            }
        }
        "ocr_image" {
            $path = $Arguments.path
            $language = if ($Arguments.language) { $Arguments.language } else { "" }
            if (-not $path) { return "ERROR: No image path provided" }
            return Invoke-OcrImage -Path $path -Language $language
        }
        "create_plan" {
            $task = $Arguments.task
            $context = if ($Arguments.context) { $Arguments.context } else { "" }
            if (-not $task) { return "ERROR: No task provided" }
            return Invoke-CreatePlan -Task $task -Context $context
        }
        "verify_step" {
            $stepNumber = $Arguments.stepNumber
            $result = $Arguments.result
            $success = if ($Arguments.success -eq $true) { $true } else { $false }
            if (-not $stepNumber) { return "ERROR: No step number provided" }
            if (-not $result) { return "ERROR: No result provided" }
            return Invoke-VerifyStep -StepNumber $stepNumber -Result $result -Success $success
        }
        "verify_task" {
            $expectedOutcome = if ($Arguments.expectedOutcome) { $Arguments.expectedOutcome } else { "" }
            return Invoke-VerifyTask -ExpectedOutcome $expectedOutcome
        }
        "save_learning" {
            $category = $Arguments.category
            $information = $Arguments.information
            $context = if ($Arguments.context) { $Arguments.context } else { "" }
            if (-not $category -or -not $information) {
                return "ERROR: Missing parameters (category, information)"
            }
            switch ($category) {
                "error_resolution" {
                    return Add-Learning -Category "error_resolution" -Problem $information -Solution "Resolved" -Context $context
                }
                "user_preference" {
                    Add-PSCoderMemoryNote -Note "PREFERENCE: $information"
                    return "User preference saved: $information"
                }
                "project_context" {
                    Add-PSCoderMemoryNote -Note "PROJECT: $information"
                    return "Project context saved: $information"
                }
                "success_pattern" {
                    $key = "success_pattern::$information"
                    $entry = @{
                        context = $context
                        saved_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    }
                    if ($Script:Patterns.ContainsKey($key)) {
                        $existing = @($Script:Patterns[$key])
                        $Script:Patterns[$key] = $existing + @($entry)
                    } else {
                        $Script:Patterns[$key] = @($entry)
                    }
                    Save-Patterns
                    return "Success pattern saved: $information"
                }
                "command_workflow" {
                    $key = "command_workflow::$information"
                    $entry = @{
                        request = $information
                        context = $context
                        saved_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    }
                    if ($Script:Patterns.ContainsKey($key)) {
                        $existing = @($Script:Patterns[$key])
                        $Script:Patterns[$key] = $existing + @($entry)
                    } else {
                        $Script:Patterns[$key] = @($entry)
                    }
                    Save-Patterns
                    return "Command workflow saved: $information"
                }
                default {
                    return Add-Learning -Category $category -Problem $information -Solution $information -Context $context
                }
            }
        }
        "list_skills" {
            return Get-SkillList
        }
        "read_skill" {
            $skillName = $Arguments.skillName
            if (-not $skillName) { return "ERROR: No skill name provided. Use list_skills first to see available skills." }
            return Get-SkillContent -SkillName $skillName
        }
        "add_plan_step" {
            $desc = $Arguments.description
            if (-not $desc) { return "ERROR: No step description provided." }
            return Invoke-AddPlanStep -Description $desc -Tool $Arguments.tool -SuccessCriteria $Arguments.successCriteria -Alternative $Arguments.alternative
        }
        default { return "ERROR: Unknown tool: $ToolName" }
    }
}
