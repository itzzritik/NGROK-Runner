[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')  	 | out-null
[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') 	 | out-null
[System.Reflection.Assembly]::LoadWithPartialName('System.Drawing') 		 | out-null
[System.Reflection.Assembly]::LoadWithPartialName('WindowsFormsIntegration') | out-null

$icon = [System.Drawing.Icon]::ExtractAssociatedIcon("C:\Windows\System32\mmc.exe")	


################################################################################################################################
# Start NGROK Server
################################################################################################################################

$Current_Folder = split-path $MyInvocation.MyCommand.Path;
$ngrok = "$Current_Folder\ngrok.exe"
$arguments = "http 3000"
$process = Start-Process $ngrok $arguments -WindowStyle Hidden -passthru

$ngrokOutput = ConvertFrom-Json (Invoke-WebRequest -Uri http://localhost:4040/api/tunnels).Content
$httpsUrl = $ngrokOutput.tunnels.public_url[0]
$httpUrl = $ngrokOutput.tunnels.public_url[1]

################################################################################################################################
# Add the systray menu
################################################################################################################################
	
$Main_Tool_Icon = New-Object System.Windows.Forms.NotifyIcon
$Main_Tool_Icon.Text = "NGROK Runner"
$Main_Tool_Icon.Icon = $icon
$Main_Tool_Icon.Visible = $true

$OpenHttpUrl = New-Object System.Windows.Forms.MenuItem
$OpenHttpUrl.Text = "Open HTTP URL"

$CopyHttpUrl = New-Object System.Windows.Forms.MenuItem
$CopyHttpUrl.Text = "Copy HTTP URLH"

$OpenHttpsUrl = New-Object System.Windows.Forms.MenuItem
$OpenHttpsUrl.Text = "Open HTTPS URL"

$CopyHttpsUrl = New-Object System.Windows.Forms.MenuItem
$CopyHttpsUrl.Text = "Copy HTTPS URL"

$ShutdownNgrok = New-Object System.Windows.Forms.MenuItem
$ShutdownNgrok.Text = "Shutdown Tunnel"

$contextmenu = New-Object System.Windows.Forms.ContextMenu
$Main_Tool_Icon.ContextMenu = $contextmenu
$Main_Tool_Icon.contextMenu.MenuItems.AddRange($OpenHttpUrl)
$Main_Tool_Icon.contextMenu.MenuItems.AddRange($CopyHttpUrl)
$Main_Tool_Icon.contextMenu.MenuItems.AddRange($OpenHttpsUrl)
$Main_Tool_Icon.contextMenu.MenuItems.AddRange($CopyHttpsUrl)
$Main_Tool_Icon.contextMenu.MenuItems.AddRange($ShutdownNgrok)

# ---------------------------------------------------------------------
# Action when after a click on the systray icon
# ---------------------------------------------------------------------
$Main_Tool_Icon.Add_Click({
	If ($_.Button -eq [Windows.Forms.MouseButtons]::Left) {
		Start-Process 'http://localhost:4040'
	}
})

# ---------------------------------------------------------------------
# Action after clicking on Open Http URL
# ---------------------------------------------------------------------
$OpenHttpUrl.Add_Click({
	Start-Process $httpUrl
})

# ---------------------------------------------------------------------
# Action after clicking on Open Https URL
# ---------------------------------------------------------------------
$OpenHttpsUrl.Add_Click({
	Start-Process $httpsUrl
})

# ---------------------------------------------------------------------
# Action after clicking on Open Https URL
# ---------------------------------------------------------------------
$CopyHttpUrl.Add_Click({
	$httpUrl | clip
})

# ---------------------------------------------------------------------
# Action after clicking on Open Https URL
# ---------------------------------------------------------------------
$CopyHttpsUrl.Add_Click({
	$httpsUrl | clip
})

# ---------------------------------------------------------------------
# When Exit is clicked, shutdown NGROK and kill the PowerShell process
# ---------------------------------------------------------------------
$ShutdownNgrok.Add_Click({
	Stop-Process -Id $process.Id
	$Main_Tool_Icon.Visible = $false
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