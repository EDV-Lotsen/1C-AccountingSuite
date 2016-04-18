
Procedure PrintCheck(Spreadsheet, Ref) Export

	Template = Documents.Check.GetTemplate("PrintCheck");
	Query = New Query;
	Query.Text =
	"SELECT
	|	Check.Date,
	|	Check.Company,
	|	Check.RemitTo,
	|	Check.DocumentTotalRC,
	|	Check.Memo,
	|	Check.BankAccount.Description AS BankAccount
	|FROM
	|	Document.Check AS Check
	|WHERE
	|	Check.Ref IN(&Ref)";
	Query.Parameters.Insert("Ref", Ref);
	Selection = Query.Execute().Select();

	AreaCaption = Template.GetArea("Caption");
	Header = Template.GetArea("Header");
	Spreadsheet.Clear();
	InsertPageBreak = False;
	While Selection.Next() Do
		If InsertPageBreak Then
			Spreadsheet.PutHorizontalPageBreak();
		EndIf;
		
		Spreadsheet.LeftMargin = 17 + Constants.CheckHorizontalAdj.Get();
		Spreadsheet.TopMargin = 15 + Constants.CheckVerticalAdj.Get();
		
		//CounterpartyInfo = PrintTemplates.ContactInfo(Selection.Company);
		//Query = New Query;
		//Query.Text =
		//"SELECT
		//|	Addresses.Ref
		//|FROM
		//|	Catalog.Addresses AS Addresses
		//|WHERE
		//|	Addresses.Owner = &Owner
		//|	AND Addresses.DefaultBilling = &True";
		//Query.Parameters.Insert("Owner", Selection.Company);
		//Query.Parameters.Insert("True", True);
		//BillAddr = Query.Execute().Unload();
		//If BillAddr.Count() > 0 Then
		//	ThemBill = PrintTemplates.ContactInfoDataset(Selection.Company, "ThemBill", BillAddr[0].Ref);
		//Else
		//	ThemBill = PrintTemplates.ContactInfoDataset(Selection.Company, "ThemBill",Catalogs.Addresses.EmptyRef());
		//EndIf;
		
		ThemBill = PrintTemplates.ContactInfoDataset(Selection.Company, "ThemBill", Selection.RemitTo);

		//ThemBill = PrintTemplates.ContactInfoDataset(Selection.Company, "ThemBill", Catalogs.Addresses.EmptyRef());
		
		Spreadsheet.Put(AreaCaption);

		Header.Parameters.Fill(Selection);
		Header.Parameters.Fill(ThemBill);
		
		//Header.Parameters.CounterpartyName = CounterpartyInfo.ThemFullName;
		//Header.Parameters.CounterpartyAddress = CounterpartyInfo.ThemBillLine1;
		//Header.Parameters.CounterpartyZIP = CounterpartyInfo.ThemBillZIP;
		
		//StringAmount = NumberInWords(Selection.DocumentTotalRC);
		//NumChar = StrLen(StringAmount);
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
		
		//Amount = Left(NumberInWords(Selection.DocumentTotalRC,,ParametersSubject) + "*******************************************************************",120);
		//Header.Parameters.WrittenAmount = NumberInWords(Selection.DocumentTotalRC,,ParametersSubject);
		
		Header.Parameters.WrittenAmount = "**" + Rawamount;
		//Message(Selection.DocumentTotalRC);
		
		FormattedNum = Format(Selection.DocumentTotalRC, "NFD=2");
		Header.Parameters.DocumentTotalRC = "**" + FormattedNum + "**";

		
		Header.Parameters.DocumentTotalRC2 = Selection.DocumentTotalRC;
		
			
		Header.Parameters.BankAccount = Selection.BankAccount;
		
		RemitTo = ThemBill.RemitTo;
		
		If RemitTo <> "" Then
			Header.Parameters.RemitTo = RemitTo;
		Else
			Header.Parameters.RemitTo = ThemBill.ThemName;
		Endif;
		
		Spreadsheet.Put(Header, Selection.Level());
		
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