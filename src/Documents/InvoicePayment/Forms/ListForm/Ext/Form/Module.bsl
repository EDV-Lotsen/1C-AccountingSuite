
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
		ImportIP(Selection.FullName);
	Else
	    DoMessageBox("File(s) not selected!");
	EndIf;

EndProcedure

&AtServer
Procedure ImportIP(File)
		
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
				
		NewIP = Documents.InvoicePayment.CreateDocument();
		NewIP.Company = Catalogs.Companies.FindByDescription(ExcelApp.Sheets(1).Cells(NRows,3).Value);
		NewIP.CompanyCode = NewIP.Company.Code;
		NewIP.DocumentTotal = ExcelApp.Sheets(1).Cells(NRows,5).Value;
		NewIP.DocumentTotalRC = ExcelApp.Sheets(1).Cells(NRows,5).Value;
		NewIP.BankAccount = ChartsOfAccounts.ChartOfAccounts.FindByCode("1010");
		NewIP.Currency = GeneralFunctionsReusable.DefaultCurrency();
		NewIP.Date = ExcelApp.Sheets(1).Cells(NRows,2).Value;
		NewIP.Number = ExcelApp.Sheets(1).Cells(NRows,1).Value;
		
		NewLine = NewIP.LineItems.Add();
		NewLine.Document = Documents.PurchaseInvoice.FindByNumber(ExcelApp.Sheets(1).Cells(NRows,4).Value);
		NewLine.Currency = GeneralFunctionsReusable.DefaultCurrency();
		NewLine.Payment = ExcelApp.Sheets(1).Cells(NRows,5).Value;
		
		NewIP.Write();
		
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

