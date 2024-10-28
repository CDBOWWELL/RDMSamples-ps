# 工程ID: 1845649487997480961
# 这个脚本用于在Remote Desktop Manager中批量添加主机到"云平台虚拟机"分组

# 检查是否安装了Devolutions.PowerShell模块，如果没有则安装
if (-not (Get-Module Devolutions.PowerShell -ListAvailable)) {
    Install-Module -Name Devolutions.PowerShell -Scope CurrentUser -Force
    Write-Output "已安装Devolutions.PowerShell模块"
}

# 设置RDM数据源为本地数据源
$ds = Get-RDMDataSource -Name "Local Data Source"
Set-RDMCurrentDataSource $ds
Write-Output "RDM数据源设置为: Local Data Source"

# 数据库连接信息
$connectionString = "Provider=SQLOLEDB.1;Password=xxzx123@;Persist Security Info=True;User ID=sjzd;Initial Catalog=Platform_U_V3.0;Data Source=192.168.133.51"
$query = "SELECT name+'-RDP' name, ipaddress, uid, pwd, ISNULL(rdpport,3389) rdpport, CASE WHEN type=2 THEN 'RDPConfigured' END RDMType FROM bw_form_cloud_vmip WHERE uid IS NOT NULL AND pwd IS NOT NULL AND type=2 UNION SELECT name+'-SSH', ipaddress, uid, pwd, ISNULL(sshport,22) rdpport, 'SSHShell' RDMType FROM bw_form_cloud_vmip WHERE uid IS NOT NULL AND pwd IS NOT NULL AND (type=1 OR (type=2 AND sshport IS NOT NULL))"

# 连接数据库并获取主机信息
$connection = New-Object -ComObject ADODB.Connection
$connection.Open($connectionString)
Write-Output "已连接到数据库"
$recordset = $connection.Execute($query)

# 遍历查询结果并添加主机到RDM
while (!$recordset.EOF) {
    $hostname = $recordset.Fields.Item("name").Value
    $ip = $recordset.Fields.Item("ipaddress").Value
    $username = $recordset.Fields.Item("uid").Value
    $password = $recordset.Fields.Item("pwd").Value
    $rdpport = $recordset.Fields.Item("rdpport").Value
    $rdmType = $recordset.Fields.Item("RDMType").Value

    # 检查是否已存在该主机条目
    $existingSession = Get-RDMSession -Name $hostname
    if ($existingSession) {
        Write-Output "主机 $hostname 已存在，跳过添加"
    }
    else {
        # 创建新的远程会话并添加到指定分组
        $session = New-RDMSession -Host $ip -Type $rdmType -Name $hostname -Group "云平台虚拟机"
        $session.HostPort = $rdpport
        Set-RDMSession -Session $session -Refresh
        Write-Output "添加主机: $hostname (${ip}:${rdpport}) 到分组: 云平台虚拟机"

        # 更新RDM界面，使条目物理保存并在脚本中可用
        Update-RDMUI

        # 设置RDM会话的用户名和密码
        Set-RDMSessionUsername -ID $session.ID -Username $username
        $pass = ConvertTo-SecureString $password -AsPlainText -Force
        Set-RDMSessionPassword -ID $session.ID -Password $pass
        Write-Output "设置主机 $hostname 的登录信息"
    }

    # 移动到下一条记录
    $recordset.MoveNext()
}

# 关闭数据库连接
$connection.Close()
Write-Output "数据库连接已关闭"
