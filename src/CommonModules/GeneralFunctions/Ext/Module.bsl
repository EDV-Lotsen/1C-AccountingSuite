//////////////////////////////////////////////////////////////////////////////// 
// THIS MODULE CONTAINS GENERAL PURPOSE FUNCTIONS AND PROCEDURES
// 

// Selects item's price from a price-list.
//
// Parameters:
// Date - date of the price in the price-list.
// Catalog.Items - price-list item.
// Catalog.Customers - price list customer (used if Advanced Pricing is enabled).
//
// Returned value:
// Number - item's price.
//
Function RetailPrice(ActualDate, Product) Export
		
	SelectParameters = New Structure;
	SelectParameters.Insert("Product", Product);
	ResourceValue = InformationRegisters.PriceList.GetLast(ActualDate, SelectParameters);
	Return ResourceValue.Price;
		
EndFunction

// Marks the document (cash receipt, cash sale) as "deposited" (included) by a deposit document.
//
// Parameters:
// DocumentLine - document Ref for which the procedure sets the "deposited" attribute.
//
Procedure WriteDepositData(DocumentLine) Export
	
	Document = DocumentLine.GetObject();
	Document.Deposited = True;
	Document.Write();

EndProcedure

// Clears the "deposited" (included) by a deposit document value from the document (cash receipt,
// cash sale)
//
// Parameters:
// DocumentLine - document Ref for which the procedure sets the "deposited" attribute.
//
Procedure ClearDepositData(DocumentLine) Export
	
	Document = DocumentLine.GetObject();
	Document.Deposited = False;
	Document.Write();

EndProcedure

// Determines a currency of a line item document.
// Used in invoice payment and cash receipt documents to calculate exchange rate for each line item.
//
// Parameter:
// Document - a document Ref for which the function selects its currency.
//
// Returned value:
// Enumeration.Currencies.
//
Function GetSpecDocumentCurrency(Document) Export
	
	Doc = Document.GetObject();
	Return Doc.Currency;

EndFunction

// Returns a value of a functional option.
//
// Parameter:
// String - functional option name.
//
// Returned value:
// Boolean - 1 - the functional option is set, 0 - the functional option is not set.
//
Function FunctionalOptionValue(FOption) Export
	
	Return GetFunctionalOption(FOption);
	
EndFunction

// Determines a currency exchange rate.
// 
// Parameters:
// Date - conversion date.
// Catalog.Currencies - conversion currency.
//
// Returned value:
// Number - an exchange rate.
// 
Function GetExchangeRate(Date, Currency) Export
		
	SelectParameters = New Structure;
	SelectParameters.Insert("Currency", Currency);
	
	ResourceValue = InformationRegisters.ExchangeRates.GetLast(Date, SelectParameters);
	
	If ResourceValue.Rate = 0 Then
		Return 1;	
	Else
		Return ResourceValue.Rate;
	EndIf;
	
EndFunction

// Returns OurCompany.
// 
// Returned value:
// Catalog.Companies.
// 
Function GetOurCompany() Export
	
	Return Catalogs.Companies.OurCompany;
	
EndFunction

// Returns a default inventory/expense account depending on an
// item type (inventory or non-inventory)
//
// Parameters:
// Enumeration.InventoryTypes - item type (inventory, non-inventory).
//
// Returned value:
// ChartsOfAccounts.ChartOfAccounts.
//
Function InventoryAcct(ProductType) Export
	
	If ProductType = Enums.InventoryTypes.Inventory Then
		Return Constants.InventoryAccount.Get(); 
	Else
		Return Constants.ExpenseAccount.Get();
	EndIf;
		
EndFunction

// Returns an item type (inventory or non-inventory)
//
// Parameters:
// Enumeration.InventoryType
//
// Returned value:
// Boolean
//
Function InventoryType(Type) Export
	
	If Type = Enums.InventoryTypes.Inventory Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Returns an account description.
//
// Parameters:
// String - account code.
//
// Returned value:
// String - account description
//
Function AccountName(StringCode) Export
	
	Account = ChartsOfAccounts.ChartOfAccounts.FindByCode(StringCode);
	Return Account.Description;
	
EndFunction

// Calculates the next check number for a selected bank account.
//
// Parameters:
// ChartOfAccounts.ChartOfAccounts.
//
// Returned value:
// Number
//
Function NextCheckNumber(BankAccount) Export
	
	Query = New Query("SELECT
	                  |	Check.Number AS Number
	                  |FROM
	                  |	Document.Check AS Check
	                  |WHERE
	                  |	Check.BankAccount = &BankAccount
	                  |
	                  |ORDER BY
	                  |	Number DESC");
	Query.SetParameter("BankAccount", BankAccount);	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then		
		Return 1;
	Else
		Dataset = QueryResult.Unload();
		LastNumber = Dataset[0][0];
		Return LastNumber + 1;
	EndIf;			
	
EndFunction

Function SearchCompanyByCode(CompanyCode) Export
	
	Query = New Query("SELECT
	                  |	Companies.Ref
	                  |FROM
	                  |	Catalog.Companies AS Companies
	                  |WHERE
	                  |	Companies.Code = &CompanyCode");
	
	Query.SetParameter("CompanyCode", CompanyCode);	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then		
		Return Catalogs.Companies.EmptyRef();
	Else
		Dataset = QueryResult.Unload();
		Return Dataset[0][0];
	EndIf;			

EndFunction

Function GetShipToAddress(Company) Export
	
	Query = New Query("SELECT
	                  |	Addresses.Ref
	                  |FROM
	                  |	Catalog.Addresses AS Addresses
	                  |WHERE
	                  |	Addresses.Owner = &Company
	                  |	AND Addresses.DefaultShipping = TRUE");
	Query.SetParameter("Company", Company);				  
	QueryResult = Query.Execute();
	Dataset = QueryResult.Unload();
	Return Dataset[0][0];
	
EndFunction

Function ProductLastCost(Product) Export
	
	Query = New Query("SELECT
	                  |	ItemLastCost.Cost
	                  |FROM
	                  |	InformationRegister.ItemLastCost AS ItemLastCost
	                  |WHERE
	                  |	ItemLastCost.Product = &Product");
	Query.SetParameter("Product", Product);
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then		
		Return 0;
	Else
		Dataset = QueryResult.Unload();
		Return Dataset[0][0];
	EndIf;			
		
EndFunction

// Check documents table parts to ensure, that products are unique
Procedure CheckDoubleItems(Ref, LineItems, Columns, Cancel) Export
	
	// Dump table part
	TableLineItems = LineItems.Unload(, Columns);
	TableLineItems.Sort(Columns);
	
	// Define subsets of data to check
	EmptyItems   = New Structure(Columns);
	CurrentItems = New Structure(Columns);
	DoubledItems = New Structure(Columns);
	CompareItems = StrReplace(Columns, "LineNumber", "");
	DisplayCodes = FunctionalOptionValue("DisplayCodes");
	DoublesCount = 0;
	Doubles      = ""; 
	
	// Check table part for doubles
	For Each LineItem In TableLineItems Do
		// Check for double
		If ComparePropertyValues(CurrentItems, LineItem, CompareItems) Then
			// Double found
			If Not ComparePropertyValues(DoubledItems, CurrentItems, CompareItems) Then
				// New double found
				FillPropertyValues(DoubledItems, CurrentItems, Columns);
				Doubles = Format(CurrentItems.LineNumber, "NFD=0; NG=0") + ", " + Format(LineItem.LineNumber, "NFD=0; NG=0"); 
			Else
				// Multiple double
				Doubles = Doubles + ", " + Format(LineItem.LineNumber, "NFD=0; NG=0"); 
			EndIf;
		Else
			// If Double found
			If FilledPropertyValues(DoubledItems, CompareItems) Then
				
				// Increment doubles counter
				DoublesCount = DoublesCount + 1;
				If DoublesCount <= 10 Then // 10 messages enough to demonstrate that check failed
					
					// Publish previously found double
					DoublesText = "";
					For Each Double In DoubledItems Do
						// Convert value to it's presentation
						Value = Double.Value;
						If Double.Key = "LineNumber" Then
							Continue; // Skip line number
							
						ElsIf TypeOf(Value) = Type("CatalogRef.Companies") Then
							Presentation = ?(DisplayCodes, TrimAll(Value.Code) + " ", "") + TrimAll(Value.Description);
							
						ElsIf TypeOf(Value) = Type("CatalogRef.Products") Then
							Presentation = TrimAll(Value.Code) + " " + TrimAll(Value.Description);
							
						Else
							Presentation = TrimAll(Value);
						EndIf;
						
						// Generate doubled items text
						DoublesText = DoublesText + ?(IsBlankString(DoublesText), "", ", ") + Double.Key + " """ + Presentation + """";
					EndDo;
					
					// Generate message to user
					MessageText = NStr("en = '%1
					                         |doubled in lines: %2'");
					MessageText = StringFunctionsClientServer.SubstitureParametersInString(MessageText, DoublesText, Doubles); 
					CommonUseClientServer.MessageToUser(MessageText, Ref,,, Cancel);
				EndIf;
				
				// Clear found double
				FillPropertyValues(DoubledItems, EmptyItems, Columns);
				Doubles = "";
			EndIf;
		EndIf;
		
		// Save current state for the next loop
		FillPropertyValues(CurrentItems, LineItem, Columns);
	EndDo;
	
	// Publish last found double
	If FilledPropertyValues(DoubledItems, CompareItems)
	And DoublesCount < 10 Then // Display 10-th message
		
		// Publish previously found double
		DoublesText = "";
		For Each Double In DoubledItems Do
			
			// Convert value to it's presentation
			Value = Double.Value;
			If Double.Key = "LineNumber" Then
				Continue; // Skip line number
				
			ElsIf TypeOf(Value) = Type("CatalogRef.Companies") Then
				Presentation = ?(DisplayCodes, TrimAll(Value.Code) + " ", "") + TrimAll(Value.Description);
				
			ElsIf TypeOf(Value) = Type("CatalogRef.Products") Then
				Presentation = TrimAll(Value.Code) + " " + TrimAll(Value.Description);
				
			Else
				Presentation = TrimAll(Value);
			EndIf;
			
			DoublesText = DoublesText + ?(IsBlankString(DoublesText), "", ", ") + Double.Key + " """ + Presentation + """";
		EndDo;
		
		// Generate message to user
		MessageText = NStr("en = '%1
		                         |doubled in lines: %2'");
		MessageText = StringFunctionsClientServer.SubstitureParametersInString(MessageText, DoublesText, Doubles); 
		CommonUseClientServer.MessageToUser(MessageText, Ref,,, Cancel);
		
	Else
		RemainingDoubles = DoublesCount + Number(FilledPropertyValues(DoubledItems, CompareItems)) - 10; // Quantity of errors, which are not displayed to user
		If RemainingDoubles > 0 Then
			// Generate message to user
			MessageText = NStr("en = 'There are also %1 error(s) found'");
			MessageText = StringFunctionsClientServer.SubstitureParametersInString(MessageText, Format(RemainingDoubles, "NFD=0; NG=0")); 
			CommonUseClientServer.MessageToUser(MessageText, Ref,,, Cancel);
		EndIf;
	EndIf;

EndProcedure

// Normalizes passed array removing empty values and duplicates
// 
// Parameters:
// 	Array - Array of items to be normalized (Arbitrary items)
//
Procedure NormalizeArray(Array) Export
	
	i = 0;
	While i < Array.Count() Do
		
		// Check current item
		If (Array[i] = Undefined) Or (Not ValueIsFilled(Array[i])) Then
			Array.Delete(i);	// Delete empty values
			
		ElsIf Array.Find(Array[i]) <> i Then
			Array.Delete(i);	// Delete duplicate
			
		Else
			i = i + 1;			// Next item
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Compares two passed objects by their properties (as analogue to FillPropertyValues)
// Compares Source property values with values of properties of the Receiver. Matching is done by property names.
// If some of the properties are absent in Source or Destination objects, they will be omitted.
// If objects don't have same properties, they will be assumed as different, because they having nothing in common.
//
// Parameters:
// 	Receiver - Reference (Arbitrary), properties of which will be compared with properties of Source. 
//  Source   - Reference (Arbitrary), properties of which will be used to compare with Receiver.
//  ListOfProperties - String of comma-separated property names that will be used in compare.
//
// Return value:
// 	Boolean - Objects are equal by the set of their properties
//
Function ComparePropertyValues(Receiver, Source, ListOfProperties) Export
	Var DstItemValue;
	
	// Create structures to compare
	SrcStruct = New Structure(ListOfProperties);
	DstStruct = New Structure(ListOfProperties);
		
	// Copy arbitrary values to comparable structures
	FillPropertyValues(SrcStruct, Source);   // Only properties, existing in Source   and defined in ListOfProperties are copied
	FillPropertyValues(DstStruct, Receiver); // Only properties, existing in Receiver and defined in ListOfProperties are copied
	
	// Flag of having similar properties
	FoundSameProperty = False;
	
	// Compare properties of structures
	For Each SrcItem In SrcStruct Do
		
		If DstStruct.Property(SrcItem.Key, DstItemValue) Then
			// Set flag of found same properties in both structures
			If Not FoundSameProperty Then FoundSameProperty = True; EndIf;
			
			// Compare values of properties
			If SrcItem.Value <> DstItemValue Then
				// Compare failed
				Return False;
			EndIf;
		Else
		    // Skip property absent in DstStruct
		EndIf;
		
	EndDo;
	
	// The structures contain the same compareble properties, or nothing in common
	Return FoundSameProperty;
			
EndFunction

// Check filling of passed object by it's properties (as analogue to FillPropertyValues)
// If some of the properties mentioned in ListOfProperties are absent in object, they will be omitted.
// If objects hasn't selected properties, it will be assumed as empty, because it hsn't any.
//
// Parameters:
//  Source   - Reference (Arbitrary), properties of which will be used to check their filling.
//  ListOfProperties - String of comma-separated property names that will be used in check.
//
// Return value:
// 	Boolean - Sre objects equal by the set of their properties
//
Function FilledPropertyValues(Source, ListOfProperties) Export
	
	// Create structures to check filling of properties
	SrcStruct = New Structure(ListOfProperties);
	FillPropertyValues(SrcStruct, Source); // Only properties, existing in Source and defined in ListOfProperties are copied
	
	// Compare properties of structures
	For Each SrcItem In SrcStruct Do
		If SrcItem.Value <> Undefined Then
			// Object has filled properties
			Return True;
		EndIf;
	EndDo;
	
	// None of properties are filled
	Return False;
	
EndFunction
