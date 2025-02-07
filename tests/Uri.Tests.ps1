Describe 'Module' {
    It 'Function: Test-PSModuleTest' {
        Test-PSModuleTest -Name 'World' | Should -Be 'Hello, World!'
    }
}
