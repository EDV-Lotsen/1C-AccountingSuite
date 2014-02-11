


&AtClient
Procedure CommandOK(Command)
	
	If PeriodClosingOption = PredefinedValue("Enum.PeriodClosingOptions.WarnAndRequirePassword") Then
		Close(Password);
	Else
		Close(DialogReturnCode.Yes);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetPrivilegedMode(True);
	PeriodClosingOption = Constants.PeriodClosingOption.Get();
	If PeriodClosingOption = Enums.PeriodClosingOptions.WarnAndRequirePassword Then
		Items.Password.Visible = True;
	Else
		Items.Password.Visible = False;
	EndIf;

EndProcedure
