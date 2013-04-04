
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.Company.Title = GeneralFunctionsReusable.GetVendorName();
	
	// AdditionalReportsAndDataProcessors
	AdditionalReportsAndDataProcessors.OnCreateAtServer(ThisForm);
	// End AdditionalReportsAndDataProcessors
	
EndProcedure

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
		ImportPI(Selection.FullName);
	Else
	    DoMessageBox("File(s) not selected!");
	EndIf;

EndProcedure

&AtServer
Procedure ImportPI(File)
		
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
	
	For n= 1 To   TotalNRows Do
		
		Account = ExcelApp.Sheets(1).Cells(NRows,5).Value;
		Account = Left(Account,1) + Right(Account,3);
		
		If round(n/2) <> n/2 Then
			
			NewPI = Documents.PurchaseInvoice.CreateDocument();
			NewPI.Number = ExcelApp.Sheets(1).Cells(NRows,2).Value;
			NewPI.Date = ExcelApp.Sheets(1).Cells(NRows,3).Value;
			NewPI.Company = Catalogs.Companies.FindByDescription(ExcelApp.Sheets(1).Cells(NRows,4).Value);
			NewPI.CompanyCode = NewPI.Company.Code;
			NewPI.DocumentTotal = ExcelApp.Sheets(1).Cells(NRows,6).Value;
			NewPI.DocumentTotalRC = ExcelApp.Sheets(1).Cells(NRows,6).Value;
			NewPI.Currency = GeneralFunctionsReusable.DefaultCurrency();
			NewPI.ExchangeRate = 1;
			NewPI.Location = Catalogs.Locations.MainWarehouse;
			NewPI.DueDate = ExcelApp.Sheets(1).Cells(NRows,3).Value + 60*60*24*30;
			NewPI.Terms = NewPI.Company.Terms;			
			If ExcelApp.Sheets(1).Cells(NRows,1).Value = "Credit" Then
				NewPI.APAccount = ChartsOfAccounts.ChartOfAccounts.FindByCode(Account);
			Else
				NewLine = NewPI.Accounts.Add();
				NewLine.Account = ChartsOfAccounts.ChartOfAccounts.FindByCode(Account);
			    NewLine.Amount = ExcelApp.Sheets(1).Cells(NRows,6).Value;
			EndIf;
		Else
			If ExcelApp.Sheets(1).Cells(NRows,1).Value = "Credit" Then
				NewPI.APAccount = ChartsOfAccounts.ChartOfAccounts.FindByCode(Account);
			Else
				NewLine = NewPI.Accounts.Add();
				NewLine.Account = ChartsOfAccounts.ChartOfAccounts.FindByCode(Account);
			    NewLine.Amount = ExcelApp.Sheets(1).Cells(NRows,6).Value;
			EndIf;
		    NewPI.Write();
				
		EndIf;
						
   		NRows = NRows +1;
		
	EndDo;
	
	except
		Message(ErrorDescription()); 
		ExcelApp.Application.Quit();
	endTry;
	
	ExcelApp.ActiveWorkbook.Close(False);

EndProcedure
