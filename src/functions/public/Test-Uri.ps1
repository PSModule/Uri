function Test-Uri {
    <#
        .SYNOPSIS
        Validates whether a given string is a valid URI.

        .DESCRIPTION
        The Test-Uri function checks whether a given string is a valid URI. By default, it enforces absolute URIs.
        If the `-AllowRelative` switch is specified, it allows both absolute and relative URIs.

        .EXAMPLE
        ```pwsh
        Test-Uri -Uri "https://example.com"
        ```

        Output:
        ```powershell
        True
        ```

        Checks if `https://example.com` is a valid URI, returning `$true`.

        .EXAMPLE
        ```pwsh
        Test-Uri -Uri "invalid-uri"
        ```

        Output:
        ```powershell
        False
        ```

        Returns `$false` for an invalid URI string.

        .EXAMPLE
        ```pwsh
        "https://example.com", "invalid-uri" | Test-Uri
        ```

        Output:
        ```powershell
        True
        False
        ```

        Accepts input from the pipeline and validates multiple URIs.

        .OUTPUTS
        [System.Boolean]

        .NOTES
        Returns `$true` if the input string is a valid URI, otherwise returns `$false`.

        .LINK
        https://psmodule.io/Uri/Functions/Test-Uri
    #>
    [OutputType([bool])]
    [CmdletBinding()]
    param(
        # Accept one or more URI strings from parameter or pipeline.
        [Parameter(Mandatory, ValueFromPipeline)]
        [string] $Uri,

        # If specified, allow valid relative URIs.
        [Parameter()]
        [switch] $AllowRelative
    )

    process {
        # If -AllowRelative is set, try to create a URI using RelativeOrAbsolute.
        # Otherwise, enforce an Absolute URI.
        $uriKind = if ($AllowRelative) {
            [System.UriKind]::RelativeOrAbsolute
        } else {
            [System.UriKind]::Absolute
        }

        # Try to create the URI. The out parameter is not used.
        $dummy = $null
        [System.Uri]::TryCreate($Uri, $uriKind, [ref]$dummy)
    }
}
