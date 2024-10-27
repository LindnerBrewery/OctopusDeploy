Describe "Mock Tests" {
    It "Should always fail" {
        $true | Should -Be $false
    }
}
