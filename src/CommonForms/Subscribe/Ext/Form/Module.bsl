
&AtClient
Procedure Entrepreneur(Command)
	GoToURL("https://pay.accountingsuite.com/monthly?token=yDU8qbKeihtBvjpri9O1&state=" + TenantV());
EndProcedure

&AtServer
Function TenantV()
	
	Return SessionParameters.TenantValue;
	
EndFunction

&AtClient
Procedure Premium(Command)
	GoToURL("https://pay.accountingsuite.com/monthly?token=jQswFppCrhgGMw8Avoz4&state=" + TenantV());
EndProcedure

&AtClient
Procedure SmallBusiness(Command)
	GoToURL("https://pay.accountingsuite.com/monthly?token=j9S512cxZHXMU6j4RhX7&state=" + TenantV());
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Constants.SubStatus.Get() = "" Then
		Items.SubStatus.Title = "Status: Free Trial";
		Items.Decoration1.Visible = False;
	Else
		Items.SubStatus.Title = "Status: " + Constants.SubStatus.Get();
		Items.Entrepreneur.Visible = False;
		Items.SmallBusiness.Visible = False;
		Items.Premium.Visible = False;
		Items.Decoration1.Visible = True;
	Endif;
EndProcedure




