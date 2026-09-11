# license:BSD-3-Clause
# copyright-holders:gregre365
<#
.SYNOPSIS
    MSYS2 MinGW64 で retropachislotemu.exe をビルドする。

.DESCRIPTION
    MAME の makefile は OS 判定に環境変数 OS=Windows_NT を使う (makefile:144)。
    Git Bash など OS を渡さないシェルから MSYS2 の bash を起動すると
        makefile:238: *** Unable to detect OS from uname -a: MINGW64_NT-...
    で停止する。このスクリプトは MSYSTEM と OS を明示して make を呼ぶので、
    PowerShell / cmd / VS Code のどのターミナルからでも同じように動く。

    stderr の扱いに注意が必要。Windows PowerShell 5.1 はネイティブ exe の
    stderr を PowerShell 側でリダイレクトすると各行を ErrorRecord
    (NativeCommandError) に変換するため、gcc の「警告」だけでビルドが
    終端エラーとして中断される。そこで stderr の合流は bash 側 (2>&1) で行い、
    PowerShell には stdout だけを渡す。ログ出力も tee でシェル内に閉じる。

.EXAMPLE
    .\build.ps1                          # ビルド
    .\build.ps1 -Jobs 24                 # 並列数を指定
    .\build.ps1 -Target clean            # クリーン
    .\build.ps1 -DebugBuild              # デバッグビルド (retropachislotemud.exe)
    .\build.ps1 -LogFile .\build.log     # ログをファイルにも残す
#>
[CmdletBinding()]
param(
    # 並列ジョブ数。MAME は 1 ファイルあたり最大 1〜2GB 使うため、
    # 論理コア数そのままだとメモリ不足になりうる。既定は 16 で頭打ち。
    [int]$Jobs = [Math]::Min([Environment]::ProcessorCount, 16),

    # make に渡すターゲット (clean, genie など)。既定は all。
    [string]$Target = '',

    # デバッグ構成 (SYMBOLS=1 DEBUG=1) でビルドする。
    [switch]$DebugBuild,

    # 出力をこのファイルにも残す (tee)。
    [string]$LogFile = '',

    # MSYS2 のインストール先。
    [string]$Msys2Root = 'C:\msys64',

    # make に素通しする追加引数 (例: SOURCES=src/mame/arktechnico/wildcats.cpp)。
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$MakeArgs
)

Set-StrictMode -Version Latest

# C:\foo\bar -> /c/foo/bar
function ConvertTo-MsysPath([string]$Path) {
    # resolve relative paths against PowerShell's location, not the .NET process directory
    $full = [IO.Path]::GetFullPath([IO.Path]::Combine((Get-Location -PSProvider FileSystem).ProviderPath, $Path))
    '/' + $full.Substring(0, 1).ToLower() + $full.Substring(2).Replace('\', '/')
}

# bash のシングルクォート文字列に安全に埋める
function ConvertTo-ShellQuoted([string]$Text) {
    "'" + $Text.Replace("'", "'\''") + "'"
}

$bash = Join-Path $Msys2Root 'usr\bin\bash.exe'
if (-not (Test-Path $bash)) {
    Write-Error "MSYS2 の bash が見つからない: $bash  (-Msys2Root で指定できる)"
    exit 1
}

$repo = $PSScriptRoot

$makeArgv = @("-j$Jobs")
if ($DebugBuild) { $makeArgv += @('SYMBOLS=1', 'DEBUG=1') }
if ($Target)     { $makeArgv += $Target }
if ($MakeArgs)   { $makeArgv += $MakeArgs }

# 各引数を個別にシェルクォートする (-Target / -MakeArgs はユーザー入力なので、
# 空白や ; & $() を含んでいても bash 側でシェル構文として解釈させない)。
$quotedArgv = $makeArgv | ForEach-Object { ConvertTo-ShellQuoted $_ }

# stderr は bash 側で stdout に合流させる (PowerShell 5.1 の NativeCommandError 回避)。
$inner = "cd $(ConvertTo-ShellQuoted (ConvertTo-MsysPath $repo)) && make $($quotedArgv -join ' ') 2>&1"
if ($LogFile) {
    $logMsys = ConvertTo-MsysPath $LogFile
    # tee を挟むので make の終了コードを拾うために pipefail が要る。
    $inner = "set -o pipefail; $inner | tee $(ConvertTo-ShellQuoted $logMsys)"
}

# makefile の OS 判定に必須。Git Bash 経由だと欠落するため明示的に渡す。
$env:MSYSTEM        = 'MINGW64'
$env:OS             = 'Windows_NT'
$env:CHERE_INVOKING = '1'

Write-Host "==> $Msys2Root (MINGW64)  make $($makeArgv -join ' ')" -ForegroundColor Cyan
$sw = [Diagnostics.Stopwatch]::StartNew()

# ネイティブ呼び出しの間は Stop にしない (警告 1 行で中断させないため)。
$prevEap = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    & $bash -lc $inner
    $code = $LASTEXITCODE
} finally {
    $ErrorActionPreference = $prevEap
}

$sw.Stop()
$elapsed = '{0:hh\:mm\:ss}' -f $sw.Elapsed

if ($code -ne 0) {
    Write-Host "==> 失敗 (exit $code) / 経過 $elapsed" -ForegroundColor Red
    exit $code
}

$exe     = if ($DebugBuild) { 'retropachislotemud.exe' } else { 'retropachislotemu.exe' }
$exePath = Join-Path $repo $exe
if (Test-Path $exePath) {
    $mb = '{0:N1}' -f ((Get-Item $exePath).Length / 1MB)
    Write-Host "==> 完了 / 経過 $elapsed / $exe ($mb MB)" -ForegroundColor Green
} else {
    Write-Host "==> 完了 / 経過 $elapsed" -ForegroundColor Green
}
