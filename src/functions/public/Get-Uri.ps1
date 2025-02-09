function Get-Uri {
    <#
        .SYNOPSIS
        Converts a string into a System.Uri, System.UriBuilder, or a normalized URI string.

        .DESCRIPTION
        The Get-Uri function processes a string and attempts to convert it into a valid URI.
        It supports three output formats: a System.Uri object, a System.UriBuilder object,
        or a normalized absolute URI string. If no scheme is present, "http://" is prefixed
        to ensure a valid URI. The function enforces mutual exclusivity between the output
        format parameters.

        .EXAMPLE
        Get-Uri -Uri 'example.com'

        Output:
        ```powershell
        http://example.com/
        ```

        Converts 'example.com' into a normalized absolute URI string.

        .EXAMPLE
        Get-Uri -Uri 'https://example.com/path' -AsUriBuilder

        Output:
        ```powershell
        Host    : example.com
        Scheme  : https
        Path    : /path
        ```

        Returns a [System.UriBuilder] object for the specified URI.

        .EXAMPLE
        Get-Uri -Uri 'https://example.com/path' -AsUri

        Output:
        ```powershell
        AbsoluteUri : https://example.com/path
        ```

        Returns a [System.Uri] object with the full absolute URI.

        .EXAMPLE
        Get-Uri -Uri '/path/to/resource'

        Returns a relative URI (with no hostname).

        .LINK
        https://psmodule.io/Uri/Functions/Get-Uri
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSReviewUnusedParameter', 'AsString',
        Scope = 'Function',
        Justification = 'Present for parameter sets'
    )]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSReviewUnusedParameter', 'AsUriBuilder',
        Scope = 'Function',
        Justification = 'Present for parameter sets'
    )]
    [OutputType(ParameterSetName = 'UriBuilder', [System.UriBuilder])]
    [OutputType(ParameterSetName = 'String', [string])]
    [OutputType(ParameterSetName = 'AsUri', [System.Uri])]
    [CmdletBinding(DefaultParameterSetName = 'AsUri')]
    param(
        # The string representation of the URI to be processed.
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string] $Uri,

        # Outputs a System.UriBuilder object.
        [Parameter(Mandatory, ParameterSetName = 'AsUriBuilder')]
        [switch] $AsUriBuilder,

        # Outputs the URI as a normalized string.
        [Parameter(Mandatory, ParameterSetName = 'AsString')]
        [switch] $AsString
    )

    process {
        $inputString = $Uri.Trim()
        if ([string]::IsNullOrWhiteSpace($inputString)) {
            throw 'The Uri parameter cannot be null or empty.'
        }

        # Attempt to create a System.Uri (absolute) from the string
        $uriObject = $null
        $success = [System.Uri]::TryCreate($inputString, [System.UriKind]::RelativeOrAbsolute, [ref]$uriObject)
        if (-not $success) {
            # If no scheme present, try adding "http://"
            if ($inputString -notmatch '^[A-Za-z][A-Za-z0-9+.-]*:') {
                $success = [System.Uri]::TryCreate("http://$inputString", [System.UriKind]::Absolute, [ref]$uriObject)
            }
            if (-not $success) {
                throw "The provided value '$Uri' cannot be converted to a valid URI."
            }
        }

        if ($uriObject.IsAbsoluteUri) {
            switch ($PSCmdlet.ParameterSetName) {
                'AsUriBuilder' {
                    return ([System.UriBuilder]::new($uriObject))
                }
                'AsString' {
                    return ($uriObject.GetComponents([System.UriComponents]::AbsoluteUri, [System.UriFormat]::SafeUnescaped))
                }
                'AsUri' {
                    return $uriObject
                }
            }
        } else {
            switch ($PSCmdlet.ParameterSetName) {
                'AsUriBuilder' {
                    throw 'Cannot convert a relative URI to a UriBuilder. Please supply an absolute URI.'
                }
                'AsString' {
                    return $uriObject.OriginalString
                }
                'AsUri' {
                    return $uriObject
                }
            }
        }
    }
}
