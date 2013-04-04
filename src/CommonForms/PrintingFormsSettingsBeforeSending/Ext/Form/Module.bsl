
&AtClient
Procedure OnOpen(Cancellation)
	
	#If WebClient Then
		FormatMXL  				 = True;
		FormatXLS  				 = False;
		FormatHTML 				 = False;
		Items.FormatXLS.Enabled  = False;
		Items.FormatHTML.Enabled = False;
	#EndIf
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// PROCEDURES - FORM ITEMS EVENT HANDLERS

&AtClient
Procedure ButtonCancelExecute()
	
	Close();
	
EndProcedure

&AtClient
Procedure ButtonOKExecute()
	
	If Not FormatMXL And Not FormatXLS And Not FormatHTML Then
		DoMessageBox(NStr("en = 'It is required to indicate minimum one  of the formats: MXL, XLS, or HTML!'"));
		Return;
	EndIf;
	
	Result = New Structure;
	Result.Insert("PackageZIP", 	PackageZIP);
	Result.Insert("FormatMXL",     	FormatMXL);
	Result.Insert("FormatXLS",     	FormatXLS);
	Result.Insert("FormatHTML",    	FormatHTML);
	
	Close(Result);
	
EndProcedure
