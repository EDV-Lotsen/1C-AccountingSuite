Procedure PrintCheck(Spreadsheet, Ref) Export

	Template = Documents.Check.GetTemplate("PrintCheck");
	Query = New Query;
	Query.Text =
	"SELECT
	|	Check.Date,
	|	Check.Company,
	|	Check.DocumentTotalRC,
	|	Check.Memo,
	|	Check.BankAccount.Description AS BankAccount
	|FROM
	|	Document.Check AS Check
	|WHERE
	|	Check.Ref IN(&Ref)";
	Query.Parameters.Insert("Ref", Ref);
	Selection = Query.Execute().Choose();

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
		ThemBill = PrintTemplates.ContactInfoDataset(Selection.Company, "ThemBill", Catalogs.Addresses.EmptyRef());
		
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
	EndDo;
	

EndProcedure