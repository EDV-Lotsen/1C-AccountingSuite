Function inoutVendor1099(jsonin) Export
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	Try 
		mode = Number(ParsedJSON.mode);
	Except
		mode = 1;
	EndTry;
	
	If mode <> 1 AND mode <> 2 AND mode <> 3 Then  //1 - 1099 vendors that meet threshold
		mode = 1;               				 //2 - 1099 below threshold
	EndIf;										//3 - Non-1099 vendors
 	
	Try 
		year = Number(ParsedJSON.year);
	Except
		errorMessage = New Map();
		strMessage = "[tax_year] : please enter a year";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndTry;
	
	If year = 2013 Then
		start = '20130101';
		end = '20131231';
	Elsif year = 2014 Then
		start = '20140101';
		end = '20141231';
	Else
		errorMessage = New Map();
		strMessage = "[tax_year] : out of accepted range";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndIf;
	
	ReportMap = New Map();
	ReportMap.Insert("report", "Vendors 1099");
		
	VendorList = New Query("SELECT
	                      |	Categories.Ref AS Ref,
	                      |	Categories.Threshold AS Threshold,
	                      |	CASE
	                      |		WHEN Categories.AmountSign
	                      |			THEN -1
	                      |		ELSE 1
	                      |	END AS AmountSign
	                      |INTO Categories
	                      |FROM
	                      |	Catalog.USTaxCategories1099 AS Categories
	                      |;
	                      |
	                      |////////////////////////////////////////////////////////////////////////////////
	                      |SELECT
	                      |	CashFlowData.Account.Category1099 AS Category,
	                      |	CashFlowData.Company AS Vendor,
	                      |	Categories.Threshold AS Threshold,
	                      |	SUM(Categories.AmountSign * CashFlowData.AmountRC) AS Turnover
	                      |INTO Turnovers
	                      |FROM
	                      |	AccumulationRegister.CashFlowData AS CashFlowData
	                      |		LEFT JOIN Categories AS Categories
	                      |		ON CashFlowData.Account.Category1099 = Categories.Ref
	                      |WHERE
	                      |	CashFlowData.Period >= &BeginOfPeriod
	                      |	AND CashFlowData.Period <= &EndOfPeriod
	                      |	AND NOT CashFlowData.Account.Category1099 = VALUE(Catalog.USTaxCategories1099.EmptyRef)
	                      |	AND CashFlowData.RecordType = VALUE(AccumulationRecordType.Expense)
	                      |	AND CashFlowData.PaymentMethod.ExcludeFrom1099 = FALSE
	                      |
	                      |GROUP BY
	                      |	CashFlowData.Account.Category1099,
	                      |	CashFlowData.Company,
	                      |	Categories.Threshold
	                      |;
	                      |
	                      |////////////////////////////////////////////////////////////////////////////////
	                      |SELECT
	                      |	Turnovers.Vendor AS Vendor,
	                      |	MAX(Turnovers.Turnover - Turnovers.Threshold) AS ThresholdOvercome
	                      |INTO VendorStatuses
	                      |FROM
	                      |	Turnovers AS Turnovers
	                      |
	                      |GROUP BY
	                      |	Turnovers.Vendor
	                      |;
	                      |
	                      |////////////////////////////////////////////////////////////////////////////////
	                      |SELECT
	                      |	CashFlowData.Account.Category1099 AS Category,
	                      |	CashFlowData.Company AS Vendor,
	                      |	CashFlowData.Document AS Document,
	                      |	CashFlowData.PaymentMethod.ExcludeFrom1099 AS PaymentExcluded,
	                      |	CASE
	                      |		WHEN Turnovers.Turnover - Turnovers.Threshold IS NULL 
	                      |			THEN FALSE
	                      |		WHEN Turnovers.Turnover - Turnovers.Threshold >= 0
	                      |			THEN TRUE
	                      |		ELSE FALSE
	                      |	END AS ExceedsThreshold,
	                      |	Categories.AmountSign * CashFlowData.AmountRC AS Amount
	                      |INTO Amounts
	                      |FROM
	                      |	AccumulationRegister.CashFlowData AS CashFlowData
	                      |		LEFT JOIN VendorStatuses AS VendorStatuses
	                      |		ON (VendorStatuses.Vendor = CashFlowData.Company)
	                      |		LEFT JOIN Turnovers AS Turnovers
	                      |		ON (Turnovers.Category = CashFlowData.Account.Category1099)
	                      |			AND (Turnovers.Vendor = CashFlowData.Company)
	                      |		LEFT JOIN Categories AS Categories
	                      |		ON (Categories.Ref = CashFlowData.Account.Category1099)
	                      |WHERE
	                      |	CashFlowData.Period >= &BeginOfPeriod
	                      |	AND CashFlowData.Period <= &EndOfPeriod
	                      |	AND NOT CashFlowData.Account.Category1099 = VALUE(Catalog.USTaxCategories1099.EmptyRef)
	                      |	AND CashFlowData.RecordType = VALUE(AccumulationRecordType.Expense)
	                      |	AND CASE
	                      |			WHEN NOT CashFlowData.Company.Vendor1099
	                      |				THEN 3
	                      |			WHEN VendorStatuses.ThresholdOvercome >= 0
	                      |				THEN 1
	                      |			ELSE 2
	                      |		END = &Mode
	                      |;
	                      |
	                      |////////////////////////////////////////////////////////////////////////////////
	                      |SELECT
	                      |	TRUE AS PaymentExcluded
	                      |INTO PaymentStatuses
	                      |
	                      |UNION ALL
	                      |
	                      |SELECT
	                      |	FALSE
	                      |;
	                      |
	                      |////////////////////////////////////////////////////////////////////////////////
	                      |SELECT DISTINCT
	                      |	Vendors.Ref AS Ref,
	                      |	Vendors.Description AS Name,
	                      |	Vendors.FederalIDType AS FederalIdType,
	                      |	Vendors.FederalIDType.Order + 1 AS FederalIdTypeNo,
	                      |	Vendors.USTaxID AS FederalIdNo,
	                      |	Vendors.FullName AS FullName,
	                      |	Addresses.AddressLine1 + CASE
	                      |		WHEN Addresses.AddressLine2 = """"
	                      |			THEN """"
	                      |		ELSE "", "" + Addresses.AddressLine2
	                      |	END + CASE
	                      |		WHEN Addresses.AddressLine3 = """"
	                      |			THEN """"
	                      |		ELSE "", "" + Addresses.AddressLine3
	                      |	END AS Address,
	                      |	Addresses.City AS City,
	                      |	Addresses.State AS State,
	                      |	Addresses.State.Code AS StateCode,
	                      |	Addresses.ZIP AS Zip,
	                      |	Addresses.Email AS Email
	                      |INTO Vendors
	                      |FROM
	                      |	Amounts AS Amounts
	                      |		LEFT JOIN Catalog.Companies AS Vendors
	                      |		ON (Vendors.Ref = Amounts.Vendor)
	                      |		LEFT JOIN Catalog.Addresses AS Addresses
	                      |		ON (Addresses.Owner = Vendors.Ref)
	                      |			AND (Addresses.DefaultBilling)
	                      |;
	                      |
	                      |////////////////////////////////////////////////////////////////////////////////
	                      |SELECT DISTINCT
	                      |	Vendors.Ref AS Vendor
	                      |{SELECT
	                      |	Amounts.Category.*,
	                      |	Vendor.*,
	                      |	Amounts.Document.*,
	                      |	Amounts.Amount}
	                      |FROM
	                      |	Catalog.USTaxCategories1099 AS Boxes
	                      |		LEFT JOIN PaymentStatuses AS PaymentStatuses
	                      |		ON (TRUE)
	                      |		LEFT JOIN Amounts AS Amounts
	                      |		ON (Amounts.Category = Boxes.Ref)
	                      |			AND (Amounts.PaymentExcluded = PaymentStatuses.PaymentExcluded)
	                      |		LEFT JOIN Vendors AS Vendors
	                      |		ON (Vendors.Ref = Amounts.Vendor)
	                      |WHERE
	                      |	Vendors.Ref <> &Ref
	                      |{WHERE
	                      |	Boxes.Ref.* AS Category,
	                      |	Amounts.Vendor.* AS Vendor,
	                      |	Amounts.Document.* AS Document,
	                      |	Amounts.Amount AS Amount}");
						  					  	
	VendorList.SetParameter("BeginOfPeriod", start);
	VendorList.SetParameter("EndOfPeriod", end );
	VendorList.SetParameter("Mode", mode);
	VendorList.SetParameter("Ref",Catalogs.Companies.EmptyRef()); 
	VendorResults = VendorList.Execute().Unload();
	
	DataMap = New Map();
	DataMap.Insert("tax_year", year);
	If mode = 1 Then
		modestring = "1099 vendors that meet threshold";
	ElsIf mode = 2 Then
		modestring = "1099 below threshold";
	ElsIf mode = 3 Then
		modestring = "Non-1099 vendors";
	Else
		modestring = "nomode";
	EndIf;
	
	DataMap.Insert("show", modestring);
	
	VendorArray = New Array();
	
	OverallTotal = 0;
	
	For each vendor in VendorResults Do
		
		VendorRef = vendor.Vendor;
		VendorMap = New Map();
		VendorMap.Insert("vendor", String(VendorRef));
		VendorMap.Insert("federal_id_type",String(VendorRef.FederalIDType));
		VendorMap.Insert("federal_id_num", VendorRef.USTaxID);
		VendorMap.Insert("secondary_name",VendorRef.FullName);
		AddrQuery = New Query("SELECT
		                      |	Addresses.Ref
		                      |FROM
		                      |	Catalog.Addresses AS Addresses
		                      |WHERE
		                      |	Addresses.Owner = &Owner
		                      |	AND Addresses.DefaultBilling = TRUE");
		AddrQuery.SetParameter("Owner", VendorRef);
		AddrResult = AddrQuery.Execute().Unload();
		
		VendorMap.Insert("address", AddrResult[0].Ref.AddressLine1);
		VendorMap.Insert("city", AddrResult[0].Ref.City);
		VendorMap.Insert("state", AddrResult[0].Ref.State);
		VendorMap.Insert("zip", AddrResult[0].Ref.ZIP);
		VendorMap.Insert("email", AddrResult[0].Ref.Email);
		
		BoxList = New Query("SELECT
		                    |	Categories.Ref AS Ref,
		                    |	Categories.Threshold AS Threshold,
		                    |	CASE
		                    |		WHEN Categories.AmountSign
		                    |			THEN -1
		                    |		ELSE 1
		                    |	END AS AmountSign
		                    |INTO Categories
		                    |FROM
		                    |	Catalog.USTaxCategories1099 AS Categories
		                    |;
		                    |
		                    |////////////////////////////////////////////////////////////////////////////////
		                    |SELECT
		                    |	CashFlowData.Account.Category1099 AS Category,
		                    |	CashFlowData.Company AS Vendor,
		                    |	Categories.Threshold AS Threshold,
		                    |	SUM(Categories.AmountSign * CashFlowData.AmountRC) AS Turnover
		                    |INTO Turnovers
		                    |FROM
		                    |	AccumulationRegister.CashFlowData AS CashFlowData
		                    |		LEFT JOIN Categories AS Categories
		                    |		ON CashFlowData.Account.Category1099 = Categories.Ref
		                    |WHERE
		                    |	CashFlowData.Period >= &BeginOfPeriod
		                    |	AND CashFlowData.Period <= &EndOfPeriod
		                    |	AND NOT CashFlowData.Account.Category1099 = VALUE(Catalog.USTaxCategories1099.EmptyRef)
		                    |	AND CashFlowData.RecordType = VALUE(AccumulationRecordType.Expense)
		                    |	AND CashFlowData.PaymentMethod.ExcludeFrom1099 = FALSE
		                    |
		                    |GROUP BY
		                    |	CashFlowData.Account.Category1099,
		                    |	CashFlowData.Company,
		                    |	Categories.Threshold
		                    |;
		                    |
		                    |////////////////////////////////////////////////////////////////////////////////
		                    |SELECT
		                    |	Turnovers.Vendor AS Vendor,
		                    |	MAX(Turnovers.Turnover - Turnovers.Threshold) AS ThresholdOvercome
		                    |INTO VendorStatuses
		                    |FROM
		                    |	Turnovers AS Turnovers
		                    |
		                    |GROUP BY
		                    |	Turnovers.Vendor
		                    |;
		                    |
		                    |////////////////////////////////////////////////////////////////////////////////
		                    |SELECT
		                    |	CashFlowData.Account.Category1099 AS Category,
		                    |	CashFlowData.Company AS Vendor,
		                    |	CashFlowData.Document AS Document,
		                    |	CashFlowData.PaymentMethod.ExcludeFrom1099 AS PaymentExcluded,
		                    |	CASE
		                    |		WHEN Turnovers.Turnover - Turnovers.Threshold IS NULL 
		                    |			THEN FALSE
		                    |		WHEN Turnovers.Turnover - Turnovers.Threshold >= 0
		                    |			THEN TRUE
		                    |		ELSE FALSE
		                    |	END AS ExceedsThreshold,
		                    |	Categories.AmountSign * CashFlowData.AmountRC AS Amount
		                    |INTO Amounts
		                    |FROM
		                    |	AccumulationRegister.CashFlowData AS CashFlowData
		                    |		LEFT JOIN VendorStatuses AS VendorStatuses
		                    |		ON (VendorStatuses.Vendor = CashFlowData.Company)
		                    |		LEFT JOIN Turnovers AS Turnovers
		                    |		ON (Turnovers.Category = CashFlowData.Account.Category1099)
		                    |			AND (Turnovers.Vendor = CashFlowData.Company)
		                    |		LEFT JOIN Categories AS Categories
		                    |		ON (Categories.Ref = CashFlowData.Account.Category1099)
		                    |WHERE
		                    |	CashFlowData.Period >= &BeginOfPeriod
		                    |	AND CashFlowData.Period <= &EndOfPeriod
		                    |	AND NOT CashFlowData.Account.Category1099 = VALUE(Catalog.USTaxCategories1099.EmptyRef)
		                    |	AND CashFlowData.RecordType = VALUE(AccumulationRecordType.Expense)
		                    |	AND CASE
		                    |			WHEN NOT CashFlowData.Company.Vendor1099
		                    |				THEN 3
		                    |			WHEN VendorStatuses.ThresholdOvercome >= 0
		                    |				THEN 1
		                    |			ELSE 2
		                    |		END = &Mode
		                    |;
		                    |
		                    |////////////////////////////////////////////////////////////////////////////////
		                    |SELECT
		                    |	TRUE AS PaymentExcluded
		                    |INTO PaymentStatuses
		                    |
		                    |UNION ALL
		                    |
		                    |SELECT
		                    |	FALSE
		                    |;
		                    |
		                    |////////////////////////////////////////////////////////////////////////////////
		                    |SELECT DISTINCT
		                    |	Vendors.Ref AS Ref,
		                    |	Vendors.Description AS Name,
		                    |	Vendors.FederalIDType AS FederalIdType,
		                    |	Vendors.FederalIDType.Order + 1 AS FederalIdTypeNo,
		                    |	Vendors.USTaxID AS FederalIdNo,
		                    |	Vendors.FullName AS FullName,
		                    |	Addresses.AddressLine1 + CASE
		                    |		WHEN Addresses.AddressLine2 = """"
		                    |			THEN """"
		                    |		ELSE "", "" + Addresses.AddressLine2
		                    |	END + CASE
		                    |		WHEN Addresses.AddressLine3 = """"
		                    |			THEN """"
		                    |		ELSE "", "" + Addresses.AddressLine3
		                    |	END AS Address,
		                    |	Addresses.City AS City,
		                    |	Addresses.State AS State,
		                    |	Addresses.State.Code AS StateCode,
		                    |	Addresses.ZIP AS Zip,
		                    |	Addresses.Email AS Email
		                    |INTO Vendors
		                    |FROM
		                    |	Amounts AS Amounts
		                    |		LEFT JOIN Catalog.Companies AS Vendors
		                    |		ON (Vendors.Ref = Amounts.Vendor)
		                    |		LEFT JOIN Catalog.Addresses AS Addresses
		                    |		ON (Addresses.Owner = Vendors.Ref)
		                    |			AND (Addresses.DefaultBilling)
		                    |;
		                    |
		                    |////////////////////////////////////////////////////////////////////////////////
		                    |SELECT
		                    |	Boxes.Ref AS Category,
		                    |	Boxes.Code AS BoxNum,
		                    |	Boxes.Threshold AS Threshold,
		                    |	PaymentStatuses.PaymentExcluded AS PaymentExcluded,
		                    |	Vendors.Ref AS Vendor,
		                    |	Vendors.Name AS VendorName,
		                    |	Vendors.FederalIdType AS VendorFederalIdType,
		                    |	Vendors.FederalIdTypeNo AS VendorFederalIdTypeNo,
		                    |	Vendors.FederalIdNo AS VendorFederalIdNo,
		                    |	Vendors.FullName AS VendorFullName,
		                    |	Vendors.Address AS VendorAddress,
		                    |	Vendors.City AS VendorCity,
		                    |	Vendors.State AS VendorState,
		                    |	Vendors.StateCode AS VendorStateCode,
		                    |	Vendors.Zip AS VendorZip,
		                    |	Vendors.Email AS VendorEmail,
		                    |	Amounts.Document AS Document,
		                    |	Amounts.ExceedsThreshold AS ExceedsThreshold,
		                    |	Amounts.Amount AS Amount
		                    |{SELECT
		                    |	Category.*,
		                    |	Vendor.*,
		                    |	Document.*,
		                    |	Amount}
		                    |FROM
		                    |	Catalog.USTaxCategories1099 AS Boxes
		                    |		LEFT JOIN PaymentStatuses AS PaymentStatuses
		                    |		ON (TRUE)
		                    |		LEFT JOIN Amounts AS Amounts
		                    |		ON (Amounts.Category = Boxes.Ref)
		                    |			AND (Amounts.PaymentExcluded = PaymentStatuses.PaymentExcluded)
		                    |		LEFT JOIN Vendors AS Vendors
		                    |		ON (Vendors.Ref = Amounts.Vendor)
		                    |WHERE
		                    |	Vendors.Ref = &Ref
		                    |{WHERE
		                    |	Boxes.Ref.* AS Category,
		                    |	Amounts.Vendor.* AS Vendor,
		                    |	Amounts.Document.* AS Document,
		                    |	Amounts.Amount AS Amount}");
						  					  	
		BoxList.SetParameter("BeginOfPeriod", start);
		BoxList.SetParameter("EndOfPeriod", end );
		BoxList.SetParameter("Mode", mode);
		BoxList.SetParameter("Ref",VendorRef);
		BoxList.SetParameter("Ref2", Catalogs.Companies.EmptyRef());
		BoxResult = BoxList.Execute().Unload();
		
		BoxesArray = New Array;
		VendorTotal = 0;
		For i = 1 to 14 Do
			If i <> 11 AND i <> 12 Then
				Box1Map = New Map;
				amount = 0;
				For each box in BoxResult Do
					If box.BoxNum = i Then
						amount = amount + box.Amount;
					EndIf;
				EndDo;
				Box1Map.Insert("amount", amount);
				VendorTotal = VendorTotal + amount;
				
				If i = 1 OR i = 3 OR i = 6 OR i = 7 OR i = 10 OR i = 14 Then
					threshold_amount = 600;
				ElsIf i = 8 OR i = 2 Then
					threshold_amount = 10;
				ElsIf i = 9 Then
					threshold_amount = 5000;
				Else
					threshold_amount = 0;
				EndIf;
				 
				Box1Map.Insert("threshold", threshold_amount);
				Box1Map.Insert("box_num", i );
				BoxesArray.Add(Box1Map);
			EndIf;
			
		EndDo;
		VendorMap.Insert("total", VendorTotal);
		OverallTotal = OverallTotal + VendorTotal;
		
		VendorMap.Insert("boxes", BoxesArray);

		VendorArray.Add(VendorMap);
		
	EndDo;
	
	DataMap.Insert("overall_total", OverallTotal);
	
	TotalArray = New Array();
	Try
		For j = 0 to BoxesArray.Count()-1 Do
			BoxTotalMap = New Map();
			BoxTotal = 0;
			boxtotal_num = 0;
			For each vndr in VendorArray Do
				boxes_array = vndr.Get("boxes");
				boxtotal_num = boxes_array[j].Get("box_num");
				thisBox = boxes_array[j].Get("amount");
				BoxTotal = BoxTotal + thisBox;
			EndDo;
			BoxTotalMap.Insert("box_num",boxtotal_num);
			BoxTotalMap.Insert("total", BoxTotal);
			TotalArray.Add(BoxTotalMap);
		EndDo;
	Except
		errorMessage = New Map();
		strMessage = "no data with these parameters";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndTry;
	
	DataMap.Insert("box_totals", TotalArray);
	
	DataMap.Insert("vendors", VendorArray);
	
	ReportMap.Insert("data", DataMap);
	
	FinalJSON = InternetConnectionClientServer.EncodeJSON(ReportMap);
	
	Return FinalJSON;	
	
EndFunction
	

Function inoutCompaniesCreate(jsonin) Export
		
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	
	alreadyExists = True;
	
	Try
		Query = New Query("SELECT
		                  |	Companies.Ref
		                  |FROM
		                  |	Catalog.Companies AS Companies
		                  |WHERE
		                  |	Companies.Description = &desc");
		Query.SetParameter("desc", ParsedJSON.company_name);
		QueryResult = Query.Execute();
	
		If QueryResult.IsEmpty() Then
			alreadyExists = False;
		EndIf;
	Except
		errorMessage = New Map();
		strMessage = " [company_name] : This is a required field ";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndTry;
	
	If alreadyExists = False Then
		
		NewCompany = Catalogs.Companies.CreateItem();
	
		NewCompany.Description = ParsedJSON.company_name;
				
		Try companyType = StrReplace(Lower(ParsedJSON.company_type), " ", ""); Except companyType = Undefined EndTry;
		If (NOT companyType = Undefined) AND (NOT companyType = "") Then
			If companyType = "customer" Then
				NewCompany.Customer = True;
			ElsIf companyType = "vendor" Then
				NewCompany.Vendor = True;
			ElsIf companyType = "customer+vendor" OR companyType = "vendor+customer" Then
				NewCompany.Customer = True;
				NewCompany.Vendor = True;
			Else
				errorMessage = New Map();
				strMessage = " [company_type] : Please enter customer, vendor, or customer+vendor ";
				errorMessage.Insert("message", strMessage);
				errorMessage.Insert("status", "error"); 
				errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
				return errorJSON;
			EndIf;
		Else 
			NewCompany.Customer = True;
		EndIf;
				
		NewCompany.DefaultCurrency = Constants.DefaultCurrency.Get();
		NewCompany.Terms = Catalogs.PaymentTerms.Net30;
		
		Try NewCompany.Website = ParsedJSON.website; Except EndTry;
		Try NewCompany.Notes  = ParsedJSON.notes; Except EndTry;
		
		Try pl = ParsedJSON.price_level Except pl = Undefined EndTry;
		If (NOT pl = Undefined) AND (NOT pl = "") Then
			plQuery = new Query("SELECT
			                    |	PriceLevels.Ref
			                    |FROM
			                    |	Catalog.PriceLevels AS PriceLevels
			                    |WHERE
			                    |	PriceLevels.Description = &Description");
							   
			plQuery.SetParameter("Description", pl);
			plResult = plQuery.Execute();
			If plResult.IsEmpty() Then
				// pricelevel is new
				Newpl = Catalogs.PriceLevels.CreateItem();
				Newpl.Description = pl;
				Newpl.Write();
				NewCompany.PriceLevel = Newpl.Ref;
			Else
				//pricelevel exists
				pricelevel = plResult.Unload();
				NewCompany.PriceLevel = pricelevel[0].Ref;
			EndIf;
		EndIf;
		
		//salesperson
		Try sp = ParsedJSON.sales_person Except  sp = Undefined EndTry;
		If (NOT sp = Undefined) AND (NOT sp = "") Then
			spQuery = new Query("SELECT
			                    |	SalesPeople.Ref
			                    |FROM
			                    |	Catalog.SalesPeople AS SalesPeople
			                    |WHERE
			                    |	SalesPeople.Description = &Description");
							   
			spQuery.SetParameter("Description", sp);
			spResult = spQuery.Execute();
			If spResult.IsEmpty() Then
				// salesperson is new
				Newsp = Catalogs.SalesPeople.CreateItem();
				Newsp.Description = sp;
				Newsp.Write();
				NewCompany.SalesPerson = Newsp.Ref;
			Else
				//salesperosn exists
				salesperson = spResult.Unload();
				NewCompany.SalesPerson = salesperson[0].Ref;
			EndIf;
		EndIf;

		Try NewCompany.CF1String = ParsedJSON.cf1_string; Except EndTry;
		Try NewCompany.CF2String = ParsedJSON.cf2_string; Except EndTry;
		Try NewCompany.CF3String = ParsedJSON.cf3_string; Except EndTry;
		Try NewCompany.CF4String = ParsedJSON.cf4_string; Except EndTry;
		Try NewCompany.CF5String = ParsedJSON.cf5_string; Except EndTry;
		Try NewCompany.CF1Num = ParsedJSON.cf1_num; Except EndTry;
		Try NewCompany.CF2Num = ParsedJSON.cf2_num; Except EndTry;
		Try NewCompany.CF3Num = ParsedJSON.cf3_num; Except EndTry;
		Try NewCompany.CF4Num = ParsedJSON.cf4_num; Except EndTry;
		Try NewCompany.CF5Num = ParsedJSON.cf5_num; Except EndTry;
		
		Try
		    // check address stuff before writing
			DataAddresses = ParsedJSON.lines.addresses;
			
			ArrayLines = DataAddresses.Count();
			
			For i = 0 To ArrayLines -1 Do
				Try
					If i > 0 Then
						For j = 0 to i-1 Do
							If DataAddresses[j].address_id = DataAddresses[i].address_id Then
								errorMessage = New Map();
								strMessage = " [address_id(" + (i+1) +  ")] : Address ID must be unique. Cannot enter identical address IDs. ";
								errorMessage.Insert("message", strMessage);
								errorMessage.Insert("status", "error"); 
								errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
								return errorJSON;
							EndIf;
						EndDo;
					EndIf;
				Except
				EndTry;
							
			EndDo;
			
		Except
			NewCompany.Write();
			// add primary address cus no address specified
			AddressLine = Catalogs.Addresses.CreateItem();
			AddressLine.Owner = NewCompany.Ref;
			AddressLine.DefaultBilling = True;
			AddressLine.DefaultShipping = True;
			AddressLine.Description = "Primary";
			AddressLine.Write();
			Return InternetConnectionClientServer.EncodeJSON(GeneralFunctions.ReturnCompanyObjectMap(NewCompany));
		EndTry;
		
	Else
		
		CompanyData = New Map();
		CompanyData.Insert("message", " [company_name] : The company already exists");
		CompanyData.Insert("status", "error");
		existingCompany = QueryResult.Unload();
		CompanyData.Insert("api_code", String(existingCompany[0].Ref.UUID()));
		
		jsonout = InternetConnectionClientServer.EncodeJSON(CompanyData);
		return jsonout;
		
	EndIf;
	
	Try
	    NewCompany.Write();
		DataAddresses = ParsedJSON.lines.addresses;
		
		ArrayLines = DataAddresses.Count();
		For i = 0 To ArrayLines -1 Do
			
			AddressLine = Catalogs.Addresses.CreateItem();

			If DataAddresses[i].address_id <> "" AND DataAddresses[i].address_id <> Undefined Then
				AddressLine.Description = DataAddresses[i].address_id;
			Else
				errorMessage = New Map();
				strMessage = " [address_id(" + (i+1) +  ")] : Address ID is a required field ";
				errorMessage.Insert("message", strMessage);
				errorMessage.Insert("status", "error"); 
				errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
				return errorJSON;
			EndIf;
			
			//salutation
			Try
				AddressLine.Salutation = DataAddresses[i].salutation;
			Except
			EndTry;
			
			Try
				FirstName = DataAddresses[i].first_name;
				AddressLine.FirstName = FirstName;
			Except
			EndTry;
			
			Try
				MiddleName = DataAddresses[i].middle_name;
				AddressLine.MiddleName = MiddleName;
			Except
			EndTry;
			
			Try
				LastName = DataAddresses[i].last_name;
				AddressLine.LastName = LastName;
			Except
			EndTry;
			
			// suffix
			Try
				AddressLine.Suffix = DataAddresses[i].suffix;
			Except
			EndTry;
				
			Try
				Phone = DataAddresses[i].phone;
				AddressLine.Phone = Phone;
			Except
			EndTry;
			
			Try
				AddressLine.Cell = DataAddresses[i].cell;
			Except
			EndTry;
			Try
				AddressLine.Fax = DataAddresses[i].fax;
			Except
			EndTry;
			Try
				AddressLine.JobTitle = DataAddresses[i].job_title;
			Except
			EndTry;
			Try
				AddressLine.Notes = DataAddresses[i].notes;
			Except
			EndTry;
			
			//salesperson
			Try sp = DataAddresses[i].sales_person Except  sp = Undefined EndTry;
			If (NOT sp = Undefined) AND (NOT sp = "") Then
				spQuery = new Query("SELECT
				                    |	SalesPeople.Ref
				                    |FROM
				                    |	Catalog.SalesPeople AS SalesPeople
				                    |WHERE
				                    |	SalesPeople.Description = &Description");
								   
				spQuery.SetParameter("Description", sp);
				spResult = spQuery.Execute();
				If spResult.IsEmpty() Then
					// salesperson is new
					Newsp = Catalogs.SalesPeople.CreateItem();
					Newsp.Description = sp;
					Newsp.Write();
					AddressLine.SalesPerson = Newsp.Ref;
				Else
					//salesperosn exists
					salesperson = spResult.Unload();
					AddressLine.SalesPerson = salesperson[0].Ref;
				EndIf;
			EndIf;
			
			Try
				Email = DataAddresses[i].email;
				AddressLine.Email = Email;
			Except
			EndTry;
			
			Try
				AddressLine1 = DataAddresses[i].address_line1;
				AddressLine.AddressLine1 = AddressLine1;
			Except
			EndTry;
			
			Try
				AddressLine2 = DataAddresses[i].address_line2;
				AddressLine.AddressLine2 = AddressLine2;
			Except
			EndTry;
			
			Try
				AddressLine3 = DataAddresses[i].address_line3;
				AddressLine.AddressLine3 = AddressLine3;
			Except
			EndTry;
			
			Try
				City = DataAddresses[i].city;
				AddressLine.City = City;
			Except
			EndTry;

			Try
				State = DataAddresses[i].state;
				AddressLine.State = Catalogs.States.FindByCode(Upper(State));
			Except
				Try
					State = DataAddresses[i].state;
					AddressLine.State = Catalogs.States.FindByDescription(Title(State));
				Except
				EndTry;
			EndTry;
			
			Try
				Country = DataAddresses[i].country;
				AddressLine.Country = Catalogs.Countries.FindByCode(Upper(Country));
			Except
				Try
					Country = DataAddresses[i].country;
					AddressLine.Country = Catalogs.Countries.FindByDescription(Title(Country));
				Except
				EndTry;
			EndTry;
			
			Try
				ZIP = DataAddresses[i].zip;
				AddressLine.ZIP = ZIP;
			Except
			EndTry;
			
			Try
				If i = 0 Then
					AddressLine.DefaultBilling = True;
				Else
					Try DefaultBilling = DataAddresses[i].default_billing;  
					Except 
						DefaultBilling = False;
					EndTry;
					If DefaultBilling = True Then
						addrQuery = New Query("SELECT
						                      |	Addresses.Ref
						                      |FROM
						                      |	Catalog.Addresses AS Addresses
						                      |WHERE
						                      |	Addresses.Owner = &Ref
						                      |	AND Addresses.DefaultBilling = TRUE");
						addrQuery.SetParameter("Ref", NewCompany.Ref);
						results = addrQuery.Execute();
						Dataset = results.Unload();
						For i = 0 to Dataset.Count()-1 Do
							addrRef = Dataset[i].Ref;
							addrObj = addrRef.GetObject();
							addrObj.DefaultBilling = False;
							addrObj.Write();	
						EndDo;
					EndIf;
					AddressLine.DefaultBilling = DefaultBilling;
				EndIf;
				
			Except
			EndTry;
			
			Try
				If i = 0 Then
					AddressLine.Defaultshipping = True;
				Else
					Try Defaultshipping = DataAddresses[i].default_shipping;  
					Except 
						Defaultshipping = False;	
					EndTry;
					If Defaultshipping = True Then
						addrQuery = New Query("SELECT
						                      |	Addresses.Ref
						                      |FROM
						                      |	Catalog.Addresses AS Addresses
						                      |WHERE
						                      |	Addresses.Owner = &Ref
						                      |	AND Addresses.DefaultShipping = TRUE");
						addrQuery.SetParameter("Ref", NewCompany.Ref);
						results = addrQuery.Execute();
						Dataset = results.Unload();
						For i = 0 to Dataset.Count()-1 Do
							addrRef = Dataset[i].Ref;
							addrObj = addrRef.GetObject();
							addrObj.DefaultShipping = False;
							addrObj.Write();	
						EndDo;
					EndIf;
					AddressLine.DefaultShipping = DefaultShipping;
				EndIf;	
			Except
			EndTry;
			
			AddressLine.Owner = NewCompany.Ref;			
			AddressLine.Write();
			
		EndDo;

	Except
		    NewCompany.Write();
			AddressLine = Catalogs.Addresses.CreateItem();
			AddressLine.Owner = NewCompany.Ref;
			AddressLine.DefaultBilling = True;
			AddressLine.DefaultShipping = True;
			AddressLine.Description = "Primary";
			AddressLine.Write();	
	EndTry;
			
	Return InternetConnectionClientServer.EncodeJSON(GeneralFunctions.ReturnCompanyObjectMap(NewCompany));
	
	
EndFunction
		
Function inoutCompaniesUpdate(jsonin, object_code) Export
	
	CompanyCodeJSON = InternetConnectionClientServer.DecodeJSON(object_code);
	
	Try api_code = CompanyCodeJSON.object_code Except api_code = Undefined EndTry;
	If api_code = Undefined OR api_code = "" Then
		errorMessage = New Map();
		strMessage = " [api_code] : Missing the company ID# ";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndIf;
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	
	Try	
		UpdatedCompany = Catalogs.Companies.getref(New UUID(api_code));
	Except
		errorMessage = New Map();
		strMessage = " [api_code] : The company does not exist. Double check that the ID# is correct. ";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndTry;
	
	companyQuery = New Query("SELECT
	                         |	Companies.Ref AS Ref1
	                         |FROM
	                         |	Catalog.Companies AS Companies
	                         |WHERE
	                         |	Companies.Ref = &com");
	companyQuery.SetParameter("com", UpdatedCompany);
	companyresult = companyQuery.Execute();
	If companyresult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = " [api_code] : The item does not exist. Double check that the ID# is correct. ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
	EndIf;
		
	UpdatedCompanyObj = UpdatedCompany.GetObject();
		
	Try
        companyName = ParsedJSON.company_name;
		Query = New Query("SELECT
		                  |	Companies.Ref
		                  |FROM
		                  |	Catalog.Companies AS Companies
		                  |WHERE
		                  |	Companies.Description = &desc");
		Query.SetParameter("desc", companyName);
		QueryResult = Query.Execute();
	
		If QueryResult.IsEmpty() Then
			UpdatedCompanyObj.Description = companyName;
		Else
			CompanyData = New Map();
			CompanyData.Insert("message", " [company_name] : The company already exists");
			CompanyData.Insert("status", "error");
			existingCompany = QueryResult.Unload();
			CompanyData.Insert("api_code", String(existingCompany[0].Ref.UUID()));
		
			jsonout = InternetConnectionClientServer.EncodeJSON(CompanyData);
			return jsonout;
		EndIf;
	Except
	EndTry;
	
	Try
		companyType = strReplace(lower(ParsedJSON.company_type), " ", "");
	Except
		companyType = Undefined;
	EndTry;
	If NOT companyType = Undefined Then
		If companyType = "customer+vendor" Then
			UpdatedCompanyObj.Customer = TRUE;
			UpdatedCompanyObj.Vendor = TRUE;
		ElsIf companyType = "vendor" AND UpdatedCompanyObj.Customer = TRUE Then
			UpdatedCompanyObj.Vendor = TRUE;
		ElsIf companyType = "customer" AND UpdatedCompanyObj.Vendor = TRUE Then
			UpdatedCompanyObj.Customer = TRUE;
		Else
	
		EndIf;
	EndIf;
	
	Try UpdatedCompanyObj.Website = ParsedJSON.website; Except EndTry;
	
	Try pl = ParsedJSON.price_level Except pl = Undefined EndTry;
	If (NOT pl = Undefined) AND (NOT pl = "") Then
		plQuery = new Query("SELECT
		                    |	PriceLevels.Ref
		                    |FROM
		                    |	Catalog.PriceLevels AS PriceLevels
		                    |WHERE
		                    |	PriceLevels.Description = &Description");
						   
		plQuery.SetParameter("Description", pl);
		plResult = plQuery.Execute();
		If plResult.IsEmpty() Then
			// pricelevel is new
			Newpl = Catalogs.PriceLevels.CreateItem();
			Newpl.Description = pl;
			Newpl.Write();
			UpdatedCompanyObj.PriceLevel = Newpl.Ref;
		Else
			//pricelevel exists
			pricelevel = plResult.Unload();
			UpdatedCompanyObj.PriceLevel = pricelevel[0].Ref;
		EndIf;               
	EndIf;
	
	//salesperson
	Try sp = ParsedJSON.sales_person Except  sp = Undefined EndTry;
	If (NOT sp = Undefined) AND (NOT sp = "") Then
		spQuery = new Query("SELECT
		                    |	SalesPeople.Ref
		                    |FROM
		                    |	Catalog.SalesPeople AS SalesPeople
		                    |WHERE
		                    |	SalesPeople.Description = &Description");
						   
		spQuery.SetParameter("Description", sp);
		spResult = spQuery.Execute();
		If spResult.IsEmpty() Then
			// salesperson is new
			Newsp = Catalogs.SalesPeople.CreateItem();
			Newsp.Description = sp;
			Newsp.Write();
			UpdatedCompanyObj.SalesPerson = Newsp.Ref;
		Else
			//salesperosn exists
			salesperson = spResult.Unload();
			UpdatedCompanyObj.SalesPerson = salesperson[0].Ref;
		EndIf;
	EndIf;
	
	//should check if its num or string, maybe disallow writing to both for same CF
	Try UpdatedCompanyObj.Notes = ParsedJSON.notes; Except EndTry;
	Try UpdatedCompanyObj.CF1String = ParsedJSON.cf1_string; Except EndTry;
	Try UpdatedCompanyObj.CF2String = ParsedJSON.cf2_string; Except EndTry;
	Try UpdatedCompanyObj.CF3String = ParsedJSON.cf3_string; Except EndTry;
	Try UpdatedCompanyObj.CF4String = ParsedJSON.cf4_string; Except EndTry;
	Try UpdatedCompanyObj.CF5String = ParsedJSON.cf5_string; Except EndTry;

	Try UpdatedCompanyObj.CF1Num = ParsedJSON.cf1_num; Except EndTry;
	Try UpdatedCompanyObj.CF2Num = ParsedJSON.cf2_num; Except EndTry;
	Try UpdatedCompanyObj.CF3Num = ParsedJSON.cf3_num; Except EndTry;
	Try UpdatedCompanyObj.CF4Num = ParsedJSON.cf4_num; Except EndTry;
	Try UpdatedCompanyObj.CF5Num = ParsedJSON.cf5_num; Except EndTry;
		
	Try
		
			DataAddresses = ParsedJSON.lines.addresses;
			
			ArrayLines = DataAddresses.Count();
			
			For i = 0 To ArrayLines -1 Do
				Try
					If i > 0 Then
						For j = 0 to i-1 Do
							If DataAddresses[j].address_id = DataAddresses[i].address_id Then
								errorMessage = New Map();
								strMessage = " [address_id(" + (i+1) +  ")] : Address ID must be unique. Cannot enter identical address IDs. ";
								errorMessage.Insert("message", strMessage);
								errorMessage.Insert("status", "error"); 
								errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
								return errorJSON;
							EndIf;
						EndDo;
					EndIf;
				Except
				EndTry;
				
			EndDo;
			
		Except
		EndTry;



	UpdatedCompanyObj.Write();

	Try
		If ParsedJSON.lines.addresses.count() > 0 Then

			For Each Address In ParsedJSON.lines.addresses Do
				
				Try aac = Address.api_code; Except aac = Undefined; EndTry;
				If NOT aac = Undefined Then
					Try CurAddress = Catalogs.Addresses.GetRef(New UUID(aac));
						//CurAddress = Catalogs.Addresses.GetRef(aac);
						aQuery = New Query("SELECT
						                  |		Addresses.Ref
						                  |FROM
						                  |		Catalog.Addresses AS Addresses
						                  |WHERE
						                  |		Addresses.Ref = &apicode");
						aQuery.SetParameter("apicode", CurAddress);
						aQueryResult = aQuery.Execute();
					Except 
						errorMessage = New Map();
						strMessage = " [address.api_code] : The address does not exist. ";
						errorMessage.Insert("message", strMessage);
						errorMessage.Insert("status", "error"); 
						errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
						return errorJSON;
					EndTry;

					If Not aQueryResult.IsEmpty() Then // <> Catalogs.Addresses.EmptyRef() Then
						CurAddress = Catalogs.Addresses.GetRef(aac);
						AddrObj = CurAddress.GetObject();

						Try  
							desc = Address.address_id;
							AddrObj.Description = desc; 
						Except 
	
						EndTry;
						
						Try AddrObj.Salutation = Address.Salutation; Except EndTry;
						Try AddrObj.FirstName = Address.first_name; Except EndTry;
						Try AddrObj.MiddleName = Address.middle_name; Except EndTry;
						Try AddrObj.LastName = Address.last_name; Except EndTry;
						Try AddrObj.Suffix = Address.suffix; Except EndTry;

						Try AddrObj.AddressLine1 = Address.address_line1; Except EndTry;
						Try AddrObj.AddressLine2 = Address.address_line2; Except EndTry;
						Try AddrObj.AddressLine3 = Address.address_line3; Except EndTry;

						Try AddrObj.City = Address.city; Except EndTry;
						Try
							State = Address.state;
							AddrObj.State = Catalogs.States.FindByCode(Upper(State));
						Except
							Try
								State = Address.state;
								AddrObj.State = Catalogs.States.FindByDescription(Title(State));
							Except
							EndTry;
						EndTry;
						
						Try
							Country = Address.country;
							AddrObj.Country = Catalogs.Countries.FindByCode(Upper(Country));
						Except
							Try
								Country = Address.country;
								AddrObj.Country = Catalogs.Countries.FindByDescription(Title(Country));
							Except
							EndTry;
						EndTry;
						Try AddrObj.ZIP = Address.zip; Except EndTry;
						
						Try AddrObj.Phone = Address.phone; Except EndTry;
						Try AddrObj.Cell = Address.cell; Except EndTry;
						Try AddrObj.Email = Address.email; Except EndTry;
						Try AddrObj.Fax = Address.fax; Except EndTry;
						Try AddrObj.JobTitle = Address.job_title; Except EndTry;
						
						//salesperson
						Try sp = Address.sales_person Except  sp = Undefined EndTry;
						If (NOT sp = Undefined) AND (NOT sp = "") Then
							spQuery = new Query("SELECT
							                    |	SalesPeople.Ref
							                    |FROM
							                    |	Catalog.SalesPeople AS SalesPeople
							                    |WHERE
							                    |	SalesPeople.Description = &Description");
											   
							spQuery.SetParameter("Description", sp);
							spResult = spQuery.Execute();
							If spResult.IsEmpty() Then
								// salesperson is new
								Newsp = Catalogs.SalesPeople.CreateItem();
								Newsp.Description = sp;
								Newsp.Write();
								AddrObj.SalesPerson = Newsp.Ref;
							Else
								//salesperosn exists
								salesperson = spResult.Unload();
								AddrObj.SalesPerson = salesperson[0].Ref;
							EndIf;
						EndIf;
						
						Try AddrObj.Notes = Address.notes; Except EndTry;
						
						Try DefaultBilling = Address.default_billing;  
						Except 
							DefaultBilling = Undefined;
						EndTry;
						If DefaultBilling = True Then
							addrQuery = New Query("SELECT
							                      |	Addresses.Ref
							                      |FROM
							                      |	Catalog.Addresses AS Addresses
							                      |WHERE
							                      |	Addresses.Owner = &Ref
							                      |	AND Addresses.DefaultBilling = TRUE");
							addrQuery.SetParameter("Ref", UpdatedCompanyObj.Ref);
							results = addrQuery.Execute();
							Dataset = results.Unload();
							For i = 0 to Dataset.Count()-1 Do
								addrRef = Dataset[i].Ref;
								addrObj1 = addrRef.GetObject();
								addrObj1.DefaultBilling = False;
								addrObj1.Write();	
							EndDo; 
							AddrObj.DefaultBilling = DefaultBilling;
						EndIf;
								
						Try Defaultshipping = Address.default_shipping;  
						Except 
							Defaultshipping = Undefined;	
						EndTry;
						If Defaultshipping = True Then
							addrQuery = New Query("SELECT
							                      |	Addresses.Ref
							                      |FROM
							                      |	Catalog.Addresses AS Addresses
							                      |WHERE
							                      |	Addresses.Owner = &Ref
							                      |	AND Addresses.DefaultShipping = TRUE");
							addrQuery.SetParameter("Ref", UpdatedCompanyObj.Ref);
							results = addrQuery.Execute();
							Dataset = results.Unload();
							For i = 0 to Dataset.Count()-1 Do
								addrRef = Dataset[i].Ref;
								addrObj1 = addrRef.GetObject();
								addrObj1.DefaultShipping = False;
								addrObj1.Write();	
							EndDo;
							AddrObj.DefaultShipping = DefaultShipping;
						EndIf;
				
						AddrObj.Write();
					Else
						errorMessage = New Map();
						strMessage = " [address.api_code] : The address does not exist. ";
						errorMessage.Insert("message", strMessage);
						errorMessage.Insert("status", "error"); 
						errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
						return errorJSON;
					EndIf;
				Else
					//add new address
					Try
						AddrObj = Catalogs.Addresses.CreateItem();
						AddrObj.Owner = UpdatedCompanyObj.Ref;
						
						Try AddrObj.Description = Address.address_id; 
						Except 
							errorMessage = New Map();
							strMessage = " [address.address_id] : This is required to create a new address. ";
							strMessage2 = " [address.api_code] : This is required to update an existing address. ";
							errorMessage.Insert("message1", strMessage);
							errorMessage.Insert("message2", strMessage2);
							errorMessage.Insert("status", "error"); 
							errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
							return errorJSON;
						EndTry;
						
						
						Try AddrObj.Salutation = Address.salutation; Except EndTry;
						Try AddrObj.Suffix = Address.suffix; Except EndTry;
						
						Try AddrObj.FirstName = Address.first_name; Except EndTry;
						Try AddrObj.MiddleName = Address.middle_name; Except EndTry;
						Try AddrObj.LastName = Address.last_name; Except EndTry;
						Try AddrObj.AddressLine1 = Address.address_line1; Except EndTry;
						Try AddrObj.AddressLine2 = Address.address_line2; Except EndTry;
						Try AddrObj.AddressLine3 = Address.address_line3; Except EndTry;

						Try AddrObj.City = Address.city; Except EndTry;
						
						Try AddrObj.ZIP = Address.zip; Except EndTry;
						
						Try
							State = Address.state;
							AddrObj.State = Catalogs.States.FindByCode(Upper(State));
						Except
							Try
								State = Address.state;
								AddrObj.State = Catalogs.States.FindByDescription(Title(State));
							Except
							EndTry;
						EndTry;
						
						Try
							Country = Address.country;
							AddrObj.Country = Catalogs.Countries.FindByCode(Upper(Country));
						Except
							Try
								Country = Address.country;
								AddrObj.Country = Catalogs.Countries.FindByDescription(Title(Country));
							Except
							EndTry;
						EndTry;
						Try AddrObj.Phone = Address.phone; Except EndTry;
						Try AddrObj.Fax = Address.fax; Except EndTry;
						Try AddrObj.Cell = Address.cell; Except EndTry;
						Try AddrObj.Email = Address.email; Except EndTry;
						Try AddrObj.JobTitle = Address.job_title; Except EndTry;
						Try AddrObj.Notes = Address.notes; Except EndTry;
						
						//salesperson
						Try sp = Address.sales_person Except  sp = Undefined EndTry;
						If (NOT sp = Undefined) AND (NOT sp = "") Then
							spQuery = new Query("SELECT
							                    |	SalesPeople.Ref
							                    |FROM
							                    |	Catalog.SalesPeople AS SalesPeople
							                    |WHERE
							                    |	SalesPeople.Description = &Description");
											   
							spQuery.SetParameter("Description", sp);
							spResult = spQuery.Execute();
							If spResult.IsEmpty() Then
								// salesperson is new
								Newsp = Catalogs.SalesPeople.CreateItem();
								Newsp.Description = sp;
								Newsp.Write();
								AddrObj.SalesPerson = Newsp.Ref;
							Else
								//salesperosn exists
								salesperson = spResult.Unload();
								AddrObj.SalesPerson = salesperson[0].Ref;
							EndIf;
						EndIf;
						
						Try DefaultBilling = Address.default_billing;  
						Except 
							DefaultBilling = Undefined;
						EndTry;
						If DefaultBilling = True Then
							addrQuery = New Query("SELECT
							                      |	Addresses.Ref
							                      |FROM
							                      |	Catalog.Addresses AS Addresses
							                      |WHERE
							                      |	Addresses.Owner = &Ref
							                      |	AND Addresses.DefaultBilling = TRUE");
							addrQuery.SetParameter("Ref", UpdatedCompanyObj.Ref);
							results = addrQuery.Execute();
							Dataset = results.Unload();
							For i = 0 to Dataset.Count()-1 Do
								addrRef = Dataset[i].Ref;
								addrObj1 = addrRef.GetObject();
								addrObj1.DefaultBilling = False;
								addrObj1.Write();	
							EndDo; 
							AddrObj.DefaultBilling = DefaultBilling;
						EndIf;
								
						Try Defaultshipping = Address.default_shipping;  
						Except 
							Defaultshipping = Undefined;	
						EndTry;
						If Defaultshipping = True Then
							addrQuery = New Query("SELECT
							                      |	Addresses.Ref
							                      |FROM
							                      |	Catalog.Addresses AS Addresses
							                      |WHERE
							                      |	Addresses.Owner = &Ref
							                      |	AND Addresses.DefaultShipping = TRUE");
							addrQuery.SetParameter("Ref", UpdatedCompanyObj.Ref);
							results = addrQuery.Execute();
							Dataset = results.Unload();
							For i = 0 to Dataset.Count()-1 Do
								addrRef = Dataset[i].Ref;
								addrObj1 = addrRef.GetObject();
								addrObj1.DefaultShipping = False;
								addrObj1.Write();	
							EndDo;
							AddrObj.DefaultShipping = DefaultShipping;
						EndIf;
												
						AddrObj.Write();
					Except
						errorMessage = New Map();
						strMessage = " [address.address_id] : The address id already exists. It must be unique. ";
						errorMessage.Insert("message", strMessage);
						errorMessage.Insert("status", "error"); 
						errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
						return errorJSON;
						
					EndTry;
					
				EndIf;
				
			EndDo;

		EndIf;
	
	Except
		Try
		If ParsedJSON.lines.addresses.count() > 0 Then 	
			errorMessage = New Map();
			strMessage = " [address.address_id] : The address id already exists. It must be unique. ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		Except; EndTry;
	EndTry;	
	
	jsonout = InternetConnectionClientServer.EncodeJSON(GeneralFunctions.ReturnCompanyObjectMap(UpdatedCompanyObj));

	Return jsonout;

EndFunction  

Function inoutCompaniesGet(jsonin) Export

	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);

	Try
		Company = Catalogs.Companies.GetRef(New UUID(ParsedJSON.object_code));
	Except
		errorMessage = New Map();
		strMessage = " [api_code] : The company does not exist. Double check that the ID# is correct. ";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndTry;
	
	companyQuery = New Query("SELECT
							 |	Companies.Ref AS Ref1
							 |FROM
							 |	Catalog.Companies AS Companies
							 |WHERE
							 |	Companies.Ref = &com");
	companyQuery.SetParameter("com", Company);
	companyresult = companyQuery.Execute();
	If companyresult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = " [api_code] : The item does not exist. Double check that the ID# is correct. ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
	EndIf;
		
	companyObj = Company.GetObject(); 
	jsonout = InternetConnectionClientServer.EncodeJSON(GeneralFunctions.ReturnCompanyObjectMap(companyObj));

	Return jsonout;

EndFunction  

Function inoutCompaniesDelete(jsonin) Export
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);

	api_code = ParsedJSON.object_code;

	Company = Catalogs.Companies.GetRef(New UUID(api_code));
	
	CompanyObj = Company.GetObject();
	
	company_name = CompanyObj.Description;
	
	SetPrivilegedMode(True);
	Try 
		CompanyObj.Delete(); //.DeletionMark = True;
	Except
		errorMessage = New Map();
		strMessage = "Failed to delete. There are linked objects to this company.";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("company_name", company_name);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndTry;
	SetPrivilegedMode(False);
	
	Output = New Map();	
	
	Output.Insert("status", "success");
	strMessage = company_name + " has been deleted.";
	Output.Insert("message", strMessage);
	
	jsonout = InternetConnectionClientServer.EncodeJSON(Output);
	
	Return jsonout;

EndFunction

Function inoutCompaniesListAll(jsonin, limit, start_after, end_before) Export
	
	Try limit = Number(limit);
	Except
		limit = 10; //default
	EndTry;
	
	If limit < 1 Then 
		errorMessage = New Map();
		strMessage = "[limit] : Cannot have a value less than 1";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndIf;
	
	If start_after <> "undefined" AND end_before <> "undefined" Then
		
		errorMessage = New Map();
		strMessage = "Please choose only one, start_after or end_before.";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
		
	ElsIf start_after <> "undefined" AND end_before = "undefined" Then
		
		Try
			Company = Catalogs.Companies.GetRef(New UUID(start_after));
		Except
			errorMessage = New Map();
			strMessage = "[start_after] : The company does not exist. Double check that the api_code is correct. ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndTry;
		
		ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
		Query = New Query("SELECT
	                  |	Companies.Ref
	                  |FROM
	                  |	Catalog.Companies AS Companies
	                  |
	                  |ORDER BY
	                  |	Companies.Description");
					  
		Result = Query.Execute().Select();
		Result_array = Query.Execute().Unload();
		
		Companies = New Array();
		
		i = 0;
		j = 0;
		While i < Result.Count() Do
			If Result_array[i].Ref = Company.Ref Then
				j = i+1;
				break;
			EndIf;
			i = i + 1;
		EndDo;
		
		limit = limit + j;
		numRecords = 0;
		While j < limit AND j < Result.Count() Do
			Companies.Add(GeneralFunctions.ReturnCompanyObjectMap(Result_array[j].Ref));
			numRecords = numRecords+1;
			j = j + 1;
		EndDo;
		
		If j+1 < Result.Count() Then 
			has_more = TRUE;
		Else
			has_more = FALSE;
		EndIf;
		
		CompanyList = New Map();
		CompanyList.Insert("companies", Companies);
		CompanyList.Insert("more_records", has_more);
		CompanyList.Insert("num_records_listed",numRecords);
		CompanyList.Insert("total_num_records", Result.Count());
		
		jsonout = InternetConnectionClientServer.EncodeJSON(CompanyList);
		
		Return jsonout;
		
	ElsIf start_after = "undefined" AND end_before <> "undefined" Then
		
		Try
			Company = Catalogs.Companies.GetRef(New UUID(end_before));
		Except
			errorMessage = New Map();
			strMessage = "[end_before] : The company does not exist. Double check that the api_code is correct. ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndTry;
		
		ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
		Query = New Query("SELECT
	                  |	Companies.Ref
	                  |FROM
	                  |	Catalog.Companies AS Companies
	                  |
	                  |ORDER BY
	                  |	Companies.Description");
					  
		Result = Query.Execute().Select();
		Result_array = Query.Execute().Unload();
		
		Companies = New Array();
		
		i = 0;
		j = 0;
		While i < Result.Count() Do
			If Result_array[i].Ref = Company.Ref Then
				j = i;
				break;
			EndIf;
			i = i + 1;
		EndDo;
		
		start = j - limit;
		If start < 0 Then
			start = 0;
		EndIf;
		
		numRecords = 0;
		While start < j AND start < Result.Count() Do
			Companies.Add(GeneralFunctions.ReturnCompanyObjectMap(Result_array[start].Ref));
			numRecords = numRecords+1;
			start = start + 1;
		EndDo;
		
		If start+1 < Result.Count() Then 
			has_more = TRUE;
		Else
			has_more = FALSE;
		EndIf;
		
		CompanyList = New Map();
		CompanyList.Insert("companies", Companies);
		CompanyList.Insert("more_records", has_more);
		CompanyList.Insert("num_records_listed",numRecords);
		CompanyList.Insert("total_num_records", Result.Count());
		
		jsonout = InternetConnectionClientServer.EncodeJSON(CompanyList);
		
		Return jsonout;
		
	Else
		// both undefined, just print with limit
		ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
		Query = New Query("SELECT
	                  |	Companies.Ref
	                  |FROM
	                  |	Catalog.Companies AS Companies
	                  |
	                  |ORDER BY
	                  |	Companies.Description");
					  
		Result = Query.Execute().Select();
		Result_array = Query.Execute().Unload();
		
		Companies = New Array();
		
		i = 0;
		numRecords = 0;
		While i < limit AND i < Result.Count() Do
			Companies.Add(GeneralFunctions.ReturnCompanyObjectMap(Result_array[i].Ref));
			numRecords = numRecords+1;
			i = i + 1;
		EndDo;
		
		If numRecords < Result.Count() Then 
			has_more = TRUE;
		Else
			has_more = FALSE;
		EndIf;
		
		CompanyList = New Map();
		CompanyList.Insert("companies", Companies);
		CompanyList.Insert("more_records", has_more);
		CompanyList.Insert("num_records_listed",numRecords);
		CompanyList.Insert("total_num_records", Result.Count());
		
		jsonout = InternetConnectionClientServer.EncodeJSON(CompanyList);
		
		Return jsonout;
		
	EndIf;
		
EndFunction


Function inoutItemsCreate(jsonin) Export
		
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	
	// check if an item already exists
	
	ProductExists = True;
	
	Try
	
		Query = New Query("SELECT
		                  |	Products.Ref
		                  |FROM
		                  |	Catalog.Products AS Products
		                  |WHERE
		                  |	Products.Code = &Code");
		Query.SetParameter("Code", ParsedJSON.item_code);
		QueryResult = Query.Execute();
		
		If QueryResult.IsEmpty() Then
			ProductExists = False;
		Else
		EndIf;
		
	Except
		
		errorMessage = New Map();
		strMessage = " [item_code] : This is a required field ";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	
	EndTry;
	
	
	// end check if product exists

	If ProductExists = False Then
	
		NewProduct = Catalogs.Products.CreateItem();
		
		NewProduct.Code = ParsedJSON.item_code;
				
		Try desc = ParsedJSON.item_description Except desc = Undefined EndTry;
		If desc = Undefined Then
			errorMessage = New Map();
			strMessage = " [item_description] : This is a required field ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		NewProduct.Description = desc;
				                            
		Try itemType = Lower(ParsedJSON.item_type); Except itemType = Undefined EndTry;
		If itemType = "service" Then
			NewProduct.Type = Enums.InventoryTypes.NonInventory;
			NewProduct.InventoryOrExpenseAccount = Constants.ExpenseAccount.Get();
			NewProduct.IncomeAccount = Constants.IncomeAccount.Get();
		Else 
			//defaults to product
			NewProduct.Type = Enums.InventoryTypes.Inventory;
			NewProduct.CostingMethod = Enums.InventoryCosting.WeightedAverage;
			NewProduct.InventoryOrExpenseAccount = Constants.InventoryAccount.Get();
			NewProduct.IncomeAccount = Constants.IncomeAccount.Get();
			NewProduct.COGSAccount = Constants.COGSAccount.Get();
		EndIf;
				
		Try itemCategory = ParsedJSON.item_category; Except itemCategory = "" EndTry;
		If itemCategory <> "" Then
			itemRef = Catalogs.ProductCategories.FindByDescription(itemCategory);
			If itemRef.Ref <> Catalogs.ProductCategories.EmptyRef() Then
				// already exists
				NewProduct.Category = itemRef.Ref;
			Else
				// create a new one
				newCat = Catalogs.ProductCategories.CreateItem();
				newCat.Description = itemCategory;
				newCat.Write();
				NewProduct.Category = newCat.Ref;
			EndIf;
		EndIf;

		
		Try UoM = ParsedJSON.unit_of_measure; Except UoM = "" EndTry;
		If UoM <> "" Then
			UoMRef = Catalogs.UnitSets.FindByDescription(UoM);
			If UoMRef.Ref <> Catalogs.UnitSets.EmptyRef() Then
				// already exists
				NewProduct.UnitSet = UoMRef.Ref;
			Else
				// create a new one
				newUoM = Catalogs.UnitSets.CreateItem();
				newUoM.Description = UoM;
				newUoM.Write();
				NewProduct.UnitSet = newUoM.Ref;
				newUnit = Catalogs.Units.CreateItem();
				newUnit.Owner       = newUoM.Ref;   // Set name
				newUnit.Code        = Left(UoM,1);// Abbreviation
				newUnit.Description = UoM;        // Unit name
				newUnit.BaseUnit    = True;                // Base ref of set
				newUnit.Factor      = 1;
				newUnit.Write();
				newUoM.DefaultReportUnit = newUnit.Ref;
				If  newUoM.DefaultSaleUnit.IsEmpty() Then
					newUoM.DefaultSaleUnit = newUnit.Ref;
				EndIf;
				If  newUoM.DefaultPurchaseUnit.IsEmpty() Then
					newUoM.DefaultPurchaseUnit = newUnit.Ref;
				EndIf;
				newUoM.Write();
				
			EndIf;
		Else
			NewProduct.UnitSet = Constants.DefaultUoMSet.Get();
		EndIf;
		 
		Try 
			NewProduct.Taxable = boolean(ParsedJSON.taxable); 
		Except 
			NewProduct.Taxable = Constants.SalesTaxMarkNewProductsTaxable.Get(); 
		EndTry;
		
		Try 
			NewProduct.Price = Number(ParsedJSON.item_price); 
		Except	 
		EndTry;
		
		Try NewProduct.CF1String = ParsedJSON.cf1_string; Except EndTry;
		Try NewProduct.CF2String = ParsedJSON.cf2_string; Except EndTry;
		Try NewProduct.CF3String = ParsedJSON.cf3_string; Except EndTry;
		Try NewProduct.CF4String = ParsedJSON.cf4_string; Except EndTry;
		Try NewProduct.CF5String = ParsedJSON.cf5_string; Except EndTry;
		Try NewProduct.CF1Num = ParsedJSON.cf1_num; Except EndTry;
		Try NewProduct.CF2Num = ParsedJSON.cf2_num; Except EndTry;
		Try NewProduct.CF3Num = ParsedJSON.cf3_num; Except EndTry;
		Try NewProduct.CF4Num = ParsedJSON.cf4_num; Except EndTry;
		Try NewProduct.CF5Num = ParsedJSON.cf5_num; Except EndTry;


		NewProduct.Write();
		
		ProductData = GeneralFunctions.ReturnProductObjectMap(NewProduct);
			
		jsonout = InternetConnectionClientServer.EncodeJSON(ProductData);
		
	Else
		
		ProductData = New Map();
		ProductData.Insert("message", " [item_code] : The item already exists. Not a unique item code.");
		ProductData.Insert("status", "error");

		existingItem = QueryResult.Unload();
  		ProductData.Insert("api_code", String(existingItem[0].Ref.UUID()));

		jsonout = InternetConnectionClientServer.EncodeJSON(ProductData);
		
	EndIf;
	
	Return jsonout;	
EndFunction

Function inoutItemsUpdate(jsonin, object_code) Export
	
	ProductCodeJSON = InternetConnectionClientServer.DecodeJSON(object_code);
	
	Try api_code = ProductCodeJSON.object_code Except api_code = Undefined EndTry;
	If api_code = Undefined OR api_code = "" Then
		errorMessage = New Map();
		strMessage = " [api_code] : Missing the item ID# ";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndIf;
		
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	
	Try	
		UpdatedProduct = Catalogs.Products.getref(New UUID(api_code));
	Except
		errorMessage = New Map();
		strMessage = " [api_code] : The item does not exist. Double check that the ID# is correct. ";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndTry;
	
	itemQuery = New Query("SELECT
	                      |	Products.Ref
	                      |FROM
	                      |	Catalog.Products AS Products
	                      |WHERE
	                      |	Products.Ref = &item");
	itemQuery.SetParameter("item", UpdatedProduct);
	itemresult = itemQuery.Execute();
	If itemresult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = " [api_code] : The item does not exist. Double check that the ID# is correct. ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
	EndIf;
	
	UpdatedProductObj = UpdatedProduct.GetObject();
	
	Try 
		itemCode = ParsedJSON.item_code;
		Query = New Query("SELECT
		                  |	Products.Ref
		                  |FROM
		                  |	Catalog.Products AS Products
		                  |WHERE
		                  |	Products.Code = &Code");
		Query.SetParameter("Code", itemCode);
		QueryResult = Query.Execute();
		
		If QueryResult.IsEmpty() Then
			UpdatedProductObj.Code = itemCode; 
		Else
			ProductData = New Map();
			ProductData.Insert("message", " [item_code] : The item already exists. Not a unique item code.");
			ProductData.Insert("status", "error");
			existingItem = QueryResult.Unload();
	  		ProductData.Insert("api_code", String(existingItem[0].Ref.UUID()));
			jsonout = InternetConnectionClientServer.EncodeJSON(ProductData);
			return jsonout;
		EndIf;
	Except 
	EndTry;
	
	Try UpdatedProductObj.Description = ParsedJSON.item_description; Except EndTry;
	
	Try itemCategory = ParsedJSON.item_category; Except itemCategory = "" EndTry;
	If itemCategory <> "" Then
		itemRef = Catalogs.ProductCategories.FindByDescription(itemCategory);
		If itemRef.Ref <> Catalogs.ProductCategories.EmptyRef() Then
			UpdatedProductObj.Category = itemRef.Ref;
		Else
			newCat = Catalogs.ProductCategories.CreateItem();
			newCat.Description = itemCategory;
			newCat.Write();
			UpdatedProductObj.Category = newCat.Ref;
		EndIf;
	EndIf;
		
	Try UoM = ParsedJSON.unit_of_measure; Except UoM = "" EndTry;
	If UoM <> "" Then
		UoMRef = Catalogs.UnitSets.FindByDescription(UoM);
		If UoMRef.Ref <> Catalogs.UnitSets.EmptyRef() Then
			UpdatedProductObj.UnitSet = UoMRef.Ref;
		Else
			newUoM = Catalogs.UnitSets.CreateItem();
			newUoM.Description = UoM;
			newUoM.Write();
			UpdatedProductObj.UnitSet = newUoM.Ref;
			newUnit = Catalogs.Units.CreateItem();
			newUnit.Owner       = newUoM.Ref;   // Set name
			newUnit.Code        = Left(UoM,1);// Abbreviation
			newUnit.Description = UoM;        // Unit name
			newUnit.BaseUnit    = True;                // Base ref of set
			newUnit.Factor      = 1;
			newUnit.Write();
			newUoM.DefaultReportUnit = newUnit.Ref;
			If  newUoM.DefaultSaleUnit.IsEmpty() Then
				newUoM.DefaultSaleUnit = newUnit.Ref;
			EndIf;
			If  newUoM.DefaultPurchaseUnit.IsEmpty() Then
				newUoM.DefaultPurchaseUnit = newUnit.Ref;
			EndIf;
			newUoM.Write();

		EndIf;
	Else
		//UpdatedProductObj.UnitSet = Constants.DefaultUoMSet.Get();
		//dont update
	EndIf;
	 
	Try 
		UpdatedProductObj.Taxable = boolean(ParsedJSON.taxable); 
	Except 
		UpdatedProductObj.Taxable = Constants.SalesTaxMarkNewProductsTaxable.Get(); 
	EndTry;
	
	Try 
		UpdatedProductObj.Price = Number(ParsedJSON.item_price); 
	Except	 
	EndTry;

	Try UpdatedProductObj.CF1String = ParsedJSON.cf1_string; Except EndTry;
	Try UpdatedProductObj.CF2String = ParsedJSON.cf2_string; Except EndTry;
	Try UpdatedProductObj.CF3String = ParsedJSON.cf3_string; Except EndTry;
	Try UpdatedProductObj.CF4String = ParsedJSON.cf4_string; Except EndTry;
	Try UpdatedProductObj.CF5String = ParsedJSON.cf5_string; Except EndTry;
	Try UpdatedProductObj.CF1Num = ParsedJSON.cf1_num; Except EndTry;
	Try UpdatedProductObj.CF2Num = ParsedJSON.cf2_num; Except EndTry;
	Try UpdatedProductObj.CF3Num = ParsedJSON.cf3_num; Except EndTry;
	Try UpdatedProductObj.CF4Num = ParsedJSON.cf4_num; Except EndTry;
	Try UpdatedProductObj.CF5Num = ParsedJSON.cf5_num; Except EndTry;
	
		
	UpdatedProductObj.Write();
	
	ProductData = GeneralFunctions.ReturnProductObjectMap(UpdatedProductObj);
	jsonout = InternetConnectionClientServer.EncodeJSON(ProductData);
	
	Return jsonout;

EndFunction

Function inoutItemsGet(jsonin) Export
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	
	api_code = ParsedJSON.object_code;
	
	Try	
		Product = Catalogs.Products.GetRef(New UUID(api_code));
	Except
		errorMessage = New Map();
		strMessage = " [api_code] : The item does not exist. Double check that the ID# is correct. ";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndTry;
	
	itemQuery = New Query("SELECT
	                      |	Products.Ref
	                      |FROM
	                      |	Catalog.Products AS Products
	                      |WHERE
	                      |	Products.Ref = &item");
	itemQuery.SetParameter("item", Product);
	itemresult = itemQuery.Execute();
	If itemresult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = " [api_code] : The item does not exist. Double check that the ID# is correct. ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
	EndIf;	
	
	jsonout = InternetConnectionClientServer.EncodeJSON(GeneralFunctions.ReturnProductObjectMap(Product));
	
	Return jsonout;

EndFunction

Function inoutItemsDelete(jsonin) Export
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	api_code = ParsedJSON.object_code;
	
	Product = Catalogs.Products.GetRef(New UUID(api_code));
	
	ProductObj = Product.GetObject();
	ic = ProductObj.Code;
	SetPrivilegedMode(True);
	Try
		ProductObj.Delete(); //.DeletionMark = True;
	Except
		errorMessage = New Map();
		strMessage = "Failed to delete. There are linked objects to this item.";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("item_code",ic);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndTry;
	SetPrivilegedMode(False);
	
	Output = New Map();	

	Output.Insert("status", "success");
	strMessage = ic + " has been deleted.";
	Output.Insert("message", strMessage);
	
	jsonout = InternetConnectionClientServer.EncodeJSON(Output);
	
	Return jsonout;

EndFunction

Function inoutItemsListAll(jsonin, limit, start_after, end_before) Export
		
	Try limit = Number(limit);
	Except
		limit = 10; //default
	EndTry;
	
	If limit < 1 Then 
		errorMessage = New Map();
		strMessage = "[limit] : Cannot have a value less than 1";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndIf;
	
	If start_after <> "undefined" AND end_before <> "undefined" Then
		
		errorMessage = New Map();
		strMessage = "Please choose only one, start_after or end_before.";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
		
	ElsIf start_after <> "undefined" AND end_before = "undefined" Then
		
		Try
			Product = Catalogs.Products.GetRef(New UUID(start_after));
		Except
			errorMessage = New Map();
			strMessage = "[start_after] : The item does not exist. Double check that the api_code is correct. ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndTry;
		
		ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
		Query = New Query("SELECT
					  |	Products.Ref,
					  |	Products.Code AS Code,
					  |	Products.Description,
					  |	Products.Type
					  |FROM
					  |	Catalog.Products AS Products
					  |
					  |ORDER BY
					  |	Code");
					  
		Result = Query.Execute().Select();
		Result_array = Query.Execute().Unload();
		
		Products = New Array();
		
		i = 0;
		j = 0;
		While i < Result.Count() Do
			If Result_array[i].Ref = Product.Ref Then
				j = i+1;
				break;
			EndIf;
			i = i + 1;
		EndDo;
		
		limit = limit + j;
		numRecords = 0;
		While j < limit AND j < Result.Count() Do
			Products.Add(GeneralFunctions.ReturnProductObjectMap(Result_array[j].Ref));
			numRecords = numRecords+1;
			j = j + 1;
		EndDo;
		
		If j+1 < Result.Count() Then 
			has_more = TRUE;
		Else
			has_more = FALSE;
		EndIf;
		
		ProductList = New Map();
		ProductList.Insert("items", Products);
		ProductList.Insert("more_records", has_more);
		ProductList.Insert("num_records_listed",numRecords);
		ProductList.Insert("total_num_records", Result.Count());
		
		jsonout = InternetConnectionClientServer.EncodeJSON(ProductList);
		
		Return jsonout;
		
	ElsIf start_after = "undefined" AND end_before <> "undefined" Then
		
		Try
			Product = Catalogs.Products.GetRef(New UUID(end_before));
		Except
			errorMessage = New Map();
			strMessage = "[end_before] : The item does not exist. Double check that the api_code is correct. ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndTry;
		
		ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
		Query = New Query("SELECT
					  |	Products.Ref,
					  |	Products.Code AS Code,
					  |	Products.Description,
					  |	Products.Type
					  |FROM
					  |	Catalog.Products AS Products
					  |
					  |ORDER BY
					  |	Code");
					  
		Result = Query.Execute().Select();
		Result_array = Query.Execute().Unload();
		
		Products = New Array();
		
		i = 0;
		j = 0;
		While i < Result.Count() Do
			If Result_array[i].Ref = Product.Ref Then
				j = i;
				break;
			EndIf;
			i = i + 1;
		EndDo;
		
		start = j - limit;
		If start < 0 Then
			start = 0;
		EndIf;
		
		numRecords = 0;
		While start < j AND start < Result.Count() Do
			Products.Add(GeneralFunctions.ReturnProductObjectMap(Result_array[start].Ref));
			numRecords = numRecords+1;
			start = start + 1;
		EndDo;
		
		If start+1 < Result.Count() Then 
			has_more = TRUE;
		Else
			has_more = FALSE;
		EndIf;
		
		ProductList = New Map();
		ProductList.Insert("items", Products);
		ProductList.Insert("more_records", has_more);
		ProductList.Insert("num_records_listed",numRecords);
		ProductList.Insert("total_num_records", Result.Count());
		
		jsonout = InternetConnectionClientServer.EncodeJSON(ProductList);
		
		Return jsonout;
		
	Else
		// both undefined, just print with limit
		ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
		Query = New Query("SELECT
					  |	Products.Ref,
					  |	Products.Code AS Code,
					  |	Products.Description,
					  |	Products.Type
					  |FROM
					  |	Catalog.Products AS Products
					  |
					  |ORDER BY
					  |	Code");
					  
		Result = Query.Execute().Select();
		Result_array = Query.Execute().Unload();
		
		Products = New Array();
		
		i = 0;
		numRecords = 0;
		While i < limit AND i < Result.Count() Do
			Products.Add(GeneralFunctions.ReturnProductObjectMap(Result_array[i].Ref));
			numRecords = numRecords+1;
			i = i + 1;
		EndDo;
		
		If numRecords < Result.Count() Then 
			has_more = TRUE;
		Else
			has_more = FALSE;
		EndIf;
		
		ProductList = New Map();
		ProductList.Insert("items", Products);
		ProductList.Insert("more_records", has_more);
		ProductList.Insert("num_records_listed",numRecords);
		ProductList.Insert("total_num_records", Result.Count());
		
		jsonout = InternetConnectionClientServer.EncodeJSON(ProductList);
		
		Return jsonout;
		
	EndIf;

EndFunction


Function inoutCashSalesCreate(jsonin) Export
		
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
		
	NewCashSale = Documents.CashSale.CreateDocument();
	//CompanyCode = ParsedJSON.company_code;
	customer_api_code = ParsedJSON.customer_api_code;
	NewCashSale.Company = Catalogs.Companies.GetRef(New UUID(customer_api_code));
	//ShipToAddressCode = ParsedJSON.ship_to_address_code;
	ship_to_api_code = ParsedJSON.ship_to_api_code;
	// check if address belongs to company
	NewCashSale.ShipTo = Catalogs.Addresses.GetRef(New UUID(ship_to_api_code));
	// select the company's default shipping address
	
	NewCashSale.Date = ParsedJSON.date;
	
	//PaymentMethod = ParsedJSON.Get("payment_method");
	// support all payment methods
	NewCashSale.PaymentMethod = Catalogs.PaymentMethods.Cash;
	Try
		NewCashSale.RefNum = ParsedJSON.ref_num;
	Except
	EndTry;
	Try
		NewCashSale.Memo = ParsedJSON.memo;
	Except
	EndTry;
	// tax rate - calculate from address?
	Try
		SalesTax = ParsedJSON.sales_tax_total; 
		NewCashSale.SalesTaxRC = ParsedJSON.sales_tax_total;		
	Except
		NewCashSale.SalesTaxRC = 0;
	EndTry;
	NewCashSale.DocumentTotal = ParsedJSON.doc_total;
	NewCashSale.DocumentTotalRC = ParsedJSON.doc_total;
    NewCashSale.DepositType = "2";
	NewCashSale.Currency = Constants.DefaultCurrency.Get();
	NewCashSale.BankAccount = Constants.BankAccount.Get();
	NewCashSale.ExchangeRate = 1;
	NewCashSale.Location = GeneralFunctions.GetDefaultLocation();
	
	Try NewCashSale.LineSubtotal = ParsedJSON.line_subtotal; Except EndTry;
	Try NewCashSale.Discount = ParsedJSON.discount; Except EndTry;
	Try NewCashSale.DiscountPercent = ParsedJSON.discount_percent; Except EndTry;
	Try NewCashSale.SubTotal = ParsedJSON.subtotal; Except EndTry;
	Try NewCashSale.Shipping = ParsedJSON.shipping; Except EndTry;
	
	DataLineItems = ParsedJSON.lines.line_items;
	
	LineItemsRows = DataLineItems.Count();
	For i = 0 To LineItemsRows -1 Do
		
		NewLine = NewCashSale.LineItems.Add();
		
		//ProductCode = Number(DataLineItems[i].api_code);
		Product = Catalogs.Products.GetRef(New UUID(DataLineItems[i].api_code));
		NewLine.Product = Product;
		NewLine.ProductDescription = Product.Description;
		//NewLine.VATCode = CommonUse.GetAttributeValue(Product, "SalesVATCode");
		//NewLine.VAT = 0;
		
		NewLine.PriceUnits = DataLineItems[i].price;
		NewLine.QtyUnits = DataLineItems[i].quantity;
		//Try NewLine.Taxable = DataLineItems[i].taxable; Except EndTry;
		// get taxable from JSON
		//Try
		//	TaxableType = DataLineItems[i].taxable_type;
		//	If TaxableType = "taxable" Then
		//		NewLine.SalesTaxType = Enums.SalesTaxTypes.Taxable;
		//	ElsIf TaxableType = "non-taxable" Then
		//		NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;
		//	Else
		//		NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;
		//	EndIf;
		//Except
		//	NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;	
		//EndTry;
		
		NewLine.LineTotal = DataLineItems[i].line_total;
		//Try
		//	TaxableAmount = DataLineItems[i].taxable_amount;
		//	NewLine.TaxableAmount = TaxableAmount				
		//Except
		//	NewLine.TaxableAmount = 0;
		//EndTry;
				
	EndDo;
	
	NewCashSale.Write();
		
	///
	
	
	CashSaleData = New Map();	
	CashSaleData.Insert("api_code", String(NewCashSale.Ref.UUID()));
	CashSaleData.Insert("customer_api_code", String(NewCashSale.Company.Ref.UUID()));
	CashSaleData.Insert("company_name", NewCashSale.Company.Description);
	CashSaleData.Insert("company_code", NewCashSale.Company.Code);
	CashSaleData.Insert("ship_to_api_code", String(NewCashSale.ShipTo.Ref.UUID()));
	CashSaleData.Insert("ship_to_address_code", NewCashSale.ShipTo.Code);
	CashSaleData.Insert("ship_to_address_id", NewCashSale.ShipTo.Description);
	// date - convert into the same format as input
	CashSaleData.Insert("cash_sale_number", NewCashSale.Number);
	// payment method - same as input
	CashSaleData.Insert("payment_method", NewCashSale.PaymentMethod.Description);
	CashSaleData.Insert("date", NewCashSale.Date);
	CashSaleData.Insert("ref_num", NewCashSale.RefNum);
	CashSaleData.Insert("memo", NewCashSale.Memo);
	CashSaleData.Insert("sales_tax_total", NewCashSale.SalesTaxRC);
	CashSaleData.Insert("doc_total", NewCashSale.DocumentTotalRC);
	
	CashSaleData.Insert("line_subtotal", NewCashSale.LineSubtotal);
	CashSaleData.Insert("discount", NewCashSale.Discount);
	CashSaleData.Insert("discount_percent", NewCashSale.DiscountPercent);
	CashSaleData.Insert("subtotal", NewCashSale.SubTotal);
	CashSaleData.Insert("shipping", NewCashSale.Shipping);


	Query = New Query("SELECT
	                  |	CashSaleLineItems.Product,
	                  |	CashSaleLineItems.PriceUnits,
	                  |	CashSaleLineItems.QtyUnits,
	                  |	CashSaleLineItems.LineTotal
	                  |FROM
	                  |	Document.CashSale.LineItems AS CashSaleLineItems
	                  |WHERE
	                  |	CashSaleLineItems.Ref = &CashSale");
	Query.SetParameter("CashSale", NewCashSale.Ref);
	Result = Query.Execute().Select();
	
	LineItems = New Array();
	
	While Result.Next() Do
		
		LineItem = New Map();
		LineItem.Insert("api_code", String(Result.Product.Ref.UUID()));
		LineItem.Insert("item_code", Result.Product.Code);
		LineItem.Insert("item_description", Result.Product.Description);
		LineItem.Insert("price", Result.PriceUnits);
		LineItem.Insert("quantity", Result.QtyUnits);
		//LineItem.Insert("taxable_amount", Result.TaxableAmount);
		LineItem.Insert("line_total", Result.LineTotal);
		//LineItem.Insert("taxable", Result.Taxable);
		//If Result.SalesTaxType = Enums.SalesTaxTypes.Taxable Then
		//	LineItem.Insert("taxable_type", "taxable");
		//ElsIf Result.SalesTaxType = Enums.SalesTaxTypes.NonTaxable Then
		//	LineItem.Insert("taxable_type", "non-taxable");
		//EndIf;
		LineItems.Add(LineItem);
		
	EndDo;
	
	LineItemsData = New Map();
	LineItemsData.Insert("line_items", LineItems);
	
	CashSaleData.Insert("lines", LineItemsData);
	
	jsonout = InternetConnectionClientServer.EncodeJSON(CashSaleData);
	
	Return jsonout;

	
EndFunction

Function inoutCashSalesUpdate(jsonin, object_code) Export
	
	CashSaleNumberJSON = InternetConnectionClientServer.DecodeJSON(object_code);
	api_code = CashSaleNumberJSON.object_code;
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	
	UpdatedCashSale = Documents.CashSale.GetRef(New UUID(api_code));	
	UpdatedCashSaleObj = UpdatedCashSale.GetObject();
	UpdatedCashSaleObj.LineItems.Clear();
	
	///
	
	customer_api_code = ParsedJSON.customer_api_code;
	//CompanyCode = ParsedJSON.company_code;
	UpdatedCashSaleObj.Company = Catalogs.Companies.GetRef(New UUID(customer_api_code));
	ship_to_api_code = ParsedJSON.ship_to_api_code;
	//ShipToAddressCode = ParsedJSON.ship_to_address_code;
	// check if address belongs to company
	UpdatedCashSaleObj.ShipTo = Catalogs.Addresses.GetRef(New UUID(ship_to_api_code));
	// select the company's default shipping address
	
	UpdatedCashSaleObj.Date = ParsedJSON.date;
	
	//PaymentMethod = ParsedJSON.Get("payment_method");
	// support all payment methods
	UpdatedCashSaleObj.PaymentMethod = Catalogs.PaymentMethods.Cash;
	Try
		UpdatedCashSaleObj.RefNum = ParsedJSON.ref_num;
	Except
	EndTry;
	Try
		UpdatedCashSaleObj.Memo = ParsedJSON.memo;
	Except
	EndTry;
	// tax rate - calculate from address?
	
	Try
		SalesTax = ParsedJSON.sales_tax_total; 
		UpdatedCashSaleObj.SalesTaxRC = ParsedJSON.sales_tax_total;		
	Except
		UpdatedCashSaleObj.SalesTaxRC = 0;
	EndTry;

	UpdatedCashSaleObj.DocumentTotal = ParsedJSON.doc_total;
	UpdatedCashSaleObj.DocumentTotalRC = ParsedJSON.doc_total;
    UpdatedCashSaleObj.DepositType = "2";
	UpdatedCashSaleObj.Currency = Constants.DefaultCurrency.Get();
	UpdatedCashSaleObj.BankAccount = Constants.BankAccount.Get();
	UpdatedCashSaleObj.ExchangeRate = 1;
	UpdatedCashSaleObj.Location = GeneralFunctions.GetDefaultLocation();
	
	Try UpdatedCashSaleObj.LineSubtotal = ParsedJSON.line_subtotal; Except EndTry;
	Try UpdatedCashSaleObj.Discount = ParsedJSON.discount; Except EndTry;
	Try UpdatedCashSaleObj.DiscountPercent = ParsedJSON.discount_percent; Except EndTry;
	Try UpdatedCashSaleObj.SubTotal = ParsedJSON.subtotal; Except EndTry;
	Try UpdatedCashSaleObj.Shipping = ParsedJSON.shipping; Except EndTry;
	
	DataLineItems = ParsedJSON.lines.line_items;
	
	LineItemsRows = DataLineItems.Count();
	For i = 0 To LineItemsRows -1 Do
		
		NewLine = UpdatedCashSaleObj.LineItems.Add();
		
		//product_api_code = DataLineItems[i].api_code;
		Product = Catalogs.Products.GetRef(New UUID(DataLineItems[i].api_code));
		//Product = Catalogs.Products.GetRef(New UUID(product_api_code));
		NewLine.Product = Product;
		NewLine.ProductDescription = Product.Description;
		//NewLine.VATCode = CommonUse.GetAttributeValue(Product, "SalesVATCode");
		//NewLine.VAT = 0;
		
		NewLine.PriceUnits = DataLineItems[i].price;
		NewLine.QtyUnits = DataLineItems[i].quantity;
		//Try NewLine.Taxable = DataLineItems[i].taxable; Except EndTry;
		// get taxable from JSON
		//Try
		//	TaxableType = DataLineItems[i].taxable_type;
		//	If TaxableType = "taxable" Then
		//		NewLine.SalesTaxType = Enums.SalesTaxTypes.Taxable;
		//	ElsIf TaxableType = "non-taxable" Then
		//		NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;
		//	Else
		//		NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;
		//	EndIf;
		//Except
		//	NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;	
		//EndTry;

		NewLine.LineTotal = DataLineItems[i].line_total;
		//Try
		//	TaxableAmount = DataLineItems[i].taxable_amount;
		//	NewLine.TaxableAmount = TaxableAmount				
		//Except
		//	NewLine.TaxableAmount = 0;
		//EndTry;
				
	EndDo;
	
	UpdatedCashSaleObj.Write();

	
	///
	
	NewCashSale = UpdatedCashSaleObj; // code below is copied from CashSalesPost
	
	CashSaleData = New Map();	
	CashSaleData.Insert("api_code", String(NewCashSale.Ref.UUID()));
	CashSaleData.Insert("customer_api_code", String(NewCashSale.Company.Ref.UUID()));
	CashSaleData.Insert("company_name", NewCashSale.Company.Description);
	CashSaleData.Insert("company_code", NewCashSale.Company.Code);
	CashSaleData.Insert("ship_to_api_code", String(NewCashSale.ShipTo.Ref.UUID()));
	CashSaleData.Insert("ship_to_address_code", NewCashSale.ShipTo.Code);
	CashSaleData.Insert("ship_to_address_id", NewCashSale.ShipTo.Description);
	// date - convert into the same format as input
	CashSaleData.Insert("cash_sale_number", NewCashSale.Number);
	// payment method - same as input
	CashSaleData.Insert("payment_method", NewCashSale.PaymentMethod.Description);
	CashSaleData.Insert("date", NewCashSale.Date);
	CashSaleData.Insert("ref_num", NewCashSale.RefNum);
	CashSaleData.Insert("memo", NewCashSale.Memo);
	CashSaleData.Insert("sales_tax_total", NewCashSale.SalesTaxRC);
	CashSaleData.Insert("doc_total", NewCashSale.DocumentTotalRC);
	CashSaleData.Insert("line_subtotal", NewCashSale.LineSubtotal);
	CashSaleData.Insert("discount", NewCashSale.Discount);
	CashSaleData.Insert("discount_percent", NewCashSale.DiscountPercent);
	CashSaleData.Insert("subtotal", NewCashSale.SubTotal);
	CashSaleData.Insert("shipping", NewCashSale.Shipping);

	Query = New Query("SELECT
	                  |	CashSaleLineItems.Product,
	                  |	CashSaleLineItems.PriceUnits,
	                  |	CashSaleLineItems.QtyUnits,
	                  |	CashSaleLineItems.LineTotal
	                  |FROM
	                  |	Document.CashSale.LineItems AS CashSaleLineItems
	                  |WHERE
	                  |	CashSaleLineItems.Ref = &CashSale");
	Query.SetParameter("CashSale", NewCashSale.Ref);
	Result = Query.Execute().Select();
	
	LineItems = New Array();
	
	While Result.Next() Do
		
		LineItem = New Map();
		LineItem.Insert("api_code", String(Result.Product.Ref.UUID()));
		LineItem.Insert("item_code", Result.Product.Code);
		LineItem.Insert("item_description", Result.Product.Description);
		LineItem.Insert("price", Result.PriceUnits);
		LineItem.Insert("quantity", Result.QtyUnits);
		//LineItem.Insert("taxable_amount", Result.TaxableAmount);
		LineItem.Insert("line_total", Result.LineTotal);
		//LineItem.Insert("taxable", Result.Taxable);
		//If Result.SalesTaxType = Enums.SalesTaxTypes.Taxable Then
		//	LineItem.Insert("taxable_type", "taxable");
		//ElsIf Result.SalesTaxType = Enums.SalesTaxTypes.NonTaxable Then
		//	LineItem.Insert("taxable_type", "non-taxable");
		//EndIf;
		LineItems.Add(LineItem);
		
	EndDo;
	
	LineItemsData = New Map();
	LineItemsData.Insert("line_items", LineItems);
	
	CashSaleData.Insert("lines", LineItemsData);
	
	jsonout = InternetConnectionClientServer.EncodeJSON(CashSaleData);
	
	Return jsonout;

EndFunction

Function inoutCashSalesGet(jsonin) Export
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	api_code = ParsedJSON.object_code;
	
	Try
		CashSale = Documents.CashSale.GetRef(New UUID(api_code));
	Except
		errorMessage = New Map();
		strMessage = " [api_code] : The cash sale does not exist. Double check that the ID# is correct. ";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndTry;
	
	SIQuery = New Query("SELECT
	                    |	CashSale.Ref
	                    |FROM
	                    |	Document.CashSale AS CashSale
	                    |WHERE
	                    |	CashSale.Ref = &Ref");
	SIQuery.SetParameter("Ref", CashSale);
	SIresult = SIQuery.Execute();
	If SIresult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = " [api_code] : The sales order does not exist. Double check that the ID# is correct. ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
	EndIf;
	
	NewCashSale = CashSale; // code below is copied from CashSalesPost
	
	CashSaleData = New Map();
	CashSaleData.Insert("api_code", String(NewCashSale.Ref.UUID()));
	CashSaleData.Insert("customer_api_code", String(NewCashSale.Company.Ref.UUID()));
	CashSaleData.Insert("company_name", NewCashSale.Company.Description);
	CashSaleData.Insert("company_code", NewCashSale.Company.Code);
	CashSaleData.Insert("ship_to_api_code", String(NewCashSale.ShipTo.Ref.UUID()));
	CashSaleData.Insert("ship_to_address_code", NewCashSale.ShipTo.Code);
	CashSaleData.Insert("ship_to_address_id", NewCashSale.ShipTo.Description);
	// date - convert into the same format as input
	CashSaleData.Insert("cash_sale_number", NewCashSale.Number);
	// payment method - same as input
	CashSaleData.Insert("payment_method", NewCashSale.PaymentMethod.Description);
	CashSaleData.Insert("date", NewCashSale.Date);
	CashSaleData.Insert("ref_num", NewCashSale.RefNum);
	CashSaleData.Insert("memo", NewCashSale.Memo);
	CashSaleData.Insert("sales_tax_total", NewCashSale.SalesTaxRC);
	CashSaleData.Insert("doc_total", NewCashSale.DocumentTotalRC);
	CashSaleData.Insert("line_subtotal", NewCashSale.LineSubtotal);
	CashSaleData.Insert("discount", NewCashSale.Discount);
	CashSaleData.Insert("discount_percent", NewCashSale.DiscountPercent);	
	CashSaleData.Insert("subtotal", NewCashSale.SubTotal);
	CashSaleData.Insert("shipping", NewCashSale.Shipping);

	Query = New Query("SELECT
	                  |	CashSaleLineItems.Product,
	                  |	CashSaleLineItems.PriceUnits,
	                  |	CashSaleLineItems.QtyUnits,
	                  |	CashSaleLineItems.LineTotal
	                  |FROM
	                  |	Document.CashSale.LineItems AS CashSaleLineItems
	                  |WHERE
	                  |	CashSaleLineItems.Ref = &CashSale");
	Query.SetParameter("CashSale", NewCashSale.Ref);
	Result = Query.Execute().Select();
	
	LineItems = New Array();
	
	While Result.Next() Do
		
		LineItem = New Map();
		LineItem.Insert("item_code", Result.Product.Code);
		LineItem.Insert("api_code", String(Result.Product.Ref.UUID()));
		LineItem.Insert("item_description", Result.Product.Description);
		LineItem.Insert("price", Result.PriceUnits);
		LineItem.Insert("quantity", Result.QtyUnits);
		//LineItem.Insert("taxable_amount", Result.TaxableAmount);
		LineItem.Insert("line_total", Result.LineTotal);
		//LineItem.Insert("taxable", Result.Taxable);
		//If Result.SalesTaxType = Enums.SalesTaxTypes.Taxable Then
		//	LineItem.Insert("taxable_type", "taxable");
		//ElsIf Result.SalesTaxType = Enums.SalesTaxTypes.NonTaxable Then
		//	LineItem.Insert("taxable_type", "non-taxable");
		//EndIf;
		LineItems.Add(LineItem);
		
	EndDo;
	
	LineItemsData = New Map();
	LineItemsData.Insert("line_items", LineItems);
	
	CashSaleData.Insert("lines", LineItemsData);
	
	jsonout = InternetConnectionClientServer.EncodeJSON(CashSaleData);
	
	Return jsonout;


EndFunction

Function inoutCashSalesDelete(jsonin) Export
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	api_code = ParsedJSON.object_code;
	
	CashSale = Documents.CashSale.GetRef(New UUID(api_code));
	
	CashSaleObj = CashSale.GetObject();
	saleNum = CashSaleObj.Number;
	date = CashSaleObj.Date;
	SetPrivilegedMode(True);
	Try
		CashSaleObj.Delete();//DeletionMark = True;
	Except
		errorMessage = New Map();
		strMessage = "Failed to delete. Cash Sale must be unposted before deletion and/or other objects are linked to this cash sale.";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("cash_sale_number",saleNum);
		errorMessage.Insert("date", date);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndTry;
	SetPrivilegedMode(False);
	
	Output = New Map();	
	
	//Try
		//CashSaleObj.Write(DocumentWriteMode.UndoPosting);
		Output.Insert("status", "success");
		strMessage = "Cash Sale # " + saleNum + " from " + date + " has been deleted.";
		Output.Insert("message", strMessage);
	//Except
		//ErrorMessage = DetailErrorDescription(ErrorInfo());
		//Output.Insert("error", "cash sale can not be deleted");
	//EndTry;
	
	jsonout = InternetConnectionClientServer.EncodeJSON(Output);
	
	Return jsonout;


EndFunction

Function inoutCashSalesListAll(jsonin) Export
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
		
	Query = New Query("SELECT
	                  |	CashSale.Ref,
	                  |	CashSale.Date AS Date
	                  |FROM
	                  |	Document.CashSale AS CashSale
	                  |
	                  |ORDER BY
	                  |	Date");
	Result = Query.Execute().Select();
	Result_array = Query.Execute().Unload();
	
	CashSales = New Array();
	
	Try 
		count = ParsedJSON.limit;
		If count > 100 Then count = 100; EndIf;
	Except count = 10; EndTry;
	
	Try offset = ParsedJSON.start_from;
		offsetNum = 0;
		start = 0;
		While Result.Next() Do
			If string(offset) = string(Result.Ref.UUID()) Then
				start = offsetNum+1;
				break;
			Else
				offsetNum = offsetNum +1;
			EndIf;
		EndDo;	
			
	Except offset = undefined; start = 0; EndTry;
	
	Try last = ParsedJSON.end_before;
		offsetNum = 0;
		start = 0;
		While Result.Next() Do
			If string(last) = string(Result.Ref.UUID()) Then
				start = offsetNum-1;
				break;
			Else
				offsetNum = offsetNum +1;
			EndIf;
		EndDo;	
			
	Except last = undefined; start = 0; EndTry;
	
	If last <> undefined AND offset <> undefined Then
		errorMessage = New Map();
		strMessage = "Cannot have both start_after and end_before.";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndIf;
	
	numRecords = 0;
	Try
		
		If last <> undefined Then
			If start-count < 0 Then
				i = 0;
			Else
				i = start-count;
			EndIf;
			While i < start Do
				CashSales.Add(Webhooks.ReturnCashSaleMap(Result_array[i].Ref));
				numRecords = numRecords+1;
				i = i + 1;
			EndDo;
			has_more = true;
		Else

			If count >= Result.Count() Then
				For i=start to Result.Count()-1 Do
					numRecords = numRecords+1;
					CashSales.Add(Webhooks.ReturnCashSaleMap(Result_array[i].Ref));
				EndDo;
				has_more = false;
			Else
				For i=start to start+count-1 Do
					numRecords = numRecords+1;
					CashSales.Add(Webhooks.ReturnCashSaleMap(Result_array[i].Ref));
				EndDo;
				has_more = true;
			EndIf;
			
		EndIf;
			
	Except

		has_more = false;
		
	EndTry;
	
	CashSalesList = New Map();
	CashSalesList.Insert("cash_sales", CashSales);
	CashSalesList.Insert("has_more", has_more);
	CashSalesList.Insert("numOfRecords",numRecords);
	
	jsonout = InternetConnectionClientServer.EncodeJSON(CashSalesList);
	
	Return jsonout;


EndFunction


Function inoutInvoicesCreate(jsonin) Export
		
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
		
	NewInvoice = Documents.SalesInvoice.CreateDocument();
	customer_api_code = ParsedJSON.customer_api_code;
	//CompanyCode = ParsedJSON.company_code;
	NewInvoice.Company = Catalogs.Companies.GetRef(New UUID(customer_api_code));
	ship_to_api_code = ParsedJSON.ship_to_api_code;
	//ShipToAddressCode = ParsedJSON.ship_to_address_code;
	// check if address belongs to company
	NewInvoice.ShipTo = Catalogs.Addresses.GetRef(New UUID(ship_to_api_code));
	// select the company's default shipping address
	
	NewInvoice.Date = ParsedJSON.date;
	NewInvoice.DueDate = ParsedJSON.due_date;
	NewInvoice.Terms = Catalogs.PaymentTerms.DueOnReceipt;
	
	//PaymentMethod = ParsedJSON.Get("payment_method");
	// support all payment methods
	//NewCashSale.PaymentMethod = Catalogs.PaymentMethods.Cash;
	Try
		NewInvoice.RefNum = ParsedJSON.ref_num;
	Except
	EndTry;
	Try
		NewInvoice.Memo = ParsedJSON.memo;
	Except
	EndTry;
	// tax rate - calculate from address?
	Try
		SalesTax = ParsedJSON.sales_tax_total; 
		NewInvoice.SalesTaxRC = ParsedJSON.sales_tax_total;		
	Except
		NewInvoice.SalesTaxRC = 0;
	EndTry;
	NewInvoice.DocumentTotal = ParsedJSON.doc_total;
	NewInvoice.DocumentTotalRC = ParsedJSON.doc_total;
    //NewCashSale.DepositType = "2";
	DefaultCurrency = Constants.DefaultCurrency.Get();
	NewInvoice.Currency = DefaultCurrency;
	NewInvoice.ARAccount = DefaultCurrency.DefaultARAccount;
	//NewCashSale.BankAccount = Constants.BankAccount.Get();
	NewInvoice.ExchangeRate = 1;
	NewInvoice.LocationActual = GeneralFunctions.GetDefaultLocation();
	
	Try NewInvoice.LineSubtotal = ParsedJSON.line_subtotal; Except EndTry;
	Try NewInvoice.Discount = ParsedJSON.discount; Except EndTry;
	Try NewInvoice.DiscountPercent = ParsedJSON.discount_percent; Except EndTry;
	Try NewInvoice.SubTotal = ParsedJSON.subtotal; Except EndTry;
	Try NewInvoice.Shipping = ParsedJSON.shipping; Except EndTry;
	
	DataLineItems = ParsedJSON.lines.line_items;
	
	LineItemsRows = DataLineItems.Count();
	For i = 0 To LineItemsRows -1 Do
		
		NewLine = NewInvoice.LineItems.Add();
		
		Product = Catalogs.Products.GetRef(New UUID(DataLineItems[i].api_code));
		NewLine.Product = Product;
		NewLine.ProductDescription = Product.Description;
		//NewLine.VATCode = CommonUse.GetAttributeValue(Product, "SalesVATCode");
		//NewLine.VAT = 0;
		
		NewLine.PriceUnits = DataLineItems[i].price;
		NewLine.QtyUnits = DataLineItems[i].quantity;
		//Try NewLine.Taxable = DataLineItems[i].taxable; Except EndTry;
		// get taxable from JSON
		//Try
		//	TaxableType = DataLineItems[i].taxable_type;
		//	If TaxableType = "taxable" Then
		//		NewLine.SalesTaxType = Enums.SalesTaxTypes.Taxable;
		//	ElsIf TaxableType = "non-taxable" Then
		//		NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;
		//	Else
		//		NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;
		//	EndIf;
		//Except
		//	NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;	
		//EndTry;
		
		NewLine.LineTotal = DataLineItems[i].line_total;
		//Try
		//	TaxableAmount = DataLineItems[i].taxable_amount;
		//	NewLine.TaxableAmount = TaxableAmount				
		//Except
		//	NewLine.TaxableAmount = 0;
		//EndTry;
				
	EndDo;
	
	NewInvoice.Write();
		
	///
	
	
	InvoiceData = New Map();
	InvoiceData.Insert("api_code", String(NewInvoice.Ref.UUID()));
	InvoiceData.Insert("customer_api_code", String(NewInvoice.Company.Ref.UUID()));
	InvoiceData.Insert("company_name", NewInvoice.Company.Description);
	InvoiceData.Insert("company_code", NewInvoice.Company.Code);
	InvoiceData.Insert("ship_to_api_code", String(NewInvoice.ShipTo.Ref.UUID()));
	InvoiceData.Insert("ship_to_address_id", NewInvoice.ShipTo.Description);
	// date - convert into the same format as input
	InvoiceData.Insert("invoice_number", NewInvoice.Number);
	// payment method - same as input
	//CashSaleData.Insert("payment_method", NewInvoice.PaymentMethod.Description);
	InvoiceData.Insert("date", NewInvoice.Date);
	InvoiceData.Insert("due_date", NewInvoice.DueDate);
	InvoiceData.Insert("ref_num", NewInvoice.RefNum);
	InvoiceData.Insert("memo", NewInvoice.Memo);
	InvoiceData.Insert("sales_tax_total", NewInvoice.SalesTaxRC);
	InvoiceData.Insert("doc_total", NewInvoice.DocumentTotalRC);
	InvoiceData.Insert("line_subtotal", NewInvoice.LineSubtotal);
	InvoiceData.Insert("discount", NewInvoice.Discount);
	InvoiceData.Insert("discount_percent", NewInvoice.DiscountPercent);
	InvoiceData.Insert("subtotal", NewInvoice.SubTotal);
	InvoiceData.Insert("shipping", NewInvoice.Shipping);

	Query = New Query("SELECT
	                  |	InvoiceLineItems.Product,
	                  |	InvoiceLineItems.PriceUnits,
	                  |	InvoiceLineItems.QtyUnits,
	                  |	InvoiceLineItems.LineTotal
	                  |FROM
	                  |	Document.SalesInvoice.LineItems AS InvoiceLineItems
	                  |WHERE
	                  |	InvoiceLineItems.Ref = &Invoice");
	Query.SetParameter("Invoice", NewInvoice.Ref);
	Result = Query.Execute().Select();
	
	LineItems = New Array();
	
	While Result.Next() Do
		
		LineItem = New Map();
		LineItem.Insert("item_code", Result.Product.Code);
		LineItem.Insert("api_code", String(Result.Product.Ref.UUID()));
		LineItem.Insert("item_description", Result.Product.Description);
		LineItem.Insert("price", Result.PriceUnits);
		LineItem.Insert("quantity", Result.QtyUnits);
		//LineItem.Insert("taxable_amount", Result.TaxableAmount);
		LineItem.Insert("line_total", Result.LineTotal);
		//LineItem.Insert("taxable", Result.Taxable);
		//If Result.SalesTaxType = Enums.SalesTaxTypes.Taxable Then
		//	LineItem.Insert("taxable_type", "taxable");
		//ElsIf Result.SalesTaxType = Enums.SalesTaxTypes.NonTaxable Then
		//	LineItem.Insert("taxable_type", "non-taxable");
		//EndIf;
		LineItems.Add(LineItem);
		
	EndDo;
	
	LineItemsData = New Map();
	LineItemsData.Insert("line_items", LineItems);
	
	InvoiceData.Insert("lines", LineItemsData);
	
	jsonout = InternetConnectionClientServer.EncodeJSON(InvoiceData);
	
	Return jsonout;

	
EndFunction

Function inoutInvoicesUpdate(jsonin, object_code) Export
	
	SalesInvoiceNumberJSON = InternetConnectionClientServer.DecodeJSON(object_code);
	api_code = SalesInvoiceNumberJSON.object_code;
		
	XInvoice = Documents.SalesInvoice.GetRef(New UUID(api_code));	
	NewInvoice = XInvoice.GetObject();
	NewInvoice.LineItems.Clear();
	
	///
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
		
	customer_api_code = ParsedJSON.customer_api_code;
	//CompanyCode = ParsedJSON.company_code;
	NewInvoice.Company = Catalogs.Companies.GetRef(New UUID(customer_api_code));
	ship_to_api_code = ParsedJSON.ship_to_api_code;
	//ShipToAddressCode = ParsedJSON.ship_to_address_code;
	// check if address belongs to company
	NewInvoice.ShipTo = Catalogs.Addresses.GetRef(New UUID(ship_to_api_code));
	// select the company's default shipping address
	
	NewInvoice.Date = ParsedJSON.date;
	NewInvoice.DueDate = ParsedJSON.due_date;
	NewInvoice.Terms = Catalogs.PaymentTerms.DueOnReceipt;
	
	//PaymentMethod = ParsedJSON.Get("payment_method");
	// support all payment methods
	//NewCashSale.PaymentMethod = Catalogs.PaymentMethods.Cash;
	Try
		NewInvoice.RefNum = ParsedJSON.ref_num;
	Except
	EndTry;
	Try
		NewInvoice.Memo = ParsedJSON.memo;
	Except
	EndTry;
	// tax rate - calculate from address?
	Try
		SalesTax = ParsedJSON.sales_tax_total; 
		NewInvoice.SalesTaxRC = ParsedJSON.sales_tax_total;		
	Except
		NewInvoice.SalesTaxRC = 0;
	EndTry;
	NewInvoice.DocumentTotal = ParsedJSON.doc_total;
	NewInvoice.DocumentTotalRC = ParsedJSON.doc_total;
    //NewCashSale.DepositType = "2";
	DefaultCurrency = Constants.DefaultCurrency.Get();
	NewInvoice.Currency = DefaultCurrency;
	NewInvoice.ARAccount = DefaultCurrency.DefaultARAccount;
	//NewCashSale.BankAccount = Constants.BankAccount.Get();
	NewInvoice.ExchangeRate = 1;
	NewInvoice.LocationActual = GeneralFunctions.GetDefaultLocation();
	Try NewInvoice.LineSubtotal = ParsedJSON.line_subtotal; Except EndTry;
	Try NewInvoice.Discount = ParsedJSON.discount; Except EndTry;
	Try NewInvoice.DiscountPercent = ParsedJSON.discount_percent; Except EndTry;
	Try NewInvoice.SubTotal = ParsedJSON.subtotal; Except EndTry;
	Try NewInvoice.Shipping = ParsedJSON.shipping; Except EndTry;

	
	DataLineItems = ParsedJSON.lines.line_items;
	
	LineItemsRows = DataLineItems.Count();
	For i = 0 To LineItemsRows -1 Do
		
		NewLine = NewInvoice.LineItems.Add();
		
		Product = Catalogs.Products.GetRef(New UUID(DataLineItems[i].api_code));
		NewLine.Product = Product;
		NewLine.ProductDescription = Product.Description;
		//NewLine.VATCode = CommonUse.GetAttributeValue(Product, "SalesVATCode");
		//NewLine.VAT = 0;
		
		NewLine.PriceUnits = DataLineItems[i].price;
		NewLine.QtyUnits = DataLineItems[i].quantity;
		//Try NewLine.Taxable = DataLineItems[i].taxable; Except EndTry;
		// get taxable from JSON
		//Try
		//	TaxableType = DataLineItems[i].taxable_type;
		//	If TaxableType = "taxable" Then
		//		NewLine.SalesTaxType = Enums.SalesTaxTypes.Taxable;
		//	ElsIf TaxableType = "non-taxable" Then
		//		NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;
		//	Else
		//		NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;
		//	EndIf;
		//Except
		//	NewLine.SalesTaxType = Enums.SalesTaxTypes.NonTaxable;	
		//EndTry;
		
		NewLine.LineTotal = DataLineItems[i].line_total;
		//Try
		//	TaxableAmount = DataLineItems[i].taxable_amount;
		//	NewLine.TaxableAmount = TaxableAmount				
		//Except
		//	NewLine.TaxableAmount = 0;
		//EndTry;
				
	EndDo;
	
	NewInvoice.Write();
		
	///
	
	
	InvoiceData = New Map();
	InvoiceData.Insert("api_code", String(NewInvoice.Ref.UUID()));
	InvoiceData.Insert("customer_api_code", String(NewInvoice.Company.Ref.UUID()));
	InvoiceData.Insert("company_name", NewInvoice.Company.Description);
	InvoiceData.Insert("company_code", NewInvoice.Company.Code);
	InvoiceData.Insert("ship_to_api_code", String(NewInvoice.ShipTo.Ref.UUID()));
	InvoiceData.Insert("ship_to_address_id", NewInvoice.ShipTo.Description);
	// date - convert into the same format as input
	InvoiceData.Insert("invoice_number", NewInvoice.Number);
	// payment method - same as input
	//CashSaleData.Insert("payment_method", NewInvoice.PaymentMethod.Description);
	InvoiceData.Insert("date", NewInvoice.Date);
	InvoiceData.Insert("due_date", NewInvoice.DueDate);
	InvoiceData.Insert("ref_num", NewInvoice.RefNum);
	InvoiceData.Insert("memo", NewInvoice.Memo);
	InvoiceData.Insert("sales_tax_total", NewInvoice.SalesTaxRC);
	InvoiceData.Insert("doc_total", NewInvoice.DocumentTotalRC);
	InvoiceData.Insert("line_subtotal", NewInvoice.LineSubtotal);
	InvoiceData.Insert("discount", NewInvoice.Discount);
	InvoiceData.Insert("discount_percent", NewInvoice.DiscountPercent);
	InvoiceData.Insert("subtotal", NewInvoice.SubTotal);
	InvoiceData.Insert("shipping", NewInvoice.Shipping);

	Query = New Query("SELECT
	                  |	InvoiceLineItems.Product,
	                  |	InvoiceLineItems.PriceUnits,
	                  |	InvoiceLineItems.QtyUnits,
	                  |	InvoiceLineItems.LineTotal
	                  |FROM
	                  |	Document.SalesInvoice.LineItems AS InvoiceLineItems
	                  |WHERE
	                  |	InvoiceLineItems.Ref = &Invoice");
	Query.SetParameter("Invoice", NewInvoice.Ref);
	Result = Query.Execute().Select();
	
	LineItems = New Array();
	
	While Result.Next() Do
		
		LineItem = New Map();
		LineItem.Insert("item_code", Result.Product.Code);
		LineItem.Insert("api_code", String(Result.Product.Ref.UUID()));
		LineItem.Insert("item_description", Result.Product.Description);
		LineItem.Insert("price", Result.PriceUnits);
		LineItem.Insert("quantity", Result.QtyUnits);
		//LineItem.Insert("taxable_amount", Result.TaxableAmount);
		LineItem.Insert("line_total", Result.LineTotal);
		//LineItem.Insert("taxable", Result.Taxable);
		//If Result.SalesTaxType = Enums.SalesTaxTypes.Taxable Then
		//	LineItem.Insert("taxable_type", "taxable");
		//ElsIf Result.SalesTaxType = Enums.SalesTaxTypes.NonTaxable Then
		//	LineItem.Insert("taxable_type", "non-taxable");
		//EndIf;
		LineItems.Add(LineItem);
		
	EndDo;
	
	LineItemsData = New Map();
	LineItemsData.Insert("line_items", LineItems);
	
	InvoiceData.Insert("lines", LineItemsData);
	
	jsonout = InternetConnectionClientServer.EncodeJSON(InvoiceData);
	
	Return jsonout;


EndFunction

Function inoutInvoicesGet(jsonin) Export
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	api_code = ParsedJSON.object_code;
	
	Try
		NewInvoice = Documents.SalesInvoice.GetRef(New UUID(api_code));
	Except
		errorMessage = New Map();
		strMessage = " [api_code] : The sales invoice does not exist. Double check that the ID# is correct. ";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndTry;
	
	SIQuery = New Query("SELECT
	                    |	SalesInvoice.Ref
	                    |FROM
	                    |	Document.SalesInvoice AS SalesInvoice
	                    |WHERE
	                    |	SalesInvoice.Ref = &Ref");
	SIQuery.SetParameter("Ref", NewInvoice);
	SIresult = SIQuery.Execute();
	If SIresult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = " [api_code] : The sales invoice does not exist. Double check that the ID# is correct. ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
	EndIf;
		
	InvoiceData = New Map();
	InvoiceData.Insert("api_code", String(NewInvoice.Ref.UUID()));
	InvoiceData.Insert("customer_api_code", String(NewInvoice.Company.Ref.UUID()));
	InvoiceData.Insert("company_name", NewInvoice.Company.Description);
	InvoiceData.Insert("company_code", NewInvoice.Company.Code);
	InvoiceData.Insert("ship_to_api_code", String(NewInvoice.ShipTo.Ref.UUID()));
	InvoiceData.Insert("ship_to_address_id", NewInvoice.ShipTo.Description);
	// date - convert into the same format as input
	InvoiceData.Insert("invoice_number", NewInvoice.Number);
	// payment method - same as input
	//CashSaleData.Insert("payment_method", NewInvoice.PaymentMethod.Description);
	InvoiceData.Insert("date", NewInvoice.Date);
	InvoiceData.Insert("due_date", NewInvoice.DueDate);
	InvoiceData.Insert("ref_num", NewInvoice.RefNum);
	InvoiceData.Insert("memo", NewInvoice.Memo);
	InvoiceData.Insert("sales_tax_total", NewInvoice.SalesTaxRC);
	InvoiceData.Insert("doc_total", NewInvoice.DocumentTotalRC);
	InvoiceData.Insert("line_subtotal", NewInvoice.LineSubtotal);
	InvoiceData.Insert("discount", NewInvoice.Discount);
	InvoiceData.Insert("discount_percent", NewInvoice.DiscountPercent);
	InvoiceData.Insert("subtotal", NewInvoice.SubTotal);
	InvoiceData.Insert("shipping", NewInvoice.Shipping);

	Query = New Query("SELECT
	                  |	InvoiceLineItems.Product,
	                  |	InvoiceLineItems.PriceUnits,
	                  |	InvoiceLineItems.QtyUnits,
	                  |	InvoiceLineItems.LineTotal
	                  |FROM
	                  |	Document.SalesInvoice.LineItems AS InvoiceLineItems
	                  |WHERE
	                  |	InvoiceLineItems.Ref = &Invoice");
	Query.SetParameter("Invoice", NewInvoice.Ref);
	Result = Query.Execute().Select();
	
	LineItems = New Array();
	
	While Result.Next() Do
		
		LineItem = New Map();
		LineItem.Insert("item_code", Result.Product.Code);
		LineItem.Insert("api_code", String(Result.Product.Ref.UUID()));
		LineItem.Insert("item_description", Result.Product.Description);
		LineItem.Insert("price", Result.PriceUnits);
		LineItem.Insert("quantity", Result.QtyUnits);
		//LineItem.Insert("taxable", Result.Taxable);
		//LineItem.Insert("taxable_amount", Result.TaxableAmount);
		LineItem.Insert("line_total", Result.LineTotal);
		//If Result.SalesTaxType = Enums.SalesTaxTypes.Taxable Then
		//	LineItem.Insert("taxable_type", "taxable");
		//ElsIf Result.SalesTaxType = Enums.SalesTaxTypes.NonTaxable Then
		//	LineItem.Insert("taxable_type", "non-taxable");
		//EndIf;
		LineItems.Add(LineItem);
		
	EndDo;
	
	LineItemsData = New Map();
	LineItemsData.Insert("line_items", LineItems);
	
	InvoiceData.Insert("lines", LineItemsData);
	
	jsonout = InternetConnectionClientServer.EncodeJSON(InvoiceData);
	
	Return jsonout;



EndFunction

Function inoutInvoicesDelete(jsonin) Export
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	api_code = ParsedJSON.object_code;
	
	SalesInvoice = Documents.SalesInvoice.GetRef(New UUID(api_code));
	
	SalesInvoiceObj = SalesInvoice.GetObject();
	invoiceNum = SalesInvoiceObj.Number;
	date = SalesInvoiceObj.Date;
	SetPrivilegedMode(True);
	Try
		SalesInvoiceObj.Delete();//.DeletionMark = True;
	Except
		errorMessage = New Map();
		strMessage = "Failed to delete. Invoice must be unposted before deletion and/or other objects are linked to this sales invoice.";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("sales_invoice_number",invoiceNum);
		errorMessage.Insert("date", date);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndTry;
	SetPrivilegedMode(False);
	
	Output = New Map();	
	
	//Try
	//	SalesInvoiceObj.Write(DocumentWriteMode.UndoPosting);
		Output.Insert("status", "success");
		strMessage = "Invoice # " + invoiceNum + " from " + date + " has been deleted.";
		Output.Insert("message", strMessage);
	//Except
		//ErrorMessage = DetailErrorDescription(ErrorInfo());
	//	Output.Insert("error", "sales invoice can not be deleted");
	//EndTry;
	
	jsonout = InternetConnectionClientServer.EncodeJSON(Output);
	
	Return jsonout;

EndFunction

Function inoutInvoicesListAll(jsonin) Export
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
		
	Query = New Query("SELECT
	                  |	SalesInvoice.Ref
	                  |FROM
	                  |	Document.SalesInvoice AS SalesInvoice
	                  |
	                  |ORDER BY
	                  |	SalesInvoice.Date");
	Result = Query.Execute().Select();

	Result_array = Query.Execute().Unload();
	
	Invoices = New Array();
	
	Try 
		count = ParsedJSON.limit;
		If count > 100 Then count = 100; EndIf;
	Except count = 10; EndTry;
	
	Try offset = ParsedJSON.start_from;
		offsetNum = 0;
		start = 0;
		While Result.Next() Do
			If string(offset) = string(Result.Ref.UUID()) Then
				start = offsetNum+1;
				break;
			Else
				offsetNum = offsetNum +1;
			EndIf;
		EndDo;	
			
	Except offset = undefined; start = 0; EndTry;
	
	Try last = ParsedJSON.end_before;
		offsetNum = 0;
		start = 0;
		While Result.Next() Do
			If string(last) = string(Result.Ref.UUID()) Then
				start = offsetNum-1;
				break;
			Else
				offsetNum = offsetNum +1;
			EndIf;
		EndDo;	
			
	Except last = undefined; start = 0; EndTry;
	
	If last <> undefined AND offset <> undefined Then
		errorMessage = New Map();
		strMessage = "Cannot have both start_after and end_before.";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndIf;
	
	numRecords = 0;
	Try
		
		If last <> undefined Then
			If start-count < 0 Then
				i = 0;
			Else
				i = start-count;
			EndIf;
			While i < start Do
				Invoices.Add(Webhooks.ReturnSalesInvoiceMap(Result_array[i].Ref));
				numRecords = numRecords+1;
				i = i + 1;
			EndDo;
			has_more = true;
		Else
			
			If count >= Result.Count() Then
				For i=start to Result.Count()-1 Do
					numRecords = numRecords+1;
					Invoices.Add(Webhooks.ReturnSalesInvoiceMap(Result_array[i].Ref));
				EndDo;
				has_more = false;
			Else
				For i=start to start+count-1 Do
					numRecords = numRecords+1;
					Invoices.Add(Webhooks.ReturnSalesInvoiceMap(Result_array[i].Ref));
				EndDo;
				has_more = true;
			EndIf;
			
		EndIf;
	
	Except

		has_more = false;
		
	EndTry;
			
	InvoicesList = New Map();
	InvoicesList.Insert("invoices", Invoices);
	InvoicesList.Insert("has_more", has_more);
	InvoicesList.Insert("numOfRecords",numRecords);
	
	jsonout = InternetConnectionClientServer.EncodeJSON(InvoicesList);
	
	Return jsonout;


EndFunction


Function inoutSalesOrdersCreate(jsonin) Export
		
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
		
	NewSO = Documents.SalesOrder.CreateDocument();
	
	Try customer_api_code = ParsedJSON.customer_api_code Except customer_api_code = Undefined EndTry;
	If NOT customer_api_code = Undefined Then
		
		Try
		cust = Catalogs.Companies.GetRef(New UUID(customer_api_code));
		Except
			errorMessage = New Map();
			strMessage = "[customer_api_code] : The customer does not exist";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndTry;

	   // check if customer api code is valid
	   custQuery = New Query("SELECT
	   						 |	Companies.Ref
							 |FROM
							 |	Catalog.Companies AS Companies
							 |WHERE
							 |	Companies.Ref = &custCode");
		custQuery.SetParameter("custCode", cust);
		custResult = custQuery.Execute();
		If custResult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = "[customer_api_code] : The customer does not exist";
			errorMessage.Insert("status", "error"); 
			errorMessage.Insert("message", strMessage);
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;					 
		NewSO.Company = cust;
	Else
		errorMessage = New Map();
		strMessage = "[customer_api_code] : This field is required";
		errorMessage.Insert("status", "error"); 
		errorMessage.Insert("message", strMessage);
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
		
	EndIf;
	
	tempSO = handleDocumentAddresses(ParsedJSON, NewSO, "create");
	Try
		If tempSO.Get("status") = "error" Then
			errorJSON = InternetConnectionClientServer.EncodeJSON(tempSO);
			return errorJSON;
		EndIf;
	Except
	EndTry;
	
	NewSO = tempSO;
		
	Numerator = Catalogs.DocumentNumbering.SalesOrder;
	NextNumber = GeneralFunctions.Increment(Numerator.Number);

	While Documents.SalesOrder.FindByNumber(NextNumber) <> Documents.SalesOrder.EmptyRef() And NextNumber <> "" Do
		ObjectNumerator = Numerator.GetObject();
		ObjectNumerator.Number = NextNumber;
		ObjectNumerator.Write();
		
		NextNumber = GeneralFunctions.Increment(NextNumber);
	EndDo;
	NewSO.Number = NextNumber;
	
	Try date = ParsedJSON.date Except date = Undefined EndTry;
	If date = Undefined Then
		//use current date
		NewSO.Date = CurrentSessionDate(); 
		
	Else
		NewSO.Date = "01/22/2013"; // creating a failed date
		wrongDate = NewSO.Date;
		NewSO.Date = ParsedJSON.date;
		If NewSO.Date = wrongDate Then
			errorMessage = New Map();
			strMessage = " [date] : Date must be in the format of YYYY-MM-DD ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		
		NewSO.Date = ParsedJSON.date;
	EndIf;
	
	Try promise_date = ParsedJSON.promise_date Except promise_date = Undefined EndTry;
	If promise_date <> Undefined Then
		NewSO.DeliveryDate = "01/22/2013"; // creating a failed date
		wrongDate = NewSO.DeliveryDate;
		NewSO.DeliveryDate = ParsedJSON.promise_date;
		If NewSO.DeliveryDate = wrongDate Then
			errorMessage = New Map();
			strMessage = " [promise_date] : Date must be in the format of YYYY-MM-DD ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		
		NewSO.DeliveryDate = ParsedJSON.promise_date;
	EndIf;
	
	Try
		NewSO.RefNum = ParsedJSON.ref_num;
	Except
	EndTry;
	
	Try
		NewSO.CF1String = ParsedJSON.cf1_string;
	Except
	EndTry;	
	
	Try
		NewSO.Memo = ParsedJSON.int_memo;
	Except
	EndTry;
	Try
		NewSO.Memo = ParsedJSON.memo;
	Except
	EndTry;
	
	Try
		NewSO.EmailNote = ParsedJSON.ext_memo;
	Except
	EndTry;
	NewSO.Currency = NewSO.Company.DefaultCurrency;
	NewSO.ExchangeRate = 1;
	NewSO.Location = Catalogs.Locations.MainWarehouse;
	
	tempSO = handleDocumentTotals(ParsedJSON, NewSO);
	Try
		If tempSO.Get("status") = "error" Then
			errorJSON = InternetConnectionClientServer.EncodeJSON(tempSO);
			return errorJSON;
		EndIf;
	Except
	EndTry;
	NewSO = tempSO;
		
	NewSO.Write(DocumentWriteMode.Posting);
		
	jsonout = InternetConnectionClientServer.EncodeJSON(GeneralFunctions.ReturnSaleOrderMap(NewSO.Ref));
	
	Return jsonout;
	
EndFunction

Function inoutSalesOrdersUpdate(jsonin, object_code) Export
	
	SONumberJSON = InternetConnectionClientServer.DecodeJSON(object_code);
		
	Try api_code = SONumberJSON.object_code Except api_code = Undefined EndTry;
	If api_code = Undefined  OR api_code = "" Then
		errorMessage = New Map();
		strMessage = " [api_code] : Missing sales order ID# ";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndIf;
	
	Try
		XSO = Documents.SalesOrder.GetRef(New UUID(api_code));
	Except
		errorMessage = New Map();
		strMessage = " [api_code] : The sales order does not exist. Double check that the ID# is correct. ";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndTry;
	
	SOQuery = New Query("SELECT
	                    |	SalesOrder.Ref
	                    |FROM
	                    |	Document.SalesOrder AS SalesOrder
	                    |WHERE
	                    |	SalesOrder.Ref = &so");
	SOQuery.SetParameter("so", XSO);
	SOresult = SOQuery.Execute();
	If SOresult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = " [api_code] : The sales order does not exist. Double check that the ID# is correct. ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
	EndIf;

	NewSO = XSO.GetObject();
	NewSO.LineItems.Clear();
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	
	Try customer_api_code = ParsedJSON.customer_api_code Except customer_api_code = Undefined EndTry;
	If NOT customer_api_code = Undefined Then
		
		Try
		cust = Catalogs.Companies.GetRef(New UUID(customer_api_code));
		Except
			errorMessage = New Map();
			strMessage = "[customer_api_code] : The customer does not exist";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndTry;

	   // check if customer api code is valid
	   custQuery = New Query("SELECT
	   						 |	Companies.Ref
							 |FROM
							 |	Catalog.Companies AS Companies
							 |WHERE
							 |	Companies.Ref = &custCode");
		custQuery.SetParameter("custCode", cust);
		custResult = custQuery.Execute();
		If custResult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = "[customer_api_code] : The customer does not exist";
			errorMessage.Insert("status", "error"); 
			errorMessage.Insert("message", strMessage);
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;					 
		NewSO.Company = cust;

	EndIf;
	
	tempSO = handleDocumentAddresses(ParsedJSON, NewSO, "update");
	Try
		If tempSO.Get("status") = "error" Then
			errorJSON = InternetConnectionClientServer.EncodeJSON(tempSO);
			return errorJSON;
		EndIf;
	Except
	EndTry;
	
	NewSO = tempSO;
			
	Try date = ParsedJSON.date Except date = Undefined EndTry;
	If NOT date = Undefined Then
		NewSO.Date = "01/22/2013"; // creating a failed date
		wrongDate = NewSO.Date;
		NewSO.Date = ParsedJSON.date;
		If NewSO.Date = wrongDate Then
			errorMessage = New Map();
			strMessage = " [date] : Date must be in the format of YYYY-MM-DD ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		
		NewSO.Date = ParsedJSON.date;
	EndIf;
	
	Try promise_date = ParsedJSON.promise_date Except promise_date = Undefined EndTry;
	If promise_date <> Undefined Then
		NewSO.DeliveryDate = "01/22/2013"; // creating a failed date
		wrongDate = NewSO.DeliveryDate;
		NewSO.DeliveryDate = ParsedJSON.promise_date;
		If NewSO.DeliveryDate = wrongDate Then
			errorMessage = New Map();
			strMessage = " [promise_date] : Date must be in the format of YYYY-MM-DD ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		
		NewSO.DeliveryDate = ParsedJSON.promise_date;
	EndIf;
	
	Try
		NewSO.RefNum = ParsedJSON.ref_num;
	Except
	EndTry;
	
	Try
		NewSO.CF1String = ParsedJSON.cf1_string;
	Except
	EndTry;	
	
	Try
		NewSO.Memo = ParsedJSON.int_memo;
	Except
	EndTry;
	Try
		NewSO.Memo = ParsedJSON.memo;
	Except
	EndTry;
	
	Try
		NewSO.EmailNote = ParsedJSON.ext_memo;
	Except
	EndTry;
	
	tempSO = handleDocumentTotals(ParsedJSON, NewSO);
	Try
		If tempSO.Get("status") = "error" Then
			errorJSON = InternetConnectionClientServer.EncodeJSON(tempSO);
			return errorJSON;
		EndIf;
	Except
	EndTry;
	NewSO = tempSO;
		
	NewSO.Write(DocumentWriteMode.Posting);
		
	jsonout = InternetConnectionClientServer.EncodeJSON(GeneralFunctions.ReturnSaleOrderMap(NewSO.Ref));
	
	Return jsonout;	

EndFunction

Function inoutSalesOrdersGet(jsonin) Export
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	api_code = ParsedJSON.object_code;
	
	Try
		SO = Documents.SalesOrder.GetRef(New UUID(api_code));
	Except
		errorMessage = New Map();
		strMessage = " [api_code] : The sales order does not exist. Double check that the ID# is correct. ";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndTry;
	
	SOQuery = New Query("SELECT
	                    |	SalesOrder.Ref
	                    |FROM
	                    |	Document.SalesOrder AS SalesOrder
	                    |WHERE
	                    |	SalesOrder.Ref = &Ref");
	SOQuery.SetParameter("Ref", SO);
	SOresult = SOQuery.Execute();
	If SOresult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = " [api_code] : The sales order does not exist. Double check that the ID# is correct. ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
	EndIf;
		
	
	jsonout = InternetConnectionClientServer.EncodeJSON(GeneralFunctions.ReturnSaleOrderMap(SO));
	
	Return jsonout;
EndFunction

Function inoutSalesOrdersDelete(jsonin) Export
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	api_code = ParsedJSON.object_code;
	
	SO = Documents.SalesOrder.GetRef(New UUID(api_code));
	
	SO_Obj = SO.GetObject();
	SO_Num = SO_Obj.Number;
	date = SO_Obj.Date;
	SetPrivilegedMode(True);
	Try
		SO_Obj.Delete();//.DeletionMark = True;
	Except
		errorMessage = New Map();
		strMessage = "Failed to delete. Sales Orders must be unposted before deletion and/or other objects are linked to this sales order.";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("so_number",SO_Num);
		errorMessage.Insert("date", date);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndTry;
	SetPrivilegedMode(False);
	
	Output = New Map();	
	
	//Try
	//	SalesInvoiceObj.Write(DocumentWriteMode.UndoPosting);
		Output.Insert("status", "success");
		strMessage = "Sales Order # " + SO_Num + " from " + date + " has been deleted.";
		Output.Insert("message", strMessage);
	//Except
		//ErrorMessage = DetailErrorDescription(ErrorInfo());
	//	Output.Insert("error", "sales invoice can not be deleted");
	//EndTry;
	
	jsonout = InternetConnectionClientServer.EncodeJSON(Output);
	
	Return jsonout;	
EndFunction

Function inoutSalesOrdersListAll(jsonin, limit, start_after, end_before) Export
	
	Try limit = Number(limit);
	Except
		limit = 10; //default
	EndTry;
	
	If limit < 1 Then 
		errorMessage = New Map();
		strMessage = "[limit] : Cannot have a value less than 1";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndIf;
	
	If start_after <> "undefined" AND end_before <> "undefined" Then
		
		errorMessage = New Map();
		strMessage = "Please choose only one, start_after or end_before.";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
		
	ElsIf start_after <> "undefined" AND end_before = "undefined" Then
		
		Try
			SalesOrder = Documents.SalesOrder.GetRef(New UUID(start_after));
		Except
			errorMessage = New Map();
			strMessage = "[start_after] : The item does not exist. Double check that the api_code is correct. ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndTry;
		
		ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
		Query =  New Query("SELECT
					  |	SalesOrder.Ref
					  |FROM
					  |	Document.SalesOrder AS SalesOrder
					  |
					  |ORDER BY
					  |	SalesOrder.Date");
					  
		Result = Query.Execute().Select();
		Result_array = Query.Execute().Unload();
		
		SalesOrders = New Array();
		
		i = 0;
		j = 0;
		While i < Result.Count() Do
			If Result_array[i].Ref = SalesOrder.Ref Then
				j = i+1;
				break;
			EndIf;
			i = i + 1;
		EndDo;
		
		limit = limit + j;
		numRecords = 0;
		While j < limit AND j < Result.Count() Do
			SalesOrders.Add(GeneralFunctions.ReturnSaleOrderMap(Result_array[j].Ref));
			numRecords = numRecords+1;
			j = j + 1;
		EndDo;
		
		If j+1 < Result.Count() Then 
			has_more = TRUE;
		Else
			has_more = FALSE;
		EndIf;
		
		SOList = New Map();
		SOList.Insert("items", SalesOrders);
		SOList.Insert("more_records", has_more);
		SOList.Insert("num_records_listed",numRecords);
		SOList.Insert("total_num_records", Result.Count());
		
		jsonout = InternetConnectionClientServer.EncodeJSON(SOList);
		
		Return jsonout;
		
	ElsIf start_after = "undefined" AND end_before <> "undefined" Then
		
		Try
			SalesOrder = Documents.SalesOrder.GetRef(New UUID(end_before));
		Except
			errorMessage = New Map();
			strMessage = "[end_before] : The item does not exist. Double check that the api_code is correct. ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndTry;
		
		ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
		Query = New Query("SELECT
					  |	SalesOrder.Ref
					  |FROM
					  |	Document.SalesOrder AS SalesOrder
					  |
					  |ORDER BY
					  |	SalesOrder.Date");
					  
		Result = Query.Execute().Select();
		Result_array = Query.Execute().Unload();
		
		SalesOrders = New Array();
		
		i = 0;
		j = 0;
		While i < Result.Count() Do
			If Result_array[i].Ref = SalesOrder.Ref Then
				j = i;
				break;
			EndIf;
			i = i + 1;
		EndDo;
		
		start = j - limit;
		If start < 0 Then
			start = 0;
		EndIf;
		
		numRecords = 0;
		While start < j AND start < Result.Count() Do
			SalesOrders.Add(GeneralFunctions.ReturnSaleOrderMap(Result_array[start].Ref));
			numRecords = numRecords+1;
			start = start + 1;
		EndDo;
		
		If start+1 < Result.Count() Then 
			has_more = TRUE;
		Else
			has_more = FALSE;
		EndIf;
		
		SOList = New Map();
		SOList.Insert("items", SalesOrders);
		SOList.Insert("more_records", has_more);
		SOList.Insert("num_records_listed",numRecords);
		SOList.Insert("total_num_records", Result.Count());
		
		jsonout = InternetConnectionClientServer.EncodeJSON(SOList);
		
		Return jsonout;
		
	Else
		// both undefined, just print with limit
		ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
		Query = New Query("SELECT
					  |	SalesOrder.Ref
					  |FROM
					  |	Document.SalesOrder AS SalesOrder
					  |
					  |ORDER BY
					  |	SalesOrder.Date");;
					  
		Result = Query.Execute().Select();
		Result_array = Query.Execute().Unload();
		
		SalesOrders = New Array();
		
		i = 0;
		numRecords = 0;
		While i < limit AND i < Result.Count() Do
			SalesOrders.Add(GeneralFunctions.ReturnSaleOrderMap(Result_array[i].Ref));
			numRecords = numRecords+1;
			i = i + 1;
		EndDo;
		
		If numRecords < Result.Count() Then 
			has_more = TRUE;
		Else
			has_more = FALSE;
		EndIf;
		
		SOList = New Map();
		SOList.Insert("items", SalesOrders);
		SOList.Insert("more_records", has_more);
		SOList.Insert("num_records_listed",numRecords);
		SOList.Insert("total_num_records", Result.Count());
		
		jsonout = InternetConnectionClientServer.EncodeJSON(SoList);
		
		Return jsonout;
		
	EndIf;
	
EndFunction


Function inoutPurchaseOrdersCreate(jsonin) Export
		
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
		
	NewPO = Documents.PurchaseOrder.CreateDocument();

	Try customer_api_code = ParsedJSON.customer_api_code Except customer_api_code = Undefined EndTry;
	If NOT customer_api_code = Undefined Then
		
		Try
		cust = Catalogs.Companies.GetRef(New UUID(customer_api_code));
		Except
			errorMessage = New Map();
			strMessage = "[customer_api_code] : The customer does not exist.";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndTry;

	   // check if customer api code is valid
	   custQuery = New Query("SELECT
	   						 |	Companies.Ref
							 |FROM
							 |	Catalog.Companies AS Companies
							 |WHERE
							 |	Companies.Ref = &custCode");
		custQuery.SetParameter("custCode", cust);
		custResult = custQuery.Execute();
		If custResult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = "[customer_api_code] : The customer does not exist.";
			errorMessage.Insert("status", "error"); 
			errorMessage.Insert("message", strMessage);
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;					 
		NewPO.Company = cust;
	Else
		errorMessage = New Map();
		strMessage = "[customer_api_code] : This field is required.";
		errorMessage.Insert("status", "error"); 
		errorMessage.Insert("message", strMessage);
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
		
	EndIf;
	// purchase ADDRESS SECTION
	
	Try address_api_code = ParsedJSON.address_api_code Except address_api_code = Undefined EndTry;
	If NOT address_api_code = Undefined Then

		Try addr = Catalogs.Addresses.GetRef(New UUID(address_api_code)) Except addr = Undefined EndTry;
		
		newQuery = New Query("SELECT
		                     |	Addresses.Ref
		                     |FROM
		                     |	Catalog.Addresses AS Addresses
		                     |WHERE
		                     |	Addresses.Owner = &Customer
		                     |	AND Addresses.Ref = &addrCode");
							 
		newQuery.SetParameter("Customer", NewPO.Company);
		newQuery.SetParameter("addrCode", addr);
		addrResult = newQuery.Execute();
		If addrResult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = " [address_api_code] : Purchase Address does not belong to the Company ";
			errorMessage.Insert("status", "error"); 
			errorMessage.Insert("message", strMessage);
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		NewPO.CompanyAddress = addr;
		
	Else
		
		Query = New Query("SELECT
		                  |	Addresses.Ref
		                  |FROM
		                  |	Catalog.Addresses AS Addresses
		                  |WHERE
		                  |	Addresses.Owner = &Customer
		                  |	AND Addresses.AddressLine1 = &AddressLine1
		                  |	AND Addresses.AddressLine2 = &AddressLine2
		                  |	AND Addresses.City = &City
		                  |	AND Addresses.State = &State
		                  |	AND Addresses.ZIP = &ZIP
		                  |	AND Addresses.Country = &Country");
		Query.SetParameter("Customer", NewPO.Company);
		
		Try purchase_address_line1 = ParsedJSON.purchase_address_line1 Except purchase_address_line1 = Undefined EndTry;
		If NOT purchase_address_line1 = Undefined Then
			Query.SetParameter("AddressLine1", purchase_address_line1);
		Else
			Query.SetParameter("AddressLine1", "");
		EndIf;
		
		Try purchase_address_line2 = ParsedJSON.purchase_address_line2 Except purchase_address_line2 = Undefined EndTry;
		If NOT purchase_address_line2 = Undefined Then
			Query.SetParameter("AddressLine2", purchase_address_line2);
		Else
			Query.SetParameter("AddressLine2", "");
		EndIf;
		
		Try purchase_city = ParsedJSON.purchase_city Except purchase_city = Undefined EndTry;
		If NOT purchase_city = Undefined Then
			Query.SetParameter("City", purchase_city);
		Else
			Query.SetParameter("City", "");
		EndIf;
		
		Try purchase_zip = ParsedJSON.purchase_zip Except purchase_zip = Undefined EndTry;
		If NOT purchase_zip = Undefined Then
			Query.SetParameter("ZIP", purchase_zip);
		Else
			Query.SetParameter("ZIP", "");
		EndIf;
		
		Try purchase_state = ParsedJSON.purchase_state Except purchase_state = Undefined EndTry;
		If NOT purchase_state = Undefined Then
			Query.SetParameter("State", Catalogs.States.FindByCode(purchase_state));
		Else
			Query.SetParameter("State", Catalogs.States.EmptyRef());
		EndIf;
		
		Try purchase_country = ParsedJSON.purchase_country Except purchase_country = Undefined EndTry;
		If NOT purchase_country = Undefined Then
			Query.SetParameter("Country", Catalogs.Countries.FindByCode(purchase_country));
		Else
			Query.SetParameter("Country", Catalogs.Countries.EmptyRef());
		EndIf;
		
		QueryResult = Query.Execute();
		
		If QueryResult.IsEmpty() Then
			// create new address		
			AddressLine = Catalogs.Addresses.CreateItem();
			AddressLine.Owner = NewPO.Company;

			Try
				AddressLine.Description = ParsedJSON.purchase_address_id;
			Except
				// generate "ShipTo_" + five random characters address ID

				PasswordLength = 5;
				SymbolString = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"; //62
				RandomChars5 = "";
				RNG = New RandomNumberGenerator;	
				For i = 0 to PasswordLength-1 Do
					RN = RNG.RandomNumber(1, 62);
					RandomChars5 = RandomChars5 + Mid(SymbolString,RN,1);
				EndDo;

				AddressLine.Description = "purchase_address_" + RandomChars5;
			EndTry;
			
			Try	AddressLine.FirstName = ParsedJSON.purchase_first_name; Except EndTry;			
			Try AddressLine.MiddleName = ParsedJSON.purchase_middle_name; Except EndTry;			
			Try AddressLine.LastName = ParsedJSON.purchase_last_name; Except EndTry;				
			Try AddressLine.Phone = ParsedJSON.purchase_phone; Except EndTry;			
			Try AddressLine.Cell = ParsedJSON.purchase_cell; Except EndTry;			
			Try AddressLine.Email = ParsedJSON.purchase_email; Except EndTry;			
			Try AddressLine.AddressLine1 = ParsedJSON.purchase_address_line1; Except EndTry;			
			Try	AddressLine.AddressLine2 = ParsedJSON.purchase_address_line2; Except EndTry;			
			Try	AddressLine.City = ParsedJSON.purchase_city; Except EndTry;
			Try AddressLine.State = Catalogs.States.FindByCode(ParsedJSON.purchase_state); Except EndTry;			
			Try AddressLine.Country = Catalogs.Countries.FindByCode(ParsedJSON.purchase_country); Except EndTry;			
			Try AddressLine.ZIP = ParsedJSON.purchase_zip; Except EndTry;
			Try	AddressLine.Notes = ParsedJSON.purchase_notes; Except EndTry;			
			Try AddressLine.SalesTaxCode = Catalogs.SalesTaxCodes.FindByCode(ParsedJSON.purchase_sales_tax_code); Except EndTry;			
			
			AddressLine.Write();
			NewPO.CompanyAddress = AddressLine.Ref;
			
		Else
			// select first address in the dataset
			Dataset = QueryResult.Unload();
			NewPO.CompanyAddress = Dataset[0].Ref; 
		EndIf

	EndIf;
	
	// Dropship stuff
	//
	Try ds_customer_api_code = ParsedJSON.ds_customer_api_code Except ds_customer_api_code = Undefined EndTry;
	If NOT ds_customer_api_code = Undefined Then
		
		Try
		cust = Catalogs.Companies.GetRef(New UUID(ds_customer_api_code));
		Except
			errorMessage = New Map();
			strMessage = "[ds_customer_api_code] : The customer does not exist.";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndTry;

	   // check if customer api code is valid
	   custQuery = New Query("SELECT
	   						 |	Companies.Ref
							 |FROM
							 |	Catalog.Companies AS Companies
							 |WHERE
							 |	Companies.Ref = &custCode");
		custQuery.SetParameter("custCode", cust);
		custResult = custQuery.Execute();
		If custResult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = "[ds_customer_api_code] : The customer does not exist.";
			errorMessage.Insert("status", "error"); 
			errorMessage.Insert("message", strMessage);
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;					 
		NewPO.DropshipCompany = cust;
		
	EndIf;
	
	Try ds_address_api_code = ParsedJSON.ds_address_api_code Except ds_address_api_code = Undefined EndTry;
	If NOT ds_address_api_code = Undefined Then
		// todo - check if address belongs to company
		NewPO.DropshipShipTo = Catalogs.Addresses.GetRef(New UUID(ds_address_api_code));
		Try addrDrop = Catalogs.Addresses.GetRef(New UUID(ds_address_api_code)) Except addrDrop = Undefined EndTry;
		
		newQuery = New Query("SELECT
							 |	Addresses.Ref
							 |FROM
							 |	Catalog.Addresses AS Addresses
							 |WHERE
							 |	Addresses.Owner = &Customer
							 |	AND Addresses.Ref = &addrCode");
							 
		newQuery.SetParameter("Customer", NewPO.DropshipCompany);
		newQuery.SetParameter("addrCode", addrDrop);
		DropResult = newQuery.Execute();
		If DropResult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = " [ds_address_api_code] : Dropship Address does not belong to the Company " ;
			errorMessage.Insert("status", "error");
			errorMessage.Insert("message", strMessage );
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		NewPO.DropshipShipTo = addrDrop;
		
	EndIf;
		
	Try po_date = ParsedJSON.po_date Except po_date = Undefined EndTry;
	If po_date = Undefined Then
		errorMessage = New Map();
		strMessage = " [po_date] : This field is required ";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndIf;
	NewPO.Date = "01/22/2013"; // creating a failed date
	wrongDate = NewPO.Date;
	NewPO.Date = ParsedJSON.po_date;
	If NewPO.Date = wrongDate Then
		errorMessage = New Map();
		strMessage = " [po_date] : Date must be in the format of YYYY-MM-DD ";
		errorMessage.Insert("message", strMessage);
		errorMessage.Insert("status", "error"); 
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndIf;
	
	NewPO.Date = ParsedJSON.po_date;
	
	Try 
		delivery_date = ParsedJSON.delivery_date; 

		NewPO.DeliveryDate = "01/22/2013"; // creating a failed date
		wrongDate = NewPO.DeliveryDate;
		NewPO.DeliveryDate = ParsedJSON.delivery_date;
		If NewPO.DeliveryDate = wrongDate Then
			errorMessage = New Map();
			strMessage = " [delivery_date] : Date must be in the format of YYYY-MM-DD ";
			errorMessage.Insert("message", strMessage);
			errorMessage.Insert("status", "error"); 
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		
		NewPO.DeliveryDate = ParsedJSON.delivery_date;
	Except
	EndTry;	
	
	Try
		NewPO.Memo = ParsedJSON.memo;
	Except
	EndTry;
		
	Try doc_total = ParsedJSON.doc_total Except doc_total = Undefined EndTry;
	If doc_total = Undefined Then
		errorMessage = New Map();
		strMessage = " [doc_total] : This field is required " ;
		errorMessage.Insert("status", "error");
		errorMessage.Insert("message", strMessage );
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndIf;
	NewPO.DocumentTotalRC = doc_total;
	
	//NewPO.Location = Catalogs.Locations.MainWarehouse;
	
	Try project = ParsedJSON.project;
		newQuery = New Query("SELECT
		                     |	Projects.Ref
		                     |FROM
		                     |	Catalog.Projects AS Projects
		                     |WHERE
		                     |	Projects.Description = &Description");
							 
		newQuery.SetParameter("Description", project);
		projResult = newQuery.Execute();
		If projResult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = "[project] : The project does not exist." ;
			errorMessage.Insert("status", "error");
			errorMessage.Insert("message", strMessage );
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf; 
		projUnload = projResult.Unload();
		NewPO.Project = projUnload[0].Ref;
	Except
	EndTry;
	
	Try class = ParsedJSON.class;
		newQuery = New Query("SELECT
		                     |	Classes.Ref
		                     |FROM
		                     |	Catalog.Classes AS Classes
		                     |WHERE
		                     |	Classes.Description = &Description");
							 
		newQuery.SetParameter("Description", class);
		classResult = newQuery.Execute();
		If classResult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = "[class] : The class does not exist." ;
			errorMessage.Insert("status", "error");
			errorMessage.Insert("message", strMessage );
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf; 
		classUnload = classResult.Unload();
		NewPO.Class = classUnload[0].Ref;
	Except
	EndTry;
	
		
	Try DataLineItems = ParsedJSON.lines.line_items Except DataLineItems = Undefined EndTry;
	If DataLineItems = Undefined Then
		errorMessage = New Map();
		strMessage = " [lines] : Must enter at least one line with correct line items " ;
		errorMessage.Insert("status", "error");
		errorMessage.Insert("message", strMessage );
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndIf;
	
	doc_total_test = 0;
	
	LineItemsRows = DataLineItems.Count();
	For i = 0 To LineItemsRows -1 Do
		
		NewLine = NewPO.LineItems.Add();
				
		Try Product = Catalogs.Products.GetRef(New UUID(DataLineItems[i].api_code)) Except Product = Undefined EndTry;
			Try apiCode = DataLineItems[i].api_code Except apiCode = Undefined EndTry;
		If NOT Product = Undefined Or NOT apiCode = Undefined Then
		    itemsQuery = New Query("SELECT
		                         	|	Products.Ref
		                         	|FROM
								 	|	Catalog.Products AS Products
			                     	|WHERE
			                     	|	Products.Ref = &items");
			itemsQuery.SetParameter("items", Product);
			itemsResult = itemsQuery.Execute();
			If itemsResult.IsEmpty() Then
				errorMessage = New Map();
				strMessage = " [line_items(" + string(i+1) + ").api_code] : Item does not exist" ;
				errorMessage.Insert("status", "error");
				errorMessage.Insert("message", strMessage );
				errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
				return errorJSON;
			EndIf;	
			NewLine.Product = Product;
		Else
			errorMessage = New Map();
			strMessage = " [line_items(" + string(i+1) + ").api_code] : Item code is missing. This is a required field for lines " ;
			errorMessage.Insert("status", "error");
			errorMessage.Insert("message", strMessage );
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		
		NewLine.ProductDescription = Product.Description;
				
		Try price = DataLineItems[i].price Except price = Undefined EndTry;
		If NOT price = Undefined Then
			NewLine.PriceUnits = price;
		Else
			errorMessage = New Map();
			strMessage = " [line_items(" + string(i+1) + ").price] : This is a required field for lines " ;
			errorMessage.Insert("status", "error");
			errorMessage.Insert("message", strMessage );
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		
		Try quantity = DataLineItems[i].quantity Except quantity = Undefined EndTry;
		If NOT quantity = Undefined Then
			NewLine.QtyUnits = quantity;
		Else
			errorMessage = New Map();
			strMessage = " [line_items(" + string(i+1) + ").quantity] : This is a required field for lines " ;
			errorMessage.Insert("status", "error");
			errorMessage.Insert("message", strMessage );
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		
		Try linetotal = DataLineItems[i].line_total Except linetotal = Undefined EndTry;
		If NOT quantity = Undefined Then
			NewLine.LineTotal = linetotal;
		Else
			errorMessage = New Map();
			strMessage = " [line_items(" + string(i+1) + ").line_total] : This is a required field for lines " ;
			errorMessage.Insert("status", "error");
			errorMessage.Insert("message", strMessage );
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		
		If NewLine.LineTotal <> (NewLine.QtyUnits * NewLine.PriceUnits) Then
			errorMessage = New Map();
			strMessage = " [line_items(" + string(i+1) + ").line_total] : Line item's total does not match quantity * price " ;
			errorMessage.Insert("status", "error");
			errorMessage.Insert("message", strMessage );
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		
		doc_total_test = doc_total_test + NewLine.LineTotal;
		
		Try NewLine.Location = GeneralFunctions.GetDefaultLocation(); Except EndTry;
		
		//Try 
		//	um = DataLineItems[i].unit_of_measure;
		//	newQuery = New Query("SELECT
		//						 |	UM.Ref
		//						 |FROM
		//						 |	Catalog.UM AS UM
		//						 |WHERE
		//						 |	UM.Description = &Description");
		//						 
		//	newQuery.SetParameter("Description", um);
		//	umResult = newQuery.Execute();
		//	If umResult.IsEmpty() Then
		//		errorMessage = New Map();
		//		strMessage = "[unit_of_measure] : The unit of measure does not exist." ;
		//		errorMessage.Insert("status", "error");
		//		errorMessage.Insert("message", strMessage );
		//		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		//		return errorJSON;
		//	EndIf; 
		//	umUnload = umResult.Unload();
		//	NewLine.UM = umUnload[0].Ref;
		//Except
		//EndTry;
		
		Try 
			proj = DataLineItems[i].project;
			newQuery = New Query("SELECT
			                     |	Projects.Ref
			                     |FROM
			                     |	Catalog.Projects AS Projects
			                     |WHERE
			                     |	Projects.Description = &Description");
								 
			newQuery.SetParameter("Description", proj);
			projResult = newQuery.Execute();
			If projResult.IsEmpty() Then
				errorMessage = New Map();
				strMessage = "[project] : The project does not exist." ;
				errorMessage.Insert("status", "error");
				errorMessage.Insert("message", strMessage );
				errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
				return errorJSON;
			EndIf; 
			projUnload = projResult.Unload();
			NewLine.Project = projUnload[0].Ref;
		Except
		EndTry;
		
		Try 
			class = DataLineItems[i].class;
			newQuery = New Query("SELECT
			                     |	Classes.Ref
			                     |FROM
			                     |	Catalog.Classes AS Classes
			                     |WHERE
			                     |	Classes.Description = &Description");
								 
			newQuery.SetParameter("Description", class);
			classResult = newQuery.Execute();
			If classResult.IsEmpty() Then
				errorMessage = New Map();
				strMessage = "[class] : The class does not exist." ;
				errorMessage.Insert("status", "error");
				errorMessage.Insert("message", strMessage );
				errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
				return errorJSON;
			EndIf; 
			classUnload = classResult.Unload();
			NewLine.Class = classUnload[0].Ref;
		Except
		EndTry;
			
				
	EndDo;
	
	Try
		NewPO.Number = ParsedJSON.po_number;
		Numerator = Catalogs.DocumentNumbering.PurchaseOrder.GetObject();
		Numerator.Number = GeneralFunctions.Increment(Numerator.Number);
		Numerator.Write();
	Except
		Numerator = Catalogs.DocumentNumbering.PurchaseOrder.GetObject();
		If Numerator.Number = "" Then
			errorMessage = New Map();
			strMessage = "[po_number] : Document numbering for PO is not set. Please manual enter a PO number." ;
			errorMessage.Insert("status", "error");
			errorMessage.Insert("message", strMessage );
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		Else
			NewPO.Number = GeneralFunctions.Increment(Numerator.Number);
			Numerator.Number = NewPO.Number;
			Numerator.Write();
		EndIf;
	EndTry;
	
	Try
		NewPO.Number = ParsedJSON.po_number;
		If NewPO.Number <> "" Then
			Query = New Query("SELECT
			                  |	PurchaseOrder.Ref
			                  |FROM
			                  |	Document.PurchaseOrder AS PurchaseOrder
			                  |WHERE
			                  |	PurchaseOrder.Number = &Code");
			Query.SetParameter("Code", ParsedJSON.po_number);
			QueryResult = Query.Execute();
			
			If QueryResult.IsEmpty() = False Then
				errorMessage = New Map();
				strMessage = "[po_number] : The document number entered is not unique." ;
				errorMessage.Insert("status", "error");
				errorMessage.Insert("message", strMessage );
				errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
				return errorJSON;
			EndIf;

			Numerator = Catalogs.DocumentNumbering.PurchaseOrder.GetObject();
			Numerator.Number = GeneralFunctions.Increment(Numerator.Number);
			Numerator.Write();
		Else
			Numerator = Catalogs.DocumentNumbering.PurchaseOrder.GetObject();
			NewPO.Number = GeneralFunctions.Increment(Numerator.Number);
			Numerator.Number = NewPO.Number;
			Numerator.Write();
		EndIf;
				
	Except
		Numerator = Catalogs.DocumentNumbering.PurchaseOrder.GetObject();
		NewPO.Number = GeneralFunctions.Increment(Numerator.Number);
		Numerator.Number = NewPO.Number;
		Numerator.Write();
	EndTry;
	
	NewPO.Write(DocumentWriteMode.Posting);
		
	jsonout = InternetConnectionClientServer.EncodeJSON(Webhooks.ReturnPurchaseOrderMap(NewPO.Ref));
	
	Return jsonout;
EndFunction


Function inoutCashReceiptCreate(jsonin) Export
		
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
		
	NCR = Documents.CashReceipt.CreateDocument();
	NCR.Date = CurrentDate(); // ParsedJSON.date; convert from seconds to normal date
	NCR.Memo = ParsedJSON.memo;
	
	Customer = Catalogs.Companies.FindByDescription(ParsedJSON.company_name);
	
	If Customer = Catalogs.Companies.EmptyRef() Then
		
		NewCompany = Catalogs.Companies.CreateItem();
		
		NewCompany.Description = ParsedJSON.company_name;
		NewCompany.Customer = True;
		NewCompany.DefaultCurrency = Constants.DefaultCurrency.Get();
		NewCompany.Terms = Catalogs.PaymentTerms.Net30;

		NewCompany.Write();
			
		AddressLine = Catalogs.Addresses.CreateItem();
		AddressLine.Owner = NewCompany.Ref;
		AddressLine.Description = "Primary";
		AddressLine.Write();
		
		Customer = NewCompany.Ref;
		
	Else	
	EndIf;
		
	NCR.Company = Customer;
	//NCR.CompanyCode = Customer.Code;
	NCR.RefNum = ParsedJSON.ref_num;
	NCR.DepositType = "1";   
	
	NCR.CashPayment = Number(ParsedJSON.amount);
	NCR.UnappliedPayment = Number(ParsedJSON.amount);
	NCR.DocumentTotal = Number(ParsedJSON.amount);
	NCR.DocumentTotalRC = Number(ParsedJSON.amount);
	NCR.PaymentMethod = Catalogs.PaymentMethods.DebitCard;
	NCR.Currency = Constants.DefaultCurrency.Get();
	NCR.ARAccount = NCR.Currency.DefaultARAccount;
	
	NCR.Write(DocumentWriteMode.Posting);
	
	///
	
	//Query = New Query("SELECT
	//				  |	Addresses.Description,
	//				  |	Addresses.FirstName,
	//				  |	Addresses.LastName,
	//				  |	Addresses.DefaultBilling,
	//				  |	Addresses.DefaultShipping,
	//				  |	Addresses.Code,
	//				  |	Addresses.MiddleName,
	//				  |	Addresses.Phone,
	//				  |	Addresses.Email,
	//				  |	Addresses.AddressLine1,
	//				  |	Addresses.AddressLine2,
	//				  |	Addresses.City,
	//				  |	Addresses.State,
	//				  |	Addresses.Country,
	//				  |	Addresses.ZIP
	//				  |FROM
	//				  |	Catalog.Addresses AS Addresses
	//				  |WHERE
	//				  |	Addresses.Owner = &Company");
	//Query.SetParameter("Company", NewCompany.Ref);
	//Result = Query.Execute().Select();
	//
	//Addresses = New Array();
	//
	//While Result.Next() Do
	//	
	//	Address = New Map();
	//	Address.Insert("address_id", Result.Description);
	//	Address.Insert("address_code", Result.Code);
	//	Address.Insert("first_name", Result.FirstName);
	//	Address.Insert("middle_name", Result.MiddleName);
	//	Address.Insert("last_name", Result.LastName);
	//	Address.Insert("phone", Result.Phone);
	//	Address.Insert("email", Result.Email);
	//	Address.Insert("address_line1", Result.AddressLine1);
	//	Address.Insert("address_line2", Result.AddressLine2);
	//	Address.Insert("city", Result.City);
	//	Address.Insert("state", Result.State.Code);
	//	Address.Insert("zip", Result.ZIP);
	//	Address.Insert("country", Result.Country.Description);
	//	Address.Insert("default_billing", Result.DefaultBilling);
	//	Address.Insert("default_shipping", Result.DefaultShipping);
	//	
	//	Addresses.Add(Address);
	//	
	//EndDo;
	//
	//DataAddresses = New Map();
	//DataAddresses.Insert("addresses", Addresses);
	//
	//CompanyData = New Map();
	//CompanyData.Insert("company_name", NewCompany.Description);
	//CompanyData.Insert("company_code", NewCompany.Code);
	//CompanyData.Insert("company_type", "customer");
	//CompanyData.Insert("lines", DataAddresses);
	//
	jsonout = InternetConnectionClientServer.EncodeJSON(Webhooks.ReturnCashReceiptMap(NCR.Ref));
	
	Return jsonout;
	
EndFunction


Function handleDocumentAddresses(ParsedJSON, DocRef, status) Export
	// SHIP TO ADDRESS SECTION
	Try ship_to_api_code = ParsedJSON.ship_to_api_code Except ship_to_api_code = "" EndTry;
	Try ship_to_address_id = ParsedJSON.ship_to_address_id Except ship_to_address_id = "" EndTry;
	
	If ship_to_api_code <> "" Then
	    // load given address apicode 
		Try addr = Catalogs.Addresses.GetRef(New UUID(ship_to_api_code)) Except addr = Undefined EndTry;
		
		newQuery = New Query("SELECT
		                     |	Addresses.Ref
		                     |FROM
		                     |	Catalog.Addresses AS Addresses
		                     |WHERE
		                     |	Addresses.Owner = &Customer
		                     |	AND Addresses.Ref = &addrCode");
							 
		newQuery.SetParameter("Customer", DocRef.Company);
		newQuery.SetParameter("addrCode", addr);
		addrResult = newQuery.Execute();
		If addrResult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = "[ship_to_api_code] : Shipping Address does not belong to the Company";
			errorMessage.Insert("status", "error"); 
			errorMessage.Insert("message", strMessage);
			//errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorMessage;
		EndIf;
		DocRef.ShipTo = addr;
		
	ElsIf ship_to_address_id <> "" Then
		// create addr from given fields
		AddressLine = Catalogs.Addresses.CreateItem();
		AddressLine.Owner = DocRef.Company;
		AddressLine.Description = ship_to_address_id;
		Try	AddressLine.Salutation = ParsedJSON.ship_to_salutation; Except EndTry;
		Try	AddressLine.FirstName = ParsedJSON.ship_to_first_name; Except EndTry;			
		Try AddressLine.MiddleName = ParsedJSON.ship_to_middle_name; Except EndTry;			
		Try AddressLine.LastName = ParsedJSON.ship_to_last_name; Except EndTry;	
		Try	AddressLine.Suffix = ParsedJSON.ship_to_suffix; Except EndTry;
		Try AddressLine.Phone = ParsedJSON.ship_to_phone; Except EndTry;			
		Try AddressLine.Cell = ParsedJSON.ship_to_cell; Except EndTry;
		Try	AddressLine.Fax = ParsedJSON.ship_to_fax; Except EndTry;
		Try AddressLine.Email = ParsedJSON.ship_to_email; Except EndTry;			
		Try AddressLine.AddressLine1 = ParsedJSON.ship_to_address_line1; Except EndTry;			
		Try	AddressLine.AddressLine2 = ParsedJSON.ship_to_address_line2; Except EndTry;
		Try	AddressLine.AddressLine3 = ParsedJSON.ship_to_address_line3; Except EndTry;
		Try	AddressLine.City = ParsedJSON.ship_to_city; Except EndTry;
		Try 
			statecode = Catalogs.States.FindByCode(Upper(ParsedJSON.ship_to_state));
			statedesc = Catalogs.States.FindByDescription(Title(ParsedJSON.ship_to_state));
			If statedesc <> Catalogs.States.EmptyRef() Then
				AddressLine.State = statedesc;
			Else
				AddressLine.State = statecode;
			EndIf;		
		Except 
		EndTry;
		
		Try 
			countrycode = Catalogs.Countries.FindByCode(Upper(ParsedJSON.ship_to_country));
			countrydesc = Catalogs.Countries.FindByDescription(Title(ParsedJSON.ship_to_country));
			If countrydesc <> Catalogs.States.EmptyRef() Then
				AddressLine.Country = countrydesc;
			Else
				AddressLine.Country = countrycode;
			EndIf;
		Except 
		EndTry;			
		Try AddressLine.ZIP = ParsedJSON.ship_to_zip; Except EndTry;
		AddressLine.Write();
		DocRef.ShipTo = AddressLine.Ref;
		
	Else
		If status = "create" Then
			//load default shipping
			Try 
				newQuery = New Query("SELECT
				                     |	Addresses.Ref
				                     |FROM
				                     |	Catalog.Addresses AS Addresses
				                     |WHERE
				                     |	Addresses.Owner = &Customer
				                     |	AND Addresses.DefaultShipping = TRUE");
									 
				newQuery.SetParameter("Customer", DocRef.Company);
				addrResult = newQuery.Execute().Unload();
				
				DocRef.ShipTo = addrResult[0].Ref;
			Except
				//no default shipping just leave blank?
			EndTry;
		EndIf;
		
	EndIf;
	
	
	// BILL TO ADDRESS SECTION
	Try bill_to_api_code = ParsedJSON.bill_to_api_code Except bill_to_api_code = "" EndTry;
	Try bill_to_address_id = ParsedJSON.bill_to_address_id Except bill_to_address_id = "" EndTry;
	
	If bill_to_api_code <> "" Then
	 
		Try addr = Catalogs.Addresses.GetRef(New UUID(bill_to_api_code)) Except addr = Undefined EndTry;
		
		newQuery = New Query("SELECT
		                     |	Addresses.Ref
		                     |FROM
		                     |	Catalog.Addresses AS Addresses
		                     |WHERE
		                     |	Addresses.Owner = &Customer
		                     |	AND Addresses.Ref = &addrCode");
							 
		newQuery.SetParameter("Customer", DocRef.Company);
		newQuery.SetParameter("addrCode", addr);
		addrResult = newQuery.Execute();
		If addrResult.IsEmpty() Then
			errorMessage = New Map();
			strMessage = "[bill_to_api_code] : Billing Address does not belong to the Company";
			errorMessage.Insert("status", "error"); 
			errorMessage.Insert("message", strMessage);
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		DocRef.BillTo = addr;
		
	ElsIf bill_to_address_id <> "" Then
		// create addr from given fields
		AddressLine = Catalogs.Addresses.CreateItem();
		AddressLine.Owner = DocRef.Company;
		AddressLine.Description = bill_to_address_id;
		Try	AddressLine.Salutation = ParsedJSON.bill_to_salutation; Except EndTry;
		Try	AddressLine.FirstName = ParsedJSON.bill_to_first_name; Except EndTry;			
		Try AddressLine.MiddleName = ParsedJSON.bill_to_middle_name; Except EndTry;			
		Try AddressLine.LastName = ParsedJSON.bill_to_last_name; Except EndTry;	
		Try	AddressLine.Suffix = ParsedJSON.bill_to_suffix; Except EndTry;
		Try AddressLine.Phone = ParsedJSON.bill_to_phone; Except EndTry;			
		Try AddressLine.Cell = ParsedJSON.bill_to_cell; Except EndTry;
		Try	AddressLine.Fax = ParsedJSON.bill_to_fax; Except EndTry;
		Try AddressLine.Email = ParsedJSON.bill_to_email; Except EndTry;			
		Try AddressLine.AddressLine1 = ParsedJSON.bill_to_address_line1; Except EndTry;			
		Try	AddressLine.AddressLine2 = ParsedJSON.bill_to_address_line2; Except EndTry;
		Try	AddressLine.AddressLine3 = ParsedJSON.bill_to_address_line3; Except EndTry;
		Try	AddressLine.City = ParsedJSON.bill_to_city; Except EndTry;
		Try 
			statecode = Catalogs.States.FindByCode(Upper(ParsedJSON.bill_to_state));
			statedesc = Catalogs.States.FindByDescription(Title(ParsedJSON.bill_to_state));
			If statedesc <> Catalogs.States.EmptyRef() Then
				AddressLine.State = statedesc;
			Else
				AddressLine.State = statecode;
			EndIf;		
		Except 
		EndTry;
		
		Try 
			countrycode = Catalogs.Countries.FindByCode(Upper(ParsedJSON.bill_to_country));
			countrydesc = Catalogs.Countries.FindByDescription(Title(ParsedJSON.bill_to_country));
			If countrydesc <> Catalogs.States.EmptyRef() Then
				AddressLine.Country = countrydesc;
			Else
				AddressLine.Country = countrycode;
			EndIf;
		Except 
		EndTry;			
		Try AddressLine.ZIP = ParsedJSON.bill_to_zip; Except EndTry;
		AddressLine.Write();
		DocRef.BillTo = AddressLine.Ref;
		
	Else
		If status = "create" Then
			//load default Billing
			Try 
				newQuery = New Query("SELECT
				                     |	Addresses.Ref
				                     |FROM
				                     |	Catalog.Addresses AS Addresses
				                     |WHERE
				                     |	Addresses.Owner = &Customer
				                     |	AND Addresses.DefaultBilling = TRUE");
									 
				newQuery.SetParameter("Customer", DocRef.Company);
				addrResult = newQuery.Execute().Unload();
				
				DocRef.billTo = addrResult[0].Ref;
			Except
				//no default Billing just leave blank?
			EndTry;
		EndIf;
		
	EndIf;
	
	Return DocRef;
	
EndFunction

Function handleDocumentTotals(ParsedJSON, DocRef) Export
	
	Try DataLineItems = ParsedJSON.lines.line_items Except DataLineItems = Undefined EndTry;
	If DataLineItems = Undefined Then
		errorMessage = New Map();
		strMessage = "[lines] : Must enter at least one line with correct line items" ;
		errorMessage.Insert("status", "error");
		errorMessage.Insert("message", strMessage );
		errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
		return errorJSON;
	EndIf;
	
	linesubtotal = 0;
	LineItemsRows = DataLineItems.Count();
	For i = 0 To LineItemsRows -1 Do
		
		NewLine = DocRef.LineItems.Add();
			
		Try Product = Catalogs.Products.GetRef(New UUID(DataLineItems[i].api_code)) Except Product = Undefined EndTry;
		Try apiCode = DataLineItems[i].api_code Except apiCode = Undefined EndTry;
		If NOT Product = Undefined Or NOT apiCode = Undefined Then
		    itemsQuery = New Query("SELECT
		                         	|	Products.Ref
		                         	|FROM
								 	|	Catalog.Products AS Products
			                     	|WHERE
			                     	|	Products.Ref = &items");
			itemsQuery.SetParameter("items", Product);
			itemsResult = itemsQuery.Execute();
			If itemsResult.IsEmpty() Then
				errorMessage = New Map();
				strMessage = "[line_items(" + string(i+1) + ").api_code] : Item does not exist" ;
				errorMessage.Insert("status", "error");
				errorMessage.Insert("message", strMessage );
				errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
				return errorJSON;
			EndIf;	
			NewLine.Product = Product;
		Else
			errorMessage = New Map();
			strMessage = " [line_items(" + string(i+1) + ").api_code] : Item code is missing. This is a required field for lines " ;
			errorMessage.Insert("status", "error");
			errorMessage.Insert("message", strMessage );
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		
		NewLine.ProductDescription = NewLine.Product.Description;
	
		Try price = DataLineItems[i].price Except price = Undefined EndTry;
		If NOT price = Undefined Then
			NewLine.PriceUnits = number(price);
		Else
			errorMessage = New Map();
			strMessage = " [line_items(" + string(i+1) + ").price] : This is a required field for lines " ;
			errorMessage.Insert("status", "error");
			errorMessage.Insert("message", strMessage );
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
		EndIf;
		
		//NewLine.Quantity = DataLineItems[i].quantity;
		Try quantity = DataLineItems[i].quantity Except quantity = Undefined EndTry;
		If NOT quantity = Undefined Then
			NewLine.QtyUnits = number(quantity);
		Else
			
			errorMessage = New Map();
			strMessage = " [line_items(" + string(i+1) + ").quantity] : This is a required field for lines " ;
			errorMessage.Insert("status", "error");
			errorMessage.Insert("message", strMessage );
			errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			return errorJSON;
			
		EndIf;
		
		Try linetotal = DataLineItems[i].line_total Except linetotal = Undefined EndTry;
		If NOT quantity = Undefined Then
			NewLine.LineTotal = linetotal;
		Else
			//errorMessage = New Map();
			//strMessage = " [line_items(" + string(i+1) + ").line_total] : This is a required field for lines " ;
			//errorMessage.Insert("status", "error");
			//errorMessage.Insert("message", strMessage );
			//errorJSON = InternetConnectionClientServer.EncodeJSON(errorMessage);
			//return errorJSON;
			NewLine.LineTotal = NewLine.QtyUnits * NewLine.PriceUnits;
		EndIf;
		linesubtotal = linesubtotal + NewLine.LineTotal;
		NewLine.Unit = NewLine.Product.UnitSet.DefaultSaleUnit;
		Try
			If Number(ParsedJSON.SalesTax) > 0 Then
				NewLine.Taxable = True;
			EndIf;
		Except
		EndTry;
				
	EndDo;
	
	DocRef.LineSubtotal = linesubtotal;
	Try
		DocRef.Discount = - Round(Number(ParsedJSON.discount),2);
		DocRef.DiscountPercent = Round(-1 * 100 * DocRef.Discount / DocRef.LineSubtotal, 2); 
	Except
	EndTry;
	Try 
		DocRef.DiscountPercent = Round(Number(ParsedJSON.discount_percent),2);
		DocRef.Discount = Round(-1 * DocRef.LineSubtotal * DocRef.DiscountPercent/100, 2);
	Except
	EndTry;
	Try DocRef.Shipping = ParsedJSON.shipping; Except EndTry;
	Try DocRef.SalesTax = ParsedJSON.sales_tax_total; Except EndTry;
	Try 
		DocRef.DocumentTotal = ParsedJSON.doc_total; 
	Except 
		DocRef.DocumentTotal = DocRef.LineSubtotal + DocRef.Shipping + DocRef.SalesTax;
	EndTry;
	
	Return DocRef;
	
EndFunction
