# URI

URI is a PowerShell module that provides robust functions for parsing, constructing, and manipulating URIs. It offers easy-to-use commands to:

- Parse URL query strings into hashtables.
- Convert hashtables (or dictionaries) into properly URL-encoded query strings.
- Build complete URIs from base addresses, path segments, query parameters, and fragments—with automatic handling of URL encoding per [RFC3986](https://datatracker.ietf.org/doc/html/rfc3986).

## Prerequisites

This module uses the following external resources:
- The [PSModule framework](https://github.com/PSModule) for building, testing, and publishing the module.

## Installation

To install the module from the PowerShell Gallery, run the following commands:

```powershell
Install-PSResource -Name Uri
Import-Module -Name Uri
```

## Usage

The **URI** module includes several functions to work with URIs. Below are common use cases and examples:

### 1. Parsing a Query String

Use `ConvertFrom-UriQueryString` to convert a URL query string into a hashtable of parameters. This function decodes percent-encoded characters and handles duplicate keys by returning an array of values.

```powershell
# Example: Parsing a query string with multiple values for the same key.
$parsed = ConvertFrom-UriQueryString -Query 'name=John%20Doe&age=30&age=40'
$parsed
```

Expected Output:

```powershell
Name                           Value
----                           -----
name                           John Doe
age                            {30, 40}
```

### 2. Constructing a Query String

Use `ConvertTo-UriQueryString` to convert a hashtable (or dictionary) of parameters into a URL-encoded query string. If a value is an array, multiple key-value pairs will be generated.

```powershell
# Example: Converting a hashtable of parameters into a query string.
$queryString = ConvertTo-UriQueryString -Query @{ foo = 'bar'; search = 'hello world'; ids = 1,2,3 }
$queryString
```

Expected Output:

```powershell
foo=bar&search=hello%20world&ids=1&ids=2&ids=3
```

### 3. Building a Complete URI

Use `New-Uri` to construct a URI by combining a base URI with optional path segments, query parameters, and a fragment.

```powershell
# Example 1: Building a URI with a base and a path.
$uri = New-Uri -BaseUri 'https://example.com' -Path 'products/item'
$uri
```

Expected Output (as a `[System.Uri]` object):

```powershell
AbsoluteUri : https://example.com/products/item
...
```

```powershell
# Example 2: Constructing a URI while merging existing query parameters.
$uriString = New-Uri 'https://example.com/data?year=2023' -Query @{ year = 2024; sort = 'asc' } -MergeQueryParameters -AsString
$uriString
```

Expected Output:

```powershell
https://example.com/data?sort=asc&year=2023&year=2024
```

## Documentation

For more detailed documentation about each function and additional examples, please refer to the [documentation](docs) folder in the repository or view the detailed help in PowerShell:

```powershell
Get-Help ConvertFrom-UriQueryString -Detailed
Get-Help ConvertTo-UriQueryString -Detailed
Get-Help New-Uri -Detailed
```

## Contributing

Contributions are welcome—whether you're a user or a developer!

### For Users

If you encounter issues, unexpected behavior, or have feature requests, please submit a new issue via the repository's Issues tab.

### For Developers

We appreciate your help in making this module even better. Please review our [Contribution Guidelines](CONTRIBUTING.md) before submitting pull requests. You can start by picking up an existing issue or proposing new features or improvements.
