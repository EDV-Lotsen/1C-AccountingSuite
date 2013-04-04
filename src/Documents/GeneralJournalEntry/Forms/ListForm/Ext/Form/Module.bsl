
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
		ImportGJE(Selection.FullName);
	Else
	    DoMessageBox("File(s) not selected!");
	EndIf;

EndProcedure

&AtServer
Procedure ImportGJE(File)
	
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
	
	TotalDebit = 0;
	
	For n= 1 To   TotalNRows Do
		
		DocNum = ExcelApp.Sheets(1).Cells(NRows,2).Value;
		If n <> 1 Then
			DocNumPrevious = ExcelApp.Sheets(1).Cells(NRows-1,2).Value;
		EndIf;
			
		If n <> 1 Then
			
			If DocNum <> DocNumPrevious Then
							
				NewGJE = Documents.GeneralJournalEntry.CreateDocument();
				NewGJE.Number = DocNum;
				NewGJE.Date = ExcelApp.Sheets(1).Cells(NRows,6).Value;
				//NewGJE.DocumentTotalRC = 1;
				//NewGJE.DocumentTotal = 1;
				NewGJE.Currency = GeneralFunctionsReusable.DefaultCurrency();
				NewGJE.ExchangeRate = 1;
				
				Acc = ExcelApp.Sheets(1).Cells(NRows,4).Value;
				AccString = String(Acc);
				NewLine = NewGJE.LineItems.Add();
				NewLine.Account = ChartsOfAccounts.ChartOfAccounts.FindByCode(AccString);
				NewLine.AccountDescription = NewLine.Account.Description;
				If ExcelApp.Sheets(1).Cells(NRows,1).Value = "Debit" Then
					NewLine.AmountDr = ExcelApp.Sheets(1).Cells(NRows,5).Value;
					TotalDebit = TotalDebit + NewLine.AmountDr;
				ElsIf ExcelApp.Sheets(1).Cells(NRows,1).Value = "Credit" Then
					NewLine.AmountCr = ExcelApp.Sheets(1).Cells(NRows,5).Value;
				EndIf;
				
			Else
				
				Acc = ExcelApp.Sheets(1).Cells(NRows,4).Value;
				AccString = String(Acc);
				NewLine = NewGJE.LineItems.Add();
				NewLine.Account = ChartsOfAccounts.ChartOfAccounts.FindByCode(AccString);
				NewLine.AccountDescription = NewLine.Account.Description;
				If ExcelApp.Sheets(1).Cells(NRows,1).Value = "Debit" Then
					NewLine.AmountDr = ExcelApp.Sheets(1).Cells(NRows,5).Value;
					TotalDebit = TotalDebit + NewLine.AmountDr;
				ElsIf ExcelApp.Sheets(1).Cells(NRows,1).Value = "Credit" Then
					NewLine.AmountCr = ExcelApp.Sheets(1).Cells(NRows,5).Value;
				EndIf;

				
			EndIf;
		Else
			
			 	NewGJE = Documents.GeneralJournalEntry.CreateDocument();
				NewGJE.Number = DocNum;
				NewGJE.Date = ExcelApp.Sheets(1).Cells(NRows,6).Value;
				//NewGJE.DocumentTotalRC = 1;
				//NewGJE.DocumentTotal = 1;
				NewGJE.Currency = GeneralFunctionsReusable.DefaultCurrency();
				NewGJE.ExchangeRate = 1;
				
				Acc = ExcelApp.Sheets(1).Cells(NRows,4).Value;
				AccString = String(Acc);
				NewLine = NewGJE.LineItems.Add();
				NewLine.Account = ChartsOfAccounts.ChartOfAccounts.FindByCode(AccString);
				NewLine.AccountDescription = NewLine.Account.Description;
				If ExcelApp.Sheets(1).Cells(NRows,1).Value = "Debit" Then
					NewLine.AmountDr = ExcelApp.Sheets(1).Cells(NRows,5).Value;
					TotalDebit = TotalDebit + NewLine.AmountDr;
				ElsIf ExcelApp.Sheets(1).Cells(NRows,1).Value = "Credit" Then
					NewLine.AmountCr = ExcelApp.Sheets(1).Cells(NRows,5).Value;
				EndIf;
		
		EndIf;
			
		If n <> 1 Then
			If n <> TotalNRows Then
				DocNumNext = ExcelApp.Sheets(1).Cells(NRows+1,2).Value;
				If DocNum <> DocNumNext Then
					NewGJE.DocumentTotal = TotalDebit;
					NewGJE.DocumentTotalRC = TotalDebit;
					NewGJE.Write();
					TotalDebit = 0;
				EndIf;
			Else
				NewGJE.DocumentTotal = TotalDebit;
				NewGJE.DocumentTotalRC = TotalDebit;
				NewGJE.Write();
				TotalDebit = 0;
			EndIf;
        EndIf;
				
		
		//DrCr = ExcelApp.Sheets(1).Cells(NRows,1).Value;
		//DocNum = ExcelApp.Sheets(1).Cells(NRows,2).Value;
		//Acc = ExcelApp.Sheets(1).Cells(NRows,4).Value;
		//Amount = ExcelApp.Sheets(1).Cells(NRows,5).Value;
		//Date = ExcelApp.Sheets(1).Cells(NRows,6).Value;
						
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
