# FitLog

A PowerShell calorie and fitness tracker built as my MSSA project. FitLog logs meals to a CSV file, tracks daily calories against a personal goal, and exports weekly reports, all from the command line.

## Features

| Function | What it does |
|---|---|
| `Add-Meal` | Logs a meal with a name, calories, and meal type. Input is validated. |
| `Get-DailyLog` | Shows the meals logged today (or any date). |
| `Set-CalorieGoal` | Saves a daily calorie goal to a config file. |
| `Get-CalorieSummary` | Compares today's total to your goal (green = under, red = over). |
| `Remove-Entry` | Deletes a mistaken entry by name, with error handling. |
| `Export-WeeklyReport` | Totals calories per day and saves a CSV report. |
| `Write-Log` | Records activity and errors with timestamps in a log file. |

## How to run it

1. Open PowerShell in the project folder.
2. Load the script (note the dot, then a space):

   ```powershell
   . .\FitLog.ps1
   ```

3. Try it out:

   ```powershell
   Set-CalorieGoal -Goal 2000
   Add-Meal -Name "Oatmeal" -Calories 300 -MealType Breakfast
   Get-DailyLog
   Get-CalorieSummary
   Export-WeeklyReport
   ```

## PowerShell skills demonstrated

- Functions with parameters, `ValidateRange`, and `ValidateSet`
- Custom objects with `[PSCustomObject]`
- `Import-Csv` and `Export-Csv` for data storage
- `ConvertTo-Json` and `ConvertFrom-Json` for a config file
- Filtering and grouping with `Where-Object`, `Group-Object`, and `Measure-Object`
- Error handling with `try`, `catch`, and `throw`
- File logging with timestamps
- Version control with Git and GitHub

## Notes

Personal data (`data/` and `logs/`) is excluded from this repository with `.gitignore`.

## Ideas for the future

- Exercise log with net calories
- A simple menu so it runs like an app
- A scheduled task for daily reminders
- Automatic backups of the meal log

## Author

Luke Marens