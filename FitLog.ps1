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

# --- Log file location (records activity and errors) ---
$LogFolder = Join-Path $PSScriptRoot 'logs'
$LogFile   = Join-Path $LogFolder 'fitlog.log'

if (-not (Test-Path $LogFolder)) {
    New-Item -ItemType Directory -Path $LogFolder | Out-Null
}

# --- Function: Write-Log ---
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Add-Content -Path $LogFile -Value "$stamp  $Message"
}

# --- Function: Remove-Entry ---
function Remove-Entry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    try {
        if (-not (Test-Path $MealFile)) {
            throw "No log file found."
        }

        $all   = @(Import-Csv $MealFile)
        $index = -1

        # Search from the newest entry backwards for a matching name
        for ($i = $all.Count - 1; $i -ge 0; $i--) {
            if ($all[$i].Name -eq $Name) {
                $index = $i
                break
            }
        }

        if ($index -eq -1) {
            throw "No entry named '$Name' was found."
        }

        # Keep every entry except the one we are removing
        $keep = @(for ($i = 0; $i -lt $all.Count; $i++) {
            if ($i -ne $index) { $all[$i] }
        })

        if ($keep.Count -eq 0) {
            Remove-Item $MealFile
        }
        else {
            $keep | Export-Csv -Path $MealFile -NoTypeInformation
        }

        Write-Host "Removed: $Name" -ForegroundColor Green
        Write-Log "Removed entry: $Name"
    }
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "ERROR in Remove-Entry: $($_.Exception.Message)"
    }
}

# --- Function: Export-WeeklyReport ---
function Export-WeeklyReport {
    [CmdletBinding()]
    param(
        [ValidateRange(1, 60)]
        [int]$Days = 7
    )

    try {
        if (-not (Test-Path $MealFile)) {
            throw "No log file found."
        }

        # Only keep meals from the last $Days days (including today)
        $cutoff = (Get-Date).AddDays(-($Days - 1)).Date
        $meals  = Import-Csv $MealFile | Where-Object { [datetime]$_.Date -ge $cutoff }

        if (-not $meals) {
            throw "No meals found in the last $Days days."
        }

        # Group by date and total each day
        $report = $meals | Group-Object Date | Sort-Object Name | ForEach-Object {
            [PSCustomObject]@{
                Date          = $_.Name
                Meals         = $_.Count
                TotalCalories = ($_.Group | Measure-Object -Property Calories -Sum).Sum
            }
        }

        $average = [math]::Round(($report | Measure-Object -Property TotalCalories -Average).Average)

        # Save the report as a CSV in data\reports
        $reportFolder = Join-Path $DataFolder 'reports'
        if (-not (Test-Path $reportFolder)) {
            New-Item -ItemType Directory -Path $reportFolder | Out-Null
        }
        $reportFile = Join-Path $reportFolder ("weekly-report-{0}.csv" -f (Get-Date -Format 'yyyy-MM-dd'))
        $report | Export-Csv -Path $reportFile -NoTypeInformation

        $report | Format-Table -AutoSize
        Write-Host "Average per logged day: $average calories"
        Write-Host "Report saved to: $reportFile" -ForegroundColor Green
        Write-Log "Weekly report exported to $reportFile"
    }
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Log "ERROR in Export-WeeklyReport: $($_.Exception.Message)"
    }
}