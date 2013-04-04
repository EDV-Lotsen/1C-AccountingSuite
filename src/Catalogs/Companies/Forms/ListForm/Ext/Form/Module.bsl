
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Try
		Items.Customer.Title = GeneralFunctionsReusable.GetCustomerName();
		Items.Vendor.Title = GeneralFunctionsReusable.GetVendorName();
	Except
	EndTry;
	
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
		ImportCompanies(Selection.FullName);
	Else
	    DoMessageBox("File(s) not selected!");
	EndIf;

EndProcedure

&AtServer
Procedure ImportCompanies(File)
		
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
	NRows =1; // not taking the header
	
	TotalNRows  = ExcelApp.Sheets(1).UsedRange.row + ExcelApp.Sheets(1).UsedRange.Rows.Count - 1;
		   
	For n= 1 To   TotalNRows Do
		
		NewCompany = Catalogs.Companies.CreateItem();
		//NewCompany.Code = GeneralFunctions.LastCompanyNumber() + 1;
		NewCompany.Description = ExcelApp.Sheets(1).Cells(NRows,1).Value;
		//NewCompany.Name = ExcelApp.Sheets(1).Cells(NRows,1).Value;
		//If ExcelApp.Sheets(1).Cells(NRows,2).Value = "C" Then
		//	NewCompany.Customer = True;
		//Else
			NewCompany.Vendor = True;
		//EndIf;
		NewCompany.DefaultCurrency = Constants.DefaultCurrency.Get();
		NewCompany.ExpenseAccount = Constants.ExpenseAccount.Get(); 
        NewCompany.IncomeAccount = Constants.IncomeAccount.Get();
		NewCompany.Terms = Catalogs.PaymentTerms.Net30;
		
		NewCompany.Write();					
		
		AddressLine = Catalogs.Addresses.CreateItem();
		AddressLine.Owner = NewCompany.Ref;
		AddressLine.Description = "Primary";
		AddressLine.DefaultShipping = True;
		AddressLine.DefaultBilling = True;
		AddressLine.Write();
		
   		NRows = NRows +1;
		
	EndDo;
	
	except
		Message(ErrorDescription()); 
		ExcelApp.Application.Quit();
	endTry;
	
	ExcelApp.ActiveWorkbook.Close(False);
		
EndProcedure
