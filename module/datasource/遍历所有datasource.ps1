if (-not (Get-Module Devolutions.PowerShell -ListAvailable)) {
    Install-Module -Name Devolutions.PowerShell -Scope CurrentUser
}

# 导入 Devolutions.PowerShell 模块
Import-Module Devolutions.PowerShell

# 遍历所有 RDM 数据源并输出名称
$allDataSources = Get-RDMDataSource
foreach ($ds in $allDataSources) {
    Write-Output "数据源名称: $($ds.Name)"
}

# 获取 RDM 数据源并设置为当前数据源
$ds = Get-RDMDataSource -Name "167"  # 数据源名称为 SQL Server 数据源 "rdmcjg"
Set-RDMCurrentDataSource $ds

# 遍历当前数据源下的所有实体并输出名称
$allEntities = Get-RDMSession
foreach ($entity in $allEntities) {
    Write-Output "实体名称: $($entity.Name)"
}
