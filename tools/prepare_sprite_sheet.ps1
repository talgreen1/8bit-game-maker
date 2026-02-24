param(
  [Parameter(Mandatory = $true)]
  [string]$InputPath,
  [string]$OutputPath = "sample_project/assets/sprites/forest_hero_walk.png",
  [int]$Frames = 8,
  [int]$FrameWidth = 20,
  [int]$FrameHeight = 28,
  [int]$BlackThreshold = 8
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

function Test-VisiblePixel {
  param(
    [System.Drawing.Color]$Color,
    [int]$Threshold
  )
  return ($Color.R -gt $Threshold) -or ($Color.G -gt $Threshold) -or ($Color.B -gt $Threshold)
}

function Get-ColumnRuns {
  param(
    [System.Drawing.Bitmap]$Bitmap,
    [int]$Threshold
  )

  $runs = New-Object System.Collections.Generic.List[object]
  $inRun = $false
  $runStart = 0

  for ($x = 0; $x -lt $Bitmap.Width; $x++) {
    $hasVisible = $false
    for ($y = 0; $y -lt $Bitmap.Height; $y++) {
      if (Test-VisiblePixel -Color $Bitmap.GetPixel($x, $y) -Threshold $Threshold) {
        $hasVisible = $true
        break
      }
    }

    if ($hasVisible -and -not $inRun) {
      $inRun = $true
      $runStart = $x
    } elseif (-not $hasVisible -and $inRun) {
      $runs.Add([pscustomobject]@{
          Start = $runStart
          End   = $x - 1
          Width = ($x - $runStart)
        })
      $inRun = $false
    }
  }

  if ($inRun) {
    $runs.Add([pscustomobject]@{
        Start = $runStart
        End   = $Bitmap.Width - 1
        Width = ($Bitmap.Width - $runStart)
      })
  }

  return $runs
}

function Get-VisibleBounds {
  param(
    [System.Drawing.Bitmap]$Bitmap,
    [int]$StartX,
    [int]$EndX,
    [int]$Threshold
  )

  $minX = $Bitmap.Width
  $minY = $Bitmap.Height
  $maxX = -1
  $maxY = -1

  for ($x = $StartX; $x -le $EndX; $x++) {
    for ($y = 0; $y -lt $Bitmap.Height; $y++) {
      $pixel = $Bitmap.GetPixel($x, $y)
      if (Test-VisiblePixel -Color $pixel -Threshold $Threshold) {
        if ($x -lt $minX) { $minX = $x }
        if ($y -lt $minY) { $minY = $y }
        if ($x -gt $maxX) { $maxX = $x }
        if ($y -gt $maxY) { $maxY = $y }
      }
    }
  }

  if ($maxX -lt 0 -or $maxY -lt 0) {
    throw "No visible pixels found in run [$StartX..$EndX]."
  }

  return [pscustomobject]@{
    X      = $minX
    Y      = $minY
    Width  = $maxX - $minX + 1
    Height = $maxY - $minY + 1
  }
}

if (-not (Test-Path -LiteralPath $InputPath)) {
  throw "Input file not found: $InputPath"
}

$source = [System.Drawing.Bitmap]::FromFile($InputPath)
try {
  $runs = Get-ColumnRuns -Bitmap $source -Threshold $BlackThreshold | Where-Object { $_.Width -ge 5 }
  if ($runs.Count -lt $Frames) {
    throw "Detected $($runs.Count) sprite regions, expected at least $Frames."
  }

  if ($runs.Count -gt $Frames) {
    $runs = $runs |
      Sort-Object Width -Descending |
      Select-Object -First $Frames |
      Sort-Object Start
  } else {
    $runs = $runs | Sort-Object Start
  }

  $sheetWidth = $FrameWidth * $Frames
  $sheet = New-Object System.Drawing.Bitmap($sheetWidth, $FrameHeight, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
  try {
    $gfx = [System.Drawing.Graphics]::FromImage($sheet)
    try {
      $gfx.Clear([System.Drawing.Color]::Transparent)
      $gfx.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
      $gfx.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
      $gfx.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
      $gfx.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::None

      for ($i = 0; $i -lt $Frames; $i++) {
        $run = $runs[$i]
        $bounds = Get-VisibleBounds -Bitmap $source -StartX $run.Start -EndX $run.End -Threshold $BlackThreshold
        $crop = New-Object System.Drawing.Bitmap($bounds.Width, $bounds.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
          for ($x = 0; $x -lt $bounds.Width; $x++) {
            for ($y = 0; $y -lt $bounds.Height; $y++) {
              $pixel = $source.GetPixel($bounds.X + $x, $bounds.Y + $y)
              if (Test-VisiblePixel -Color $pixel -Threshold $BlackThreshold) {
                $crop.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $pixel.R, $pixel.G, $pixel.B))
              } else {
                $crop.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
              }
            }
          }

          $scaleX = [double]$FrameWidth / [double]$bounds.Width
          $scaleY = [double]$FrameHeight / [double]$bounds.Height
          $scale = [Math]::Min($scaleX, $scaleY)
          $dstW = [Math]::Max(1, [int][Math]::Floor($bounds.Width * $scale))
          $dstH = [Math]::Max(1, [int][Math]::Floor($bounds.Height * $scale))
          $dstX = ($i * $FrameWidth) + [int][Math]::Floor(($FrameWidth - $dstW) / 2.0)
          $dstY = $FrameHeight - $dstH

          $gfx.DrawImage(
            $crop,
            [System.Drawing.Rectangle]::new($dstX, $dstY, $dstW, $dstH),
            [System.Drawing.Rectangle]::new(0, 0, $bounds.Width, $bounds.Height),
            [System.Drawing.GraphicsUnit]::Pixel
          )
        } finally {
          $crop.Dispose()
        }
      }
    } finally {
      $gfx.Dispose()
    }

    $outputDir = Split-Path -Parent $OutputPath
    if ($outputDir -and -not (Test-Path -LiteralPath $outputDir)) {
      New-Item -ItemType Directory -Path $outputDir | Out-Null
    }

    $sheet.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Output "Saved sprite sheet: $OutputPath"
    Write-Output "Layout: $Frames frames, ${FrameWidth}x${FrameHeight} each, total ${sheetWidth}x${FrameHeight}"
  } finally {
    $sheet.Dispose()
  }
} finally {
  $source.Dispose()
}
