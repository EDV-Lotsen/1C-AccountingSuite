Procedure PrintCheck(Spreadsheet, Ref) Export

	Template = Documents.Check.GetTemplate("PrintCheck");
	Query = New Query;
	Query.Text =
	"SELECT
	|	Check.Date,
	|	Check.Company,
	|	Check.DocumentTotalRC,
	|	Check.Memo
	|FROM
	|	Document.Check AS Check
	|WHERE
	|	Check.Ref IN (&Ref)";
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
		
		Header.Parameters.WrittenAmount = NumberInWords(Selection.DocumentTotalRC);
		//Header.Parameters.WrittenAmount = Left(StringAmount, NumChar - 3);
		
		Spreadsheet.Put(Header, Selection.Level());

		InsertPageBreak = True;
	EndDo;

EndProcedure
