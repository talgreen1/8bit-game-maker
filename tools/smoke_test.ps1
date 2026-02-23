param(
	[string]$GodotExe = "C:\temp\godot-4.6.1\Godot_v4.6.1-stable_win64_console.exe",
	[string]$ProjectPath = "."
)

if (-not (Test-Path $GodotExe)) {
	Write-Error "Godot executable not found at '$GodotExe'."
	exit 1
}

$resolvedProjectPath = Resolve-Path $ProjectPath
& $GodotExe --headless --path $resolvedProjectPath --quit
$exitCode = $LASTEXITCODE

if ($exitCode -eq 0) {
	Write-Host "Smoke test passed."
	exit 0
}

Write-Error "Smoke test failed with exit code $exitCode."
exit $exitCode
