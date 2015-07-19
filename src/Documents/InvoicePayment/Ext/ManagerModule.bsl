
Procedure PrintCheck(Spreadsheet, Ref) Export
	
	Template = Documents.InvoicePayment.GetTemplate("PrintCheck");
	Query = New Query;
	Query.Text =
	"SELECT
	|	InvoicePayment.Date,
	|	InvoicePayment.Company,
	|	InvoicePayment.DocumentTotalRC,
	|	InvoicePayment.Memo,
	|	InvoicePayment.LineItems.(
	|		Ref,
	|		LineNumber,
	|		Document,
	|		Document.Date,
	|		Document.Number,
	|		VALUETYPE(InvoicePayment.LineItems.Document) AS DocType,
	|		Document.DocumentTotalRC,
	|		Payment,
	|		Balance,
	|		BalanceFCY,
	|		Currency
	|	),
	|	InvoicePayment.BankAccount.Description As BankDesc
	|FROM
	|	Document.InvoicePayment AS InvoicePayment
	|WHERE
	|	InvoicePayment.Ref IN(&Ref)";
	Query.Parameters.Insert("Ref", Ref);
	
	//Selection = Query.Execute().Unload();
	
	Selection = Query.Execute().Select();
	
	/////
	AreaCaption = Template.GetArea("Caption");
	Header = Template.GetArea("Header");
	Header2 = Template.GetArea("Header2");
	EndStatement = Template.GetArea("EndStatement");
	EndStatement2 = Template.GetArea("EndStatement2");
	
	Spreadsheet.Clear();
	InsertPageBreak = False;
	While Selection.Next() Do
		If InsertPageBreak Then
			Spreadsheet.PutHorizontalPageBreak();
		EndIf;
		
		Spreadsheet.LeftMargin = 17 + Constants.CheckHorizontalAdj.Get();
		Spreadsheet.TopMargin = 15 + Constants.CheckVerticalAdj.Get();
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	Addresses.Ref
		|FROM
		|	Catalog.Addresses AS Addresses
		|WHERE
		|	Addresses.Owner = &Owner
		|	AND Addresses.DefaultBilling = &True";
		Query.Parameters.Insert("Owner", Selection.Company);
		Query.Parameters.Insert("True", True);
		BillAddr = Query.Execute().Unload();
		If BillAddr.Count() > 0 Then
			ThemBill = PrintTemplates.ContactInfoDataset(Selection.Company, "ThemBill", BillAddr[0].Ref);
		Else
			ThemBill = PrintTemplates.ContactInfoDataset(Selection.Company, "ThemBill",Catalogs.Addresses.EmptyRef());
		EndIf;
		
		
		//ThemBill = PrintTemplates.ContactInfoDataset(Selection.Company, "ThemBill", Catalogs.Addresses.EmptyRef());
		
		Spreadsheet.Put(AreaCaption);
		
		Header.Parameters.Fill(Selection);
		Header.Parameters.Fill(ThemBill);
		
		numtostr = string(Selection.DocumentTotalRC);
		Result = StrOccurrenceCount(numtostr,".");	
		
		ParametersSubject="dollar and, dollars and, cent, cents, 2";
		
		Rawamount = NumberInWords(Selection.DocumentTotalRC,,ParametersSubject);
		
		If Selection.DocumentTotalRC > 1 Then
			Rawamount = StrReplace(Rawamount,"dollar ","dollars ");
		Endif;
		
		
		For	i = StrLen(Rawamount) To 110 Do
			Rawamount = Rawamount + "*";
		EndDo;
		
		Header.Parameters.WrittenAmount = "**" + Rawamount;
		
		FormattedNum = Format(Selection.DocumentTotalRC, "NFD=2");
		Header.Parameters.DocumentTotalRC = "**" + FormattedNum + "**";
		
		//If Result = 0 Then
		//	Header.Parameters.DocumentTotalRC = "**" + Selection.DocumentTotalRC + ".00**";
		//Else
		//	FormattedNum = Format(Selection.DocumentTotalRC, "NFD=2");
		//	Header.Parameters.DocumentTotalRC = "**" + FormattedNum + "**";
		
		//Endif;	
		
		RemitTo = ThemBill.RemitTo;
		
		If RemitTo <> "" Then
			Header.Parameters.RemitTo = RemitTo;
		Else
			Header.Parameters.RemitTo = ThemBill.ThemName;
		Endif;
		
		//Header.Parameters.BankAccount = Selection.BankDesc;
		
		Spreadsheet.Put(Header, Selection.Level());		
		
		
		//InvoicePayment Fill
		SelectionLineItems = Selection.LineItems.Select();
		
		TemplateBills = Template.GetArea("Bills");
		InvoiceCount = 0;
		While SelectionLineItems.Next() Do
			
			//--//
			If InvoiceCount = 15 Then
				InvoiceCount = InvoiceCount + 1;
				
				TemplateBills.Parameters.InvoiceDate  = "...";
				TemplateBills.Parameters.Type         = "...";
				TemplateBills.Parameters.ReferenceNum = "..."; 
				TemplateBills.Parameters.OrigAmount   = "...";
				TemplateBills.Parameters.BalDue       = "...";
				TemplateBills.Parameters.Payment      = "...";
				
				Spreadsheet.Put(TemplateBills, SelectionLineItems.Level());
				Continue;
			ElsIf InvoiceCount > 15 Then
				Break;
			EndIf;
			//--//
			
			FormattedDate = Format(SelectionLineItems.Document.Date, "DF=""MM/dd/yyyy""");		                    
			//TemplateBills.Parameters.InvoiceDate = SelectionLineItems.Document.Date;
			TemplateBills.Parameters.InvoiceDate = FormattedDate;
			
			TemplateBills.Parameters.Type = SelectionLineItems.DocType;
			TemplateBills.Parameters.ReferenceNum = SelectionLineItems.Document.Number;
			TemplateBills.Parameters.Payment = SelectionLineItems.Payment;
			
			Query2 = New Query;
			Query2.Text =
			"SELECT
			|	GeneralJournalBalance.AmountRCBalance * -1 AS Balance
			|FROM
			|	AccountingRegister.GeneralJournal.Balance AS GeneralJournalBalance
			|WHERE
			|	GeneralJournalBalance.ExtDimension2 = &Ref2";
			
			Query2.Parameters.Insert("Ref2", SelectionLineItems.Document);
			Query2Result = Query2.Execute();
			If Query2Result.IsEmpty() Then
				BalanceD = 0;
			Else
				BalanceD = Query2.Execute().Unload()[0][0];
			EndIf;
			
			numtostr = string(SelectionLineItems.Document.DocumentTotalRC);
			Result = StrOccurrenceCount(numtostr,".");
			
			FormattedNum = Format(BalanceD, "NFD=2");
			TemplateBills.Parameters.BalDue = FormattedNum;
			
			
			numtostr = string(SelectionLineItems.Document.DocumentTotalRC);
			Result = StrOccurrenceCount(numtostr,".");
			
			FormattedNum = Format(SelectionLineItems.Document.DocumentTotalRC, "NFD=2");
			TemplateBills.Parameters.OrigAmount = FormattedNum;
			
			
			Spreadsheet.Put(TemplateBills, SelectionLineItems.Level());
			InvoiceCount = InvoiceCount + 1;
			
		EndDo;
		
		//TemplateArea = Template.GetArea("EmptyArea");
		//  Spreadsheet.Put(TemplateArea);
		FillArea = Template.GetArea("FillArea");
		For I = InvoiceCount To 15 Do
			Spreadsheet.Put(FillArea);
		EndDo;
		
		EndStatement.Parameters.BankAccount = Selection.BankDesc;
		EndStatement.Parameters.Memo = Selection.Memo;
		EndStatement.Parameters.DocumentTotalRC2 = Selection.DocumentTotalRC;
		Spreadsheet.Put(EndStatement);
		
		
		TemplateArea = Template.GetArea("EmptyArea3");
		Spreadsheet.Put(TemplateArea);
		
		
		Head2 = Template.GetArea("Header2");
		Head2.Parameters.Date = Selection.Date;
		Head2.Parameters.RemitTo = RemitTo;
		Spreadsheet.Put(Head2);
		
		//Second InvoiceFill
		SelectionLineItems = Selection.LineItems.Select();
		
		TemplateBills = Template.GetArea("Bills2");
		InvoiceCount = 0;
		While SelectionLineItems.Next() Do
			
			//--//
			If InvoiceCount = 15 Then
				InvoiceCount = InvoiceCount + 1;
				
				TemplateBills.Parameters.InvoiceDate  = "...";
				TemplateBills.Parameters.Type         = "...";
				TemplateBills.Parameters.ReferenceNum = "..."; 
				TemplateBills.Parameters.OrigAmount   = "...";
				TemplateBills.Parameters.BalDue       = "...";
				TemplateBills.Parameters.Payment      = "...";
				
				Spreadsheet.Put(TemplateBills, SelectionLineItems.Level());
				Continue;
			ElsIf InvoiceCount > 15 Then
				Break;
			EndIf;
			//--//
			
			FormattedDate = Format(SelectionLineItems.Document.Date, "DF=""MM/dd/yyyy""");		                    
			//TemplateBills.Parameters.InvoiceDate = SelectionLineItems.Document.Date;
			TemplateBills.Parameters.InvoiceDate = FormattedDate;
			
			TemplateBills.Parameters.Type = SelectionLineItems.DocType;
			TemplateBills.Parameters.ReferenceNum = SelectionLineItems.Document.Number;
			TemplateBills.Parameters.Payment = SelectionLineItems.Payment;
			
			Query2 = New Query;
			Query2.Text =
			"SELECT
			|	GeneralJournalBalance.AmountRCBalance * -1 AS Balance
			|FROM
			|	AccountingRegister.GeneralJournal.Balance AS GeneralJournalBalance
			|WHERE
			|	GeneralJournalBalance.ExtDimension2 = &Ref2";
			
			Query2.Parameters.Insert("Ref2", SelectionLineItems.Document);
			Query2Result = Query2.Execute();
			If Query2Result.IsEmpty() Then
				BalanceD = 0;
			Else
				BalanceD = Query2.Execute().Unload()[0][0];
			EndIf;
			
			
			
			numtostr = string(SelectionLineItems.Document.DocumentTotalRC);
			Result = StrOccurrenceCount(numtostr,".");
			
			FormattedNum = Format(BalanceD, "NFD=2");
			TemplateBills.Parameters.BalDue = FormattedNum;	
			
			numtostr = string(SelectionLineItems.Document.DocumentTotalRC);
			Result = StrOccurrenceCount(numtostr,".");
			
			FormattedNum = Format(SelectionLineItems.Document.DocumentTotalRC, "NFD=2");
			TemplateBills.Parameters.OrigAmount = FormattedNum;
			
			
			Spreadsheet.Put(TemplateBills, SelectionLineItems.Level());
			InvoiceCount = InvoiceCount + 1;
			
		EndDo;
		//
		
		For I = InvoiceCount To 15 Do
			Spreadsheet.Put(FillArea);
		EndDo;
		
		EndStatement2.Parameters.BankAccount = Selection.BankDesc;
		EndStatement2.Parameters.Memo = Selection.Memo;
		EndStatement2.Parameters.DocumentTotalRC2 = Selection.DocumentTotalRC;
		
		Spreadsheet.Put(EndStatement2);
		
		
		InsertPageBreak = True;
		
		//
		Spreadsheet.PageSize = "Letter"; 
		Spreadsheet.FitToPage = True;
		
	EndDo;
	
	
EndProcedure

&AtServer
Procedure Test()
	
	Spread = New SpreadsheetDocument;
	test = Spread.PageWidth;
EndProcedure