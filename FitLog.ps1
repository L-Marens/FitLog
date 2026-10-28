# ===== FitLog: Calorie & Fitness Tracker =====
# Author: Luke Marens
# Purpose: Log meals and track daily calories using PowerShell

# --- File locations ---
$DataFolder = Join-Path $PSScriptRoot 'data'
$MealFile   = Join-Path $DataFolder 'fitlog.csv'

# --- Make sure the data folder exists ---
if (-not (Test-Path $DataFolder)) {
    New-Item -ItemType Directory -Path $DataFolder | Out-Null
}

# --- Function: Add-Meal ---
function Add-Meal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [ValidateRange(1, 5000)]
        [int]$Calories,

        [ValidateSet('Breakfast', 'Lunch', 'Dinner', 'Snack')]
        [string]$MealType = 'Snack'
    )

    # Build one record (an object) for this meal
    $entry = [PSCustomObject]@{
        Date     = Get-Date -Format 'yyyy-MM-dd'
        Time     = Get-Date -Format 'HH:mm'
        MealType = $MealType
        Name     = $Name
        Calories = $Calories
    }

    # Append it to the CSV file
    $entry | Export-Csv -Path $MealFile -Append -NoTypeInformation

    Write-Host "Logged: $Name ($Calories cal) as $MealType" -ForegroundColor Green
}
