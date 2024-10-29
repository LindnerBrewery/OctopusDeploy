# TODO: create get user function
ipmo ./OctoDeploy -Force
$repo = Get-OctopusRepositoryObject
$allusers =  $repo._repository.Users.GetAll()

# TODO: function to retrieve permissions and export them as csv
foreach ($user in $allusers) {
    $permissions = $repo._repository.UserPermissions.Get($user)
    foreach ($SpacePermission in $Permissions.SpacePermissions.GetEnumerator()){
        $SpacePermission
        "----"
    }
}
$tenant = Get-Tenant
$SpacePermission
[PSCustomObject]@{
    Permission = $SpacePermission.Key
    RestrictedToEnvironmentNames = ''
    RestrictedToProjectNames = ''
    RestrictedToTenantNames = ''
    RestrictedToProjectGroupNames = ''
    SpaceId = ''
}
