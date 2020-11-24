[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')  	 | out-null
[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') 	 | out-null
[System.Reflection.Assembly]::LoadWithPartialName('System.Drawing') 		 | out-null
[System.Reflection.Assembly]::LoadWithPartialName('WindowsFormsIntegration') | out-null


################################################################################################################################
# Start NGROK Server
################################################################################################################################

$Current_Folder = split-path $MyInvocation.MyCommand.Path;
$ngrok = "$Current_Folder\ngrok.exe"
$arguments = "http 3000"
$process = Start-Process $ngrok $arguments -WindowStyle Hidden -passthru

$ngrokOutput = ConvertFrom-Json (Invoke-WebRequest -Uri http://localhost:4040/api/tunnels).Content
$public_urls = $ngrokOutput.tunnels.public_url | sort;
$httpUrl = $public_urls[0]
$httpsUrl = $public_urls[1]

################################################################################################################################
# Add the systray menu
################################################################################################################################

# -----------------------------------------------------------------------------------
# Caching all Icons
# -----------------------------------------------------------------------------------
$App_Tray_Icon = "$Current_Folder\icons\logo.ico"
$Dashboard_Icon = [System.Drawing.Bitmap]::FromFile("$Current_Folder\icons\dashboard.png");
$Web_Icon = [System.Drawing.Bitmap]::FromFile("$Current_Folder\icons\web.png");
$Copy_Icon = [System.Drawing.Bitmap]::FromFile("$Current_Folder\icons\copy.png");
$Safe_Icon = [System.Drawing.Bitmap]::FromFile("$Current_Folder\icons\safe.png");
$Unsafe_Icon = [System.Drawing.Bitmap]::FromFile("$Current_Folder\icons\unsafe.png");
$Exit_Icon = [System.Drawing.Bitmap]::FromFile("$Current_Folder\icons\exit.png");


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

# Adding item `Open Dashboard`
$Dashboard = $contextmenu.Items.Add("Open NGROK Dashboard");
$Dashboard.Image = $Dashboard_Icon
$Dashboard.Add_Click({
	Start-Process 'http://localhost:4040'
})

# -----------------------------------------------------------------------------------
# Adding Submenu `Open`
# -----------------------------------------------------------------------------------
$Open_SubMenu = $contextmenu.Items.Add("Open In Web Browser");
$Open_SubMenu.Image = $Web_Icon

$OpenHttp = New-Object System.Windows.Forms.ToolStripMenuItem
$OpenHttp.Text = "HTTP App"
$OpenHttp.Image = $Unsafe_Icon
$OpenHttp.Add_Click({
	Start-Process $httpUrl
})
$Open_SubMenu.DropDownItems.Add($OpenHttp)

$OpenHttps = New-Object System.Windows.Forms.ToolStripMenuItem
$OpenHttps.Text = "HTTPS App"
$OpenHttps.Image = $Safe_Icon
$OpenHttps.Add_Click({
	Start-Process $httpsUrl
})
$Open_SubMenu.DropDownItems.Add($OpenHttps)

# -----------------------------------------------------------------------------------
# Adding Submenu `Copy to clipboard`
# -----------------------------------------------------------------------------------
$Copy_SubMenu = $contextmenu.Items.Add("Copy To Clipboard");
$Copy_SubMenu.Image = $Copy_Icon

$CopyHttp = New-Object System.Windows.Forms.ToolStripMenuItem
$CopyHttp.Text = "HTTP Url"
$CopyHttp.Image = $Unsafe_Icon
$CopyHttp.Add_Click({
	$httpUrl | clip
})
$Copy_SubMenu.DropDownItems.Add($CopyHttp)

$CopyHttps = New-Object System.Windows.Forms.ToolStripMenuItem
$CopyHttps.Text = "HTTPS Url"
$CopyHttps.Image = $Safe_Icon
$CopyHttps.Add_Click({
	$httpsUrl | clip
})
$Copy_SubMenu.DropDownItems.Add($CopyHttps)

# Adding item `Copy to clipboard`
$Exit = $contextmenu.Items.Add("Exit");
$Exit.Image = $Exit_Icon
$Exit.Add_Click({
	Stop-Process -Id $process.Id
	$App_Icon.Visible = $false
	Stop-Process $pid
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