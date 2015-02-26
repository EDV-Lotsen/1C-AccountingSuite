
// Closing the books. Defines whether the document falls in the closed period.
//Parameters:
// DocumentReference - type: DocumentRef - document reference 
// Date - type: date - the new date of the document
//
//Result:
// boolean - if period is closed true else false
//
Function DocumentPeriodIsClosed(DocumentReference, Date) Export
	SetPrivilegedMode(True);
	
	SettingsRequest = New Query("SELECT
	                            |	PeriodClosingDate.Value AS PeriodClosingDate,
	                            |	PeriodClosingByModule.Value AS PeriodClosingByModule
	                            |FROM
	                            |	Constant.PeriodClosingDate AS PeriodClosingDate,
	                            |	Constant.PeriodClosingByModule AS PeriodClosingByModule");
	SettingsTable = SettingsRequest.Execute().Unload();
	CurrentClosingDate = SettingsTable[0].PeriodClosingDate;
	
	If SettingsTable[0].PeriodClosingByModule Then
		CurrentDocumentName = TrimAll(DocumentReference.Metadata().Name);
		Request = New Query("SELECT
		                    |	PeriodClosingByModule.Document,
		                    |	PeriodClosingByModule.PeriodClosingDate
		                    |FROM
		                    |	InformationRegister.PeriodClosingByModule AS PeriodClosingByModule
		                    |WHERE
		                    |	PeriodClosingByModule.Document = &CurrentDocumentName
		                    |;
		                    |
		                    |////////////////////////////////////////////////////////////////////////////////
		                    |SELECT
		                    |	CurrentDocument.Date AS DocumentDate
		                    |FROM
		                    |	Document." + CurrentDocumentName + " AS CurrentDocument
		                    |WHERE
		                    |	CurrentDocument.Ref = &Ref");
		Request.SetParameter("CurrentDocumentName", CurrentDocumentName);
		Request.SetParameter("Ref", DocumentReference);
		Res = Request.ExecuteBatch();
		PeriodClosingByModule = Res[0].Select();
		If PeriodClosingByModule.Next() Then
			CurrentClosingDate = PeriodClosingByModule.PeriodClosingDate;		
		EndIf;
		
		If DocumentReference.IsEmpty() Then
			If Date > EndOfDay(CurrentClosingDate) Then
				return False;
			Else
				return True;
			EndIf;
		Else 
			DocumentInfo = Res[1].Select();
			DocumentInfo.Next();
			If (Date > EndOfDay(CurrentClosingDate)) And (DocumentInfo.DocumentDate > EndOfDay(CurrentClosingDate)) Then
				return False;
			Else
				return True;
			EndIf;
		EndIf;

	Else //Single period closing date
		If DocumentReference.IsEmpty() Then			
			If Date > EndOfDay(CurrentClosingDate) Then
				return False;
			Else
				return True;
			EndIf;
		Else
			CurrentDocumentName = TrimAll(DocumentReference.Metadata().Name);
			Request = New Query("SELECT
			                    |	Document.Date AS DocumentDate
			                    |FROM
			                    |	Document." + CurrentDocumentName + " AS Document
			                    |WHERE
			                    |	Document.Ref = &Ref");
			Request.SetParameter("Ref", DocumentReference);
			Res = Request.Execute().Select();
			If Res.Next() Then
				If (Date > EndOfDay(CurrentClosingDate)) And (Res.DocumentDate > EndOfDay(CurrentClosingDate)) Then
					return False;
				Else
					return True;
				EndIf;
			Else
				return True;
			EndIf;
		EndIf;
	EndIf;
EndFunction

// Permits writing of the document 
// if WriteParameters are correct
Function DocumentWritePermitted(WriteParameters) Export
	If Not WriteParameters.Property("PeriodClosingPassword") Then
		return False;
	EndIf;
	If (TypeOf(WriteParameters.PeriodClosingPassword) <> Type("String")) Then
		return False;
	EndIf;
	SetPrivilegedMode(True);
	CurrentPassword = Constants.PeriodClosingPassword.Get();
	CurrentOption	= Constants.PeriodClosingOption.Get();
	SetPrivilegedMode(False);
	If (CurrentOption = Enums.PeriodClosingOptions.WarnAndRequirePassword) Then
		If TrimAll(CurrentPassword) = TrimAll(WriteParameters.PeriodClosingPassword) Then
			return True;
		Else
			return False;
		EndIf;
	Else
		If WriteParameters.PeriodClosingPassword = "Yes" Then
			return True;
		Else
			return False;
		EndIf;
	EndIf;
EndFunction

//------------------------------------------------------------------------------

// Event subscribtion handler. Prevents document deletion in closed period
Procedure ClosedPeriodDeletionProtectionBeforeDelete(Source, Cancel) Export
	//Period closing
	//If GeneralFunctionsReusable.DisableAuditLogValue() = True Then
		//return;
	//EndIf;
	If Source.DataExchange.Load Then
		return;
	EndIf;
	If DocumentPeriodIsClosed(Source.Ref, Source.Date) Then
		MessageText = String(Source) + NStr("en = ': This document''s date is prior to your company''s closing date. Delete failed!'");
		CommonUseClientServer.MessageToUser(MessageText,,,,Cancel);
		return;
	EndIf; 
EndProcedure

// Event subscribtion handler. Prevents changes to the document in closed period
Procedure ClosedPeriodBeforeWriteBeforeWrite(Source, Cancel, WriteMode, PostingMode) Export
	//Period closing
	//If GeneralFunctionsReusable.DisableAuditLogValue() = True Then
		//return;
	//EndIf;
	If Source.DataExchange.Load Then
		return;
	EndIf;
	If DocumentPeriodIsClosed(Source.Ref, Source.Date) Then
		If Source.AdditionalProperties.Property("PermitWrite") Then
			PermitWrite = Source.AdditionalProperties.PermitWrite;
		Else
			PermitWrite = False;
		EndIf;
		If Not PermitWrite Then
			MessageText = String(Source) + NStr("en = ': This document''s date is prior to your company''s closing date. The document could not be written!'");
			CommonUseClientServer.MessageToUser(MessageText,,,,Cancel);
			return;
		EndIf;
	EndIf;
EndProcedure
