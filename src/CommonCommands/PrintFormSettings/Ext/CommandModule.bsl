
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	//Paste handler content.
	
	//If Find(CommandExecuteParameters.Source.FormName,"GeneralReport") <> 0 Then
	//	TypeID = CommandExecuteParameters.Source.ThisObject.CurrentReport.ReportObjectTypeID;	
	//Else
	//	TypeID = CommandExecuteParameters.Source.Report.ReportObjectTypeID;	
	//EndIf; 
	
	If CommandExecuteParameters.Source.FormName = "CommonForm.PrintForm" Then
		ObjectTypeID = CommandExecuteParameters.Source.PrintFormID;
	Else
		//Obtain ObjectTypeID from form name
		ObjectTypeID	= CommonUseClient.GetObjectTypeID(CommandExecuteParameters.Source.FormName);
	EndIf;
	
	NotifyParams 	= new Structure("SourceForm,ObjectTypeID", CommandExecuteParameters.Source,ObjectTypeID);
	Notify 			= new NotifyDescription("ApplyPrintFormSettingsOnSettingsChange", CommonUseClient, NotifyParams);
	FormParameters = New Structure("ObjectTypeID",ObjectTypeID);
	OpenForm("CommonForm.PrintFormSettings", FormParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL, Notify);
	
EndProcedure
