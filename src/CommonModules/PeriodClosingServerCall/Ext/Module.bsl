
// Closing the books. Defines whether the document falls in the closed period.
Function DocumentPeriodIsClosed(DocumentReference, Date) Export
	SetPrivilegedMode(True);
	If DocumentReference.IsEmpty() Then
		CurrentClosingDate = Constants.PeriodClosingDate.Get();
		SetPrivilegedMode(False);
		If Date > EndOfDay(CurrentClosingDate) Then
			return False;
		Else
			return True;
		EndIf;
	Else
		Request = New Query("SELECT
		                    |	Document.Date AS DocumentDate,
		                    |	PeriodClosingDate.Value AS PeriodClosingDate
		                    |FROM
		                    |	Document." + TrimAll(DocumentReference.Metadata().Name) + " AS Document,
		                    |	Constant.PeriodClosingDate AS PeriodClosingDate
		                    |WHERE
		                    |	Document.Ref = &Ref");
		Request.SetParameter("Ref", DocumentReference);
		Res = Request.Execute().Select();
		If Res.Next() Then
			If (Date > EndOfDay(Res.PeriodClosingDate)) And (Res.DocumentDate > EndOfDay(Res.PeriodClosingDate)) Then
				return False;
			Else
				return True;
			EndIf;
		Else
			return True;
		EndIf;
		SetPrivilegedMode(False);
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
