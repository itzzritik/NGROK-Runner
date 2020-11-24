Install-Module powershell-yaml
[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')  	 | out-null
[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') 	 | out-null
[System.Reflection.Assembly]::LoadWithPartialName('System.Drawing') 		 | out-null
[System.Reflection.Assembly]::LoadWithPartialName('WindowsFormsIntegration') | out-null

$Current_Folder = split-path $MyInvocation.MyCommand.Path
$Binaries = "$Current_Folder\bin"
$config_url = ".\bin\config.yml"

################################################################################################################################
# Parse config.yml
################################################################################################################################
$fileContent = Get-Content -Path $config_url
$content = ''
foreach ($line in $fileContent) { 
	$content = $content + "`n" + $line 
}
$config = ConvertFrom-YAML $content


################################################################################################################################
# Start NGROK Server
################################################################################################################################
$arguments = "http -config $Binaries\auth.yml -config $Binaries\config.yml 3000"
$scriptblock = [scriptblock]::Create("$Binaries\ngrok.exe $arguments")
start-job -scriptblock $scriptblock

$ngrokOutput = $NULL
do  
{
	Start-Sleep -s 1
	$ngrokOutput = ConvertFrom-Json (Invoke-WebRequest -Uri http://localhost:4040/api/tunnels).Content
}
while($ngrokOutput.tunnels.length -lt 2)  

$public_urls = $ngrokOutput.tunnels.public_url | sort
$httpUrl = $public_urls[0]
$httpsUrl = $public_urls[1]

################################################################################################################################
# Add the systray menu
################################################################################################################################

# -----------------------------------------------------------------------------------
# Caching all Icons
# -----------------------------------------------------------------------------------
$App_Tray_Icon = "$Current_Folder\icons\logo.ico"
$Dashboard_Icon = [System.Drawing.Bitmap]::FromFile("$Current_Folder\icons\dashboard.png")
$Web_Icon = [System.Drawing.Bitmap]::FromFile("$Current_Folder\icons\web.png")
$Copy_Icon = [System.Drawing.Bitmap]::FromFile("$Current_Folder\icons\copy.png")
$Safe_Icon = [System.Drawing.Bitmap]::FromFile("$Current_Folder\icons\safe.png")
$Unsafe_Icon = [System.Drawing.Bitmap]::FromFile("$Current_Folder\icons\unsafe.png")
$Region_Icon = [System.Drawing.Bitmap]::FromFile("$Current_Folder\icons\region.png")
$Tick_Icon = [System.Drawing.Bitmap]::FromFile("$Current_Folder\icons\tick.png")
$Cross_Icon = [System.Drawing.Bitmap]::FromFile("$Current_Folder\icons\exit.png")

$App_Icon = New-Object System.Windows.Forms.NotifyIcon
$App_Icon.Text = "NGROK Runner"
$App_Icon.Icon = $App_Tray_Icon
$App_Icon.Visible = $true
$App_Icon.Add_Click({
	If ($_.Button -eq [Windows.Forms.MouseButtons]::Left) {
		Start-Process $httpsUrl
	}
})

$contextmenu = New-Object System.Windows.Forms.ContextMenuStrip
$App_Icon.ContextMenuStrip = $contextmenu

# -----------------------------------------------------------------------------------
# Adding Submenu `Open Dashboard`
# -----------------------------------------------------------------------------------
$Dashboard = $contextmenu.Items.Add("Open Dashboard")
$Dashboard.Image = $Dashboard_Icon
$Dashboard.Add_Click({
	Start-Process 'http://localhost:4040'
})

# -----------------------------------------------------------------------------------
# Adding Submenu `Open`
# -----------------------------------------------------------------------------------
$Open_SubMenu = $contextmenu.Items.Add("Open in web browser")
$Open_SubMenu.Image = $Web_Icon

$OpenHttps = New-Object System.Windows.Forms.ToolStripMenuItem
$OpenHttps.Text = "Https App"
$OpenHttps.Image = $Safe_Icon
$OpenHttps.Add_Click({
	Start-Process $httpsUrl
})
$Open_SubMenu.DropDownItems.Add($OpenHttps)

$OpenHttp = New-Object System.Windows.Forms.ToolStripMenuItem
$OpenHttp.Text = "Http App"
$OpenHttp.Image = $Unsafe_Icon
$OpenHttp.Add_Click({
	Start-Process $httpUrl
})
$Open_SubMenu.DropDownItems.Add($OpenHttp)

# -----------------------------------------------------------------------------------
# Adding Submenu `Copy to clipboard`
# -----------------------------------------------------------------------------------
$Copy_SubMenu = $contextmenu.Items.Add("Copy to clipboard")
$Copy_SubMenu.Image = $Copy_Icon

$CopyHttps = New-Object System.Windows.Forms.ToolStripMenuItem
$CopyHttps.Text = "Https Url"
$CopyHttps.Image = $Safe_Icon
$CopyHttps.Add_Click({
	$httpsUrl | clip
})
$Copy_SubMenu.DropDownItems.Add($CopyHttps)

$CopyHttp = New-Object System.Windows.Forms.ToolStripMenuItem
$CopyHttp.Text = "Http Url"
$CopyHttp.Image = $Unsafe_Icon
$CopyHttp.Add_Click({
	$httpUrl | clip
})
$Copy_SubMenu.DropDownItems.Add($CopyHttp)

# -----------------------------------------------------------------------------------
# Adding Submenu `Region (Country)`
# -----------------------------------------------------------------------------------
$Selected_Region = 'us'

if ($config.region -ne $NULL) {
	$Selected_Region = $config.region
}

$Region_SubMenu = $contextmenu.Items.Add("Region ($Selected_Region)")
$Region_SubMenu.Image = $Region_Icon

$Country_Names = @("Asia/Pacific","Australia","Europe","India","Japan","South America","United States")
$Country_Codes = @("ap","au","eu","in","jp","sa","us")

for ($i = 0; $i -lt $Country_Names.Length; $i++) {
	$Country = New-Object System.Windows.Forms.ToolStripMenuItem
	$Country.Text = $Country_Names[$i]
	if ($Country_Codes[$i] -eq $Selected_Region) {
		$Country.Image = $Tick_Icon
	}
	$Country.Add_Click({
		# Write new config.yml file
		$config.region = $Country_Codes[$i]
		$config_new = ConvertTo-Yaml $config
		$config_new.trim() | Out-File -FilePath $config_url

		# Restart NGROK Server
		Start-Process -WindowStyle hidden powershell.exe "$Current_Folder\script.ps1"
		$App_Icon.Visible = $false
		Stop-Process -Id $pid
	}.GetNewClosure())
	$Region_SubMenu.DropDownItems.Add($Country)
}

# -----------------------------------------------------------------------------------
# Adding Submenu `Quit`
# -----------------------------------------------------------------------------------
$Quit = $contextmenu.Items.Add("Quit")
$Quit.Image = $Cross_Icon
$Quit.Add_Click({
	$App_Icon.Visible = $false
	Stop-Process -Id $pid
})


# Make PowerShell Disappear
$windowcode = '[DllImport("user32.dll")] public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);'
$asyncwindow = Add-Type -MemberDefinition $windowcode -name Win32ShowWindowAsync -namespace Win32Functions -PassThru
$null = $asyncwindow::ShowWindowAsync((Get-Process -PID $pid).MainWindowHandle, 0)

# Force garbage collection just to start slightly lower RAM usage.
[System.GC]::Collect()

Create an application context for it to all run within.
This helps with responsiveness, especially when clicking Exit.
$appContext = New-Object System.Windows.Forms.ApplicationContext
[void][System.Windows.Forms.Application]::Run($appContext)