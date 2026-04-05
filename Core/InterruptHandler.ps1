# InterruptHandler.ps1 - Disabled
# Ctrl+C and all interrupt combinations are disabled.
# The only way to exit is using /exit command.

function Initialize-InterruptHandler {
    # No interrupt handler registered
}

function Test-Interrupt {
    # Always returns false - no interrupts allowed
    return $false
}

function Clear-Interrupt {
    # Nothing to clear
}

function Invoke-InterruptCleanup {
    # Nothing to clean up
}
