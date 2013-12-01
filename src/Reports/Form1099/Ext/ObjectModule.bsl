Function Form1099(StartDate, EndDate) Export
	
	If StartDate =  Date(1,1,1) Then
		WhereCase = "AND GeneralJournal.Period <= &EndDate";
		PeriodLabel = "- " + Format(EndDate, "DLF=D");
	EndIf;
	
	If EndDate =  Date(1,1,1) Then
		WhereCase = "AND GeneralJournal.Period >= &StartDate";
		PeriodLabel = Format(StartDate, "DLF=D") + " -";
	EndIf;
	
	If StartDate = Date(1,1,1) AND EndDate = Date(1,1,1) Then
		WhereCase = "";
		PeriodLabel = "All dates";
	EndIf;
	
	If NOT StartDate = Date(1,1,1) AND NOT EndDate = Date(1,1,1) Then
		WhereCase = "AND GeneralJournal.Period >= &StartDate AND GeneralJournal.Period <= &EndDate";
		PeriodLabel = Format(StartDate, "DLF=D") + " - " + Format(EndDate, "DLF=D");
	EndIf;
		
	SpreadsheetDocument = New SpreadsheetDocument;
	Template = GetTemplate("Template");
	
	FormContent = Template.GetArea("FormContent");
	
	Data1099 = US_FL.Data1099(WhereCase);

	Box1Total = 0;
	Box2Total = 0;
	Box3Total = 0;
	Box4Total = 0;
	Box5Total = 0;
	Box6Total = 0;
	Box7Total = 0;
	Box8Total = 0;
	Box9Total = 0;
	Box10Total = 0;
	Box13Total = 0;
	Box14Total = 0;

	Box1Threshold = CommonUse.GetAttributeValue(Catalogs.USTaxCategories1099.Box1, "Threshold");
	Box2Threshold = CommonUse.GetAttributeValue(Catalogs.USTaxCategories1099.Box2, "Threshold");
	Box3Threshold = CommonUse.GetAttributeValue(Catalogs.USTaxCategories1099.Box3, "Threshold");
	Box4Threshold = CommonUse.GetAttributeValue(Catalogs.USTaxCategories1099.Box4, "Threshold");
	Box5Threshold = CommonUse.GetAttributeValue(Catalogs.USTaxCategories1099.Box5, "Threshold");
	Box6Threshold = CommonUse.GetAttributeValue(Catalogs.USTaxCategories1099.Box6, "Threshold");
	Box7Threshold = CommonUse.GetAttributeValue(Catalogs.USTaxCategories1099.Box7, "Threshold");
	Box8Threshold = CommonUse.GetAttributeValue(Catalogs.USTaxCategories1099.Box8, "Threshold");
	Box9Threshold = CommonUse.GetAttributeValue(Catalogs.USTaxCategories1099.Box9, "Threshold");
	Box10Threshold = CommonUse.GetAttributeValue(Catalogs.USTaxCategories1099.Box10, "Threshold");
	Box13Threshold = CommonUse.GetAttributeValue(Catalogs.USTaxCategories1099.Box13, "Threshold");
	Box14Threshold = CommonUse.GetAttributeValue(Catalogs.USTaxCategories1099.Box14, "Threshold");
		
	VendorsList = Data1099.Copy();
	VendorsList.GroupBy("Vendor");
			
	Filter = New Structure();
	Filter.Insert("Vendor", Vendor);
	Subset1099 = Data1099.FindRows(Filter);
	
	// Transforming the array to a value table
	
	Subset1099VT = New ValueTable();
	
	Subset1099VT.Columns.Add("Category1099");
	Subset1099VT.Columns.Add("AmountRC");
	Subset1099VT.Columns.Add("Vendor");	
	
	For Each ArrayRow In Subset1099 Do
		VTRow = Subset1099VT.Add();
		VTRow.Category1099 = ArrayRow.Category1099;
		VTRow.AmountRC = ArrayRow.AmountRC;
		VTRow.Vendor = ArrayRow.Vendor;
	EndDo;
	
	// Done transforming
	
	// Outputting data
	
	OurCompany = Catalogs.Companies.OurCompany;
	
	OurCompanyInfo = New Structure();   // PrintTemplates.ContactInfo(OurCompany);
	CounterpartyInfo = New Structure(); // PrintTemplates.ContactInfo(Vendor);
	
	FormContent.Parameters.OurCompanyName = OurCompanyInfo.Name;
	FormContent.Parameters.OurCompanyAddress = OurCompanyInfo.Address;
	FormContent.Parameters.OurCompanyZIP = OurCompanyInfo.ZIP;
	FormContent.Parameters.OurCompanyPhone = OurCompanyInfo.Phone;
	FormContent.Parameters.OurTaxID = CommonUse.GetAttributeValue(OurCompany, "USTaxID");
	
	FormContent.Parameters.CounterpartyName = CounterpartyInfo.Name;
	FormContent.Parameters.CounterpartyAddress = CounterpartyInfo.Address;
	FormContent.Parameters.CounterpartyZIP = CounterpartyInfo.ZIP;
	FormContent.Parameters.CounterPartyTaxID = CommonUse.GetAttributeValue(Vendor, "USTaxID");
	
	Box1Data = Subset1099VT.Find(Catalogs.USTaxCategories1099.Box1, "Category1099");
	If Box1Data = Undefined Then
		FormContent.Parameters.Box1 = "";	
	Else
		If Box1Data.AmountRC >= Box1Threshold Then
			FormContent.Parameters.Box1 = Box1Data.AmountRC;
		Else
			FormContent.Parameters.Box1 = "";
		EndIf;
	EndIf;
	
	Box2Data = Subset1099VT.Find(Catalogs.USTaxCategories1099.Box2, "Category1099");
	If Box2Data = Undefined Then
		FormContent.Parameters.Box2 = "";	
	Else
		If Box2Data.AmountRC >= Box2Threshold Then
			FormContent.Parameters.Box2 = Box2Data.AmountRC;
		Else
			FormContent.Parameters.Box2 = "";
		EndIf;
	EndIf;

	Box3Data = Subset1099VT.Find(Catalogs.USTaxCategories1099.Box3, "Category1099");
	If Box3Data = Undefined Then
		FormContent.Parameters.Box3 = "";	
	Else
		If Box3Data.AmountRC >= Box3Threshold Then
			FormContent.Parameters.Box3 = Box3Data.AmountRC;
		Else
			FormContent.Parameters.Box3 = "";
		EndIf;
	EndIf;

	Box4Data = Subset1099VT.Find(Catalogs.USTaxCategories1099.Box4, "Category1099");
	If Box4Data = Undefined Then
		FormContent.Parameters.Box4 = "";	
	Else
		If Box4Data.AmountRC >= Box4Threshold Then
			FormContent.Parameters.Box4 = Box4Data.AmountRC;
		Else
			FormContent.Parameters.Box4 = "";
		EndIf;
	EndIf;

	Box5Data = Subset1099VT.Find(Catalogs.USTaxCategories1099.Box5, "Category1099");
	If Box5Data = Undefined Then
		FormContent.Parameters.Box5 = "";	
	Else
		If Box5Data.AmountRC >= Box5Threshold Then
			FormContent.Parameters.Box5 = Box5Data.AmountRC;
		Else
			FormContent.Parameters.Box5 = "";
		EndIf;
	EndIf;

	Box6Data = Subset1099VT.Find(Catalogs.USTaxCategories1099.Box6, "Category1099");
	If Box6Data = Undefined Then
		FormContent.Parameters.Box6 = "";	
	Else
		If Box6Data.AmountRC >= Box6Threshold Then
			FormContent.Parameters.Box6 = Box6Data.AmountRC;
		Else
			FormContent.Parameters.Box6 = "";
		EndIf;
	EndIf;
	
	Box7Data = Subset1099VT.Find(Catalogs.USTaxCategories1099.Box7, "Category1099");
	If Box7Data = Undefined Then
		FormContent.Parameters.Box1 = "";	
	Else
		If Box7Data.AmountRC >= Box7Threshold Then
			FormContent.Parameters.Box7 = Box7Data.AmountRC;
		Else
			FormContent.Parameters.Box7 = "";
		EndIf;
	EndIf;

	Box8Data = Subset1099VT.Find(Catalogs.USTaxCategories1099.Box8, "Category1099");
	If Box8Data = Undefined Then
		FormContent.Parameters.Box8 = "";	
	Else
		If Box8Data.AmountRC >= Box8Threshold Then
			FormContent.Parameters.Box8 = Box8Data.AmountRC;
		Else
			FormContent.Parameters.Box8 = "";
		EndIf;
	EndIf;

	Box9Data = Subset1099VT.Find(Catalogs.USTaxCategories1099.Box9, "Category1099");
	If Box9Data = Undefined Then
		FormContent.Parameters.Box9 = "";	
	Else
		If Box9Data.AmountRC >= Box9Threshold Then
			FormContent.Parameters.Box9 = Box9Data.AmountRC;
		Else
			FormContent.Parameters.Box9 = "";
		EndIf;
	EndIf;

	Box10Data = Subset1099VT.Find(Catalogs.USTaxCategories1099.Box10, "Category1099");
	If Box10Data = Undefined Then
		FormContent.Parameters.Box10 = "";	
	Else
		If Box10Data.AmountRC >= Box10Threshold Then
			FormContent.Parameters.Box10 = Box10Data.AmountRC;
		Else
			FormContent.Parameters.Box10 = "";
		EndIf;
	EndIf;

	Box13Data = Subset1099VT.Find(Catalogs.USTaxCategories1099.Box13, "Category1099");
	If Box13Data = Undefined Then
		FormContent.Parameters.Box13 = "";	
	Else
		If Box13Data.AmountRC >= Box13Threshold Then
			FormContent.Parameters.Box13 = Box13Data.AmountRC;
		Else
			FormContent.Parameters.Box13 = "";
		EndIf;
	EndIf;

	Box14Data = Subset1099VT.Find(Catalogs.USTaxCategories1099.Box14, "Category1099");
	If Box14Data = Undefined Then
		FormContent.Parameters.Box14 = "";	
	Else
		If Box14Data.AmountRC >= Box14Threshold Then
			FormContent.Parameters.Box14 = Box14Data.AmountRC;
		Else
			FormContent.Parameters.Box14 = "";
		EndIf;
	EndIf;
	
	SpreadsheetDocument.Put(FormContent);			
	
	// Return result
	
	Return SpreadSheetDocument;
	
EndFunction