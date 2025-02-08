filter ConvertFrom-UriQueryString {
    <#
        .SYNOPSIS
        Parses a URL query string into a hashtable of parameters.

        .DESCRIPTION
        Takes a URI query string (the portion after the '?') and converts it into a hashtable
        where each key is a parameter name and the corresponding value is the parameter value.
        If the query string contains the same parameter multiple times, the resulting value
        will be an array of those values. Percent-encoded characters in the input are decoded
        back to their normal representation.

        .EXAMPLE
        ConvertFrom-UriQueryString -QueryString 'name=John%20Doe&age=30&age=40'

        Output:
        ```powershell
        Name                           Value
        ----                           -----
        name                           John Doe
        age                            {30, 40}
        ```

        Parses the given query string and returns a hashtable where keys are parameter names and
        values are decoded parameter values.

        .EXAMPLE
        ConvertFrom-UriQueryString '?q=PowerShell%20URI'

        Output:
        ```powershell
        Name                           Value
        ----                           -----
        q                              PowerShell URI
        ```

        Parses a query string that contains a single parameter and returns the corresponding value.

        .LINK
        https://psmodule.io/Uri/Functions/ConvertFrom-UriQueryString/
    #>
    [OutputType([hashtable])]
    [CmdletBinding()]
    param(
        # The query string to parse. This can include the leading '?' or just the key-value pairs.
        # For example, both "?foo=bar&count=10" and "foo=bar&count=10" are acceptable.
        [Parameter(Position = 0, ValueFromPipeline)]
        [AllowNull()]
        [string] $Query
    )

    # Early exit if $Query is null or empty.
    if ([string]::IsNullOrEmpty($Query)) {
        Write-Verbose 'Query string is null or empty.'
        return @{}
    }

    Write-Verbose "Parsing query string: $Query"
    # Remove leading '?' if present
    if ($Query.StartsWith('?')) {
        $Query = $Query.Substring(1)
    }
    if ([string]::IsNullOrEmpty($Query)) {
        return @{}  # return empty hashtable if no query present
    }

    $result = @{}
    # Split by '&' to get each key=value pair
    $pairs = $Query.Split('&')
    foreach ($pair in $pairs) {
        if ([string]::IsNullOrWhiteSpace($pair)) { continue }  # skip empty segments (e.g. "&&")

        $key, $val = $pair.Split('=', 2)  # split into two parts at first '='
        $key = [System.Uri]::UnescapeDataString($key)
        if ($null -ne $val) {
            $val = [System.Uri]::UnescapeDataString($val)
        } else {
            $val = ''  # if no '=' present, treat value as empty string
        }

        if ($result.Contains($key)) {
            # If key already exists, convert value to array or add to existing array
            if ($result[$key] -is [System.Collections.IEnumerable] -and
                $result[$key] -isnot [string]) {
                # If already an array or collection, just add
                $result[$key] += $val
            } else {
                # If a single value exists, turn it into an array
                $result[$key] = @($result[$key], $val)
            }
        } else {
            $result[$key] = $val
        }
    }
    return $result
}
