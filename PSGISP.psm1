#Import modules
$Module = Get-ChildItem -Path "$PSScriptRoot\function" -Recurse -Include "*.ps1"
$Module | ForEach-Object {
    try {
        . $_.FullName
    }
    catch {
        Throw "Cannot import all functions: $_"
    }
    
}
Export-ModuleMember -Function $Module.BaseName