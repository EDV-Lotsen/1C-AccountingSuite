
&AtClient
Procedure DocumentListSelection(Item, SelectedRow, Field, StandardProcessing)
	StandardProcessing = False;
	NotifyChoice(Item.CurrentData.Ref);
EndProcedure

&AtClient
Procedure SelectCommand(Command)
	If Items.DocumentList.CurrentData <> Undefined Then
		NotifyChoice(Items.DocumentList.CurrentData.Ref);
	EndIf;
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	TransactionDate = Parameters.TransactionDate;
	DocumentList.Parameters.SetParameterValue("BankAccount", Parameters.BankAccount);
	DocumentList.Parameters.SetParameterValue("AccountInBank", Parameters.AccountInBank);
	DocumentList.Parameters.SetParameterValue("Amount", Parameters.Amount);
	ListOfDocumentTypes = Parameters.ListOfDocumentTypes.UnloadValues();	
	DocumentList.Parameters.SetParameterValue("ListOfDocumentTypes", ListOfDocumentTypes);
	DocumentList.Parameters.SetParameterValue("IncomingPayment", Parameters.IncomingPayment);
	DocumentList.Parameters.SetParameterValue("PeriodStart", AddMonth(Parameters.TransactionDate, -3));
	DocumentList.Parameters.SetParameterValue("PeriodEnd", AddMonth(Parameters.TransactionDate, 3));
	DocumentList.Parameters.SetParameterValue("TransactionID", Parameters.TransactionID);
	DocumentList.Parameters.SetParameterValue("DateFilter", ?(DateFilter = 0, True, False));
	ListWithoutTransfersAndJE = New Array();
	DocumentExtD = New Array();
	DocumentExtD.Add(ChartsOfCharacteristicTypes.Dimensions.Document);
	For Each DocumentType In ListOfDocumentTypes Do
		If DocumentType = Type("DocumentRef.BankTransfer") OR DocumentType = Type("DocumentRef.GeneralJournalEntry") Then
			Continue;
		EndIf;
		ListWithoutTransfersAndJE.Add(DocumentType);
	EndDo;
	DocumentList.Parameters.SetParameterValue("ListWithoutTransfersAndJE", ListWithoutTransfersAndJE);
	DocumentList.Parameters.SetParameterValue("DocumentExtD", DocumentExtD);
EndProcedure

&AtClient
Procedure DateFilterOnChange(Item)
	
	DocumentList.Parameters.SetParameterValue("DateFilter", ?(DateFilter = 0, True, False));
	If DateFilter = 0 Then //Enabled date filter
		DocumentList.Parameters.SetParameterValue("PeriodStart", AddMonth(TransactionDate, -3));
		DocumentList.Parameters.SetParameterValue("PeriodEnd", AddMonth(TransactionDate, 3));
	Else
		DocumentList.Parameters.SetParameterValue("PeriodStart", AddMonth(TransactionDate, -12));
		DocumentList.Parameters.SetParameterValue("PeriodEnd", AddMonth(TransactionDate, 12));
	EndIf;
	Items.DocumentList.Refresh();
	
EndProcedure
