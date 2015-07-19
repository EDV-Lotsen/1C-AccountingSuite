////////////////////////////////////////////////////////////////////////////////
//  Methods, implementing tax calculation at Avalara
//  
////////////////////////////////////////////////////////////////////////////////
#Region PUBLIC_INTERFACE

//Fills AvataxCustomerUsageTypes catalog with predefined items
//Need to be called within open transaction to apply data locks
Procedure FillCustomerUsageTypes() Export
	
	SetPrivilegedMode(True);
	
	//Lock TaxCodes catalog
	DLock = New DataLock();
	LockItem = DLock.Add("Catalog.AvataxCustomerUsageTypes");
	LockItem.Mode = DataLockMode.Exclusive;
	DLock.Lock();
	
	//Fills only empty catalog (until any items are added)
	Request = New Query("SELECT
	                    |	1 AS Field1
	                    |FROM
	                    |	Catalog.AvataxCustomerUsageTypes AS AvataxCustomerUsageTypes");
	If Not Request.Execute().IsEmpty() Then
		return;
	EndIf;
	
	NewItem = Catalogs.AvataxCustomerUsageTypes.CreateItem();
	NewItem.Code = "A";
	NewItem.Description = "Federal Government";
	NewItem.Write();
	
	NewItem = Catalogs.AvataxCustomerUsageTypes.CreateItem();
	NewItem.Code = "B";
	NewItem.Description = "State/Local Govt.";
	NewItem.Write();
	
	NewItem = Catalogs.AvataxCustomerUsageTypes.CreateItem();
	NewItem.Code = "C";
	NewItem.Description = "Tribal Government";
	NewItem.Write();
	
	NewItem = Catalogs.AvataxCustomerUsageTypes.CreateItem();
	NewItem.Code = "D";
	NewItem.Description = "Foreign Diplomat";
	NewItem.Write();
	
	NewItem = Catalogs.AvataxCustomerUsageTypes.CreateItem();
	NewItem.Code = "E";
	NewItem.Description = "Charitable Organization";
	NewItem.Write();
	
	NewItem = Catalogs.AvataxCustomerUsageTypes.CreateItem();
	NewItem.Code = "F";
	NewItem.Description = "Religious/Education";
	NewItem.Write();
	
	NewItem = Catalogs.AvataxCustomerUsageTypes.CreateItem();
	NewItem.Code = "G";
	NewItem.Description = "Resale";
	NewItem.Write();
	
	NewItem = Catalogs.AvataxCustomerUsageTypes.CreateItem();
	NewItem.Code = "H";
	NewItem.Description = "Agricultural Production";
	NewItem.Write();
	
	NewItem = Catalogs.AvataxCustomerUsageTypes.CreateItem();
	NewItem.Code = "I";
	NewItem.Description = "Industrial Prod/Mfg";
	NewItem.Write();
	
	NewItem = Catalogs.AvataxCustomerUsageTypes.CreateItem();
	NewItem.Code = "J";
	NewItem.Description = "Direct Pay Permit";
	NewItem.Write();
	
	NewItem = Catalogs.AvataxCustomerUsageTypes.CreateItem();
	NewItem.Code = "K";
	NewItem.Description = "Direct Mail";
	NewItem.Write();
	
	NewItem = Catalogs.AvataxCustomerUsageTypes.CreateItem();
	NewItem.Code = "L";
	NewItem.Description = "Other";
	NewItem.Write();
	
	NewItem = Catalogs.AvataxCustomerUsageTypes.CreateItem();
	NewItem.Code = "N";
	NewItem.Description = "Local Government";
	NewItem.Write();
	
	NewItem = Catalogs.AvataxCustomerUsageTypes.CreateItem();
	NewItem.Code = "P";
	NewItem.Description = "Commercial Aquaculture (Canada)";
	NewItem.Write();
	
	NewItem = Catalogs.AvataxCustomerUsageTypes.CreateItem();
	NewItem.Code = "Q";
	NewItem.Description = "Commercial Fishery (Canada)";
	NewItem.Write();
	
	NewItem = Catalogs.AvataxCustomerUsageTypes.CreateItem();
	NewItem.Code = "R";
	NewItem.Description = "Non-resident (Canada)";
	NewItem.Write();
	
	NewItem = Catalogs.AvataxCustomerUsageTypes.CreateItem();
	NewItem.Code = "MED1";
	NewItem.Description = "US MDET with exempt sales tax";
	NewItem.Write();
	
	NewItem = Catalogs.AvataxCustomerUsageTypes.CreateItem();
	NewItem.Code = "MED2";
	NewItem.Description = "US MDET with taxable sales tax";
	NewItem.Write();	
	
	SetPrivilegedMode(False);
	
EndProcedure

//Function tries to get values from the StructureSource and put them in the StructureDestination
//Not all required items may be present in the StructureSource
//List of structure item names to read is taken from StructureDestination keys
Procedure ReadStructureValuesSafely(StructureSource, StructureDestination) Export
	
	For Each StructDestItem In StructureDestination Do
		If StructureSource.Property(StructDestItem.Key) Then
			StructureDestination[StructDestItem.Key] = StructureSource[StructDestItem.Key];
		EndIf;
	EndDo;
	
EndProcedure

//Preliminary temporary calculation of taxes at Avalara. For posting purpose.
//Permanent document will be saved at Avalara after successful posting is committed (In the AfterWriteAtServer procedure)
// Parameters:
//  CurrentObject 	- DocumentObject - CurrentObject parameter of the BeforeWriteAtServer document form event handler
//  WriteParameters - Structure - WriteParameters parameter of the BeforeWriteAtServer document form event handler
//  Cancel			- Boolean - Cancel parameter of the BeforeWriteAtServer document form event handler
//  DocType			- String - "SalesOrder", "ReturnOrder"
//
Procedure CalculateTaxBeforeWrite(CurrentObject, WriteParameters, Cancel, Val DocType) Export
	
	If CurrentObject.UseAvatax Then
		SaveAvataxDetails = False;
		If DocType = "SalesOrder" Then
			DocumentIsPresentAtAvatax = IsDocumentPresentAtAvatax(CurrentObject.Ref);
			If Not DocumentIsPresentAtAvatax Then
				SaveAvataxDetails = True;
			EndIf;
		EndIf;
		//Avatax calculation
		If WriteParameters.Property("CalculateTaxAtAvalara") And (Cancel = False) Then
			//Preliminary temporary calculation of taxes at Avalara. For posting purpose.
			//Permanent document will be saved at Avalara after successful posting is committed (In the AfterWriteAtServer procedure)
			CalculateTaxAtAvalara(CurrentObject, DocType, False, Cancel, SaveAvataxDetails);
			CurrentObject.AdditionalProperties.Insert("CalculateTaxAtAvalara", WriteParameters.CalculateTaxAtAvalara);
		ElsIf WriteParameters.Property("CancelAndCalculateTaxAtAvalara") And (Cancel = False) Then
			If Not (WriteParameters.WriteMode = DocumentWriteMode.UndoPosting) Then //When undoing posting there is no need in calculating sales tax
				CalculateTaxAtAvalara(CurrentObject, DocType, False, Cancel);
			EndIf;
			CurrentObject.AdditionalProperties.Insert("CancelAndCalculateTaxAtAvalara", WriteParameters.CancelAndCalculateTaxAtAvalara);
		EndIf;
	EndIf;
	
EndProcedure

//Permanent calculation of taxes at Avalara. Appropriate document is created at Avalara side
//Occures after successful posting is committed (In the AfterWriteAtServer procedure)
// Parameters:
//  CurrentObject 	- DocumentObject - CurrentObject parameter of the BeforeWriteAtServer document form event handler
//  WriteParameters - Structure - WriteParameters parameter of the BeforeWriteAtServer document form event handler
//  DocType			- String - "SalesInvoice", "ReturnInvoice"
//
Procedure CalculateTaxAfterWrite(CurrentObject, WriteParameters, Val DocType) Export
	
	//For Sales Order we save uncommitted document at Avalara, when the document is posted 
	If DocType = "SalesOrder" Then
		DocumentIsPresentAtAvatax = IsDocumentPresentAtAvatax(CurrentObject.Ref);
		If Not (CurrentObject.Posted Or DocumentIsPresentAtAvatax) Then
			return;
		Else
			Commit = False;
			DocType = "SalesInvoice";
		EndIf;
	Else
		Commit = CurrentObject.Posted;
	EndIf;
	If WriteParameters.Property("CalculateTaxAtAvalara") Then
		//Saving permanent document at Avalara after successful posting is committed
		CalculateTaxAtAvalara(CurrentObject, DocType, Commit);
	ElsIf WriteParameters.Property("CancelAndCalculateTaxAtAvalara") Then
		CancelTaxAtAvalara(CurrentObject, DocType);
		CalculateTaxAtAvalara(CurrentObject, DocType, Commit);
	EndIf;
	
EndProcedure

//Function sends a request to Avalara
//
// Parameters:
//  RequestType - Type: EnumRef.AvalaraRequestType - defines request type: testing connection, address validation or tax calculation
//  RequestParameters - Type: Structure - contains passed parameters
//	ObjectRef - Type: DocumentRef.SalesOrder, DocumentRef.SalesInvoice, DocumentRef.SalesReturn, CatalogRef.Addresses - object, using AvaTax functionality
// Returns:
//  DecodedResultBody 	- Type: Structure - decoded contents of requested data
//    Successful 		- Type: Boolean - if True, then the operation performed successfully, if False then failed
//    ErrorMessage		- Type: String	- present, if Successful = False. Contains a message for display to the user
//    Other fields depend on the operation performed (RequestType). If the response is not empty, the following fields should be:
//    ResultCode		- Type: String - An indication of the success of the request. Possible SeverityLevel values are: Success, Error, Warning, Exception.	SeverityLevel
//    Messages			- Type: Array - If ResultCode is Success, Messages is null. Otherwise, it describes any warnings, errors, or exceptions encountered while processing the request.	Message[]
//    TransactionId		- Type: String - The unique transaction ID assigned by AvaTax to this request/response set. This value need only be retained for troubleshooting.	Integer
//
Function SendRequestToAvalara(RequestType, RequestParameters, ObjectRef, ServiceParameters = Undefined, TransactionID = Undefined) Export
	
Try
		
	SetPrivilegedMode(True);
	
	//For logging 
	HeadersMap 	= New Map();
	TimeSpent	= 0;
	
	ConnectionTestAddress 		= "1.0/tax/47.627935,-122.51702/get";
	AddressValidationAddress 	= "1.0/address/validate";
	TaxCalculationAddress 		= "1.0/tax/get";
	CancelTaxAddress			= "1.0/tax/cancel";
	
	If ServiceParameters = Undefined Then
		AvataxServiceURL 			= Constants.AvataxServiceURL.Get();
		AvataxAuthorizationString 	= Constants.AvataxAuthorizationString.Get();
	Else
		AvataxServiceURL 			= ServiceParameters.AvataxServiceURL;
		AvataxAuthorizationString	= ServiceParameters.AvataxAuthorizationString;
	EndIf;	
	
	If RequestType = Enums.AvalaraRequestTypes.TaxCalculation Then
		HTTPAddress = AvataxServiceURL + TaxCalculationAddress;
		Method = "POST";
	ElsIf RequestType = Enums.AvalaraRequestTypes.CancelTax Then
		HTTPAddress = AvataxServiceURL + CancelTaxAddress;
		Method = "POST";
	ElsIf RequestType = Enums.AvalaraRequestTypes.AddressValidation Then
		HTTPAddress = AvataxServiceURL + AddressValidationAddress;
		Method = "GET";
	ElsIf RequestType = Enums.AvalaraRequestTypes.ConnectionTest Then
		HTTPAddress = AvataxServiceURL + ConnectionTestAddress;
		Method = "GET";
	Else
		Raise "Unsupported Avalara request type";
	EndIf;
	
	Authorization 	= TrimAll(AvataxAuthorizationString);
	DataJSON 		= Undefined;
	If Method = "GET" Then
		// Apply parameters to the connection settings (override URL).
		ConnectionSettings = New Structure("Parameters, ParametersDecoded");
		ConnectionSettings.Parameters        = InternetConnectionClientServer.EncodeQueryData(RequestParameters);
		ConnectionSettings.ParametersDecoded = RequestParameters;
	ElsIf Method = "POST" Then
		ConnectionSettings = New Structure();
		DataJSON = InternetConnectionClientServer.EncodeJSON(RequestParameters);
	Else
		Raise "Unsupported internet request method";
	EndIf;
	
	AvalaraRequestStart = CurrentUniversalDateInMilliseconds();//Avalara request time measurement
	HeadersMap = New Map();
	HeadersMap.Insert("Content-Type", "text/json");
	HeadersMap.Insert("Authorization", Authorization);
	Connection 	= InternetConnectionClientServer.CreateConnection(HTTPAddress, ConnectionSettings).Result;
	Response	= InternetConnectionClientServer.SendRequest(Connection, Method, ConnectionSettings, HeadersMap, DataJSON);
	AvalaraRequestEnd	= CurrentUniversalDateInMilliseconds();//Avalara request time measurement
	TimeSpent = AvalaraRequestEnd - AvalaraRequestStart;
	If ValueIsFilled(Response.Result) Then
		JSONResponse = Response.Result;
		DecodedResultBody = InternetConnectionClientServer.DecodeJSON(JSONResponse);
	Else
		JSONResponse = "";
		DecodedResultBody = New Structure;
		If ValueIsFilled(Response.Description) Then
			Messages = New Array();
			Messages.Add(New Structure("Name, Summary, Details, Severety, RefersTo, Source, HelpLink", "Internet connection error", "Internet request failed", Response.Description, "Error", "", "", ""));
			DecodedResultBody.Insert("Messages", Messages);
		EndIf;
	EndIf;
	
	//For CancelTax should change DecodedResultBody to conform standard format (if differs)
	If RequestType = Enums.AvalaraRequestTypes.CancelTax Then
		If DecodedResultBody.Property("CancelTaxResult") Then
			For Each Field In DecodedResultBody.CancelTaxResult Do
				DecodedResultBody.Insert(Field.Key, Field.Value);
			EndDo;
		EndIf;
	EndIf;
			
Except
	
	ErrInfo = ErrorInfo();
	ErrDescription = ErrorDescription();
	Messages = New Array();
	Messages.Add(New Structure("Name, Summary, Details, Severety, RefersTo, Source, HelpLink", "AccountingSuite Exception", ErrInfo.Description, ErrDescription, "Exception", "", "AccountingSuite Module:" + ErrInfo.ModuleName + " Line:" + String(ErrInfo.LineNumber), ""));
	DecodedResultBody = New Structure("ResultCode, Messages", "Exception", Messages);
	
EndTry;

	If DecodedResultBody.Property("ResultCode") Then
		If Upper(DecodedResultBody.ResultCode) <> "SUCCESS" Then
			If DecodedResultBody.Property("Messages") Then
				DecodedResultBody.Insert("ErrorMessage", GetErrorMessage(DecodedResultBody.Messages, RequestType, ObjectRef));
			Else
				DecodedResultBody.Insert("ErrorMessage", "An unknown error occured");
			EndIf;
			If RequestType = Enums.AvalaraRequestTypes.CancelTax Then
				If Find(DecodedResultBody.ErrorMessage, "The tax document could not be found.") Then
					DecodedResultBody.Insert("Successful", True);
				Else
					DecodedResultBody.Insert("Successful", False);
				EndIf;
			Else
				DecodedResultBody.Insert("Successful", False);
			EndIf;
		Else
			DecodedResultBody.Insert("Successful", True);
		EndIf;
	Else
		DecodedResultBody.Insert("ErrorMessage", GetErrorMessage(DecodedResultBody.Messages, RequestType, ObjectRef));
		DecodedResultBody.Insert("Successful", False);
	EndIf;
	
	//Log Avalara request
	//If the request to Avalara is inside an active transaction then we should log it in a background job,
	//so that transaction rollback couldn't influence logging
	If TransactionActive() Then
		//Prepare data for background execution
		ProcParameters = New Array;
 		ProcParameters.Add(ObjectRef);
 		ProcParameters.Add(RequestType);
		ProcParameters.Add(RequestParameters);
		ProcParameters.Add(HTTPAddress);
		ProcParameters.Add(Response.AdditionalData);//Headers and StatusCode
		ProcParameters.Add(JSONResponse);
		ProcParameters.Add(DecodedResultBody);
		ProcParameters.Add(TimeSpent);
		If TransactionID <> Undefined Then
			ProcParameters.Add(TransactionID);
		EndIf;
	
		//Performing background operation
		JobTitle = NStr("en = 'Logging Avalara request'");
		Job = BackgroundJobs.Execute("AvaTaxServer.LogAvataxTransaction", ProcParameters, , JobTitle);
	Else
		AvaTaxServer.LogAvataxTransaction(ObjectRef, RequestType, RequestParameters, HTTPAddress, Response.AdditionalData, JSONResponse, DecodedResultBody, TimeSpent, TransactionID);
	EndIf;
	
	return DecodedResultBody;
	
EndFunction

Procedure LogAvataxTransaction(ObjectRef, RequestType, RequestParameters, HTTPAddress, HeadersMap, ResultBody, DecodedResultBody, TimeSpent, TransactionID = Undefined) Export
	
	SetPrivilegedMode(True);
	ResultCode 	= "Unknown";
	AvataxTransactionID = "";
	Messages 	= New Array();
	ErrorMessage = "";

	If DecodedResultBody.Property("ResultCode") Then
		ResultCode = DecodedResultBody.ResultCode;
	EndIf;
	If DecodedResultBody.Property("Messages") Then
		Messages = DecodedResultBody.Messages;
	EndIf;
	If DecodedResultBody.Property("TransactionID") Then
		AvataxTransactionID = DecodedResultBody.TransactionID;
	EndIf;
	If DecodedResultBody.Property("ErrorMessage") Then
		ErrorMessage = DecodedResultBody.ErrorMessage;
	EndIf;

	TransactionDate = CurrentUniversalDate();
	If TransactionID = Undefined Then
		TransactionID	= New UUID();
	EndIf;
	
	NewRecordSet = InformationRegisters.AvalaraTransactions.CreateRecordSet();
	NewRecordSet.Filter.ObjectRef.Set(ObjectRef);
	NewRecordSet.Filter.Date.Set(TransactionDate);
	NewRecordSet.Filter.TransactionID.Set(TransactionID);
	NewRecordSet.Filter.RequestType.Set(RequestType);
	NewRecord = NewRecordSet.Add();
	NewRecord.Active = True;
	NewRecord.ObjectRef = ObjectRef;
	NewRecord.Date 		= TransactionDate;
	NewRecord.TransactionID = TransactionID;
	NewRecord.RequestType	= RequestType;
	RequestParametersStructure = New Structure("HTTPAddress, HeadersMap, RequestParameters", HTTPAddress, HeadersMap, RequestParameters);
	NewRecord.RequestParameters = New ValueStorage(RequestParametersStructure);
	NewRecord.ResultBody		= ResultBody;
	NewRecord.ResultCode		= ResultCode;
	NewRecord.Messages 			= New ValueStorage(Messages);
	NewRecord.AvataxTransactionID 	= AvataxTransactionID;
	NewRecord.ErrorMessage		= ErrorMessage;
	NewRecord.TimeSpent			= TimeSpent;
	NewRecordSet.Write();
	
EndProcedure

Function GetErrorMessage(Messages, RequestType, ObjectRef) Export
	If TypeOf(Messages) = Type("Array") Then
		ErrorMessage = ?(ValueIsFilled(ObjectRef), String(ObjectRef) + ". ", "") + "During the " + Lower(String(RequestType)) + " an error(s) occured. Details:" + Chars.LF;
		For Each Message In Messages Do
			CurrentMessage = New Structure("Name, Summary, Details, Severety, RefersTo, Source, HelpLink");
			ReadStructureValuesSafely(Message, CurrentMessage);
			ErrorMessage = ErrorMessage + ?(ValueIsFilled(CurrentMessage.Source), CurrentMessage.Source + ": ", "");
			ErrorMessage = ErrorMessage + CurrentMessage.Summary;
			ErrorMessage = TrimAll(ErrorMessage) + ?(ValueIsFilled(CurrentMessage.RefersTo), " Refers to: " + CurrentMessage.RefersTo + ".", "");
			ErrorMessage = TrimAll(ErrorMessage) + ?(ValueIsFilled(CurrentMessage.Details), " Details: " + CurrentMessage.Details, "");
			ErrorMessage = TrimAll(ErrorMessage) + Chars.LF;
		EndDo;
		return ErrorMessage;
	Else
		return "An unknown error occured";
	EndIf;
EndFunction

Procedure RestoreCalculatedSalesTax(Object) Export
	
	SetPrivilegedMode(True);
	If Object.Ref.IsEmpty() Then
		return;
	EndIf;
	
	Request = New Query("SELECT
	                    |	AvataxDetails.TimeStamp,
	                    |	AvataxDetails.TaxDetails
	                    |FROM
	                    |	InformationRegister.AvataxDetails AS AvataxDetails
	                    |WHERE
	                    |	AvataxDetails.ObjectRef = &ObjectRef");
	Request.SetParameter("ObjectRef", Object.Ref);
	Res = Request.Execute();
	If Res.IsEmpty() Then
		return;
	EndIf;
	Sel = Res.Select();
	Sel.Next();
	DecodedResultBody = Sel.TaxDetails.Get();
	//Object.TaxableSubtotal = DecodedResultBody.TotalTaxable;
	//Object.SalesTax		= DecodedResultBody.TotalTax;
	////Recalculate totals
	//Object.SalesTaxRC       = Round(Object.SalesTax * Object.ExchangeRate, 2);
	//Object.DocumentTotal    = Object.SubTotal + Object.Shipping + Object.SalesTax;
	//Object.DocumentTotalRC  = Round(Object.DocumentTotal * Object.ExchangeRate, 2);
	
	ObjectType = TypeOf(Object.Ref);
	If ObjectType = Type("DocumentRef.SalesOrder") Or ObjectType = Type("DocumentRef.SalesInvoice") Then
		Object.TaxableSubtotal 	= DecodedResultBody.TotalTaxable;
		Object.SalesTax			= DecodedResultBody.TotalTax;
		Object.SalesTaxRC       = Round(Object.SalesTax * Object.ExchangeRate, 2);
		SalesTaxRC				= Object.SalesTaxRC;
	ElsIf ObjectType = Type("DocumentRef.SalesReturn") Then
		Object.TaxableSubtotal 	= -1 * DecodedResultBody.TotalTaxable;
		Object.SalesTax			= -1 * DecodedResultBody.TotalTax;
		SalesTaxRC       		= Round(Object.SalesTax * Object.ExchangeRate, 2);
	EndIf;				
	Object.DocumentTotal    = Object.SubTotal + Object.Shipping + Object.SalesTax;
	SubTotalRC				= Round(Object.SubTotal * Object.ExchangeRate, 2);
	ShippingRC				= Round(Object.Shipping * Object.ExchangeRate, 2);
	Object.DocumentTotalRC	= SubTotalRC + ShippingRC + SalesTaxRC;
		
	//Fill tax details (tax components)
	TaxDetailsTab = New ValueTable();
	TaxDetailsTab.Columns.Add("TaxName", New TypeDescription("String"));
	TaxDetailsTab.Columns.Add("Rate", New TypeDescription("Number"));
	TaxDetailsTab.Columns.Add("Tax", New TypeDescription("Number"));
	For Each TaxLine In DecodedResultBody.TaxLines Do
		For Each TaxDetail In TaxLine.TaxDetails Do
			NewTaxDetail = TaxDetailsTab.Add();
			FillPropertyValues(NewTaxDetail, TaxDetail);
		EndDo;
	EndDo;
	TaxDetailsTab.GroupBy("TaxName, Rate", "Tax");
	Object.SalesTaxAcrossAgencies.Clear();
	For Each TaxDetail In TaxDetailsTab Do
		NewSTAA = Object.SalesTaxAcrossAgencies.Add();
		NewSTAA.AvataxTaxComponent 	= TaxDetail.TaxName;
		NewSTAA.Rate				= TaxDetail.Rate * 100;
		If ObjectType = Type("DocumentRef.SalesReturn") Then
			NewSTAA.Amount				= -1 * TaxDetail.Tax;
		Else
			NewSTAA.Amount				= TaxDetail.Tax;
		EndIf;
	EndDo;

EndProcedure

Function GetRequestParametersForGetTax(Object, DocType, Commit) Export
	
	SetPrivilegedMode(True);
	CommitValue = Commit;
	RequestParameters = New Structure();
	Company = Object.Company;
	RequestParameters.Insert("BusinessIdentificationNo", Company.BusinessIdentificationNo);
	RequestParameters.Insert("Commit", CommitValue);
	RequestParameters.Insert("Client", "AccountingSuite");
	RequestParameters.Insert("CompanyCode", Constants.AvataxCompanyCode.Get());
	RequestParameters.Insert("CustomerCode", Company.Code);
	RequestParameters.Insert("CurrencyCode", Object.Currency.Code);
	If ValueIsFilled(Company.AvataxCustomerUsageType.Code) Then
		RequestParameters.Insert("CustomerUsageType", Company.AvataxCustomerUsageType.Code);
	EndIf;
	RequestParameters.Insert("DetailLevel", "Tax");
	RequestParameters.Insert("Discount", -1 * Object.Discount);
	DocID = Object.AvataxDocCode;
	
	FoundDisallowedSymbol = FindDisallowedXMLCharacters(DocID);
	
	RequestParameters.Insert("DocCode", DocID);
	RequestParameters.Insert("DocDate", Format(Object.Date, "DF=yyyy-MM-dd"));
	
	RequestParameters.Insert("DocType", DocType);	
		
	If ValueIsFilled(Company.ResaleNO) Then
		RequestParameters.Insert("ExemptionNo", Company.ResaleNO);	
	EndIf;
	//Addresses
	UsedAddresses = New Array();
	
	If DocType = "SalesOrder" Or DocType = "SalesInvoice" Then
		DestinationCode = Object.ShipTo;
		LocationColumn = "";
		If TypeOf(Object) = Type("DocumentObject.SalesInvoice") Then
			OriginCode		= Object.LocationActual;
			LocationColumn = "LocationActual";
		Else
			OriginCode		= Object.Location;
			LocationColumn = "Location";
		EndIf;
		UsedAddresses.Add(Object.ShipTo);
		UsedAddresses.Add(OriginCode);		
		For Each Line In Object.LineItems Do
			If ValueIsFilled(Line[LocationColumn]) Then
				If UsedAddresses.Find(Line[LocationColumn]) = Undefined  Then
					UsedAddresses.Add(Line[LocationColumn]);
				EndIf;
			EndIf;
		EndDo;

	ElsIf DocType = "ReturnOrder" Or DocType = "ReturnInvoice" Then
		DestinationCode = Object.ShipFrom;
		OriginCode		= Object.Location;
		UsedAddresses.Add(Object.ShipFrom);
		UsedAddresses.Add(Object.Location);		
	Else
		raise "Unsupported document type";
	EndIf;
	
	Addresses = New Array();
	i = 1;
	For Each UsedAddress In UsedAddresses Do
		AddressStructure = New Structure();
		AddressStructure.Insert("AddressCode", "Address" + String(i));
		AddressStructure.Insert("Line1", UsedAddress.AddressLine1);
		AddressStructure.Insert("Line2", UsedAddress.AddressLine2);
		AddressStructure.Insert("Line3", UsedAddress.AddressLine3);
		AddressStructure.Insert("City", UsedAddress.City);
		AddressStructure.Insert("Region", UsedAddress.State.Code);
		AddressStructure.Insert("Country", UsedAddress.Country.Code);
		AddressStructure.Insert("PostalCode", UsedAddress.ZIP);
		Addresses.Add(AddressStructure);
		i = i + 1;
	EndDo;
	RequestParameters.Insert("Addresses", Addresses);
	Lines = New Array();
	For Each LineItem In Object.LineItems Do
		Line = New Structure();
		Line.Insert("LineNo", String(LineItem.LineNumber));
		Line.Insert("DestinationCode", "Address" + String(UsedAddresses.Find(DestinationCode) + 1));
		If DocType = "SalesOrder" Or DocType = "SalesInvoice" Then
			ShipFrom = ?(ValueIsFilled(LineItem[LocationColumn]), LineItem[LocationColumn], Object[LocationColumn]);
		ElsIf DocType = "ReturnOrder" Or DocType = "ReturnInvoice" Then
			ShipFrom = Object.Location;
		EndIf;
		Line.Insert("OriginCode", "Address" + String(UsedAddresses.Find(ShipFrom) + 1));
		Line.Insert("ItemCode", ?(ValueIsFilled(LineItem.Product.UPC), LineItem.Product.UPC, LineItem.Product.Code));
		Line.Insert("TaxCode", LineItem.AvataxTaxCode.Code);
		Line.Insert("Description", LineItem.Product.Description);
		Line.Insert("Qty", LineItem.QtyUnits);
		TaxableAmount = 0;
		Discounted = False;
		If Object.DiscountTaxability = Enums.DiscountTaxability.NonTaxable Then
			TaxableAmount = LineItem.LineTotal - Round(LineItem.LineTotal * Object.DiscountPercent/100, 2);
			Discounted = True;
		ElsIf Object.DiscountTaxability = Enums.DiscountTaxability.Taxable Then
			TaxableAmount = LineItem.LineTotal;
			Discounted = False;
		Else
			TaxableAmount = LineItem.LineTotal - ?(LineItem.DiscountIsTaxable, 0, Round(LineItem.LineTotal * Object.DiscountPercent/100, 2));
			Discounted = Not LineItem.DiscountIsTaxable;
		EndIf;
		Line.Insert("Amount", TaxableAmount);
		Line.Insert("Discounted", False);
		Lines.Add(Line);
	EndDo;
	//Should add separate line for Shipping
	//Shipping
	If Object.Shipping <> 0 Then
		Line = New Structure();
		Line.Insert("LineNo", "Shipping");
		Line.Insert("DestinationCode", "Address" + String(UsedAddresses.Find(DestinationCode) + 1));
		Line.Insert("OriginCode", "Address" + String(UsedAddresses.Find(OriginCode) + 1));
		Line.Insert("ItemCode", "Shipping_a7c0a68f-6324-47fa-9c19-911b5dfbe532");
		Line.Insert("TaxCode", Object.AvataxShippingTaxCode.Code);
		Line.Insert("Description", "Shipping");
		Line.Insert("Qty", 1);
		Line.Insert("Amount", Object.Shipping);
		Line.Insert("Discounted", False);
		Lines.Add(Line);
	EndIf;
	RequestParameters.Insert("Lines", Lines);
	
	//Apply some changes to the RequestParameters in case of ReturnOrder or ReturnInvoice
	//Invert amounts (except for shipping which should be recorded as per business practice)
	//Set TaxOverride.TaxDate to the original order date
	If DocType = "ReturnOrder" Or DocType = "ReturnInvoice" Then
		RequestParameters.Discount = -1 * RequestParameters.Discount;
		For Each Line In RequestParameters.Lines Do
			If Line.LineNo = "Shipping" Then 
				Continue;
			EndIf;
			Line.Amount = -1 * Line.Amount;
		EndDo;
		If ValueIsFilled(Object.ParentDocument) Then
			TaxOverride = New Structure("Reason, TaxOverrideType, TaxDate", "Using the original sales invoice date for the tax rates", "TaxDate", Format(Object.ParentDocument.Date, "DF=yyyy-MM-dd"));
			RequestParameters.Insert("TaxOverride", TaxOverride);
		EndIf;
	EndIf;
	
	return RequestParameters;
	
EndFunction

Procedure CalculateTaxAtAvalara(Object, DocType, Commit = False, Cancel = False, SaveAvataxDetails = False) Export
	
	SetPrivilegedMode(True);
	//If Avalara is enabled then calculate taxes at Avalara
	If Constants.AvataxEnabled.Get() And (Not Constants.AvataxDisableTaxCalculation.Get()) Then
		RequestParameters = AvataxServer.GetRequestParametersForGetTax(Object, DocType, Commit);
		//If object ref is empty, then assign a new ID to correctly log the transaction
		If Object.Ref.IsEmpty() Then
			DocID 	= New UUID();
			DocRef	= Documents[Object.Metadata().Name].GetRef(DocID);
			Object.SetNewObjectRef(DocRef);
		Else
			DocRef 	= Object.Ref; 
		EndIf;
		TransactionID = New UUID();
		DecodedResultBody = AvaTaxServer.SendRequestToAvalara(Enums.AvalaraRequestTypes.TaxCalculation, RequestParameters, DocRef,, TransactionID);
		If DecodedResultBody.Successful Then
			//Recalculate totals
			If DocType = "SalesOrder" Or DocType = "SalesInvoice" Then
				Object.TaxableSubtotal 	= DecodedResultBody.TotalTaxable;
				Object.SalesTax			= DecodedResultBody.TotalTax;
				Object.SalesTaxRC       = Round(Object.SalesTax * Object.ExchangeRate, 2);
				SalesTaxRC				= Object.SalesTaxRC;
			ElsIf DocType = "ReturnOrder" Or DocType = "ReturnInvoice" Then
				Object.TaxableSubtotal	= DecodedResultBody.TotalTaxable;
				Object.SalesTax			= DecodedResultBody.TotalTax;
				Object.TaxableSubtotal 	= ?(Object.TaxableSubtotal < 0, -1 * Object.TaxableSubtotal, Object.TaxableSubtotal);
				Object.SalesTax			= ?(Object.SalesTax < 0, -1 * Object.SalesTax, Object.SalesTax);
				SalesTaxRC       		= Round(Object.SalesTax * Object.ExchangeRate, 2);
			EndIf;				
			Object.DocumentTotal    = Object.SubTotal + Object.Shipping + Object.SalesTax;
			SubTotalRC				= Round(Object.SubTotal * Object.ExchangeRate, 2);
			ShippingRC				= Round(Object.Shipping * Object.ExchangeRate, 2);
			Object.DocumentTotalRC	= SubTotalRC + ShippingRC + SalesTaxRC;
		
			//Fill tax details (tax components)
			TaxDetailsTab = New ValueTable();
			TaxDetailsTab.Columns.Add("TaxName", New TypeDescription("String"));
			TaxDetailsTab.Columns.Add("Rate", New TypeDescription("Number"));
			TaxDetailsTab.Columns.Add("Tax", New TypeDescription("Number"));
			For Each TaxLine In DecodedResultBody.TaxLines Do
				For Each TaxDetail In TaxLine.TaxDetails Do
					NewTaxDetail = TaxDetailsTab.Add();
					FillPropertyValues(NewTaxDetail, TaxDetail);
				EndDo;
			EndDo;
			TaxDetailsTab.GroupBy("TaxName, Rate", "Tax");
			Object.SalesTaxAcrossAgencies.Clear();
			For Each TaxDetail In TaxDetailsTab Do
				NewSTAA = Object.SalesTaxAcrossAgencies.Add();
				NewSTAA.AvataxTaxComponent 	= TaxDetail.TaxName;
				NewSTAA.Rate				= TaxDetail.Rate * 100;
				If DocType = "SalesOrder" Or DocType = "SalesInvoice" Then
					NewSTAA.Amount				= TaxDetail.Tax;
				ElsIf DocType = "ReturnOrder" Or DocType = "ReturnInvoice" Then
					NewSTAA.Amount				= -1 * TaxDetail.Tax;
				EndIf;					
			EndDo;
			//Save AvaTax details for the document
			If ((DocType <> "SalesOrder") And (DocType <> "ReturnOrder")) Or (SaveAvataxDetails = True) Then
				NewRecordSet = InformationRegisters.AvataxDetails.CreateRecordSet();
				NewRecordSet.Filter.ObjectRef.Set(DocRef);
				NewRecord = NewRecordSet.Add();
				NewRecord.ObjectRef 	= DocRef;
				NewRecord.TimeStamp		= CurrentUniversalDate();
				NewRecord.TransactionID = TransactionID;
				NewRecord.TaxDetails 	= New ValueStorage(DecodedResultBody);
				If SaveAvataxDetails And (DocType = "SalesOrder") Then
					NewRecord.Status 	= Enums.AvataxStatus.EmptyRef();
				Else
					NewRecord.Status		= ?(Commit = False, Enums.AvataxStatus.Uncommitted, Enums.AvataxStatus.Committed);
				EndIf;
				NewRecord.AvataxDocCode	= Object.AvataxDocCode;
				NewRecordSet.Write();
			EndIf;
		Else
			Message("AvaTax: " + DecodedResultBody.ErrorMessage, MessageStatus.Important);
			Cancel = True;
		EndIf;
	Else
		Message("AvaTax is either not enabled or tax calculation is disabled!", MessageStatus.Important);
		Cancel = True;
	EndIf;

EndProcedure

Procedure CancelTaxAtAvalara(Object, DocType, Cancel = False) Export
	
	SetPrivilegedMode(True);
	//If Avalara is enabled then cancel taxes at Avalara
	If Constants.AvataxEnabled.Get() And (Not Constants.AvataxDisableTaxCalculation.Get()) Then
		
		//First move the document into Voided status
		RequestParameters = New Structure();
		RequestParameters.Insert("CompanyCode", Constants.AvataxCompanyCode.Get());
		RequestParameters.Insert("DocType", DocType);
		DocID = GetLastAvataxDocCode(Object.Ref);
		If Not ValueIsFilled(DocID) Then
			return;
			//DocID = Object.PreviousAvataxDocCode;
		EndIf;
		RequestParameters.Insert("DocCode", DocID);
		RequestParameters.Insert("CancelCode", "DocVoided");
		
		TransactionID = New UUID();
		DecodedResultBody = AvaTaxServer.SendRequestToAvalara(Enums.AvalaraRequestTypes.CancelTax, RequestParameters, Object.Ref,, TransactionID);
		If DecodedResultBody.Successful Then
			//After the document is voided, move it into Deleted status (permanently removed from Avalara)
			RequestParameters = New Structure();
			RequestParameters.Insert("CompanyCode", Constants.AvataxCompanyCode.Get());
			RequestParameters.Insert("DocType", DocType);
			RequestParameters.Insert("DocCode", DocID);
			RequestParameters.Insert("CancelCode", "DocDeleted");
		
			TransactionID = New UUID();
			DecodedResultBody = AvaTaxServer.SendRequestToAvalara(Enums.AvalaraRequestTypes.CancelTax, RequestParameters, Object.Ref,, TransactionID);
		Else
			Message("AvaTax: " + DecodedResultBody.ErrorMessage, MessageStatus.Important);
			Cancel = True;
			return;
		EndIf;
		
		If DecodedResultBody.Successful Then
			Object.SalesTaxAcrossAgencies.Clear();
			//Save AvaTax details for the document 
			If (DocType <> "SalesOrder") And (DocType <> "ReturnOrder") Then
				NewRecordSet = InformationRegisters.AvataxDetails.CreateRecordSet();
				NewRecordSet.Filter.ObjectRef.Set(Object.Ref);
				NewRecordSet.Write();
			EndIf;
		Else
			Message("AvaTax: " + DecodedResultBody.ErrorMessage, MessageStatus.Important);
			Cancel = True;
		EndIf;
	Else
		Message("AvaTax is either not enabled or tax calculation is disabled!", MessageStatus.Important);
		Cancel = True;
	EndIf;

EndProcedure

Function GetLastAvataxDocCode(ObjectRef) Export
	
	SetPrivilegedMode(True);
	If ObjectRef.IsEmpty() Then
		return Undefined;
	EndIf;
	Request = New Query("SELECT
	                    |	AvataxDetails.AvataxDocCode
	                    |FROM
	                    |	InformationRegister.AvataxDetails AS AvataxDetails
	                    |WHERE
	                    |	AvataxDetails.ObjectRef = &ObjectRef");	
	Request.SetParameter("ObjectRef", ObjectRef);
	Res = Request.Execute();
	If Res.IsEmpty() Then
		return Undefined;
	EndIf;
	Sel = Res.Select();
	Sel.Next();
	return Sel.AvataxDocCode;
	
EndFunction

Function IsDocumentPresentAtAvatax(ObjectRef) Export
	
	SetPrivilegedMode(True);
	If ObjectRef.IsEmpty() Then
		return False;
	EndIf;
	Request = New Query("SELECT
	                    |	AvataxDetails.Status
	                    |FROM
	                    |	InformationRegister.AvataxDetails AS AvataxDetails
	                    |WHERE
	                    |	AvataxDetails.ObjectRef = &ObjectRef");
	Request.SetParameter("ObjectRef", ObjectRef);
	Res = Request.Execute();
	If Res.IsEmpty() Then
		return False;		
	EndIf;
	Sel = Res.Select();
	Sel.Next();
	If (Sel.Status = Enums.AvataxStatus.Deleted) Or (Sel.Status = Enums.AvataxStatus.EmptyRef()) Then
		return False;
	Else
		return True;
	EndIf;
	
EndFunction

Function GetLastAvataxDocumentStatus(ObjectRef) Export
	
	SetPrivilegedMode(True);
	If ObjectRef.IsEmpty() Then
		return Enums.AvataxStatus.EmptyRef();
	EndIf;
	Request = New Query("SELECT
	                    |	AvataxDetails.Status
	                    |FROM
	                    |	InformationRegister.AvataxDetails AS AvataxDetails
	                    |WHERE
	                    |	AvataxDetails.ObjectRef = &ObjectRef");
	Request.SetParameter("ObjectRef", ObjectRef);
	Res = Request.Execute();
	If Res.IsEmpty() Then
		return Enums.AvataxStatus.EmptyRef();		
	EndIf;
	Sel = Res.Select();
	Sel.Next();
	return Sel.Status;
	
EndFunction

Procedure AvalaraLogOnObjectDeletion(ObjectRef) Export
	
	SetPrivilegedMode(True);
	GUID = ObjectRef.UUID();				
	XMLGUID = XMLString(GUID);
	RecordSetForDeletion 	= InformationRegisters.AvalaraTransactions.CreateRecordSet();
	RecordSetForDeletion.Filter.ObjectRef.Set(ObjectRef, True);
	RecordSetForDeletion.Read();
	If RecordSetForDeletion.Count() > 0 Then
		NewRecordSet			= InformationRegisters.AvalaraTransactions.CreateRecordSet();
		NewRecordSet.Filter.ObjectRef.Set(XMLGUID, True);
		For Each Rec In RecordSetForDeletion Do
			NewRecord = NewRecordSet.Add();
			FillPropertyValues(NewRecord, Rec);
			NewRecord.ObjectRef = XMLGUID;
		EndDo;
		NewRecordSet.Write(True);
		RecordSetForDeletion.Clear();
		RecordSetForDeletion.Write(True);
	EndIf;	

EndProcedure

Procedure ClearAvataxDetails(ObjectRef) Export
	
	SetPrivilegedMode(True);
	NewRecordSet = InformationRegisters.AvataxDetails.CreateRecordSet();
	NewRecordSet.Filter.ObjectRef.Set(ObjectRef);
	NewRecordSet.Write();

EndProcedure

//Delete the document at Avatax prior to actual deletion
Procedure AvataxDocumentBeforeDelete(Object, Cancel, Val DocType) Export
	
	//Avatax. Delete the document at Avatax prior to actual deletion
	If Constants.AvataxEnabled.Get() And (Not Constants.AvataxDisableTaxCalculation.Get()) Then
		If IsDocumentPresentAtAvatax(Object.Ref) Then
			If DocType = "SalesOrder" Then
				DocType = "SalesInvoice";
			EndIf;
			CancelTaxAtAvalara(Object, DocType, Cancel);
		EndIf;
		ClearAvataxDetails(Object.Ref);
		If Not Cancel Then
			//To delete document we need to replace object ref in InformationRegister.AvalaraTransactions to appropriate GUIDs
			AvalaraLogOnObjectDeletion(Object.Ref);
		EndIf;
	EndIf;
	
EndProcedure

Procedure AvataxDocumentBeforeWrite(Object, Cancel) Export
	
	If Object.DataExchange.Load Then
		return;
	EndIf;
	
	If Object.UseAvatax Then
		If Constants.AvataxEnabled.Get() And (Not Constants.AvataxDisableTaxCalculation.Get()) Then
			If Not (Object.AdditionalProperties.Property("CalculateTaxAtAvalara") Or Object.AdditionalProperties.Property("CancelAndCalculateTaxAtAvalara")) Then
				Cancel = True;
				CommonUseClientServer.MessageToUser(String(Object.Ref) + " uses AvaTax for sales tax. Perform the operation interactively!");
			EndIf;
		Else
			Cancel = True;
			CommonUseClientServer.MessageToUser(String(Object.Ref) + " uses AvaTax for sales tax. Avatax is either not enabled or tax calculation is disabled");
		EndIf;
	EndIf;

EndProcedure

//Defines whether address validation is enabled for given Country
//Parameters:
// Country - Type: CatalogRef.Countries - given country
//Returns - Type: boolean - True if address validation is enabled and false if not
//
Function AddressValidationForCountryEnabled(Country) Export
	
	If (Not ValueIsFilled(Country)) Or Country.Code = "US" Or Country.Code = "CA" Then
		return True;
	Else
		return False;
	EndIf;
	
EndFunction

Function AddNewTaxCode(AvataxCode) Export
	
	BeginTransaction(DataLockControlMode.Managed);
	
	Try
		Blocking = New DataLock();
		LockItem = Blocking.Add("Catalog.TaxCodes");
		LockItem.Mode = DataLockMode.Exclusive;
		Blocking.Lock();
	
		AddAvataxCode(AvataxCode);
		CommitTransaction();
		return True;
	Except
		ErrorDescription = ErrorDescription();
		CommonUseClientServer.MessageToUser(ErrorDescription);
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		return False;
	EndTry;
	
EndFunction

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

Function AddAvataxCode(AvataxCode)
	
	If AvataxCode = Catalogs.TaxCodesPredefined.EmptyRef() Then
		return Catalogs.TaxCodes.EmptyRef();
	EndIf;
	//Try to find if the same tax code is already in TaxCodes
	Request = New Query("SELECT
	                    |	TaxCodes.Ref
	                    |FROM
	                    |	Catalog.TaxCodes AS TaxCodes
	                    |WHERE
	                    |	CASE
	                    |			WHEN &Code = """"
	                    |				THEN TaxCodes.Description = &Description
	                    |			ELSE TaxCodes.Code = &Code
	                    |		END");
	Request.SetParameter("Code", ?(IsBlankString(AvataxCode.Code), "", AvataxCode.Code));
	Request.SetParameter("Description", AvataxCode.Description);
	Result = Request.Execute();
	If Not Result.IsEmpty() Then
		Sel = Result.Select();
		Sel.Next();
		return Sel.Ref;
	EndIf;
	NewItem = Catalogs.TaxCodes.CreateItem();
	NewItem.Code = AvataxCode.Code;
	NewItem.Description = AvataxCode.Description;
	NewItem.AdditionalInformation = AvataxCode.AdditionalInformation;
	NewItem.Parent = AddAvataxCode(AvataxCode.Parent);
	NewItem.Write();
	return NewItem.Ref;
	
EndFunction

//Fills TaxCodes catalog with predefined groups
//Need to be called within open transaction to apply data locks
Procedure FillTaxCodeGroups() Export
	
	//SetPrivilegedMode(True);
	//
	////Lock TaxCodes catalog
	//DLock = New DataLock();
	//LockItem = DLock.Add("Catalog.TaxCodes");
	//LockItem.Mode = DataLockMode.Exclusive;
	//DLock.Lock();
	//
	////Fills only empty catalog (until any folders are added)
	//Request = New Query("SELECT
	//                    |	1 AS Field1
	//                    |FROM
	//                    |	Catalog.TaxCodes AS TaxCodes
	//                    |WHERE
	//                    |	TaxCodes.IsFolder = TRUE");
	//					
	//If Not Request.Execute().IsEmpty() Then
	//	return;
	//EndIf;
	//					
	//
	//NewFolder = Catalogs.TaxCodes.CreateFolder();
	//NewFolder.Code = "D0000000";
	//NewFolder.Description = "Digital goods";
	//NewFolder.AdditionalInformation = "Digital goods are generally viewed as downloadable items that are sold on websites or that are otherwise transferred electronically. Examples would include computer software, artwork, photographs, music, movies, zip files, e-books, PDFs and more.";
	//NewFolder.Write();
	//
	//NewFolder = Catalogs.TaxCodes.CreateFolder();
	//NewFolder.Code = "FR000000";
	//NewFolder.Description = "Freight";
	//NewFolder.AdditionalInformation = "Charges for delivery, shipping, or shipping and handling. These charges represent the cost of the transportation of product sold to the customer, and if applicable, any special charges for handling or preparing the product for shipping. These separately identified charges are paid to the seller of the goods and not to the shipping company.";
	//NewFolder.Write();
	//
	//NewFolder = Catalogs.TaxCodes.CreateFolder();
	//NewFolder.Code = "O0000000";
	//NewFolder.Description = "Other";
	//NewFolder.AdditionalInformation = "Other miscellaneous types charges that are not normally viewed as either the sale of tangible personal property or the performance of a service.";
	//NewFolder.Write();
	//
	//NewFolder = Catalogs.TaxCodes.CreateFolder();
	//NewFolder.Code = "P0000000";
	//NewFolder.Description = "Tangible Personal Property (TPP)";
	//NewFolder.AdditionalInformation = "Tangible personal property is generally deemed to be items, other than real property (i.e. land and buildings etc.), that are tangible in nature. The presumption of taxability is on all items of TPP unless specifically made non-taxable by individual state and/or local statutes. This system tax code can be used when no other specific system tax code is applicable or available. Additionally, this system tax code has a taxable default associated with it and consequently the user could use this code for any and all products that are known to be taxable and if they want to limit the number of system tax codes being used.";
	//NewFolder.Write();
	//
	//NewFolder = Catalogs.TaxCodes.CreateFolder();
	//NewFolder.Code = "S0000000";
	//NewFolder.Description = "Services";
	//NewFolder.AdditionalInformation = "The rendering of knowledge, expertise or labor towards a certain goal or objective.  For the majority of taxable jurisdictions, the sale of services, unlike the sale of tangible personal property, is not presumed to be taxable unless specifically made taxable by individual state and/or local statutes.";
	//NewFolder.Write();
	//
	//SetPrivilegedMode(False);
	
EndProcedure

#EndRegion