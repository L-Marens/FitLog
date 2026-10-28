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
# --- Config file location (stores the daily calorie goal) ---
$ConfigFile = Join-Path $DataFolder 'config.json'

# --- Function: Get-DailyLog ---
function Get-DailyLog {
    [CmdletBinding()]
    param(
        [datetime]$Date = (Get-Date)
    )

    # Stop early if nothing has ever been logged
    if (-not (Test-Path $MealFile)) {
        Write-Host "No meals logged yet." -ForegroundColor Yellow
        return
    }

    $day   = $Date.ToString('yyyy-MM-dd')
    $meals = Import-Csv $MealFile | Where-Object { $_.Date -eq $day }

    if (-not $meals) {
        Write-Host "No meals logged for $day." -ForegroundColor Yellow
        return
    }

    $meals | Sort-Object Time | Format-Table Time, MealType, Name, Calories -AutoSize
}

# --- Function: Set-CalorieGoal ---
function Set-CalorieGoal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateRange(500, 10000)]
        [int]$Goal
    )

    [PSCustomObject]@{ DailyGoal = $Goal } | ConvertTo-Json | Set-Content $ConfigFile
    Write-Host "Daily goal set to $Goal calories." -ForegroundColor Green
}

# --- Function: Get-CalorieSummary ---
function Get-CalorieSummary {
    [CmdletBinding()]
    param(
        [datetime]$Date = (Get-Date)
    )

    $day = $Date.ToString('yyyy-MM-dd')

    # Read the goal from the config file (default to 2000 if none is set)
    $goal = 2000
    if (Test-Path $ConfigFile) {
        $goal = (Get-Content $ConfigFile -Raw | ConvertFrom-Json).DailyGoal
    }

    # Add up today's calories
    $total = 0
    if (Test-Path $MealFile) {
        $total = (Import-Csv $MealFile |
            Where-Object { $_.Date -eq $day } |
            Measure-Object -Property Calories -Sum).Sum
    }
    if (-not $total) { $total = 0 }

    $remaining = $goal - $total

    Write-Host "----- Summary for $day -----"
    Write-Host "Goal:      $goal"
    Write-Host "Eaten:     $total"
    if ($remaining -ge 0) {
        Write-Host "Remaining: $remaining" -ForegroundColor Green
    }
    else {
        Write-Host "Over by:   $([math]::Abs($remaining))" -ForegroundColor Red
    }
}