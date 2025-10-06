$text = "Fallout.S01E01.The.End"
$pattern = '(?i)^(.*?)(\.)(s\d{1,2}e\d{1,2})(\.)(.*)$'   # (?i) = case-insensitive

if ($text -match $pattern) {
    $prefix = $matches[1]
    $dotBefore = $matches[2]
    $se = $matches[3]
    $dotAfter = $matches[4]
    $suffix = $matches[5]

    # preserve extension (keep last dot + extension intact)
    $lastDot = $suffix.LastIndexOf('.')
    if ($lastDot -ge 0) {
        $body = $suffix.Substring(0, $lastDot)
        $ext = $suffix.Substring($lastDot)   # includes dot
    }
    else {
        $body = $suffix
        $ext = ''
    }

    $result = ($prefix -replace '\.', '-') + $dotBefore + $se + $dotAfter + ($body -replace '\.', '-') + $ext
}
else {
    Write-Host "Pattern did not match. Check case / SxxExx format."
    $result = $text
}

$result
