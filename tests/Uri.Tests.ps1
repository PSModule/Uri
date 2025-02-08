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
            $result.age | Should -HaveCount 2
            $result.age[0] | Should -Be '30'
            $result.age[1] | Should -Be '40'
        }

        It 'ConvertFrom-UriQueryString - removes leading question mark if present' {
            $result1 = ConvertFrom-UriQueryString -Query '?foo=bar'
            $result1.foo | Should -Be 'bar'

            $result2 = ConvertFrom-UriQueryString -Query 'foo=bar'
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
    }
}

Describe 'Get-Uri' {
    Context 'Default Behavior (returns a [System.Uri] object)' {

        It 'Should return a valid System.Uri when given a URI with scheme' {
            $result = Get-Uri -Uri 'https://example.com/path'
            $result | Out-String -Stream | ForEach-Object { Write-Verbose $_ -Verbose }
            $result | Should -BeOfType 'System.Uri'
            $result.Scheme | Should -Be 'https'
            $result.Host | Should -Be 'example.com'
        }

        It 'Should add default scheme (http) when missing' {
            $result = Get-Uri -Uri 'example.com/path'
            $result | Out-String -Stream | ForEach-Object { Write-Verbose $_ -Verbose }
            $result | Should -BeOfType 'System.Uri'
            $result.Scheme | Should -Be 'http'
            $result.Host | Should -Be 'example.com'
        }
    }

    Context 'Switch: -AsUriBuilder' {

        It 'Should return a System.UriBuilder object' {
            $result = Get-Uri -Uri 'https://example.com/path' -AsUriBuilder
            $result | Out-String -Stream | ForEach-Object { Write-Verbose $_ -Verbose }
            $result | Should -BeOfType 'System.UriBuilder'
            $result.Uri.Scheme | Should -Be 'https'
            $result.Uri.Host | Should -Be 'example.com'
        }
    }

    Context 'Switch: -AsString' {

        It 'Should return a normalized URI string' {
            # Example with uppercase scheme and percent-encoded characters
            $inputUri = 'HTTP://Example.com/%7Euser/path/page.html'
            $result = Get-Uri -Uri $inputUri -AsString
            $result | Out-String -Stream | ForEach-Object { Write-Verbose $_ -Verbose }
            $expected = 'http://example.com/~user/path/page.html'
            $result | Should -Be $expected
        }
    }

    Context 'Error Handling' {

        It 'Should throw an error for an invalid URI' {
            { Get-Uri -Uri 'http://??' } | Should -Throw
        }

        It 'Should throw an error when both -AsUriBuilder and -AsString are provided' {
            { Get-Uri -Uri 'https://example.com' -AsUriBuilder -AsString } | Should -Throw
        }

        It 'Should throw an error when an empty URI string is provided' {
            { Get-Uri -Uri '' } | Should -Throw
        }
    }

    Context 'Pipeline Input' {

        It 'Should accept pipeline input and return a valid [System.Uri]' {
            'example.com/path' | Get-Uri | ForEach-Object {
                $_ | Out-String -Stream | ForEach-Object { Write-Verbose $_ -Verbose }
                $_ | Should -BeOfType 'System.Uri'
                $_.Scheme | Should -Be 'http'
            }
        }

        It 'Should return a valid System.Uri when given a URI with scheme' {
            $result = Get-Uri -Uri 'https://example.com/path'
            $result | Out-String -Stream | ForEach-Object { Write-Verbose $_ -Verbose }
            $result | Should -BeOfType 'System.Uri'
            $result.Scheme | Should -Be 'https'
            $result.Host | Should -Be 'example.com'
        }

        It 'Should add default scheme (http) when missing' {
            $result = Get-Uri -Uri 'example.com/path'
            $result | Out-String -Stream | ForEach-Object { Write-Verbose $_ -Verbose }
            $result | Should -BeOfType 'System.Uri'
            $result.Scheme | Should -Be 'http'
            $result.Host | Should -Be 'example.com'
        }
    }

    Context 'Edge Cases' {
        It 'Should handle URIs with ports' {
            $result = Get-Uri -Uri 'http://example.com:8080'
            $result | Out-String -Stream | ForEach-Object { Write-Verbose $_ -Verbose }
            $result | Should -BeOfType 'System.Uri'
            $result.Port | Should -Be 8080
        }

        It 'Should handle URIs with query strings' {
            $result = Get-Uri -Uri 'https://example.com?query=test'
            $result | Out-String -Stream | ForEach-Object { Write-Verbose $_ -Verbose }
            $result | Should -BeOfType 'System.Uri'
            $result.Query | Should -Be '?query=test'
        }

        It 'Should handle URIs with multiple query strings' {
            $result = Get-Uri -Uri 'https://example.com?query=test&sort=asc&page=1'
            $result | Out-String -Stream | ForEach-Object { Write-Verbose $_ -Verbose }
            $result | Should -BeOfType 'System.Uri'
            $result.Query | Should -Be '?query=test&sort=asc&page=1'
        }

        It 'Should handle URIs with query strings and fragments' {
            $result = Get-Uri -Uri 'https://example.com?query=test#section1'
            $result | Out-String -Stream | ForEach-Object { Write-Verbose $_ -Verbose }
            $result | Should -BeOfType 'System.Uri'
            $result.Query | Should -Be '?query=test'
            $result.Fragment | Should -Be '#section1'
        }

        # Uri + same key query string and fragment
        It 'Should handle URIs with query strings and fragments' {
            $result = Get-Uri -Uri 'https://example.com?include=test&include=dev&include=prod#section1'
            $result | Out-String -Stream | ForEach-Object { Write-Verbose $_ -Verbose }
            $result | Should -BeOfType 'System.Uri'
            $result.Query | Should -Be '?include=test&include=dev&include=prod'
            $result.Fragment | Should -Be '#section1'
        }

        It 'Should handle URIs with fragments' {
            $result = Get-Uri -Uri 'https://example.com#section1'
            $result | Out-String -Stream | ForEach-Object { Write-Verbose $_ -Verbose }
            $result | Should -BeOfType 'System.Uri'
            $result.Fragment | Should -Be '#section1'
        }

        It 'Should handle IPv6 addresses' {
            $result = Get-Uri -Uri 'http://[::1]'
            $result | Out-String -Stream | ForEach-Object { Write-Verbose $_ -Verbose }
            $result | Should -BeOfType 'System.Uri'
            $result.Host | Should -Be '[::1]'
        }
    }
}
