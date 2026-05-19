#Requires -Version 5.1
<#
.SYNOPSIS
    Раскладывает junction-ы из skills/<name> в ~/.claude/skills/<name>.

.PARAMETER DryRun
    Показать что будет сделано, ничего не менять.

.PARAMETER Force
    Перезаписать существующие реальные папки (с бэкапом).

.PARAMETER Only
    Список имён скиллов через запятую (без пробелов): -Only caveman,tdd

.EXAMPLE
    .\scripts\sync.ps1
    .\scripts\sync.ps1 -DryRun
    .\scripts\sync.ps1 -Force -Only caveman,tdd
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Force,
    [string]$Only
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$skillsSrc = Join-Path $repoRoot 'skills'
$skillsDst = Join-Path $env:USERPROFILE '.claude\skills'

if (-not (Test-Path $skillsSrc)) {
    Write-Error "Не найдена папка $skillsSrc. Запускай из клонированного репо."
}

# Предохранитель: если skills/ это junction/симлинк — мы в publisher-режиме, sync.ps1 не применим
$skillsSrcItem = Get-Item $skillsSrc -Force
if ($skillsSrcItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
    $target = $skillsSrcItem.Target | Select-Object -First 1
    Write-Error "skills/ это junction → $target. Похоже, мы в publisher-режиме. sync.ps1 не применим. Используй link-from-local.ps1 или удали junction вручную."
    exit 1
}

if (-not (Test-Path $skillsDst)) {
    if ($DryRun) {
        Write-Host "[dry-run] создал бы $skillsDst" -ForegroundColor Yellow
    } else {
        New-Item -ItemType Directory -Path $skillsDst -Force | Out-Null
        Write-Host "Создал $skillsDst" -ForegroundColor Green
    }
}

$onlySet = $null
if ($Only) {
    $onlySet = @{}
    foreach ($n in $Only.Split(',')) { $onlySet[$n.Trim()] = $true }
}

$srcDrive = (Get-Item $skillsSrc).PSDrive.Name
$dstDrive = $skillsDst.Substring(0, 1)
if ($srcDrive -ne $dstDrive) {
    Write-Warning "Репо на диске $srcDrive, целевая папка на $dstDrive. Junction между дисками не работает — придётся хранить репо на том же диске, что и профиль ($dstDrive)."
    exit 1
}

$stats = @{ created = 0; skipped = 0; replaced = 0; backedUp = 0; errors = 0 }

Get-ChildItem -Path $skillsSrc -Directory | ForEach-Object {
    $name = $_.Name
    $src = $_.FullName
    $dst = Join-Path $skillsDst $name

    if ($onlySet -and -not $onlySet.ContainsKey($name)) {
        return
    }

    Write-Host ""
    Write-Host "[$name]" -ForegroundColor Cyan

    if (Test-Path $dst) {
        $item = Get-Item $dst -Force
        $isLink = $item.Attributes -band [System.IO.FileAttributes]::ReparsePoint

        if ($isLink) {
            $currentTarget = $item.Target | Select-Object -First 1
            if ($currentTarget -eq $src) {
                Write-Host "  уже синкнут (junction указывает на $src)" -ForegroundColor DarkGray
                $stats.skipped++
                return
            }
            Write-Host "  существует junction → $currentTarget" -ForegroundColor Yellow
            if ($DryRun) {
                Write-Host "  [dry-run] пересоздал бы junction → $src" -ForegroundColor Yellow
                return
            }
            Remove-Item $dst -Force
            New-Item -ItemType Junction -Path $dst -Value $src | Out-Null
            Write-Host "  пересоздал junction → $src" -ForegroundColor Green
            $stats.replaced++
            return
        }

        if (-not $Force) {
            Write-Host "  существует реальная папка. Пропускаю (используй -Force чтобы заменить с бэкапом)." -ForegroundColor Yellow
            $stats.skipped++
            return
        }

        $backup = "$dst.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        if ($DryRun) {
            Write-Host "  [dry-run] переименовал бы папку в $backup и создал junction → $src" -ForegroundColor Yellow
            return
        }
        Rename-Item -Path $dst -NewName (Split-Path -Leaf $backup)
        Write-Host "  бэкап: $backup" -ForegroundColor Magenta
        $stats.backedUp++
        New-Item -ItemType Junction -Path $dst -Value $src | Out-Null
        Write-Host "  создал junction → $src" -ForegroundColor Green
        $stats.created++
        return
    }

    if ($DryRun) {
        Write-Host "  [dry-run] создал бы junction $dst → $src" -ForegroundColor Yellow
        return
    }

    try {
        New-Item -ItemType Junction -Path $dst -Value $src | Out-Null
        Write-Host "  создал junction → $src" -ForegroundColor Green
        $stats.created++
    } catch {
        Write-Host "  ошибка: $_" -ForegroundColor Red
        $stats.errors++
    }
}

Write-Host ""
Write-Host "Итого:" -ForegroundColor Cyan
Write-Host "  создано:    $($stats.created)"
Write-Host "  пересоздано:$($stats.replaced)"
Write-Host "  пропущено:  $($stats.skipped)"
Write-Host "  бэкапов:    $($stats.backedUp)"
Write-Host "  ошибок:     $($stats.errors)"

if ($DryRun) {
    Write-Host ""
    Write-Host "Это был dry-run. Запусти без -DryRun чтобы применить." -ForegroundColor Yellow
}
