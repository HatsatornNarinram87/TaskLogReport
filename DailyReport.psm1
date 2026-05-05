# ============================================================
#  DailyReport Module
#  Import: Import-Module "D:\Laodoove\DailyReport\DailyReport.psm1"
# ============================================================

$script:RepoRoots = @("D:\Laodoove")
$script:OutputDir = "D:\Laodoove\daily-log"

function Get-DailyReport {
    param(
        [string]$Date = (Get-Date -Format "yyyy-MM-dd")
    )

    $afterArg     = "$Date 00:00:00"
    $beforeArg    = "$Date 23:59:59"
    $report       = [System.Collections.Generic.List[string]]::new()
    $totalCommits = 0

    $report.Add("# Daily Work Report - $Date")
    $report.Add("")

    foreach ($root in $script:RepoRoots) {
        if (-not (Test-Path $root)) { continue }

        $repos = Get-ChildItem -Path $root -Directory | Where-Object {
            Test-Path (Join-Path $_.FullName ".git")
        }

        foreach ($repo in $repos) {
            $commits = git -C $repo.FullName log `
                --oneline `
                --after="$afterArg" `
                --before="$beforeArg" `
                --format="%h|%s|%ai" 2>$null

            if ($commits) {
                $report.Add("## $($repo.Name)")

                foreach ($line in $commits) {
                    $parts = $line -split "\|"
                    $hash  = $parts[0]
                    $msg   = $parts[1]
                    $time  = ([datetime]$parts[2]).ToString("HH:mm")
                    $report.Add("  - [$time] $msg  ``$hash``")
                    $totalCommits++
                }

                $report.Add("")
            }
        }
    }

    $report.Add("---")
    $report.Add("**Total commits: $totalCommits**")
    $report.Add("_Generated at $(Get-Date -Format 'HH:mm') on $Date_")

    return $report
}

function Save-DailyReport {
    param(
        [string]$Date = (Get-Date -Format "yyyy-MM-dd")
    )

    $report     = Get-DailyReport -Date $Date
    $outputFile = "$script:OutputDir\$Date.md"

    if (-not (Test-Path $script:OutputDir)) {
        New-Item -Path $script:OutputDir -ItemType Directory -Force | Out-Null
    }

    $report | Set-Content -Path $outputFile -Encoding UTF8
    $report | ForEach-Object { Write-Host $_ }

    Write-Host ""
    Write-Host "Saved -> $outputFile" -ForegroundColor Green
}

function Save-TodayReport  { Save-DailyReport -Date (Get-Date -Format "yyyy-MM-dd") }
function Save-YesterdayReport { Save-DailyReport -Date (Get-Date).AddDays(-1).ToString("yyyy-MM-dd") }

Export-ModuleMember -Function Get-DailyReport, Save-DailyReport, Save-TodayReport, Save-YesterdayReport
