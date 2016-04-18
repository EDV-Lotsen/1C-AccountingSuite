
////////////////////////////////////////////////////////////////////////////////
// Lots & Serial numbers: Server module
//------------------------------------------------------------------------------
// Available on:
// - Server
// - External Connection
//

////////////////////////////////////////////////////////////////////////////////
#Region PUBLIC_INTERFACE

//------------------------------------------------------------------------------
// Lots servicing functions.

// Request and fill lot owner.
// Fills owner value for product lots.
//
// Parameters:
//  Product  - CatalogRef.Products        - Product for requesting lots properties.
//  LotOwner - CatalogRef.Products        - Product owns lots.
//           - CatalogRef.Characteristics - Characteristic owns product lots.
//
Procedure FillLotOwner(Product, LotOwner) Export
	
	// Lots accounting settings.
	If  Product.HasLotsSerialNumbers    // Use lots & serial numbers.
	And Product.UseLots = 0 Then        // Use lots (not serials).
		// Select link for lots.
		If Product.UseLotsType = 1 Then // Use lots by characteristic.
			LotOwner = Product.Characteristic;
		Else                            // Use lots by vendor code or expiration date.
			LotOwner = Product.Ref;
		EndIf;
	Else
		LotOwner = Undefined;
	EndIf;
	
EndProcedure

// Check lot compliance to it's owner.
// Clears lot if it doesn't comply to it's owner.
//
// Parameters:
//  Lot      - CatalogRef.Lots            - Lot for checking.
//  LotOwner - CatalogRef.Products        - Product owns lots.
//           - CatalogRef.Characteristics - Characteristic owns product lots.
//
Procedure CheckLotByOwner(Lot, LotOwner) Export
	
	// Lots accounting settings.
	If Lot.Owner <> LotOwner Then
		Lot = Catalogs.Lots.EmptyRef();
	EndIf;
	
EndProcedure

// Check filing of lots in table part line items.
// A message generated if lots are not filled.
//
// Parameters:
//  Ref       - DocumentRef           - Ref to an object while filling check.
//  LineItems - DocumentRef.LineItems - Table part to be checked.
//  Cancel    - Boolean               - Flag of cancel further document check.
//  Target    - String                - Name of table part/header, where lots checking proceeds.
//
Procedure CheckLotsFilling(Ref, LineItems, Cancel, Target = "") Export
	
	// Copy document tabular section into temporary table.
	Lots = Ref.LineItems.UnloadColumns("LineNumber, Product, Lot");
	For Each Row In LineItems Do
		FillPropertyValues(Lots.Add(), Row, "LineNumber, Product, Lot");
	EndDo;
	
	// Check filling of lots.
	i = 0;
	While i < Lots.Count() Do
		Row = Lots[i];
		If  Row.Product <> Catalogs.Products.EmptyRef() // Product filled.
		And Row.Product.HasLotsSerialNumbers            // Use lots & serial numbers.
		And Row.Product.UseLots = 0                     // Use lots (not serials).
		And Row.Lot = Catalogs.Lots.EmptyRef() Then     // Lot is empty.
			// Found unfilled lot.
			i = i + 1;
		Else
			// Lot does not required to be filled.
			Lots.Delete(i);
		EndIf;
	EndDo;
	
	// Generate message to user.
	If Lots.Count() > 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'The lots are not filled%1%2:'"),
		              ?(Not IsBlankString(Target), " in " + Target, ""), ?(Target <> "header", " in following lines", ""));
		For Each Row In Lots Do
			MessageText = MessageText + Chars.CR + Chars.LF +
			              StringFunctionsClientServer.SubstituteParametersInString(NStr("en = '%1: %2, %3'"), Row.LineNumber, Row.Product, Row.Product.Description);
		EndDo;
		CommonUseClientServer.MessageToUser(MessageText, Ref,,, Cancel);
	EndIf;
	
EndProcedure

//------------------------------------------------------------------------------
// Serial numbers servicing functions.

// Request and fill serial numbers for specified row.
// Fills serial numbers string for specified produc line.
//
// Parameters:
//  SerialNumbersTbl - TabularSection       - Tabular section containing serial numbers.
//  Product          - CatalogRef.Products  - Product for requesting serial numbers.
//  InOut            - Number               - 0 - Check reception, 1 - Check issue.
//  LineID           - UUID                 - ID of row, containing owner product.
//  SerialNumbersStr - String               - String representation of product serial numbers.
//
Procedure FillSerialNumbers(SerialNumbersTbl, Product, InOut, LineID, SerialNumbersStr) Export
	
	// Lots accounting settings.
	If  Product.HasLotsSerialNumbers    // Use lots & serial numbers.
	And Product.UseLots = 1 Then        // Use serial numbers.
		
		// Select serial numbers using type.
		If (InOut = 0 And Product.UseSerialNumbersOnGoodsReception) // Serial numbers are used on reception.
		Or (InOut = 1 And Product.UseSerialNumbersOnShipment) Then  // Serial numbers are used on shipment.
			
			// Find matching serials.
			SerialsRows = SerialNumbersTbl.FindRows(New Structure("LineItemsLineID", LineID));
			SerialNumbersArr = New Array;
			For i = 0 To SerialsRows.Count() - 1 Do
				SerialNumbersArr.Add(SerialsRows[i].SerialNumber);
			EndDo;
			
			// Generate string from serial numbers column.
			SerialNumbersStr = StringFunctionsClientServer.GetStringFromSubstringArray(SerialNumbersArr, ", ");
		Else
			SerialNumbersStr = "";
		EndIf;
	Else
		SerialNumbersStr = "";
	EndIf;
	
EndProcedure

// Check filing of serial numbers in table parts line items and serial numbers.
// A message generated if serial numbers are not filled, or filled unproperly.
//
// Parameters:
//  Ref           - DocumentRef               - Ref to an object while filling check.
//  LineItems     - DocumentRef.LineItems     - Table part to be checked.
//  SerialNumbers - DocumentRef.SerialNumbers - Table part to be checked.
//  InOut         - Number                    - 0 - Check reception, 1 - Check issue.
//  IgnoreField   - String                    - Name of a field, the non-empty values of which causing the error to be skipped.
//  Cancel        - Boolean                   - Flag of cancel further document check.
//  Target        - String                    - Name of table part/header, where serial numbers checking proceeds.
//
Procedure CheckSerialNumbersFilling(Ref, PointInTime, LineItems, SerialNumbers, InOut, IgnoreField, Cancel, Target = "") Export
	
	// Create list of query tables.
	TablesList  = New Structure;
	CheckResult = New Structure;
	Errors = 0;
	
	// Prepare query for checking the data.
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("PointInTime", New Boundary(PointInTime, BoundaryType.Excluding));
	
	// Copy document tabular sections into temporary tables.
	LineItemsVT = Ref.LineItems.UnloadColumns("LineNumber, Product, ProductDescription, QtyUnits" + ?(Not IsBlankString(IgnoreField), ", " + IgnoreField, ""));
	LineItemsVT.Columns.Insert(1, "LineID", New TypeDescription("String",, New StringQualifiers(36)), "Line ID", 25); // UUID can't be loaded directly :(
	For Each Row In LineItems Do
		FillPropertyValues(LineItemsVT.Add(), Row, "LineNumber, LineID, Product, ProductDescription, QtyUnits" + ?(Not IsBlankString(IgnoreField), ", " + IgnoreField, ""));
	EndDo;
	SerialNumVT = Ref.SerialNumbers.UnloadColumns("SerialNumber");
	SerialNumVT.Columns.Insert(0, "LineItemsLineID", New TypeDescription("String",, New StringQualifiers(36)), "Line ID", 25); // UUID can't be loaded directly :(
	For Each Row In SerialNumbers Do
		FillPropertyValues(SerialNumVT.Add(), Row, "LineItemsLineID, SerialNumber");
	EndDo;
	
	// Check line items matching the serial numbers - string serials and their quantity.
	Query.Text = Query.Text +
	             Query_Check_SerialNumbers_Count(TablesList) +
	             Query_Check_SerialNumbers(TablesList, InOut);
	
	// Add serial numbers balances table.
	If InOut = 0 Or InOut = 1 Then
		Query.Text = Query.Text +
		             Query_Check_SerialNumbers_Items(TablesList, IgnoreField, InOut) +
		             Query_Check_SerialNumbers_Balance(TablesList);
	EndIf;
	
	// Check unickness for reception.
	If InOut = 0 Then
		Query.Text = Query.Text +
		             Query_Check_SerialNumbers_UnicknessOnReception(TablesList, IgnoreField);
	EndIf;
	
	// Check reception for issue.
	If InOut = 1 Then
		Query.Text = Query.Text +
		             Query_Check_SerialNumbers_ReceptionOnIssue(TablesList, IgnoreField);
	EndIf;
	
	// Execute query, fill temporary tables with data.
	If Not IsBlankString(Query.Text) Then
		// Fill data from current document.
		DocumentPosting.PutTemporaryTable(LineItemsVT, "Table_LineItems",     Query.TempTablesManager);
		DocumentPosting.PutTemporaryTable(SerialNumVT, "Table_SerialNumbers", Query.TempTablesManager);
		
		// Execute query.
		QueryResult = Query.ExecuteBatch();
		
		// Save documents table in parameters.
		For Each Table In TablesList Do
			ResultTable = QueryResult[Table.Value].Unload();
			If Not DocumentPosting.IsTemporaryTable(ResultTable) Then
				CheckResult.Insert(Table.Key, ResultTable);
			EndIf;
		EndDo;
	EndIf;
	
	// Clear used temporary tables manager.
	Query.TempTablesManager.Close();
	
	// Define message formating.
	QuantityFormat = GeneralFunctionsReusable.DefaultQuantityFormat();
	IntegerFormat  = "NFD=0; NZ=0";
	MessageParams  = New Structure("LineNumber, Product, ProductDescription, Target, SerialNumber, QuantityExpected, QuantityFound");
	MessageParams.Target = Target;
	ParamsFormat   = New Structure("QuantityExpected, QuantityFound");
	ParamsFormat.QuantityExpected = IntegerFormat;
	ParamsFormat.QuantityFound    = IntegerFormat;
	
	// Format user messages.
	For Each Row In CheckResult.Table_SerialNumbers Do
		
		// Parse data to prepare user message template.
		If Int(Row.QuantityExpected) <> Row.QuantityExpected Then
			// The items quantity is not an integer value.
			ParamsFormat.QuantityExpected = QuantityFormat;
			MessageTemplate = NStr("en = 'Quantity of {Product} {ProductDescription}{Target} is not an integer value: {QuantityExpected}'");
		Else
			// The items quantity does not match the serial numbers count.
			ParamsFormat.QuantityExpected = IntegerFormat;
			MessageTemplate = NStr("en = 'Quantity of {Product} {ProductDescription}{Target} does not match the serial numbers count: expected {QuantityExpected}, found {QuantityFound}.'");
		EndIf;
		MessageTemplate = StrReplace(MessageTemplate, "{Target}", ?(Not IsBlankString(Target), " in {Target}", "") + ?(Target <> "header", " in line {LineNumber}", ""));
		FillPropertyValues(MessageParams, Row, "LineNumber, Product, ProductDescription, QuantityExpected, QuantityFound");
		
		// Fill pattern with parameters.
		MessageText = StringFunctionsClientServer.SubstituteParametersInStringByName(MessageTemplate, MessageParams, ParamsFormat);
		
		// Transfer message to user.
		Errors = Errors + 1;
		If Errors <= 10 Then // There is no need to inform user more then 10 times.
			CommonUseClientServer.MessageToUser(MessageText, Ref,,, Cancel);
		EndIf;
	EndDo;
	
	// Format user messages.
	If CheckResult.Property("Table_SerialNumbers_UnicknessOnReception") Then
		For Each Row In CheckResult.Table_SerialNumbers_UnicknessOnReception Do
			
			// Skip ignored rows.
			If Not IsBlankString(IgnoreField) And ValueIsFilled(Row[IgnoreField]) Then
				Continue;
			EndIf;
			
			// Parse data to prepare user message template.
			MessageTemplate = NStr("en = 'The product {Product} {ProductDescription} with serial {SerialNumber}{Target} already present on hand.'");
			MessageTemplate = StrReplace(MessageTemplate, "{Target}", ?(Not IsBlankString(Target), " in {Target}", "") + ?(Target <> "header", " in line {LineNumber}", ""));
			FillPropertyValues(MessageParams, Row, "LineNumber, Product, ProductDescription, SerialNumber");
			
			// Fill pattern with parameters.
			MessageText = StringFunctionsClientServer.SubstituteParametersInStringByName(MessageTemplate, MessageParams);
			
			// Transfer message to user.
			Errors = Errors + 1;
			If Errors <= 10 Then // There is no need to inform user more then 10 times.
				CommonUseClientServer.MessageToUser(MessageText, Ref,,, Cancel);
			EndIf;
		EndDo;
	EndIf;
	
	// Format user messages.
	If CheckResult.Property("Table_SerialNumbers_ReceptionOnIssue") Then
		For Each Row In CheckResult.Table_SerialNumbers_ReceptionOnIssue Do
			
			// Skip ignored rows.
			If Not IsBlankString(IgnoreField) And ValueIsFilled(Row[IgnoreField]) Then
				Continue;
			EndIf;
			
			// Parse data to prepare user message template.
			MessageTemplate = NStr("en = 'The product {Product} {ProductDescription} with serial {SerialNumber}{Target} is not present on hand.'");
			MessageTemplate = StrReplace(MessageTemplate, "{Target}", ?(Not IsBlankString(Target), " in {Target}", "") + ?(Target <> "header", " in line {LineNumber}", ""));
			FillPropertyValues(MessageParams, Row, "LineNumber, Product, ProductDescription, SerialNumber");
			
			// Fill pattern with parameters.
			MessageText = StringFunctionsClientServer.SubstituteParametersInStringByName(MessageTemplate, MessageParams);
			
			// Transfer message to user.
			Errors = Errors + 1;
			If Errors <= 10 Then // There is no need to inform user more then 10 times.
				CommonUseClientServer.MessageToUser(MessageText, Ref,,, Cancel);
			EndIf;
		EndDo;
	EndIf;
	
	// Inform user about remaining errors.
	If Errors > 10 Then
		MessageText = NStr("en = 'There are also %1 error(s) found'");
		MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessageText, Format(Errors-10, "NFD=0; NG=0"));
		CommonUseClientServer.MessageToUser(MessageText, Ref,,, Cancel);
	EndIf;
	
EndProcedure

//------------------------------------------------------------------------------
// Common lots / serial numbers servicing functions.

// Update visible property of Lots and SerialNumbers columns in a form.
//
// Parameters:
//  Product   - CatalogRef.Products - Ref to a catalog item in a row, which prperties
//                                   are used for setting columns properties.
//            - Structure           - Structure containing same properties.
//  FormItems - FormAllItems        - Ref to form items for adjusting columns properties.
//  InOut     - Number              - 0 - Check reception, 1 - Check issue.
//  AllowEdit - Number              - 0 - Editing of lot / serial number is not allowed,
//                                    1 - Editing of lots is allowed, 2 - Editing of serials is allowed.
//  Target    - String              - Name of table part, where visibility settings must be applied
//
Procedure UpdateLotsSerialNumbersVisibility(Product, FormItems, InOut, AllowEdit, Target = "LineItems") Export
	
	// By default lots and serials are disabled.
	AllowEdit = 0;
	
	// Check using of lots / serial numbers.
	If Product.HasLotsSerialNumbers Then
		
		// Check lots / serails type.
		If Product.UseLots = 0 Then
			// The product uses lots.
			AllowEdit = 1;
			If FormItems.Find(Target+"Lot") <> Undefined Then
				FormItems[Target+"Lot"].Visible = True;
			EndIf;
			
		ElsIf Product.UseLots = 1 Then
			// The product uses serial numbers.
			
			// Select serial numbers using type.
			If (InOut = 0 And Product.UseSerialNumbersOnGoodsReception) // Serial numbers are used on reception.
			Or (InOut = 1 And Product.UseSerialNumbersOnShipment) Then  // Serial numbers are used on shipment.
				
				// The product uses serial numbers.
				AllowEdit = 2;
				If FormItems.Find(Target+"SerialNumbers") <> Undefined Then
					FormItems[Target+"SerialNumbers"].Visible = True;
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

//------------------------------------------------------------------------------
// Serial numbers checking queries.

// Query for document data.
Function Query_Check_SerialNumbers_Count(TablesList)
	
	// Add serial numbers table to document structure.
	TablesList.Insert("Table_SerialNumbers_Count", TablesList.Count());
	
	// Collect serial numbers data.
	QueryText =
	"SELECT
	|	SerialNumbers.LineItemsLineID     AS LineID,
	|	COUNT(SerialNumbers.SerialNumber) AS Quantity
	|INTO
	|	Table_SerialNumbers_Count
	|FROM
	|	Table_SerialNumbers AS SerialNumbers
	|GROUP BY
	|	SerialNumbers.LineItemsLineID";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_Check_SerialNumbers(TablesList, InOut)
	
	// Add serial numbers table to document structure.
	TablesList.Insert("Table_SerialNumbers", TablesList.Count());
	
	// Collect serial numbers data.
	QueryText =
	"SELECT
	|	LineItems.LineNumber              AS LineNumber,
	|	LineItems.Product                 AS Product,
	|	LineItems.ProductDescription      AS ProductDescription,
	|	LineItems.QtyUnits                AS QuantityExpected,
	|	ISNULL(SerialNumbers.Quantity, 0) AS QuantityFound
	|FROM
	|	Table_LineItems AS LineItems
	|	LEFT JOIN Table_SerialNumbers_Count AS SerialNumbers
	|		ON LineItems.LineID = SerialNumbers.LineID
	|WHERE
	|	    LineItems.Product.HasLotsSerialNumbers                  // Has a lots / serial numbers accounting
	|	AND LineItems.Product.UseLots = 1                           // Use serial numbers
	|	AND LineItems.Product.{SerialNumbersCheckingMode}           // Can be used on goods receipt / shipment
	|	AND LineItems.QtyUnits <> ISNULL(SerialNumbers.Quantity, 0) // Quantity does not match
	|";
	
	// Update prdouct checking mode.
	QueryText = StrReplace(QueryText, "{SerialNumbersCheckingMode}",
	                     ?(InOut = 1, "UseSerialNumbersOnShipment", "UseSerialNumbersOnGoodsReception"));
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_Check_SerialNumbers_Items(TablesList, AddField, InOut)
	
	// Add serial numbers table to document structure.
	TablesList.Insert("Table_SerialNumbers_Items", TablesList.Count());
	
	// Collect serial numbers data.
	QueryText =
	"SELECT
	|	LineItemsRows.LineNumber          AS LineNumber,
	|	LineItemsRows.Product             AS Product,
	|	LineItemsRows.ProductDescription  AS ProductDescription,{AddField}
	|	SerialNumbers.SerialNumber        AS SerialNumber
	|INTO
	|	Table_SerialNumbers_Items
	|FROM
	|	Table_SerialNumbers AS SerialNumbers
	|	LEFT JOIN Table_LineItems AS LineItemsRows
	|		ON LineItemsRows.LineID = SerialNumbers.LineItemsLineID
	|	LEFT JOIN Catalog.Products AS Products
	|		ON  Products.Ref = LineItemsRows.Product
	|		AND Products.HasLotsSerialNumbers        // Has a lots / serial numbers accounting
	|		AND Products.UseLots = 1                 // Use serial numbers
	|		AND Products.{SerialNumbersCheckingMode} // Can be used on goods receipt / shipment
	|WHERE
	|	LineItemsRows.Product IS NOT NULL";
	
	// Update fields list.
	QueryText = StrReplace(QueryText, "{AddField}",
	                     ?(Not IsBlankString(AddField), StringFunctionsClientServer.SubstituteParametersInString("
	                       |	LineItemsRows.%1 AS %1,", AddField), ""));
	
	// Update prdouct checking mode.
	QueryText = StrReplace(QueryText, "{SerialNumbersCheckingMode}",
	                     ?(InOut = 1, "UseSerialNumbersOnShipment", "UseSerialNumbersOnGoodsReception"));
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_Check_SerialNumbers_Balance(TablesList)
	
	// Add serial numbers table to document structure.
	TablesList.Insert("Table_SerialNumbers_Balance", TablesList.Count());
	
	// Collect serial numbers data.
	QueryText =
	"SELECT
	|	SerialNumbersSliceLast.Product      AS Product,
	|	SerialNumbersSliceLast.SerialNumber AS SerialNumber,
	|	SerialNumbersSliceLast.OnHand       AS OnHand
	|INTO
	|	Table_SerialNumbers_Balance
	|FROM
	|	InformationRegister.SerialNumbers.SliceLast(&PointInTime, (Product, SerialNumber) IN
	|		(SELECT DISTINCT Product, SerialNumber FROM Table_SerialNumbers_Items))
	|		                                AS SerialNumbersSliceLast";
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_Check_SerialNumbers_UnicknessOnReception(TablesList, AddField)
	
	// Add serial numbers table to document structure.
	TablesList.Insert("Table_SerialNumbers_UnicknessOnReception", TablesList.Count());
	
	// Collect serial numbers data.
	QueryText =
	"SELECT
	|	SerialNumbers.LineNumber          AS LineNumber,
	|	SerialNumbers.Product             AS Product,
	|	SerialNumbers.ProductDescription  AS ProductDescription,{AddField}
	|	SerialNumbers.SerialNumber        AS SerialNumber
	|FROM
	|	Table_SerialNumbers_Items AS SerialNumbers
	|	LEFT JOIN Table_SerialNumbers_Balance AS Balance
	|		ON  SerialNumbers.SerialNumber = Balance.SerialNumber
	|		AND SerialNumbers.Product      = Balance.Product
	|WHERE
	|	    SerialNumbers.Product.UseSerialNumbersCheckUniqueness // Check unickness on goods receipt
	|	AND ISNULL(Balance.OnHand, False)                         // The product with serial number is on hand (i.e. not unique)";
	
	// Update fields list.
	QueryText = StrReplace(QueryText, "{AddField}",
	                     ?(Not IsBlankString(AddField), StringFunctionsClientServer.SubstituteParametersInString("
	                       |	SerialNumbers.%1 AS %1,", AddField), ""));
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

// Query for document data.
Function Query_Check_SerialNumbers_ReceptionOnIssue(TablesList, AddField)
	
	// Add serial numbers table to document structure.
	TablesList.Insert("Table_SerialNumbers_ReceptionOnIssue", TablesList.Count());
	
	// Collect serial numbers data.
	QueryText =
	"SELECT
	|	SerialNumbers.LineNumber          AS LineNumber,
	|	SerialNumbers.Product             AS Product,
	|	SerialNumbers.ProductDescription  AS ProductDescription,{AddField}
	|	SerialNumbers.SerialNumber        AS SerialNumber
	|FROM
	|	Table_SerialNumbers_Items AS SerialNumbers
	|	LEFT JOIN Table_SerialNumbers_Balance AS Balance
	|		ON  SerialNumbers.SerialNumber = Balance.SerialNumber
	|		AND SerialNumbers.Product      = Balance.Product
	|WHERE
	|	    SerialNumbers.Product.UseSerialNumbersCheckReception  // Check reception on shipment
	|	AND NOT ISNULL(Balance.OnHand, False)                     // The product with serial number is not on hand (not recepted)";
	
	// Update fields list.
	QueryText = StrReplace(QueryText, "{AddField}",
	                     ?(Not IsBlankString(AddField), StringFunctionsClientServer.SubstituteParametersInString("
	                       |	SerialNumbers.%1 AS %1,", AddField), ""));
	
	Return QueryText + DocumentPosting.GetDelimeterOfBatchQuery();
	
EndFunction

#EndRegion