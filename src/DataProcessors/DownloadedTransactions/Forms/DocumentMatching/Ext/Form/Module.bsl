
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
	DocumentList.Parameters.SetParameterValue("BankAccount", Parameters.BankAccount);
	DocumentList.Parameters.SetParameterValue("AccountInBank", Parameters.AccountInBank);
	DocumentList.Parameters.SetParameterValue("Amount", Parameters.Amount);
	ListOfDocumentTypes = Parameters.ListOfDocumentTypes.UnloadValues();	
	DocumentList.Parameters.SetParameterValue("ListOfDocumentTypes", ListOfDocumentTypes);
	DocumentList.Parameters.SetParameterValue("IncomingPayment", Parameters.IncomingPayment);
	DocumentList.Parameters.SetParameterValue("PeriodStart", AddMonth(Parameters.TransactionDate, -3));
	DocumentList.Parameters.SetParameterValue("PeriodEnd", AddMonth(Parameters.TransactionDate, 3));
	DocumentList.Parameters.SetParameterValue("TransactionID", Parameters.TransactionID);
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
