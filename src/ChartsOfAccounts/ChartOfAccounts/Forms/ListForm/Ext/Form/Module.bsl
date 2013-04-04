
&AtClient
Procedure Import(Command)
	
	Mode = FileDialogMode.Open;
	OpeningFileDialogue = New FileDialog(Mode);
	OpeningFileDialogue.FullFileName = "";
	Filter = "Excel(*.xlsx)|*.xlsx|Excel 97(*.xls)|*.xls";
	OpeningFileDialogue.Filter = Filter;
	OpeningFileDialogue.Multiselect = False;
	OpeningFileDialogue.Title = "Select file";
	If OpeningFileDialogue.Choose() Then
	    FilesArray = OpeningFileDialogue.SelectedFiles;
	    For Each FileName In FilesArray Do
	        Selection = New File(FileName);
	        //Message(FileName+"; Size = "+Selection.Size());
		EndDo;
		ImportAccounts(Selection.FullName);
	Else
	    DoMessageBox("File(s) not selected!");
	EndIf;

EndProcedure

&AtServer
Procedure ImportAccounts(File)
	
	try
	      ExcelApp    = New  COMObject("Excel.Application");
	except
	      Message(ErrorDescription()); 
	      Message("Can't initialize Excel"); 
	      Return; 
	EndTry; 
	
	try 
	ExcelFile = ExcelApp.Workbooks.Open(File);

	NColumns =1;
	NRows =1; // no header
	
	TotalNRows  = ExcelApp.Sheets(1).UsedRange.row + ExcelApp.Sheets(1).UsedRange.Rows.Count - 1;
		   
	For n= 1 To   TotalNRows -1 Do
			   
	    AccountNumber = ExcelApp.Sheets(1).Cells(NRows,1).Value;
		AccountName = ExcelApp.Sheets(1).Cells(NRows,2).Value;
		
		AccountTypeString = ExcelApp.Sheets(1).Cells(NRows,3).Value;
		If AccountTypeString = "Accounts payable" Then
			AccountTypeValue = Enums.AccountTypes.AccountsPayable;
		ElsIf AccountTypeString = "Accounts receivable" Then
			AccountTypeValue = Enums.AccountTypes.AccountsReceivable
		ElsIf AccountTypeString = "Accumulated depreciation" Then
			AccountTypeValue = Enums.AccountTypes.AccumulatedDepreciation					
		ElsIf AccountTypeString = "Bank" Then
			AccountTypeValue = Enums.AccountTypes.Bank					
		ElsIf AccountTypeString = "Cost of sales" Then
			AccountTypeValue = Enums.AccountTypes.CostOfSales
		ElsIf AccountTypeString = "Equity" Then
			AccountTypeValue = Enums.AccountTypes.Equity				
		ElsIf AccountTypeString = "Expense" Then
			AccountTypeValue = Enums.AccountTypes.Expense
		ElsIf AccountTypeString = "Fixed asset" Then
			AccountTypeValue = Enums.AccountTypes.FixedAsset					
		ElsIf AccountTypeString = "Income" Then
			AccountTypeValue = Enums.AccountTypes.Income
		ElsIf AccountTypeString = "Inventory" Then
			AccountTypeValue = Enums.AccountTypes.Inventory					
		ElsIf AccountTypeString = "Long term liability" Then
			AccountTypeValue = Enums.AccountTypes.LongTermLiability					
		ElsIf AccountTypeString = "Other current asset" Then
			AccountTypeValue = Enums.AccountTypes.OtherCurrentAsset					
		ElsIf AccountTypeString = "Other current liability" Then
			AccountTypeValue = Enums.AccountTypes.OtherCurrentLiability
		ElsIf AccountTypeString = "Other expense" Then
			AccountTypeValue = Enums.AccountTypes.OtherExpense					
		ElsIf AccountTypeString = "Other income" Then
			AccountTypeValue = Enums.AccountTypes.OtherIncome					
		ElsIf AccountTypeString = "Other noncurrent asset" Then
			AccountTypeValue = Enums.AccountTypes.OtherNonCurrentAsset
		EndIf;
		
		//AccountMemo = ExcelApp.Sheets(1).Cells(NRows,4).Value;
		
		NewAccount = ChartsOfAccounts.ChartOfAccounts.CreateAccount();
		NewAccount.Code = AccountNumber;
		NewAccount.Description = AccountName;
		If AccountTypeValue = GeneralFunctionsReusable.BankAccountType() OR
			AccountTypeValue = GeneralFunctionsReusable.ARAccountType() OR
			AccountTypeValue = GeneralFunctionsReusable.APAccountType() Then
			
			NewAccount.Currency = GeneralFunctionsReusable.DefaultCurrency();
		EndIf;
		
		NewAccount.AccountType = AccountTypeValue;
		//NewAccount.Memo = AccountMemo;
		NewAccount.CashFlowSection = Enums.CashFlowSections.Operating;
		NewAccount.Write();					
						
   		NRows = NRows +1;
		
	EndDo;
	
	except
		Message(ErrorDescription()); 
		ExcelApp.Application.Quit();
	endTry;
	
	ExcelApp.ActiveWorkbook.Close(False);
			
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// AdditionalReportsAndDataProcessors
	AdditionalReportsAndDataProcessors.OnCreateAtServer(ThisForm);
	// End AdditionalReportsAndDataProcessors
	
EndProcedure
