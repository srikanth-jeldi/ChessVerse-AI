param(
    [Parameter(Mandatory = $true)]
    [string]$Atlas,
    [Parameter(Mandatory = $true)]
    [string]$OutputDirectory,
    [switch]$KingPair
)

Add-Type -AssemblyName System.Drawing
$drawingReferences = [System.AppDomain]::CurrentDomain.GetAssemblies() |
    Where-Object { $_.GetName().Name -in @(
        'System.Drawing.Common',
        'System.Drawing.Primitives',
        'System.Private.Windows.Core',
        'System.Private.Windows.GdiPlus'
    ) } |
    ForEach-Object { $_.Location }
$drawingReferences += [System.Collections.Generic.List[int]].Assembly.Location
$drawingReferences = $drawingReferences | Select-Object -Unique

if (-not ('SpriteAlphaCleaner' -as [type])) {
Add-Type -ReferencedAssemblies $drawingReferences -TypeDefinition @"
using System.Drawing;
using System.Drawing.Imaging;

public static class SpriteAlphaCleaner
{
    public static void RemoveSmallComponents(Bitmap bitmap, int minimumArea)
    {
        var width = bitmap.Width;
        var height = bitmap.Height;
        var labels = new int[width * height];
        var counts = new int[width * height];
        var queue = new int[width * height];
        var label = 0;
        for (var y = 0; y < height; y++)
        {
            for (var x = 0; x < width; x++)
            {
                var start = y * width + x;
                if (labels[start] != 0 || bitmap.GetPixel(x, y).A < 48) continue;
                label++;
                var head = 0;
                var tail = 0;
                queue[tail++] = start;
                labels[start] = label;
                while (head < tail)
                {
                    var current = queue[head++];
                    counts[label]++;
                    var cx = current % width;
                    var cy = current / width;
                    for (var dy = -1; dy <= 1; dy++)
                    {
                        for (var dx = -1; dx <= 1; dx++)
                        {
                            if (dx == 0 && dy == 0) continue;
                            var nx = cx + dx;
                            var ny = cy + dy;
                            if (nx < 0 || ny < 0 || nx >= width || ny >= height) continue;
                            var next = ny * width + nx;
                            if (labels[next] != 0 || bitmap.GetPixel(nx, ny).A < 48) continue;
                            labels[next] = label;
                            queue[tail++] = next;
                        }
                    }
                }
            }
        }

        var largestLabel = 0;
        for (var candidate = 1; candidate <= label; candidate++)
            if (counts[candidate] > counts[largestLabel]) largestLabel = candidate;

        for (var y = 0; y < height; y++)
        {
            for (var x = 0; x < width; x++)
            {
                var currentLabel = labels[y * width + x];
                if (currentLabel != 0 && currentLabel != largestLabel)
                    bitmap.SetPixel(x, y, Color.Transparent);
            }
        }
    }

    public static Rectangle FindBounds(Bitmap bitmap, Rectangle cell)
    {
        var left = cell.Right;
        var top = cell.Bottom;
        var right = cell.Left;
        var bottom = cell.Top;
        var cellRight = System.Math.Min(cell.Right, bitmap.Width);
        var cellBottom = System.Math.Min(cell.Bottom, bitmap.Height);
        for (var y = System.Math.Max(0, cell.Top); y < cellBottom; y++)
        {
            for (var x = System.Math.Max(0, cell.Left); x < cellRight; x++)
            {
                if (bitmap.GetPixel(x, y).A < 48) continue;
                if (x < left) left = x;
                if (x > right) right = x;
                if (y < top) top = y;
                if (y > bottom) bottom = y;
            }
        }
        return right >= left && bottom >= top
            ? Rectangle.FromLTRB(left, top, right + 1, bottom + 1)
            : cell;
    }

    public static void ErodeTransparentEdge(Bitmap bitmap, int radius)
    {
        using (var original = (Bitmap)bitmap.Clone())
        {
            for (var y = 0; y < bitmap.Height; y++)
            {
                for (var x = 0; x < bitmap.Width; x++)
                {
                    var color = original.GetPixel(x, y);
                    if (color.A < 96)
                    {
                        bitmap.SetPixel(x, y, Color.Transparent);
                        continue;
                    }

                    var touchesTransparency = false;
                    for (var dy = -radius; dy <= radius && !touchesTransparency; dy++)
                    {
                        for (var dx = -radius; dx <= radius; dx++)
                        {
                            var nx = x + dx;
                            var ny = y + dy;
                            if (nx < 0 || ny < 0 || nx >= bitmap.Width || ny >= bitmap.Height ||
                                original.GetPixel(nx, ny).A < 48)
                            {
                                touchesTransparency = true;
                                break;
                            }
                        }
                    }

                    if (touchesTransparency)
                    {
                        bitmap.SetPixel(x, y, Color.Transparent);
                    }
                }
            }
        }
    }
}
"@
}

$pieceNames = if ($KingPair) { @('king', 'king') } else { @('rook', 'knight', 'bishop', 'queen', 'king', 'pawn') }
$source = [System.Drawing.Bitmap]::FromFile($Atlas)
try {
    $columns = if ($KingPair) { 2 } else { 6 }
    $rows = if ($KingPair) { 1 } else { 2 }
    $cellWidth = [int]($source.Width / $columns)
    $cellHeight = [int]($source.Height / $rows)

    for ($row = 0; $row -lt $rows; $row++) {
        for ($column = 0; $column -lt $columns; $column++) {
            $side = if ($KingPair) {
                if ($column -eq 0) { 'black' } else { 'white' }
            } else {
                if ($row -eq 0) { 'black' } else { 'white' }
            }
            $sideDirectory = Join-Path $OutputDirectory $side
            New-Item -ItemType Directory -Path $sideDirectory -Force | Out-Null
            $target = New-Object System.Drawing.Bitmap 300, 300, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
            try {
                $graphics = [System.Drawing.Graphics]::FromImage($target)
                try {
                    $graphics.Clear([System.Drawing.Color]::Transparent)
                    $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
                    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
                    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
                    $cellRect = New-Object System.Drawing.Rectangle ($column * $cellWidth), ($row * $cellHeight), $cellWidth, $cellHeight
                    $sourceRect = [SpriteAlphaCleaner]::FindBounds($source, $cellRect)
                    $scale = [Math]::Min(276.0 / $sourceRect.Width, 276.0 / $sourceRect.Height)
                    $drawWidth = [int][Math]::Round($sourceRect.Width * $scale)
                    $drawHeight = [int][Math]::Round($sourceRect.Height * $scale)
                    $targetRect = New-Object System.Drawing.Rectangle ([int]((300 - $drawWidth) / 2)), (288 - $drawHeight), $drawWidth, $drawHeight
                    $graphics.DrawImage($source, $targetRect, $sourceRect, [System.Drawing.GraphicsUnit]::Pixel)
                } finally {
                    $graphics.Dispose()
                }

                [SpriteAlphaCleaner]::RemoveSmallComponents($target, 500)
                [SpriteAlphaCleaner]::ErodeTransparentEdge($target, 2)

                $path = Join-Path $sideDirectory ($pieceNames[$column] + '.png')
                $target.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
            } finally {
                $target.Dispose()
            }
        }
    }
} finally {
    $source.Dispose()
}
