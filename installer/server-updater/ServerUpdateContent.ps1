function Convert-ServerUpdateContentToText {
    param(
        [AllowNull()]
        [object]$Content
    )

    if ($null -eq $Content) {
        return ""
    }
    if ($Content -is [byte[]]) {
        $utf8 = [Text.UTF8Encoding]::new($false, $true)
        return $utf8.GetString([byte[]]$Content)
    }
    return [string]$Content
}
