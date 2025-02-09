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

        .LINK
        https://psmodule.io/Uri/Functions/Get-Uri
    #>

    [OutputType(ParameterSetName = 'UriBuilder', [System.UriBuilder])]
    [OutputType(ParameterSetName = 'String', [string])]
    [OutputType(ParameterSetName = 'AsUri', [System.Uri])]
    [CmdletBinding(DefaultParameterSetName = 'AsUri')]
    param(
        # The string representation of the URI to be processed.
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string] $Uri,

        # Outputs a System.UriBuilder object.
        [Parameter(Mandatory, ParameterSetName = 'UriBuilder')]
        [switch] $AsUriBuilder,

        # Outputs the URI as a normalized string.
        [Parameter(Mandatory, ParameterSetName = 'String')]
        [switch] $AsString
    )

    process {
        # Ensure mutually exclusive output switches (cannot use both simultaneously)
        if ($PSBoundParameters.ContainsKey('AsUriBuilder') -and $PSBoundParameters.ContainsKey('AsString')) {
            throw 'Please specify only one of -AsUriBuilder or -AsString.'
        }

        # Trim input to avoid issues with leading/trailing whitespace
        $inputString = $Uri.Trim()
        if ([string]::IsNullOrWhiteSpace($inputString)) {
            throw 'The Uri parameter cannot be null or empty.'
        }

        # Attempt to create a System.Uri (absolute) from the string
        $uriObject = $null
        $success = [System.Uri]::TryCreate($inputString, [System.UriKind]::Absolute, [ref]$uriObject)
        if (-not $success) {
            # If no scheme present, try adding "http://"
            if ($inputString -notmatch '^[A-Za-z][A-Za-z0-9+.-]*:') {
                $success = [System.Uri]::TryCreate("http://$inputString", [System.UriKind]::Absolute, [ref]$uriObject)
            }
            if (-not $success) {
                throw "The provided value '$Uri' cannot be converted to a valid URI."
            }
        }

        switch ($PSCmdlet.ParameterSetName) {
            'UriBuilder' {
                return [System.UriBuilder]::new($uriObject)   # Return UriBuilder object
            }
            'String' {
                # Return normalized absolute URI string (safe unescaped format)
                return $uriObject.GetComponents([System.UriComponents]::AbsoluteUri, [System.UriFormat]::SafeUnescaped)
            }
            'AsUri' {
                return $uriObject  # Return the System.Uri object by default
            }
        }
    }
}
