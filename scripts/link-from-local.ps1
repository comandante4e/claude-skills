#Requires -Version 5.1
<#
.SYNOPSIS
    Publisher-режим: делает ~/.claude/skills/ источником правды.

    Заменяет repo/skills/ на junction → ~/.claude/skills/. После этого
    правки в ~/.claude/skills/<имя>/SKILL.md сразу видны git-у в репо.

.PARAMETER DryRun
    Показать план, ничего не менять.
.PARAMETER Force
    Если repo/skills/ это реальная папка — переименовать в *.backup-... и заменить.

.EXAMPLE
    .\scripts\link-from-local.ps1 -DryRun
    .\scripts\link-from-local.ps1 -Force
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$skillsRepo = Join-Path $repoRoot 'skills'
$skillsLocal = Join-Path $env:USERPROFILE '.claude\skills'

if (-not (Test-Path $skillsLocal)) {
    Write-Error "Нет $skillsLocal. На этой машине пока нет локальных скиллов — используй sync.ps1 (consumer-режим)."
    exit 1
}

$srcDrive = $skillsLocal.Substring(0, 1)
$dstDrive = $skillsRepo.Substring(0, 1)
if ($srcDrive -ne $dstDrive) {
    Write-Error "Репо на диске $dstDrive, локальные скиллы на $srcDrive. Junction между дисками не работает — клонируй репо на $srcDrive."
    exit 1
}

if (Test-Path $skillsRepo) {
    $item = Get-Item $skillsRepo -Force
    $isLink = $item.Attributes -band [System.IO.FileAttributes]::ReparsePoint

    if ($isLink) {
        $current = $item.Target | Select-Object -First 1
        if ($current -eq $skillsLocal) {
            Write-Host "Уже в publisher-режиме: $skillsRepo → $current" -ForegroundColor Green
            exit 0
        }
        Write-Host "skills/ существует как junction → $current" -ForegroundColor Yellow
        if ($DryRun) {
            Write-Host "[dry-run] пересоздал бы junction → $skillsLocal" -ForegroundColor Yellow
            exit 0
        }
        Remove-Item $skillsRepo -Force
        New-Item -ItemType Junction -Path $skillsRepo -Value $skillsLocal | Out-Null
        Write-Host "Пересоздал junction $skillsRepo → $skillsLocal" -ForegroundColor Green
        exit 0
    }

    if (-not $Force) {
        Write-Host "skills/ существует как реальная папка. Используй -Force чтобы переименовать в бэкап и заменить junction-ом." -ForegroundColor Yellow
        exit 1
    }

    $backup = "$skillsRepo.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    if ($DryRun) {
        Write-Host "[dry-run] переименовал бы $skillsRepo → $backup и создал junction → $skillsLocal" -ForegroundColor Yellow
        exit 0
    }
    Rename-Item -Path $skillsRepo -NewName (Split-Path -Leaf $backup)
    Write-Host "Бэкап: $backup" -ForegroundColor Magenta
}

if ($DryRun) {
    Write-Host "[dry-run] создал бы junction $skillsRepo → $skillsLocal" -ForegroundColor Yellow
    exit 0
}

New-Item -ItemType Junction -Path $skillsRepo -Value $skillsLocal | Out-Null
Write-Host "Создал junction $skillsRepo → $skillsLocal" -ForegroundColor Green
Write-Host ""
Write-Host "Дальше:" -ForegroundColor Cyan
Write-Host "  git status      # проверить что чисто (или увидеть локальные изменения)"
Write-Host "  git add -A"
Write-Host "  git commit -m '...'"
Write-Host "  git push"
