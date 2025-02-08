filter ConvertTo-UriQueryString {
    <#
        .SYNOPSIS
        Converts a hashtable of parameters into a URL query string.

        .DESCRIPTION
        Takes a hashtable or dictionary of query parameters (keys and values) and constructs
        a properly encoded query string (e.g. "key1=value1&key2=value2"). By default, all keys
        and values are URL-encoded per RFC3986 rules to ensure the query string is valid. If a value
        is an array, multiple entries for the same key are generated. Use -NoEncoding to skip encoding.

        .EXAMPLE
        ConvertTo-UriQueryString -Query @{ foo = 'bar'; search = 'hello world'; ids = 1,2,3 }

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
        [Alias('Params', 'Hashtable')]
        [System.Collections.IDictionary] $Query,

        # If set, keys and values are not URL-encoded. Use this only if the inputs are already encoded or consist solely
        # of characters safe in URLs. Without this, encoding is applied to escape special characters (e.g. spaces, &, =, #).
        [Parameter()]
        [switch] $NoEncoding
    )

    Write-Verbose "Converting hashtable to query string"
    Write-Verbose "NoEncoding: $NoEncoding"
    Write-Verbose "Query: $($Query | Out-String)"
    
    # Build the query string by iterating through each key-value pair
    $pairs = @()
    foreach ($key in $Query.Keys) {
        $name = if ($NoEncoding) { $key.ToString() } else { [System.Uri]::EscapeDataString($key.ToString()) }
        $value = $Query[$key]

        if ($null -eq $value) {
            # Null value -> include key with empty value
            $pairs += "$name="
        } elseif ([System.Collections.IEnumerable].IsAssignableFrom($value.GetType()) -and
            -not ($value -is [string])) {
            # If the value is a collection (and not a string, since strings are IEnumerable of chars), handle each.
            foreach ($item in $value) {
                $itemValue = if ($NoEncoding) { "$item" } else { [System.Uri]::EscapeDataString( ("$item") ) }
                $pairs += "$name=$itemValue"
            }
        } else {
            # Single value (includes strings, numbers, booleans, etc.)
            $itemValue = if ($NoEncoding) { "$value" } else { [System.Uri]::EscapeDataString( ("$value") ) }
            $pairs += "$name=$itemValue"
        }
    }
    # Join all pairs with '&' and return
    return [string]::Join('&', $pairs)
}
