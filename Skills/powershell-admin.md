# Skill: PowerShell Admin

## Description
Perform Windows system administration tasks using PowerShell: manage services, processes, registry, users, permissions, networking, and system configuration.

## When to use
- Managing Windows services (start, stop, configure)
- Working with processes, tasks, or scheduled jobs
- Registry operations (read, write, modify)
- User and group management
- Network configuration (IP, DNS, firewall)
- File and folder permissions
- System information gathering
- Software installation or removal

## Tools to use
- execute_powershell - run admin commands
- read_file - read config files, logs
- write_file - create scripts or configs
- list_directory - explore system paths

## Workflow
1. Understand the admin task required
2. Check current state (get current config, status)
3. Plan the changes needed
4. Execute commands with execute_powershell
5. Verify the changes took effect
6. Report results to user

## Tips
- Use Get- commands first to check current state
- Always verify changes after making them
- Use -WhatIf for destructive operations when available
- Warn user before making system changes
- Some commands require Administrator privileges
- Log what was changed for audit purposes
