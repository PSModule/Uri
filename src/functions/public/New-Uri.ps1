function New-Uri {
    <#
        .SYNOPSIS
        Constructs a URI from base, paths, query parameters, and fragment.

        .DESCRIPTION
        Builds a URI string or object by combining a base URI with additional path segments,
        query parameters, and an optional fragment. Ensures proper encoding (per [RFC3986](https://datatracker.ietf.org/doc/html/rfc3986))
        and correct placement of '/' in paths, handles query parameter merging, and appends
        fragment identifiers. By default, returns a `[System.Uri]` object.

        .EXAMPLE
        # Simple usage with base and path
        New-Uri -BaseUri 'https://example.com' -Path 'products/item'

        Output:
        ```powershell
        AbsolutePath   : /products/item
        AbsoluteUri    : https://example.com/products/item
        LocalPath      : /products/item
        Authority      : example.com
        HostNameType   : Dns
        IsDefaultPort  : True
        IsFile         : False
        IsLoopback     : False
        PathAndQuery   : /products/item
        Segments       : {/, products/, item}
        IsUnc          : False
        Host           : example.com
        Port           : 443
        Query          :
        Fragment       :
        Scheme         : https
        OriginalString : https://example.com:443/products/item
        DnsSafeHost    : example.com
        IdnHost        : example.com
        IsAbsoluteUri  : True
        UserEscaped    : False
        UserInfo       :
        ```

        Constructs a URI with the given base and path.

        .EXAMPLE
        # Adding query parameters via hashtable
        New-Uri 'https://example.com/api' -Path 'search' -Query @{ q = 'test search'; page = @(2, 4) } -AsUriBuilder

        Output:
        ```powershell
        Scheme   : https
        UserName :
        Password :
        Host     : example.com
        Port     : 443
        Path     : /api/search
        Query    : ?q=test%20search&page=2&page=4
        Fragment :
        Uri      : https://example.com/api/search?q=test search&page=2&page=4
        ```

        Adds query parameters to the URI, automatically encoding values.

        .EXAMPLE
        # Merging with existing query and using -MergeQueryParameter
        New-Uri 'https://example.com/data?year=2023' -Query @{ year = 2024; sort = 'asc' } -MergeQueryParameters -AsString

        Output:
        ```powershell
        https://example.com/data?sort=asc&year=2023&year=2024
        ```

        Merges new query parameters with the existing ones instead of replacing them.

        .OUTPUTS
        System.Uri

        .OUTPUTS
        System.UriBuilder

        .OUTPUTS
        string

        .NOTES
        - This function ensures URL encoding unless `-NoEncoding` is used.
        - Merging query parameters allows keeping multiple values for the same key.

        .LINK
        https://psmodule.io/Uri/Functions/New-Uri
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions', '',
        Scope = 'Function',
        Justification = 'Creates a new URI object without changing state'
    )]
    [OutputType(ParameterSetName = 'AsString', [string])]
    [OutputType(ParameterSetName = 'AsUri', [System.Uri])]
    [OutputType(ParameterSetName = 'AsUriBuilder', [System.UriBuilder])]
    [CmdletBinding(DefaultParameterSetName = 'AsUri')]
    param(
        # The base URI (string or [System.Uri]) to start from.
        [Parameter(Mandatory, Position = 0)]
        [Alias('Uri')]
        [object] $BaseUri,

        # One or more path segments to append to the base URI.
        [Parameter(Position = 1)]
        [string[]] $Path,

        # Query parameters to add to the URI.
        [Parameter()]
        [object] $Query,

        # A URI fragment to append (the part after '#').
        [Parameter()]
        [string] $Fragment,

        # If set, allows duplicate query keys instead of overriding.
        [Parameter()]
        [switch] $MergeQueryParameters,

        # Outputs the resulting URI as a string.
        [Parameter(Mandatory, ParameterSetName = 'AsString')]
        [switch] $AsString,

        # Outputs the resulting URI as a System.UriBuilder object.
        [Parameter(Mandatory, ParameterSetName = 'AsUriBuilder')]
        [switch] $AsUriBuilder
    )

    # Validate and prepare base URI
    try {
        $baseUriObj = if ($BaseUri -is [System.Uri]) {
            $BaseUri
        } else {
            [System.Uri]::new([string]$BaseUri)  # may throw if invalid
        }
    } catch {
        throw "BaseUri '$BaseUri' is not a valid URI: $($_.Exception.Message)"
    }

    # Use UriBuilder for convenient manipulation
    $builder = [System.UriBuilder]::new($baseUriObj)

    # Handle path segments
    if ($Path) {
        $basePath = $builder.Path  # e.g. "/" from 'https://example.com'
        $segments = @()

        # If a single element containing '/' was passed, split it into segments.
        if ($Path.Count -eq 1 -and $Path[0] -match '/') {
            $segments = $Path[0].Split('/') | Where-Object { $_ -ne '' }
        } else {
            $segments = $Path
        }

        # Normalize base path: ensure it ends with '/' if we need to append, except if base path is empty or just "/"
        if ([string]::IsNullOrEmpty($basePath) -or $basePath -eq '/') {
            $basePath = ''
        } elseif ($basePath[-1] -ne '/') {
            $basePath += '/'
        }

        # Build combined path string from segments, always encoding
        $encodedSegments = @()
        foreach ($seg in $segments) {
            $encodedSegments += [System.Uri]::EscapeDataString($seg)
        }

        $combinedPath = if ($basePath -ne '' -and $basePath -ne '/') {
            "$basePath$([string]::Join('/', $encodedSegments))"
        } else {
            '/' + [string]::Join('/', $encodedSegments)
        }

        # Preserve trailing slash if original single string ended with '/'
        if ($Path.Count -eq 1 -and $Path[0].EndsWith('/')) {
            $combinedPath += '/'
        }
        $builder.Path = $combinedPath
    }

    # Handle query parameters
    if ($null -ne $Query) {
        # Convert base URI's existing query to hashtable for merging (if any)
        $baseQueryParams = @{}
        if ($builder.Query -and $builder.Query.Length -gt 1) {
            # builder.Query returns string starting with '?'
            $existingQueryString = $builder.Query.Substring(1)  # drop the '?'
            $baseQueryParams = ConvertFrom-UriQueryString -Query $existingQueryString
        }

        # Determine new query parameters from $Query input
        $newQueryParams = @{}
        if ($Query -is [hashtable] -or $Query -is [System.Collections.IDictionary]) {
            $newQueryParams = $Query
        } elseif ($Query -is [string]) {
            # Remove leading '?' if present
            $queryStr = $Query
            if ($queryStr.StartsWith('?')) { $queryStr = $queryStr.Substring(1) }
            if ($queryStr -ne '') {
                $newQueryParams = ConvertFrom-UriQueryString -Query $queryStr
            }
        } else {
            throw 'Query parameter must be a hashtable or query string (string).'
        }

        # Merge base and new query params
        $mergedParams = @{}
        foreach ($key in $baseQueryParams.Keys) {
            $mergedParams[$key] = $baseQueryParams[$key]
        }
        foreach ($key in $newQueryParams.Keys) {
            if ($MergeQueryParameters -and $mergedParams.Contains($key)) {
                # Merge same parameter: ensure value becomes an array of all values
                $existingVal = $mergedParams[$key]
                # Convert single existing value to array if not already
                if ($null -ne $existingVal -and $existingVal.GetType().IsArray -eq $false) {
                    $existingVal = , $existingVal  # wrap in array
                }
                $newVal = $newQueryParams[$key]
                if ($null -ne $newVal -and $newVal.GetType().IsArray -eq $false) {
                    $newVal = , $newVal
                }
                # Combine arrays (or values) into one array
                $combinedVal = @()
                if ($existingVal) { $combinedVal += $existingVal }
                if ($newVal) { $combinedVal += $newVal }
                $mergedParams[$key] = $combinedVal
            } else {
                # New value overwrites or adds
                $mergedParams[$key] = $newQueryParams[$key]
            }
        }

        # Convert merged hashtable to query string (always encoding)
        $finalQueryString = ConvertTo-UriQueryString -Query $mergedParams
        $builder.Query = $finalQueryString  # UriBuilder handles the '?' automatically
    }

    # Handle fragment
    if ($PSBoundParameters.ContainsKey('Fragment')) {
        if ([string]::IsNullOrEmpty($Fragment)) {
            $builder.Fragment = ''  # remove any existing fragment
        } else {
            $builder.Fragment = [System.Uri]::EscapeDataString(($Fragment -replace '^#', ''))
        }
    }
    # (If fragment not provided, any fragment in base URI stays as is)

    # Output based on switches
    switch ($PSCmdlet.ParameterSetName) {
        'AsUriBuilder' {
            return $builder
        }
        'AsUri' {
            return $builder.Uri
        }
        'AsString' {
            $uriString = "$($builder.Scheme)://$($builder.Host)$($builder.Uri.PathAndQuery)"
            if ($builder.Fragment) { $uriString += "$($builder.Fragment)" -replace '(%20| )', '-' }
            return $uriString
        }
    }
}
