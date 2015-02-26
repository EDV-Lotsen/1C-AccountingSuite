﻿
&AtClient
Procedure Support(Command)
	GotoURL("http://help.accountingsuite.com");
EndProcedure

&AtClient
Procedure UserGuide(Command)
	GotoURL("http://userguide.accountingsuite.com");
	//OpenHelpContent();
EndProcedure

&AtServer
Function CFOTodayConstant()
	Return Constants.CFOToday.Get();
EndFunction

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Constants.CFOToday.Get() = False Then
		Items.Group4.Visible = False;
	EndIf;
	
	// Remove 1C Buttons
	Items.Group1.Visible = False;
	Items.Group3.Visible = False;
	Items.Support.Visible = False;
	Items.UserGuide.Visible = False;
	
	//Using simpliest HTML code to write a table 2x3, width 60 from whole area of field
	// columns - 40/60 (for better look)
	// In first row are buttons
	// Height - 35 px, font Arial
	// Basicly in code are used templates like [OpenNew],
	// Later templates are replaced with required links
	// Checked on Chrome, IExplorer, Opera, Safari
	
	HTMLFieldCOde = "<html>
	|<head>
	|	<title></title>  
	|</head>
	|<body lang=""en-US"" dir=""ltr"">
|<table width=""60%"" cellspacing=""0"">
	|<tbody><tr valign=""top"">
		|<td width=""40%"" height=""35px"">
			|<span style=""white-space: nowrap; cursor: pointer;"" class=""staticTextHyper staticTextHyperBorder""><a href=""[Support]"" target=""_blank""><input type=""button"" value=""Support / Live Chat""></a><span><font face=""Arial"">
		|</font></td>
		|<td width=""60%"" height=""35px"">
			|<span style=""white-space: nowrap; cursor: pointer;"" class=""staticTextHyper staticTextHyperBorder""><a href=""[UserGuide]"" target=""_blank""><input type=""button"" value=""User guide""></a></td>	
	|</tr>
	|<tr valign=""top"">
		|<td width=""40%"" height=""35px"">
			|<span style=""white-space: nowrap; cursor: pointer;"" class=""staticTextHyper staticTextHyperBorder""><a href=""[OpenNew]"" target=""_blank"">Open new</a></span></td>
		|<td width=""60%"" height=""35px"">
			|<span style=""white-space: nowrap; cursor: pointer;"" class=""staticTextHyper staticTextHyperBorder""><a href=""[OnboardingWebinars]"" target=""_blank"">Onboarding webinars</a></span></td>	
	|</tr>
	|<tr valign=""top"">
		|<td width=""40%"">
			|<span style=""white-space: nowrap; cursor: pointer;"" class=""staticTextHyper staticTextHyperBorder""><a href=""[ReleaseNotes]"" target=""_blank"">Release notes</a></span></td>
		|<td width=""60%"">
			|<span style=""white-space: nowrap; cursor: pointer;"" class=""staticTextHyper staticTextHyperBorder""><a href=""[DemoForAccountants]"" target=""_blank"">Demo for accountants</a></span></td>	
	|</tr>	
|</tbody></table></body>
	|</html>";
	
	HTMLFieldCode = StrReplace(HTMLFieldCode,"[Support]","http://help.accountingsuite.com");    
	HTMLFieldCode = StrReplace(HTMLFieldCode,"[UserGuide]","http://userguide.accountingsuite.com");
	
	If CFOTodayConstant() Then
		HTMLFieldCode = StrReplace(HTMLFieldCode,"[OpenNew]","https://cfotoday.accountingsuite.com");
	Else
		HTMLFieldCode = StrReplace(HTMLFieldCode,"[OpenNew]","https://login.accountingsuite.com");
	EndIf;
	
	HTMLFieldCode = StrReplace(HTMLFieldCode,"[ReleaseNotes]","http://www.accountingsuite.com/product-release");    
	HTMLFieldCode = StrReplace(HTMLFieldCode,"[DemoForAccountants]","https://attendee.gotowebinar.com/rt/7437736924938618882");
	HTMLFieldCode = StrReplace(HTMLFieldCode,"[OnboardingWebinars]","https://attendee.gotowebinar.com/rt/8808644308605056514");
	HyperlinkFields = HTMLFieldCOde;
	


EndProcedure

&AtClient
Procedure SignOut(Command)
	Exit(False, False);
EndProcedure



&AtServer
Function TenantV()
	
	Return SessionParameters.TenantValue;
	
EndFunction
