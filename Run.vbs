Set fso = CreateObject("Scripting.FileSystemObject")
authFile=".\bin\auth.yml"

If Not (fso.FileExists(authFile)) Then
	authKey = InputBox("Please Enter Your NGROK Auth Key!")

	Set newFIle = fso.CreateTextFile(authFile, True)
	newFIle.Write "authtoken: " & authKey & vbCrLf
	newFIle.Close
End If

Set WshShell = CreateObject("Wscript.shell")
WshShell.run "powershell.exe -ExecutionPolicy bypass -windowstyle hidden -file ./script.ps1", 0