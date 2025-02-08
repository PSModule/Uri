function New-Uri {
    <#
        .SYNOPSIS
        Constructs a URI from base, paths, query parameters, and fragment.

        .DESCRIPTION
        Builds a URI string or object by combining a base URI with additional path segments,
        query parameters, and an optional fragment. Ensures proper encoding (per RFC3986)
        and correct placement of '/' in paths, handles query parameter merging, and appends
        fragment identifiers. By default, returns a System.Uri object.

        .EXAMPLE
        # Simple usage with base and path
        New-Uri -BaseUri 'https://example.com' -Path 'products/item'

        Output:
        ```powershell
        https://example.com/products/item
        ```

        Constructs a URI with the given base and path.

        .EXAMPLE
        # Adding query parameters via hashtable
        New-Uri 'https://example.com/api' -Path 'search' -Query @{ q = 'test search'; page = @(2, 4) }

        Output:
        ```powershell
        https://example.com/api/search?q=test%20search&page=2
        ```

        Adds query parameters to the URI, automatically encoding values.

        .EXAMPLE
        # Merging with existing query and using -MergeQueryParameter
        New-Uri 'https://example.com/data?year=2023' -Query @{ year = 2024; sort = 'asc' } -MergeQueryParameters

        Output:
        ```powershell
        https://example.com/data?year=2023&year=2024&sort=asc
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
        [Alias('Paths')]
        [string[]] $Path,

        # Query parameters to add to the URI.
        [Parameter()]
        [Alias('QueryParameters', 'QueryString')]
        [object] $Query,

        # A URI fragment to append (the part after '#').
        [Parameter()]
        [string] $Fragment,

        # If set, allows duplicate query keys instead of overriding.
        [Parameter()]
        [switch] $MergeQueryParameters,

        # Disables automatic URL encoding of path, query, and fragment.
        [Parameter()]
        [switch] $NoEncoding,

        # Outputs the resulting URI as a string.
        [Parameter(Mandatory, ParameterSetName = 'AsString')]
        [switch] $AsString,

        # Outputs the resulting URI as a System.UriBuilder object.
        [Parameter(Mandatory, ParameterSetName = 'AsUriBuilder')]
        [switch] $AsUriBuilder
    )

    # Validate and prepare base URI
    try {
        # Accept [System.Uri] or string for base
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

        # Build combined path string from segments
        $encodedSegments = @()
        foreach ($seg in $segments) {
            if ($NoEncoding) {
                $encodedSegments += $seg
            } else {
                # Encode each segment individually (slashes are added between segments)
                $encodedSegments += [System.Uri]::EscapeDataString($seg)
            }
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
                # If not merging duplicates, new value overwrites existing (or just adds if new)
                $mergedParams[$key] = $newQueryParams[$key]
            }
        }

        # Convert merged hashtable to query string
        $finalQueryString = ConvertTo-UriQueryString -Query $mergedParams -NoEncoding:$NoEncoding
        $builder.Query = $finalQueryString  # UriBuilder will prepend '?' automatically as needed
    } else {
        # If no new Query provided, but base URI had a query, ensure it's correctly encoded if NoEncoding is false.
        # (UriBuilder.Query should have the base query already, and it is already encoded by System.Uri on BaseUriObj creation)
        if ($NoEncoding) {
            # If NoEncoding, we take the base query as-is (UriBuilder would have percent-encoded it already if base was string).
            # Optionally, user might expect to keep percent-encoding from base even if NoEncoding is set.
            # We'll leave it untouched.
        }
    }

    # Handle fragment
    if ($PSBoundParameters.ContainsKey('Fragment')) {
        # If Fragment is explicitly provided (even if empty string)
        if ([string]::IsNullOrEmpty($Fragment)) {
            # Empty fragment means remove any existing fragment
            $builder.Fragment = ''  # setting to empty string effectively removes fragment
        } else {
            $builder.Fragment = $NoEncoding ? ($Fragment -replace '^#', '')
            : [System.Uri]::EscapeDataString(($Fragment -replace '^#', ''))
        }
    }
    # (If fragment not provided, any fragment in base URI stays as is in builder.Fragment)

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
