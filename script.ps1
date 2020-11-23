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
$httpUrl = $ngrokOutput.tunnels.public_url[0]
$httpsUrl = $ngrokOutput.tunnels.public_url[1]

################################################################################################################################
# Add the systray menu
################################################################################################################################
	
$App_Icon = New-Object System.Windows.Forms.NotifyIcon
$App_Icon.Text = "NGROK Runner"
$App_Icon.Icon = "$Current_Folder\icons\logo.ico"
$App_Icon.Visible = $true

$contextmenu = New-Object System.Windows.Forms.ContextMenuStrip
$App_Icon.ContextMenuStrip = $contextmenu

# Adding Submenu `Open`
$Open_SubMenu = $contextmenu.Items.Add("Open In Web Browser");

$OpenHttp = New-Object System.Windows.Forms.ToolStripMenuItem
$OpenHttp.Text = "HTTP App"
$Open_SubMenu.DropDownItems.Add($OpenHttp)

$OpenHttps = New-Object System.Windows.Forms.ToolStripMenuItem
$OpenHttps.Text = "HTTPS App"
$Open_SubMenu.DropDownItems.Add($OpenHttps)

# Adding Submenu `Copy to clipboard`
$Copy_SubMenu = $contextmenu.Items.Add("Copy To Clipboard");

$CopyHttp = New-Object System.Windows.Forms.ToolStripMenuItem
$CopyHttp.Text = "HTTP Url"
$Copy_SubMenu.DropDownItems.Add($CopyHttp)

$CopyHttps = New-Object System.Windows.Forms.ToolStripMenuItem
$CopyHttps.Text = "HTTPS Url"
$Copy_SubMenu.DropDownItems.Add($CopyHttps)

# Adding item `Copy to clipboard`
$Exit = $contextmenu.Items.Add("Exit");

# ---------------------------------------------------------------------
# Action when after a click on the systray icon
# ---------------------------------------------------------------------
$App_Icon.Add_Click({
	If ($_.Button -eq [Windows.Forms.MouseButtons]::Left) {
		Start-Process 'http://localhost:4040'
	}
})

# ---------------------------------------------------------------------
# Action after clicking on Open Http URL
# ---------------------------------------------------------------------
$OpenHttp.Add_Click({
	Start-Process $httpUrl
})

# ---------------------------------------------------------------------
# Action after clicking on Open Https URL
# ---------------------------------------------------------------------
$OpenHttps.Add_Click({
	Start-Process $httpsUrl
})

# ---------------------------------------------------------------------
# Action after clicking on Open Https URL
# ---------------------------------------------------------------------
$CopyHttp.Add_Click({
	$httpUrl | clip
})

# ---------------------------------------------------------------------
# Action after clicking on Open Https URL
# ---------------------------------------------------------------------
$CopyHttps.Add_Click({
	$httpsUrl | clip
})

# ---------------------------------------------------------------------
# When Exit is clicked, shutdown NGROK and kill the PowerShell process
# ---------------------------------------------------------------------
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