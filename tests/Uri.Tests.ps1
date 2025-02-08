Describe 'Uri' {

    Context 'Function: ConvertFrom-UriQueryString' {

        It 'ConvertFrom-UriQueryString - returns empty hashtable for empty input' {
            $result = ConvertFrom-UriQueryString -Query ''
            $result | Should -BeOfType 'Hashtable'
            $result.Count | Should -Be 0

            $result2 = ConvertFrom-UriQueryString -Query '?'
            $result2.Count | Should -Be 0
        }

        It 'ConvertFrom-UriQueryString - decodes percent-encoded characters' {
            $result = ConvertFrom-UriQueryString -Query '?q=PowerShell%20URI'
            $result.q | Should -Be 'PowerShell URI'
        }

        It 'ConvertFrom-UriQueryString - handles multiple values for same key' {
            $result = ConvertFrom-UriQueryString -Query 'name=John%20Doe&age=30&age=40'
            $result.name | Should -Be 'John Doe'
            # When the key repeats, the value becomes an array
            $result.age | Should -BeOfType 'Object[]'
            $result.age[0] | Should -Be '30'
            $result.age[1] | Should -Be '40'
        }

        It 'ConvertFrom-UriQueryString - removes leading question mark if present' {
            $result1 = ConvertFrom-UriQueryString -Query '?foo=bar'
            $result2 = ConvertFrom-UriQueryString -Query 'foo=bar'
            $result1.foo | Should -Be 'bar'
            $result2.foo | Should -Be 'bar'
        }

        It 'ConvertFrom-UriQueryString - treats key with no value as empty string' {
            $result = ConvertFrom-UriQueryString -Query 'foo'
            $result.foo | Should -Be ''
        }
    }

    Context 'Function: ConvertTo-UriQueryString' {

        It 'ConvertTo-UriQueryString - builds query string from hashtable with single values' {
            $query = @{ foo = 'bar'; search = 'hello world' }
            $result = ConvertTo-UriQueryString -Query $query
            # Order is not guaranteed so check for expected pairs:
            $pairs = $result -split '&'
            $pairs | Should -Contain 'foo=bar'
            $pairs | Should -Contain 'search=hello%20world'
        }

        It 'ConvertTo-UriQueryString - handles array values producing multiple parameters' {
            $query = @{ ids = 1, 2, 3 }
            $result = ConvertTo-UriQueryString -Query $query
            $pairs = $result -split '&'
            $pairs | Should -Contain 'ids=1'
            $pairs | Should -Contain 'ids=2'
            $pairs | Should -Contain 'ids=3'
        }

        It 'ConvertTo-UriQueryString - outputs query string without encoding when NoEncoding is used' {
            $query = @{ foo = 'hello world'; bar = 'a=b c' }
            $result = ConvertTo-UriQueryString -Query $query -NoEncoding
            $pairs = $result -split '&'
            $pairs | Should -Contain 'foo=hello world'
            $pairs | Should -Contain 'bar=a=b c'
        }

        It 'ConvertTo-UriQueryString - handles null values producing key with empty value' {
            $query = @{ foo = $null }
            $result = ConvertTo-UriQueryString -Query $query
            $result | Should -Be 'foo='
        }
    }

    Context 'Function: New-Uri' {

        It 'New-Uri - constructs a URI with base and appended path' {
            $uri = New-Uri -BaseUri 'https://example.com' -Path 'products/item'
            # Expect a System.Uri object with the proper path
            $uri.AbsoluteUri | Should -Be 'https://example.com/products/item'
        }

        It 'New-Uri - adds query parameters from hashtable correctly' {
            $uri = New-Uri -BaseUri 'https://example.com/api' -Path 'search' -Query @{ q = 'test search'; page = 2 }
            $query = $uri.Query.TrimStart('?')
            $pairs = $query -split '&'
            $pairs | Should -Contain 'q=test%20search'
            $pairs | Should -Contain 'page=2'
        }

        It 'New-Uri - merges query parameters when MergeQueryParameters switch is used' {
            $uri = New-Uri -BaseUri 'https://example.com/data?year=2023' -Query @{ year = 2024; sort = 'asc' } -MergeQueryParameters
            $query = $uri.Query.TrimStart('?')
            $pairs = $query -split '&'
            $pairs | Should -Contain 'year=2023'
            $pairs | Should -Contain 'year=2024'
            $pairs | Should -Contain 'sort=asc'
        }

        It 'New-Uri - appends fragment to URI' {
            $uri = New-Uri -BaseUri 'https://example.com/path' -Fragment 'section1'
            # The resulting URI should have the fragment appended after '#'
            $uri.AbsoluteUri | Should -Match '#section1$'
        }

        It 'New-Uri - returns string output when AsString switch is used' {
            $uriString = New-Uri -BaseUri 'https://example.com' -Path 'test' -AsString
            $uriString | Should -BeOfType 'string'
            $uriString | Should -Match '^https://example\.com/test'
        }

        It 'New-Uri - returns System.Uri object by default' {
            $uri = New-Uri -BaseUri 'https://example.com'
            $uri | Should -BeOfType 'System.Uri'
        }

        It 'New-Uri - throws error for invalid BaseUri' {
            { New-Uri -BaseUri 'notaurl' } | Should -Throw
        }

        It 'New-Uri - accepts query string as Query parameter input' {
            $uri = New-Uri -BaseUri 'https://example.com/api' -Path 'search' -Query '?q=hello%20world'
            $query = $uri.Query.TrimStart('?')
            $query | Should -Match 'q=hello%20world'
        }

        It 'New-Uri - respects NoEncoding switch for path segments' {
            $uri = New-Uri -BaseUri 'https://example.com' -Path 'a b/c d' -NoEncoding -AsString
            # With NoEncoding, spaces should remain as-is in the path
            $uri | Should -Match 'https://example\.com/a b/c d'
        }
    }
}
