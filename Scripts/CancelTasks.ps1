$release = Get-Release -Project 'Update RIS DB Schema' -Version 2024.12.11.3518
$tasks = Get-Task -Regarding $release

$repo = Get-OctopusRepositoryObject
foreach ($task in $tasks) {
    $repo._repository.Tasks.Cancel($task)
}
