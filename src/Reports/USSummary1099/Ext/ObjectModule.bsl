Function Summary1099(StartDate, EndDate) Export
	
	StartD = StartDate;
	EndD = EndDate;
	
	If StartDate =  Date(1,1,1) Then
		WhereCase = "AND GeneralJournal.Period <= &EndDate";
		PeriodLabel = "- " + Format(EndD, "DLF=D");
	EndIf;
	
	If EndDate =  Date(1,1,1) Then
		WhereCase = "AND GeneralJournal.Period >= &StartDate";
		PeriodLabel = Format(StartD, "DLF=D") + " -";
	EndIf;
	
	If StartDate = Date(1,1,1) AND EndDate = Date(1,1,1) Then
		WhereCase = "";
		PeriodLabel = "All dates";
	EndIf;
	
	If NOT StartDate = Date(1,1,1) AND NOT EndDate = Date(1,1,1) Then
		WhereCase = "AND GeneralJournal.Period >= &StartDate AND GeneralJournal.Period <= &EndDate";
		PeriodLabel = Format(StartD, "DLF=D") + " - " + Format(EndD, "DLF=D");
	EndIf;
	
	OurCompany = Catalogs.Companies.OurCompany;
	
	SpreadsheetDocument = New SpreadsheetDocument;
	Template = GetTemplate("Template");
	
	Header = Template.GetArea("Header");
	Header.Parameters.PeriodLabel = PeriodLabel;
	Header.Parameters.Company = GeneralFunctions.GetAttributeValue(OurCompany, "Name");
	SpreadsheetDocument.Put(Header);
	
	Data1099 = US_FL.Data1099(WhereCase);
	
	// Outputting column headers
	
	Box1Present = False;
	Box2Present = False;
	Box3Present = False;
	Box4Present = False;
	Box5Present = False;
	Box6Present = False;
	Box7Present = False;
	Box8Present = False;
	Box9Present = False;
	Box10Present = False;
	Box13Present = False;
	Box14Present = False;
	
	ColumnTitles = Template.GetArea("ColumnValues|ColumnTitles");
	
	ColumnTitles.Parameters.BoxTitle = "";
	SpreadsheetDocument.Put(ColumnTitles);
	
	If Data1099.Find(Catalogs.USTaxCategories1099.Box1, "Category1099") = Undefined Then
	Else
		ColumnTitles.Parameters.BoxTitle = "Box 1: Rents";
		SpreadsheetDocument.Join(ColumnTitles);
		Box1Present = True;
	EndIf;
	
	If Data1099.Find(Catalogs.USTaxCategories1099.Box2, "Category1099") = Undefined Then
	Else
		ColumnTitles.Parameters.BoxTitle = "Box 2: Royalties";
		SpreadsheetDocument.Join(ColumnTitles);
		Box2Present = True;
	EndIf;

	
	If Data1099.Find(Catalogs.USTaxCategories1099.Box3, "Category1099") = Undefined Then
	Else
		ColumnTitles.Parameters.BoxTitle = "Box 3: Other income";
		SpreadsheetDocument.Join(ColumnTitles);
		Box3Present = True;
	EndIf;
	
	If Data1099.Find(Catalogs.USTaxCategories1099.Box4, "Category1099") = Undefined Then
	Else
		ColumnTitles.Parameters.BoxTitle = "Box 4: Federal income tax withheld";
		SpreadsheetDocument.Join(ColumnTitles);
		Box4Present = True;
	EndIf;

	If Data1099.Find(Catalogs.USTaxCategories1099.Box5, "Category1099") = Undefined Then
	Else
		ColumnTitles.Parameters.BoxTitle = "Box 5: Fishing boat proceeds";
		SpreadsheetDocument.Join(ColumnTitles);
		Box5Present = True;
	EndIf;

	If Data1099.Find(Catalogs.USTaxCategories1099.Box6, "Category1099") = Undefined Then
	Else
		ColumnTitles.Parameters.BoxTitle = "Box 6: Medical and health care payments";
		SpreadsheetDocument.Join(ColumnTitles);
		Box6Present = True;
	EndIf;

	
	If Data1099.Find(Catalogs.USTaxCategories1099.Box7, "Category1099") = Undefined Then
	Else
		ColumnTitles.Parameters.BoxTitle = "Box 7: Nonemployee compensation";
		SpreadsheetDocument.Join(ColumnTitles);
		Box7Present = True;
	EndIf;

	If Data1099.Find(Catalogs.USTaxCategories1099.Box8, "Category1099") = Undefined Then
	Else
		ColumnTitles.Parameters.BoxTitle = "Box 8: Substitute payments";
		SpreadsheetDocument.Join(ColumnTitles);
		Box8Present = True;
	EndIf;

	If Data1099.Find(Catalogs.USTaxCategories1099.Box9, "Category1099") = Undefined Then
	Else
		ColumnTitles.Parameters.BoxTitle = "Box 9: Direct sales";
		SpreadsheetDocument.Join(ColumnTitles);
		Box9Present = True;
	EndIf;

	If Data1099.Find(Catalogs.USTaxCategories1099.Box10, "Category1099") = Undefined Then
	Else
		ColumnTitles.Parameters.BoxTitle = "Box 10: Crop insurance proceeds";
		SpreadsheetDocument.Join(ColumnTitles);
		Box10Present = True;
	EndIf;

	If Data1099.Find(Catalogs.USTaxCategories1099.Box13, "Category1099") = Undefined Then
	Else
		ColumnTitles.Parameters.BoxTitle = "Box 13: Excess golden parachute";
		SpreadsheetDocument.Join(ColumnTitles);
		Box13Present = True;
	EndIf;

	If Data1099.Find(Catalogs.USTaxCategories1099.Box14, "Category1099") = Undefined Then
	Else
		ColumnTitles.Parameters.BoxTitle = "Box 14: Gross proceeds to attorney";
		SpreadsheetDocument.Join(ColumnTitles);
		Box14Present = True;
	EndIf;

	
	// Outputting 1099 data
	
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

	Box1Threshold = GeneralFunctions.GetAttributeValue(Catalogs.USTaxCategories1099.Box1, "Threshold");
	Box2Threshold = GeneralFunctions.GetAttributeValue(Catalogs.USTaxCategories1099.Box2, "Threshold");
	Box3Threshold = GeneralFunctions.GetAttributeValue(Catalogs.USTaxCategories1099.Box3, "Threshold");
	Box4Threshold = GeneralFunctions.GetAttributeValue(Catalogs.USTaxCategories1099.Box4, "Threshold");
	Box5Threshold = GeneralFunctions.GetAttributeValue(Catalogs.USTaxCategories1099.Box5, "Threshold");
	Box6Threshold = GeneralFunctions.GetAttributeValue(Catalogs.USTaxCategories1099.Box6, "Threshold");
	Box7Threshold = GeneralFunctions.GetAttributeValue(Catalogs.USTaxCategories1099.Box7, "Threshold");
	Box8Threshold = GeneralFunctions.GetAttributeValue(Catalogs.USTaxCategories1099.Box8, "Threshold");
	Box9Threshold = GeneralFunctions.GetAttributeValue(Catalogs.USTaxCategories1099.Box9, "Threshold");
	Box10Threshold = GeneralFunctions.GetAttributeValue(Catalogs.USTaxCategories1099.Box10, "Threshold");
	Box13Threshold = GeneralFunctions.GetAttributeValue(Catalogs.USTaxCategories1099.Box13, "Threshold");
	Box14Threshold = GeneralFunctions.GetAttributeValue(Catalogs.USTaxCategories1099.Box14, "Threshold");
		
	VendorsList = Data1099.Copy();
	VendorsList.GroupBy("Vendor");
	
	For x = 0 to VendorsList.Count() - 1 Do
		
		Details = Template.GetArea("ColumnValues|Details");
		Details.Parameters.BoxValue = VendorsList[x].Vendor;
		SpreadsheetDocument.Put(Details);
		
		Filter = New Structure();
		Filter.Insert("Vendor", VendorsList[x].Vendor);
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
				
		If Box1Present Then
			Box1Data = Subset1099VT.Find(Catalogs.USTaxCategories1099.Box1, "Category1099");
			If Box1Data = Undefined Then
				Details.Parameters.BoxValue = "";	
			Else
				If Box1Data.AmountRC >= Box1Threshold Then
					Details.Parameters.BoxValue = Box1Data.AmountRC;
				    Box1Total = Box1Total + Box1Data.AmountRC;
				Else
					Details.Parameters.BoxValue = "";
				EndIf;
			EndIf;
			SpreadsheetDocument.Join(Details);
		EndIf;
		
		If Box2Present Then
			Box2Data = Subset1099VT.Find(Catalogs.USTaxCategories1099.Box2, "Category1099");
			If Box2Data = Undefined Then
				Details.Parameters.BoxValue = "";
			Else	
				If Box2Data.AmountRC >= Box2Threshold Then
					Details.Parameters.BoxValue = Box2Data.AmountRC;
					Box2Total = Box2Total + Box2Data.AmountRC;
				Else
					Details.Parameters.BoxValue = "";
				EndIf;
			EndIf;
			SpreadsheetDocument.Join(Details);
		EndIf;

		If Box3Present Then
			Box3Data = Subset1099VT.Find(Catalogs.USTaxCategories1099.Box3, "Category1099");
			If Box3Data = Undefined Then
				Details.Parameters.BoxValue = "";
			Else	
				If Box3Data.AmountRC >= Box3Threshold Then
					Details.Parameters.BoxValue = Box3Data.AmountRC;
					Box3Total = Box3Total + Box3Data.AmountRC;
				Else
					Details.Parameters.BoxValue = "";
				EndIf;
			EndIf;
			SpreadsheetDocument.Join(Details);
		EndIf;

		If Box4Present Then
			Box4Data = Subset1099VT.Find(Catalogs.USTaxCategories1099.Box4, "Category1099");
			If Box4Data = Undefined Then
				Details.Parameters.BoxValue = "";
			Else	
				If Box4Data.AmountRC >= Box4Threshold Then
					Details.Parameters.BoxValue = Box4Data.AmountRC;
					Box4Total = Box4Total + Box4Data.AmountRC;
				Else
					Details.Parameters.BoxValue = "";
				EndIf;
			EndIf;
			SpreadsheetDocument.Join(Details);
		EndIf;

		If Box5Present Then
			Box5Data = Subset1099VT.Find(Catalogs.USTaxCategories1099.Box5, "Category1099");
			If Box5Data = Undefined Then
				Details.Parameters.BoxValue = "";
			Else	
				If Box5Data.AmountRC >= Box5Threshold Then
					Details.Parameters.BoxValue = Box5Data.AmountRC;
					Box5Total = Box5Total + Box5Data.AmountRC;
				Else
					Details.Parameters.BoxValue = "";
				EndIf;
			EndIf;
			SpreadsheetDocument.Join(Details);
		EndIf;

		If Box6Present Then
			Box6Data = Subset1099VT.Find(Catalogs.USTaxCategories1099.Box6, "Category1099");
			If Box6Data = Undefined Then
				Details.Parameters.BoxValue = "";
			Else	
				If Box6Data.AmountRC >= Box6Threshold Then
					Details.Parameters.BoxValue = Box6Data.AmountRC;
					Box6Total = Box6Total + Box6Data.AmountRC;
				Else
					Details.Parameters.BoxValue = "";
				EndIf;
			EndIf;
			SpreadsheetDocument.Join(Details);
		EndIf;
		
		If Box7Present Then
			Box7Data = Subset1099VT.Find(Catalogs.USTaxCategories1099.Box7, "Category1099");
			If Box7Data = Undefined Then
				Details.Parameters.BoxValue = "";
			Else
				If Box7Data.AmountRC >= Box7Threshold Then
					Details.Parameters.BoxValue = Box7Data.AmountRC;
					Box7Total = Box7Total + Box7Data.AmountRC;
				Else
					Details.Parameters.BoxValue = "";
				EndIf;
			EndIf;
			SpreadsheetDocument.Join(Details);
		EndIf;
		
		If Box8Present Then
			Box8Data = Subset1099VT.Find(Catalogs.USTaxCategories1099.Box8, "Category1099");
			If Box8Data = Undefined Then
				Details.Parameters.BoxValue = "";
			Else	
				If Box8Data.AmountRC >= Box8Threshold Then
					Details.Parameters.BoxValue = Box8Data.AmountRC;
					Box8Total = Box8Total + Box8Data.AmountRC;
				Else
					Details.Parameters.BoxValue = "";
				EndIf;
			EndIf;
			SpreadsheetDocument.Join(Details);
		EndIf;

		If Box9Present Then
			Box9Data = Subset1099VT.Find(Catalogs.USTaxCategories1099.Box9, "Category1099");
			If Box9Data = Undefined Then
				Details.Parameters.BoxValue = "";
			Else	
				If Box9Data.AmountRC >= Box9Threshold Then
					Details.Parameters.BoxValue = Box9Data.AmountRC;
					Box9Total = Box9Total + Box9Data.AmountRC;
				Else
					Details.Parameters.BoxValue = "";
				EndIf;
			EndIf;
			SpreadsheetDocument.Join(Details);
		EndIf;

		If Box10Present Then
			Box10Data = Subset1099VT.Find(Catalogs.USTaxCategories1099.Box10, "Category1099");
			If Box10Data = Undefined Then
				Details.Parameters.BoxValue = "";
			Else	
				If Box10Data.AmountRC >= Box10Threshold Then
					Details.Parameters.BoxValue = Box10Data.AmountRC;
					Box10Total = Box10Total + Box10Data.AmountRC;
				Else
					Details.Parameters.BoxValue = "";
				EndIf;
			EndIf;
			SpreadsheetDocument.Join(Details);
		EndIf;

		If Box13Present Then
			Box13Data = Subset1099VT.Find(Catalogs.USTaxCategories1099.Box13, "Category1099");
			If Box13Data = Undefined Then
				Details.Parameters.BoxValue = "";
			Else	
				If Box13Data.AmountRC >= Box13Threshold Then
					Details.Parameters.BoxValue = Box13Data.AmountRC;
					Box13Total = Box13Total + Box13Data.AmountRC;
				Else
					Details.Parameters.BoxValue = "";
				EndIf;
			EndIf;
			SpreadsheetDocument.Join(Details);
		EndIf;

		If Box14Present Then
			Box14Data = Subset1099VT.Find(Catalogs.USTaxCategories1099.Box14, "Category1099");
			If Box14Data = Undefined Then
				Details.Parameters.BoxValue = "";
			Else	
				If Box14Data.AmountRC >= Box14Threshold Then
					Details.Parameters.BoxValue = Box14Data.AmountRC;
					Box14Total = Box14Total + Box14Data.AmountRC;
				Else
					Details.Parameters.BoxValue = "";
				EndIf;
			EndIf;
			SpreadsheetDocument.Join(Details);
		EndIf;
		
	EndDo;
	
	
	// Outputting totals
	
	Totals = Template.GetArea("ColumnValues|Totals");
	
	Totals.Parameters.BoxTotal = "";
	SpreadsheetDocument.Put(Totals);

	If Box1Present Then
		Totals.Parameters.BoxTotal = Box1Total;
		SpreadsheetDocument.Join(Totals);	
	EndIf;	
	
	If Box2Present Then
		Totals.Parameters.BoxTotal = Box2Total;
		SpreadsheetDocument.Join(Totals);	
	EndIf;	

	If Box3Present Then
		Totals.Parameters.BoxTotal = Box3Total;
		SpreadsheetDocument.Join(Totals);	
	EndIf;	

	If Box4Present Then
		Totals.Parameters.BoxTotal = Box4Total;
		SpreadsheetDocument.Join(Totals);	
	EndIf;	

	If Box5Present Then
		Totals.Parameters.BoxTotal = Box5Total;
		SpreadsheetDocument.Join(Totals);	
	EndIf;	

	If Box6Present Then
		Totals.Parameters.BoxTotal = Box6Total;
		SpreadsheetDocument.Join(Totals);	
	EndIf;	
	
	If Box7Present Then
		Totals.Parameters.BoxTotal = Box7Total;
		SpreadsheetDocument.Join(Totals);	
	EndIf;	

	If Box8Present Then
		Totals.Parameters.BoxTotal = Box8Total;
		SpreadsheetDocument.Join(Totals);	
	EndIf;	

	If Box9Present Then
		Totals.Parameters.BoxTotal = Box9Total;
		SpreadsheetDocument.Join(Totals);	
	EndIf;	

	If Box10Present Then
		Totals.Parameters.BoxTotal = Box10Total;
		SpreadsheetDocument.Join(Totals);	
	EndIf;	

	If Box13Present Then
		Totals.Parameters.BoxTotal = Box13Total;
		SpreadsheetDocument.Join(Totals);	
	EndIf;	

	If Box14Present Then
		Totals.Parameters.BoxTotal = Box14Total;
		SpreadsheetDocument.Join(Totals);	
	EndIf;	
	
	// Return result
	
	Return SpreadSheetDocument;
	
EndFunction