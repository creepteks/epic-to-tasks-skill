# Copy the epic-pipeline skills into a project's .claude folder.
# Usage: .\install.ps1 -Project D:\Projects\SomeGame [-NoAgent]
param(
    [Parameter(Mandatory = $true)][string]$Project,
    [switch]$NoAgent
)
$ErrorActionPreference = 'Stop'
$src = $PSScriptRoot
if (-not (Test-Path $Project)) { throw "Project folder not found: $Project" }
$skillsDst = Join-Path $Project '.claude\skills'
New-Item -ItemType Directory -Force -Path $skillsDst | Out-Null
foreach ($name in 'epic-to-tasks', 'implement-task', 'epic-status') {
    $dst = Join-Path $skillsDst $name
    if (Test-Path $dst) { Remove-Item -Recurse -Force $dst }
    Copy-Item -Recurse (Join-Path $src "skills\$name") $dst
    Write-Host "skill  -> $dst"
}
if (-not $NoAgent) {
    $agentsDst = Join-Path $Project '.claude\agents'
    New-Item -ItemType Directory -Force -Path $agentsDst | Out-Null
    Copy-Item -Force (Join-Path $src 'agents\task-decomposer.md') $agentsDst
    Write-Host "agent  -> $agentsDst\task-decomposer.md"
}
Write-Host "Done. Restart Claude Code in $Project and commit .claude/skills + .claude/agents."
