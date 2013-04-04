
// Handler of form event "OnCreateAtServer"
//
&AtServer
Procedure OnCreateAtServer(Cancellation, StandardProcessing)
	
	ReportRecipientEMailAddresses = EventLogManagement.GetReportReceiptRecipientsByEventLog();
	
EndProcedure

// Handler of click on button "OK"
// Tries to save string of entered mailing addresses and closes the form
// if saving was successful
//
&AtClient
Procedure SaveAddressExecute()
	
	Var MessageAboutError;
	
	Result = SaveReportRecipientsEMailAddresses(ReportRecipientEMailAddresses, MessageAboutError);
	
	If Not Result Then
		If Not IsBlankString(MessageAboutError) Then
			CommonUseClientServer.MessageToUser(
					MessageAboutError, , "ReportRecipientEMailAddresses");
		EndIf;
	Else
		Close();
	EndIf;
	
EndProcedure

// Service function - tries to save string of mailing addresses
// String is not saved if format of mailing addresses is incorrect.
//
&AtServerNoContext
Function SaveReportRecipientsEMailAddresses(ReportRecipientEMailAddresses, MessageAboutError = "")
	
	If ValueIsFilled(ReportRecipientEMailAddresses) Then
		Try
			CommonUseClientServer.ParseEmailString(ReportRecipientEMailAddresses);
		Except
			MessageAboutError = NStr("en = 'Postal address format is wrong'");
			Return False;
		EndTry;
	EndIf;
	
	Try
		EventLogManagement.SetReportRecipientsByEventlog(ReportRecipientEMailAddresses);
	Except
		ErrorInformation = ErrorInfo();
		If ErrorInformation.Cause = Undefined Then
			MessageAboutError =ErrorInformation.Description;
		Else
			MessageAboutError = ErrorInformation.Cause.Description;
		EndIf;
		CommonUseClientServer.MessageToUser(MessageAboutError);
		Return False;
	EndTry;
	
	Return True;
	
EndFunction
