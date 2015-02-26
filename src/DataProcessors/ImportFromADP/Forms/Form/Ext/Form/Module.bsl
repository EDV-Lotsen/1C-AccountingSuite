
&AtClient
Procedure FileUpload(Command)
	
	Notify = New NotifyDescription("ExcelFileUpload", ThisForm);

	BeginPutFile(Notify, "", "*.xls", True, ThisForm.UUID);
	
EndProcedure

&AtClient
Procedure ListRefClick(Item)
	
	OpenForm("Document.GeneralJournalEntry.ListForm");
	Close();
	
EndProcedure

///////////////////////////////////
&AtClient
Procedure ExcelFileUpload(Result, Address, SelectedFileName, AdditionalParameters) Export
	
	If (Find(SelectedFileName, ".xls") = 0)
		And (Find(SelectedFileName, ".xlsx") = 0)
		And (Find(SelectedFileName, ".XLS") = 0)
		And (Find(SelectedFileName, ".XLSX") = 0)
		Then
		ShowMessageBox(, NStr("en = 'Please upload a valid Excel file (.xls, .xlsx)'"));
		Return;
	EndIf;
	
	If ValueIsFilled(Address) Then
		ShowUserNotification(NStr("en = 'Reading file with  Microsoft Excel...'"));
		Errors = False;
		ImportData(Address);
	EndIf;
	
	If Not Errors Then 
		Items.FileUpload.Visible = False;
		Items.Group1.Visible     = True;   
		ThisForm.CurrentItem     = Items.ListRef;
		ShowMessageBox(,NStr("en = 'Done!'"));
	EndIf;
	
EndProcedure

&AtServer
Procedure ImportData(TempStorageAddress)
	
	BinaryData = GetFromTempStorage(TempStorageAddress);
	TempFileName = GetTempFileName("xls");
	BinaryData.Write(TempFileName);

	Try
        COMExcel = New COMObject("Excel.Application");
        Excel = COMExcel.Application.WorkBooks.Open(TempFileName);
        ExcelSheet = Excel.Sheets(1);
	Except
		ErrorDescription = ErrorDescription();
       	CommonUseClientServer.MessageToUser(NStr("en = 'An error occurred. Details:'") + ErrorDescription);
		
		Errors = True;
        Return;
	EndTry;
	
	//Clear collections
	VT = New ValueTable();
	VT.Columns.Add("DateTransaction", New TypeDescription("Date"));
	VT.Columns.Add("AccountNumber",  New TypeDescription("String"));
	VT.Columns.Add("Amount", New TypeDescription("Number"));
	
	RowNumber = 1;
	
	While True Do
		
		RowNumber = RowNumber + 1;
		
		DateTransaction = ExcelSheet.Cells(RowNumber, 5).Value;
		AccountNumber   = ExcelSheet.Cells(RowNumber, 2).Text;
		Amount          = ExcelSheet.Cells(RowNumber, 4).Value;
		
		If Not ValueIsFilled(DateTransaction) Then
			Break;
		EndIf;
		
		RowVT = VT.Add();
		RowVT.DateTransaction = DateTransaction;
		RowVT.AccountNumber   = AccountNumber;
		RowVT.Amount          = Amount;
		
	EndDo;
	
	Excel.Close();
	
	CreateGJE(VT);
	
EndProcedure

&AtServer
Procedure CreateGJE(VT)
	
	//Check accounts
	ErrorAccounts = New ValueList;
	
	For Each RowVT In VT Do
		FoundAccount = ChartsOfAccounts.ChartOfAccounts.FindByCode(RowVT.AccountNumber);
		
		If FoundAccount = Undefined Or FoundAccount = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
			If ErrorAccounts.FindByValue(RowVT.AccountNumber) = Undefined Then
				ErrorAccounts.Add(RowVT.AccountNumber);	
			EndIf;
		EndIf;
	EndDo;
	
	If ErrorAccounts.Count() > 0 Then
		For Each RowErrorAccounts In ErrorAccounts Do
			TextMessage = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Code of account %1 is not found!'"), RowErrorAccounts);
			CommonUseClientServer.MessageToUser(TextMessage);
		EndDo;
		
		Errors = True;
		Return;
	EndIf;
	
	//Create documents
	VT.Sort("DateTransaction");
	
	If VT.Count() = 0 Then
		TextMessage = NStr("en = 'There is no data in the file!'");
		CommonUseClientServer.MessageToUser(TextMessage);
		
		Errors = True;
		Return;
	EndIf;
	
	FirstRow        = True;
	DateTransaction = Undefined;
	
	For Each RowVT In VT Do
		
		If FirstRow Then
			
			FirstRow        = False;
			DateTransaction = RowVT.DateTransaction;
			
			//Add document
			NewGJ = Documents.GeneralJournalEntry.CreateDocument();
			NewGJ.Date = RowVT.DateTransaction;
			NewGJ.Memo = "Import from ADP (auto-created)";
			
			//Add row
			NewGJLine = NewGJ.LineItems.Add();
			NewGJLine.Account = ChartsOfAccounts.ChartOfAccounts.FindByCode(RowVT.AccountNumber);
			If RowVT.Amount > 0 Then
				NewGJLine.AmountDr = RowVT.Amount;
			Else
				NewGJLine.AmountCr = -RowVT.Amount;
			EndIf;
			
		ElsIf DateTransaction <> RowVT.DateTransaction Then
			
			DateTransaction = RowVT.DateTransaction;
			
			//Finish document
			DocTotal = NewGJ.LineItems.Total("AmountDr");
			NewGJ.DocumentTotalRC = DocTotal;
			NewGJ.DocumentTotal   = DocTotal;
			NewGJ.Currency        = GeneralFunctionsReusable.DefaultCurrency();
			NewGJ.ExchangeRate    = 1;
			NewGJ.Write();
			
			//Add document
			NewGJ = Documents.GeneralJournalEntry.CreateDocument();
			NewGJ.Date = RowVT.DateTransaction;
			NewGJ.Memo = "Import from ADP (auto-created)";
			
			//Add row
			NewGJLine = NewGJ.LineItems.Add();
			NewGJLine.Account = ChartsOfAccounts.ChartOfAccounts.FindByCode(RowVT.AccountNumber);
			If RowVT.Amount > 0 Then
				NewGJLine.AmountDr = RowVT.Amount;
			Else
				NewGJLine.AmountCr = -RowVT.Amount;
			EndIf;
			
		Else
			
			//Add row
			NewGJLine = NewGJ.LineItems.Add();
			NewGJLine.Account = ChartsOfAccounts.ChartOfAccounts.FindByCode(RowVT.AccountNumber);
			If RowVT.Amount > 0 Then
				NewGJLine.AmountDr = RowVT.Amount;
			Else
				NewGJLine.AmountCr = -RowVT.Amount;
			EndIf;
			
		EndIf; 	
		
	EndDo;
	
	If Not FirstRow Then   
		
		//Finish document
		DocTotal = NewGJ.LineItems.Total("AmountDr");
		NewGJ.DocumentTotalRC = DocTotal;
		NewGJ.DocumentTotal   = DocTotal;
		NewGJ.Currency        = GeneralFunctionsReusable.DefaultCurrency();
		NewGJ.ExchangeRate    = 1;
		NewGJ.Write();
		
	EndIf;
	
EndProcedure