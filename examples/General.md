# Advanced Examples for the URI Module

This document demonstrates advanced usage scenarios for the **URI** module. These examples cover more complex cases, including handling duplicate query parameters, merging queries, and constructing URIs with multiple path segments and fragments.

---

## Example 1: Parsing a Complex Query String

When a query string includes duplicate keys and URL-encoded characters, the `ConvertFrom-UriQueryString` function returns arrays for keys with multiple values.

```powershell
# A query string with duplicate keys and an empty value.
$query = 'filter=active&filter=recent&search=PowerShell%20URI&empty'
$result = ConvertFrom-UriQueryString -Query $query
$result
```

**Expected Output:**

```none
Name                           Value
----                           -----
empty
search                         PowerShell URI
filter                         {active, recent}
```

---

## Example 2: Converting a Hashtable with Array Values to a Query String

The `ConvertTo-UriQueryString` function handles hashtables where some keys have array values by generating multiple key-value pairs.

```powershell
# A hashtable where 'tags' contains multiple values.
$params = @{
    category  = 'books'
    tags      = @('fiction', 'bestseller', '2023')
    available = $true
}
$queryString = ConvertTo-UriQueryString -Query $params
$queryString
```

**Expected Output:**

```none
category=books&tags=fiction&tags=bestseller&tags=2023&available=True
```

---

## Example 3: Merging Existing and New Query Parameters

Use `New-Uri` with the `-MergeQueryParameters` switch to merge new query parameters into a base URI that already includes a query string.

```powershell
# Base URI with an existing 'page' parameter.
$baseUri = 'https://example.com/api/items?page=1'
$newParams = @{ page = @(2,3); sort = 'desc' }
$uri = New-Uri -BaseUri $baseUri -Query $newParams -MergeQueryParameters -AsUri
$uri
```

**Expected Output:**

The resulting URI should merge the original and new query parameters, producing duplicate `page` keys:

```none
Scheme   : https
UserName :
Password :
Host     : example.com
Port     : 443
Path     : /api/items
Query    : ?page=1&page=2&page=3&sort=desc
Fragment :
Uri      : https://example.com/api/items?page=1&page=2&page=3&sort=desc
```

---

## Example 4: Constructing a URI with Multiple Path Segments and a Fragment

`New-Uri` accepts an array of path segments and a fragment, constructing a well-formed URI.

```powershell
# Combining multiple path segments and appending a fragment.
$uri = New-Uri -BaseUri 'https://example.com' -Path @('catalog', 'books', 'fiction') -Fragment 'section2'
$uri
```

**Expected Output:**

A URI similar to:

```none
AbsolutePath   : /catalog/books/fiction
AbsoluteUri    : https://example.com/catalog/books/fiction#section2
LocalPath      : /catalog/books/fiction
Authority      : example.com
HostNameType   : Dns
IsDefaultPort  : True
IsFile         : False
IsLoopback     : False
PathAndQuery   : /catalog/books/fiction
Segments       : {/, catalog/, books/, fiction}
IsUnc          : False
Host           : example.com
Port           : 443
Query          :
Fragment       : #section2
Scheme         : https
OriginalString : https://example.com:443/catalog/books/fiction#section2
DnsSafeHost    : example.com
IdnHost        : example.com
IsAbsoluteUri  : True
UserEscaped    : False
UserInfo       :
```

---

## Example 5: Producing a Custom-Formatted URI String

If you prefer the final URI as a string, use the `-AsString` switch. In this advanced example, notice how the fragment is appended after custom formatting.

```powershell
# Create a URI string with a custom formatted fragment.
$uriString = New-Uri -BaseUri 'https://example.com/store' -Path 'items/special offers/' -Fragment 'limited edition' -AsString
$uriString
```

**Expected Output:**

The output will be a formatted URI string with the fragment adjusted (e.g., spaces replaced with hyphens):

```none
https://example.com/store/items/special%20offers/#limited-edition
```

---

These advanced examples illustrate how to leverage the full power of the **URI** module for complex scenarios.
For additional details or further use cases, consult the module’s documentation or source code.
