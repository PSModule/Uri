filter ConvertTo-UriQueryString {
    <#
        .SYNOPSIS
        Converts a hashtable of parameters into a URL query string.

        .DESCRIPTION
        Takes a hashtable or dictionary of query parameters (keys and values) and constructs
        a properly encoded query string (e.g. "key1=value1&key2=value2"). By default, all keys
        and values are URL-encoded per RFC3986 rules to ensure the query string is valid. If a value
        is an array, multiple entries for the same key are generated.

        .EXAMPLE`
        ```pwsh
        ConvertTo-UriQueryString -Query @{ foo = 'bar'; search = 'hello world'; ids = 1,2,3 }
        ```

        Output:
        ```powershell
        foo=bar&search=hello%20world&ids=1&ids=2&ids=3
        ```

        Converts the hashtable into a URL-encoded query string. Spaces are replaced with `%20`.

        .EXAMPLE
        ConvertTo-UriQueryString -Query @{ q = 'PowerShell'; verbose = $true }

        Output:
        ```powershell
        q=PowerShell&verbose=True
        ```

        Converts the query parameters into a valid query string.

        .LINK
        https://psmodule.io/Uri/Functions/ConvertTo-UriQueryString
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param(
        # The hashtable (or IDictionary) containing parameter names and values. Each key becomes a parameter name.
        # Values can be strings or other types convertible to string. If a value is an array or collection, each element
        # in it will result in a separate instance of that parameter name in the output string.
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [System.Collections.IDictionary] $Query
    )

    Write-Verbose 'Converting hashtable to query string with URL encoding'
    Write-Verbose "Query: $($Query | Out-String)"
    # Build the query string by iterating through each key-value pair
    $pairs = @()
    foreach ($key in $Query.Keys) {
        # URL-encode the key.
        $name = [System.Uri]::EscapeDataString($key.ToString())
        $value = $Query[$key]

        if ($null -eq $value) {
            # Null value -> include key with empty value
            $pairs += "$name="
        } elseif ([System.Collections.IEnumerable].IsAssignableFrom($value.GetType()) -and -not ($value -is [string])) {
            foreach ($item in $value) {
                $itemValue = [System.Uri]::EscapeDataString("$item")
                $pairs += "$name=$itemValue"
            }
        } else {
            # Single value (includes strings, numbers, booleans, etc.)
            $itemValue = [System.Uri]::EscapeDataString("$value")
            $pairs += "$name=$itemValue"
        }
    }
    return [string]::Join('&', $pairs)
}
