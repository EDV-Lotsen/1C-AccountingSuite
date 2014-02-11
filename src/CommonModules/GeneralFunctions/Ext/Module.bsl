//////////////////////////////////////////////////////////////////////////////// 
// THIS MODULE CONTAINS GENERAL PURPOSE FUNCTIONS AND PROCEDURES
// 

// Rupasov
Procedure CheckConnectionAtServer() Export
	
	SetPrivilegedMode(True);
	CurrentSessionNumber = InfoBaseSessionNumber();
	CurrentUserName = UserName();
	InfobaseSessions = GetInfobaseSessions();
	For Each InfobaseSession In InfobaseSessions Do
		If InfobaseSession.User.Name = CurrentUserName and InfobaseSession.SessionNumber <> CurrentSessionNumber then
		WriteLogEvent("There is another session working under the same user name", EventLogLevel.Warning,,, 
			"Application Name: " + InfobaseSession.ApplicationName + Chars.CR +
			"Computer Name: " + InfobaseSession.ComputerName + Chars.CR +
			"User Name: " + InfobaseSession.User.Name + " (" + InfobaseSession.User.FullName + ")" + Chars.CR +
			"SessionStarted: " + InfobaseSession.SessionStarted);
			Return;
		endif;
	EndDo;
	SetPrivilegedMode(False);
	
EndProcedure


Procedure ObjectBeforeDelete(Source, Cancel) Export

	ReferenceList = New Array();
	ReferenceList.Add(Source.Ref);
	SourceObj = Source.Ref.GetObject();	
	test = cancel;
	
	ReferencedObjects = FindByRef(ReferenceList);
	
	If ReferencedObjects.Count() = 0 Then

		AuditLog.AuditLogDeleteBeforeDelete(SourceObj,False);

	Else
		MessageText = "Linked objects found: ";
		For Each Ref In ReferencedObjects Do
			MessageText = MessageText + Ref[2] + ":" + TrimAll(Ref[1]) + ", ";
		EndDo;
		StringLength = StrLen(MessageText);
		MessageText = Left(MessageText, StringLength - 2);
		Message(MessageText);
		Cancel = True;
	EndIf;

EndProcedure


// Inverts the passed filter of collection items,
// allows selection items by filter on non-equal conition
//
// Parameters:
//  Collection     - Collection, for which filter is used.
//  PositiveFilter - Array of items selected by equal condition.
//
// Return value:
//  NegativeFilter - Array of items selected by non-equal condition.
//
Function InvertCollectionFilter(Collection, PositiveFilter) Export
	NegativeFilter = New Array;
	
	// Add to negative filter all of the items, which are not found in positive.
	For Each Item In Collection Do
		If PositiveFilter.Find(Item) = Undefined Then
			NegativeFilter.Add(Item);
		EndIf;
	EndDo;
	
	// Return negative filter.
	Return NegativeFilter;
	
EndFunction


Function ReturnSaleOrderMap(NewOrder) Export
	
	OrderData = New Map();
	//OrderData.Insert("sales_order_code", NewOrder.Code);
	OrderData.Insert("api_code", String(NewOrder.Ref.UUID()));
	OrderData.Insert("customer_api_code", String(NewOrder.Company.Ref.UUID()));
	//OrderData.Insert("description", NewOrder.Ref.Description);
	OrderData.Insert("ship_to_api_code",String(NewOrder.ShipTo.Ref.UUID()));
	OrderData.Insert("bill_to_api_code",String(NewOrder.BillTo.Ref.UUID()));
	OrderData.Insert("ship_to_address_id",String(NewOrder.ShipTo.Description));
	OrderData.Insert("ship_to_first_name",String(NewOrder.ShipTo.FirstName));
	OrderData.Insert("ship_to_middle_name",String(NewOrder.ShipTo.MiddleName));
	OrderData.Insert("ship_to_address_line1",String(NewOrder.ShipTo.AddressLine1));
	OrderData.Insert("ship_to_address_line2",String(NewOrder.ShipTo.AddressLine2));
	OrderData.Insert("ship_to_city",String(NewOrder.ShipTo.City));
	OrderData.Insert("ship_to_state",String(NewOrder.ShipTo.State));
	OrderData.Insert("ship_to_zip",String(NewOrder.ShipTo.ZIP));
	OrderData.Insert("ship_to_country",String(NewOrder.ShipTo.Country));
	OrderData.Insert("ship_to_phone",String(NewOrder.ShipTo.Phone));
	OrderData.Insert("ship_to_cell",String(NewOrder.ShipTo.Cell));
	OrderData.Insert("ship_to_email",String(NewOrder.ShipTo.Email));
	OrderData.Insert("ship_to_sales_tax_code",String(NewOrder.ShipTo.SalesTaxCode));
	OrderData.Insert("ship_to_notes",String(NewOrder.ShipTo.Notes));
	
	OrderData.Insert("bill_to_address_id",String(NewOrder.BillTo.Description));
	OrderData.Insert("bill_to_first_name",String(NewOrder.BillTo.FirstName));
	OrderData.Insert("bill_to_middle_name",String(NewOrder.BillTo.MiddleName));
	OrderData.Insert("bill_to_address_line1",String(NewOrder.BillTo.AddressLine1));
	OrderData.Insert("bill_to_address_line2",String(NewOrder.BillTo.AddressLine2));
	OrderData.Insert("bill_to_city",String(NewOrder.BillTo.City));
	OrderData.Insert("bill_to_state",String(NewOrder.BillTo.State));
	OrderData.Insert("bill_to_zip",String(NewOrder.BillTo.ZIP));
	OrderData.Insert("bill_to_country",String(NewOrder.BillTo.Country));
	OrderData.Insert("bill_to_phone",String(NewOrder.BillTo.Phone));
	OrderData.Insert("bill_to_cell",String(NewOrder.BillTo.Cell));
	OrderData.Insert("bill_to_email",String(NewOrder.BillTo.Email));
	OrderData.Insert("bill_to_sales_tax_code",String(NewOrder.BillTo.SalesTaxCode));
	OrderData.Insert("bill_to_notes",String(NewOrder.BillTo.Notes));



	
	OrderData.Insert("company", string(NewOrder.Company));
	//OrderData.Insert("company_code", NewOrder.CompanyCode);
	//OrderData.Insert("billTo", NewOrder.BillTo);
	//OrderData.Insert("confirmTo", NewOrder.ConfirmTo);
	OrderData.Insert("so_number",NewOrder.Number);
	OrderData.Insert("date",NewOrder.Date);
	OrderData.Insert("ref_num", NewOrder.RefNum);
	//OrderData.Insert("currency", string(NewOrder.Currency));
	//OrderData.Insert("exchangeRate", NewOrder.ExchangeRate);
	//OrderData.Insert("priceIncludesVAT", NewOrder.PriceIncludesVAT);
	//OrderData.Insert("location", string(NewOrder.Location));
	//OrderData.Insert("deliveryDate", NewOrder.deliverydate);
	//OrderData.Insert("project", string(NewOrder.project));
	//OrderData.Insert("class", string(NewOrder.Class));
	OrderData.Insert("memo", NewOrder.Memo);
	OrderData.Insert("sales_tax_total", NewOrder.SalesTaxRC);
	//OrderData.Insert("DocumentTotal", NewOrder.DocumentTotal);
	OrderData.Insert("doc_total", NewOrder.DocumentTotalRC);
	OrderData.Insert("cf1_string",NewOrder.CF1String);
	//OrderData.Insert("VATTotal", NewOrder.VATTotal);
	//OrderData.Insert("VATTotalRC", NewOrder.VATTotalRC);
	//OrderData.Insert("SalesPerson", string(NewOrder.SalesPerson));
	
	//include custom field
	
	OrderData2 = New Array();
	
	For Each LineItem in NewOrder.LineItems Do
			
			OrderData3 = New Map();
			OrderData3.Insert("api_code",String(LineItem.Product.Ref.UUID()));
			OrderData3.Insert("Product",LineItem.Product.Code);
			//OrderData3.Insert("ProductDescription",LineItem.ProductDescription);
			OrderData3.Insert("quantity",LineItem.Quantity);
			//OrderData3.Insert("UM",LineItem.UM);
			OrderData3.Insert("price",LineItem.Price);
			//OrderData3.Insert("taxable_type",string(LineItem.SalesTaxType));
			//OrderData3.Insert("taxable_amount",LineItem.TaxableAmount);
			OrderData3.Insert("line_total",LineItem.LineTotal);
			//OrderData3.Insert("VATCode",LineItem.VATCode);
			//OrderData3.Insert("VAT",LineItem.VAT);
			//OrderData3.Insert("Location",string(LineItem.Location));
			//OrderData3.Insert("DeliveryDate",LineItem.DeliveryDate);
			//OrderData3.Insert("Project",string(LineItem.Project));
			//OrderData3.Insert("Class",string(LineItem.Class));
			OrderData2.Add(OrderData3);

		
	EndDo;
		
	OrderData.Insert("line_items",OrderData2);	


	
	Return OrderData;

EndFunction


Function RetrieveTransaction(TransactionData) Export
	Method = "Get"; Object = "Transaction";
	
	// Define API connection settings.
	ConnectionMethod    = Method;
	ConnectionAddress   = StrReplace(GetStripeApiEndpoint() + GetStripeApiResourcePath(Object), "{TRANSACTION_ID}", TrimAll(TransactionData));
	ConnectionSettings  = New Structure;
	ExternalHandler     = CommonUseClientServer.CommonModule("ApiStripeProtectedRequestor");
	
	// Create HTTP connection object within custom protected requestor.
	ConnectionStructure = InternetConnectionClientServer.CreateConnection(ConnectionAddress, ConnectionSettings,,, ExternalHandler);
	
	// Check connection result.
	If ConnectionStructure.Result = Undefined Then
		// Return error description.
		Return ConnectionStructure;
	EndIf;
	
	// Define connection object.
	Connection        = ConnectionStructure.Result;
	
	// Open connection and request Stripe API.
	RequestStructure  = InternetConnectionClientServer.SendRequest(Connection, ConnectionMethod, ConnectionSettings,,,, ExternalHandler);
	
	// Check request result.
	If RequestStructure.Result = Undefined Then
		// Return error description.
		Return RequestStructure;
	EndIf;
	
	// Handle the execution result and return the object structure.
	Return GetRequestResult(RequestStructure);
	
EndFunction

// Returns Stripe API endpoint.
//
// Returns:
//  String - Web address of Stripe API server end point.
//

Function GetStripeApiEndpoint()

	// Primary Stripe API endpoint for serving client calls.
	Return "https://api.stripe.com";

EndFunction


// Returns pathes to Stripe API resources.
//
// Parameters:
//  ResourceName - String - Type of resource, which path is requested.
//
// Returns:
//  String - Path to requested type of resource of Stripe API.
//

Function GetStripeApiResourcePath(ResourceName)
	

	// Case by resource names and their pathes.
	If    ResourceName = "Account" Then
		Return "/v1/account";
		
	ElsIf ResourceName = "Charges" Then
		Return "/v1/charges";

	ElsIf ResourceName = "Charge" Then
		Return "/v1/charges/{CHARGE_ID}";

	ElsIf ResourceName = "ChargeRefund" Then
		Return "/v1/charges/{CHARGE_ID}/refund";

	ElsIf ResourceName = "Coupons" Then
		Return "/v1/coupons";

	ElsIf ResourceName = "Coupon" Then
		Return "/v1/coupons/{COUPON_ID}";

		
	ElsIf ResourceName = "Customers" Then
		Return "/v1/customers";
		
	ElsIf ResourceName = "Customer" Then
		Return "/v1/customers/{CUSTOMER_ID}";

	ElsIf ResourceName = "Subscriptions" Then
		Return "/v1/customers/{CUSTOMER_ID}/subscription";
		
	ElsIf ResourceName = "Invoices" Then
		Return "/v1/invoices";
		
	ElsIf ResourceName = "Invoice" Then
		Return "/v1/invoices/{INVOICE_ID}";
		
	ElsIf ResourceName = "InvoiceLines" Then
		Return "/v1/invoices/{INVOICE_ID}/lines";
		
	ElsIf ResourceName = "InvoiceItems" Then
		Return "/v1/invoiceitems";
		
	ElsIf ResourceName = "InvoiceItem" Then
		Return "/v1/invoiceitems/{INVOICEITEM_ID}";

	ElsIf ResourceName = "Plans" Then
		Return "/v1/plans";
		
	ElsIf ResourceName = "Plan" Then
		Return "/v1/plans/{PLAN_ID}";
		
	ElsIf ResourceName = "Tokens" Then
		Return "/v1/tokens";
		
	ElsIf ResourceName = "Token" Then
		Return "/v1/tokens/{TOKEN_ID}";
		
	ElsIf ResourceName = "Events" Then
		Return "/v1/events";
		
	ElsIf ResourceName = "Event" Then
		Return "/v1/events/{EVENT_ID}";

	ElsIf ResourceName = "Transaction" Then
		Return "/v1/transfers/{TRANSACTION_ID}/transactions?count=20?offset=1000";

	Else
		Return "";
	EndIf;

EndFunction

#Region Stripe_Result_Description



// Implementation of Stripe error object, returns error description.

//

// Parameters:

//  ErrorCode - Number - HTTP server status (response) code:

//                       http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html.

//  ErrorJSON - String - JSON object, containing error description.

//   type     - String - The type of error returned:

//                       "invalid_request_error", "api_error", or "card_error".

//   message  - String - A human-readable message giving more details about the error.

//   code     - String - (optional) For card errors, a short string describing

//                                  the kind of card error that occurred.

//   param    - String - (optional) The parameter the error relates to

//                                  if the error is parameter-specific.

//

// Returns:

//  ErrorDescription - A human-readable error description displaying to the user.

//

Function GetErrorDescription(ErrorCode, ErrorJSON = "")

	Var error, type, message, code, param, id, deleted;

	

	// Define error description basing on error code.

	If ErrorCode = 200 Then

		// Everything worked as expected.

		ErrorDescription = NStr("en = 'OK'");

		

	ElsIf ErrorCode = 400 Then

		// Missing a required parameter.

		ErrorDescription = NStr("en = 'Bad request'");

		

	ElsIf ErrorCode = 401 Then

		// No valid API key provided.

		ErrorDescription = NStr("en = 'Unauthorized'");

		

	ElsIf ErrorCode = 402 Then

		// Parameters were valid but request failed.

		ErrorDescription = NStr("en = 'Request failed'");

		

	ElsIf ErrorCode = 404 Then

		// The requested item doesn't exist.

		ErrorDescription = NStr("en = 'Not Found'");

		

	ElsIf ErrorCode = 500

	   Or ErrorCode = 502

	   Or ErrorCode = 503

	   Or ErrorCode = 504

	Then

		// Something went wrong on Stripe's end.

		ErrorDescription = NStr("en = 'Server error'");

	Else

		// Unexpected error ocured.

		ErrorDescription = NStr("en = 'Unknown error'");

	EndIf;

		

	// Decode the error structure.

	ErrorStruct = InternetConnectionClientServer.DecodeJSON(ErrorJSON, New Structure("UseLocalDate", False));

	If TypeOf(ErrorStruct) = Type("Structure") Then

		

		// Check error.

		If ErrorStruct.Property("error", error) Then

			

			// Check error type.

			If error.Property("type", type) Then

				

				// Define error type description.

				If type = "invalid_request_error" Then

					// Invalid request errors arise when your request has invalid parameters.

					ErrorDescription = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Invalid request error: %1'"), ErrorDescription);

					

				ElsIf type = "api_error" Then

					// API errors cover any other type of problem (e.g. a temporary problem with Stripe's servers) and should turn up only very infrequently.

					ErrorDescription = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Stripe API error: %1'"), ErrorDescription);

				

				ElsIf type = "card_error" Then

					// Card errors are the most common type of error you should expect to handle.

					// They result when the user enters a card that can't be charged for some reason.

					If error.Property("code", code) Then

						If    code = "incorrect_number"     Then CodeDescription = "The card number is incorrect.";

						ElsIf code = "invalid_number"       Then CodeDescription = "The card number is not a valid credit card number.";

						ElsIf code = "invalid_expiry_month" Then CodeDescription = "The card's expiration month is invalid.";

						ElsIf code = "invalid_expiry_year"  Then CodeDescription = "The card's expiration year is invalid.";

						ElsIf code = "invalid_cvc"          Then CodeDescription = "The card's security code is invalid.";

						ElsIf code = "expired_card"         Then CodeDescription = "The card has expired.";

						ElsIf code = "incorrect_cvc"        Then CodeDescription = "The card's security code is incorrect.";

						ElsIf code = "incorrect_zip"        Then CodeDescription = "The card's zip code failed validation.";

						ElsIf code = "card_declined"        Then CodeDescription = "The card was declined.";

						ElsIf code = "missing"              Then CodeDescription = "There is no card on a customer that is being charged.";

						ElsIf code = "processing_error"     Then CodeDescription = "An error occurred while processing the card.";

						Else                                     CodeDescription = ErrorDescription; // Default error code description.

						EndIf;

					EndIf;

					

					// Add extended card error description.

					ErrorDescription = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Card error: %1'"), CodeDescription);

				EndIf;

			EndIf;

			

			// Add a human-readable description.

			If error.Property("message", message) Then

				ErrorDescription = ErrorDescription + Chars.LF + message;

			EndIf;

			

		ElsIf ErrorStruct.Property("deleted", deleted) and (deleted = True) Then

			// The requested object is already deleted and operation can not be completed.

			ErrorDescription = NStr("en = 'Invalid request error: Not Found.

			                              |Requested record deleted%1.'");

			ErrorDescription = StringFunctionsClientServer.SubstituteParametersInString(

			                   ErrorDescription, ?(ErrorStruct.Property("id", id), ": " + id, ""));

			

			// Reset the source code 200 OK.

			ErrorCode = 206; // Partial content.

		EndIf;

	EndIf;

	

	// Return error description.

	Return ErrorDescription;

	

EndFunction



// The function implements handling of request result including error decoding

// and messgae processing.

//

// Parameters:

//  RequestStructure - Structure - Structure with the following key and value:

//   Result                      - String - contents of requested data.

//                               - Undefined - if request failed.

//   Description                 - String - if succeded can take on the following values:

//                                "String" - data returned directly in Result parameter.

//                                 or contain an error message in case of failure.

//  RequestedObjectType - String - Description of Stripe object expected.

//

// Returns:

//  ResultDescription - Structure with following parameters:

//   Result           - Structure - expected object,

//                    - Undefined - if request was failed.

//   Description      - String    - user message, containing error description.

//

Function GetRequestResult(RequestStructure, RequestedObjectType = Undefined)

	var objectType, RequestedObject;

	

	// Check additional properties.

	AdditionalData      = Undefined;

	If RequestStructure.Property("AdditionalData", AdditionalData) Then

		// There is the result code of operation.

		StatusCode = AdditionalData.StatusCode;

		

		// Check response code.

		If (StatusCode = 200) And (TypeOf(RequestStructure.Result) = Type("String")) And Left(TrimAll(RequestStructure.Result), 1) = "{" Then

			// Everything worked as expected.

			RequestedObject = InternetConnectionClientServer.DecodeJSON(RequestStructure.Result, New Structure("UseLocalDate", False));

			// Check returned object type.

			If (RequestedObjectType = Undefined) // Do not check object type.

			Or (RequestedObject.Property("object", objectType) And objectType = RequestedObjectType) Then // Object type match.

				Return ResultDescription(RequestedObject);

			EndIf;

		EndIf;

		

		// An error is occured.

		Return ResultDescription(Undefined, GetErrorDescription(StatusCode, RequestStructure.Result), New Structure("Code, Result", StatusCode, RequestedObject));

		

	Else

		// No additional error description/code available.

		

		// Check returning data is JSON object.

		If (TypeOf(RequestStructure.Result) = Type("String")) And Left(TrimAll(RequestStructure.Result), 1) = "{" Then

			// Everything worked as expected.

			RequestedObject = InternetConnectionClientServer.DecodeJSON(RequestStructure.Result, New Structure("UseLocalDate", False));

			// Check returned object type.

			If (RequestedObjectType = Undefined) // Do not check object type.

			Or (RequestedObject.Property("object", objectType) And objectType = RequestedObjectType) Then // Object type match.

				Return ResultDescription(RequestedObject);

			EndIf;

		EndIf;

		

		// An error is occured.

		Return ResultDescription(Undefined, RequestStructure.Description, New Structure("Code, Result", Undefined, RequestedObject));

	EndIf;

	

EndFunction



// Returns the structure with passed parameters.

//

// Parameters:

//  Result             - Arbitrary - Returned function value.

//  Description        - String    - Success string or error description.

//  AdditionalData     - Arbitrary - Additional returning parameters.

//

// Returns:

//  Structure with the passed parameters:

//   Result            - Arbitrary.

//   Description       - String.

//   AdditionalData    - Arbitrary.

//

Function ResultDescription(Result, Description = "", AdditionalData = Undefined)

	

	// Return parameters converted to the structure

	Return New Structure("Result, Description, AdditionalData",

	                      Result, Description, AdditionalData);

	

EndFunction



#EndRegion


Function ReturnProductObjectMap(NewProduct) Export
	
	ProductData = New Map();
	ProductData.Insert("item_code", NewProduct.Code);
	ProductData.Insert("api_code", String(NewProduct.Ref.UUID()));
	ProductData.Insert("item_description", NewProduct.Description);
	If NewProduct.Type = Enums.InventoryTypes.Inventory Then
		ProductData.Insert("item_type", "product");
	ElsIf NewProduct.Type = Enums.InventoryTypes.NonInventory Then
		ProductData.Insert("item_type", "service");	
	EndIf;
	If NewProduct.CostingMethod = Enums.InventoryCosting.FIFO Then
		ProductData.Insert("costing_method", "fifo");
	ElsIf NewProduct.CostingMethod = Enums.InventoryCosting.WeightedAverage Then
		ProductData.Insert("costing_method", "weighted_average");	
	EndIf;
	ProductData.Insert("inventory_or_expense_account", NewProduct.InventoryOrExpenseAccount.Code);
	ProductData.Insert("income_account", NewProduct.IncomeAccount.Code);
	ProductData.Insert("cogs_account", NewProduct.COGSAccount.Code);
	ProductData.Insert("unit_of_measure", NewProduct.UM.Description);
	ProductData.Insert("category", NewProduct.Category.Description);
	Try
		ProductData.Insert("item_price",GeneralFunctions.RetailPrice(CurrentDate(),NewProduct,Catalogs.Companies.EmptyRef()));
	Except
		ProductData.Insert("item_price",0);
	EndTry;
	
	Query = New Query;
	Query.Text = "SELECT
				|	PriceListSliceLast.Product.Ref,
				|	PriceListSliceLast.PriceLevel.Description,
				|	PriceListSliceLast.ProductCategory.Description,
				|	PriceListSliceLast.Price,
				|	PriceListSliceLast.Cost,
				|	PriceListSliceLast.PriceType,
				|	PriceListSliceLast.Period
				|FROM
				|	InformationRegister.PriceList.SliceLast AS PriceListSliceLast
				|WHERE
				|	PriceListSliceLast.Product = &Product
				|	AND PriceListSliceLast.PriceLevel <> &PriceLevel";
	Query.SetParameter("Product", NewProduct.Ref);
	Query.SetParameter("PriceLevel", Catalogs.PriceLevels.EmptyRef());
	QueryResult = Query.Execute().Unload();	
	ProductData2 = New Array();
	
	Count = 0;
	If QueryResult.Count() > 0 Then
		For Each PriceLevelItem in QueryResult Do
			
			ProductData3 = New Map();
			ProductData3.Insert("description",PriceLevelItem.PriceLevelDescription);
			ProductData3.Insert("price",PriceLevelItem.Price);	
			//ProductData3.Insert("period", Format(PriceLevelItem.Period,"DF=dd.MM.yyyy"));
			//ProductData2.Insert("pricelevel_" + Count,ProductData3);
			ProductData2.Add(ProductData3);
			Count = Count + 1;
		EndDo;
	EndIf;
	
	ProductData.Insert("price_levels",ProductData2);


	ProductData.Insert("cf1_string", NewProduct.CF1String);
	ProductData.Insert("cf1_num", NewProduct.CF1Num);	
	ProductData.Insert("cf2_string", NewProduct.CF2String);
	ProductData.Insert("cf2_num", NewProduct.CF2Num);
	ProductData.Insert("cf3_string", NewProduct.CF3String);
	ProductData.Insert("cf3_num", NewProduct.CF3Num);
	ProductData.Insert("cf4_string", NewProduct.CF4String);
	ProductData.Insert("cf4_num", NewProduct.CF4Num);
	ProductData.Insert("cf5_string", NewProduct.CF5String);
	ProductData.Insert("cf5_num", NewProduct.CF5Num);
			
	Return ProductData;	
	
EndFunction

Function ReturnCompanyObjectMap(NewCompany) Export
	
	CompanyData = New Map();
	CompanyData.Insert("api_code", String(NewCompany.Ref.UUID()));
	CompanyData.Insert("company_name", String(NewCompany.Description));
	CompanyData.Insert("company_code", String(NewCompany.Code));
	
	If NewCompany.Customer = True And NewCompany.Vendor = True Then
		
		CompanyData.Insert("company_type", "customer+vendor");
	ElsIf NewCompany.Customer = True Then
		CompanyData.Insert("company_type", "customer");
	ElsIf NewCompany.Vendor = True Then
		CompanyData.Insert("company_type", "vendor");
	Else
		CompanyData.Insert("company_type", "");
	EndIF;
	
	CompanyData.Insert("website", NewCompany.Website);
	CompanyData.Insert("price_level", string(NewCompany.PriceLevel));
	CompanyData.Insert("notes", NewCompany.Notes);
	CompanyData.Insert("cf1_string", NewCompany.CF1String);
	CompanyData.Insert("cf1_num", NewCompany.CF1Num);
	CompanyData.Insert("cf2_string", NewCompany.CF2String);
	CompanyData.Insert("cf2_num", NewCompany.CF3Num);
	CompanyData.Insert("cf3_string", NewCompany.CF1String);
	CompanyData.Insert("cf3_num", NewCompany.CF3Num);
	CompanyData.Insert("cf4_string", NewCompany.CF4String);
	CompanyData.Insert("cf4_num", NewCompany.CF4Num);
	CompanyData.Insert("cf5_string", NewCompany.CF5String);
	CompanyData.Insert("cf5_num", NewCompany.CF5Num);
	
	QueryText = "SELECT
				|	Addresses.Ref
				|FROM
				|	Catalog.Addresses AS Addresses
				|WHERE
				|	Addresses.Owner.Ref = &Ref";
	Query = New Query(QueryText);
	Query.SetParameter("Ref", NewCompany.Ref); 
	Result = Query.Execute().Unload();
	
	CompanyData2 = New Array();
	
	Count = 0;
	If Result.Count() > 0 Then
		For Each AddressItem in Result Do
			
			CompanyData3 = New Map();
			CompanyData3.Insert("address_code",string(AddressItem.Ref.Code));
			CompanyData3.Insert("api_code",string(AddressItem.Ref.UUID()));
			CompanyData3.Insert("address_id",AddressItem.Ref.Description);	
			CompanyData3.Insert("first_name",AddressItem.Ref.FirstName);
			CompanyData3.Insert("middle_name",AddressItem.Ref.MiddleName);
			CompanyData3.Insert("last_name",AddressItem.Ref.LastName);
			CompanyData3.Insert("address_line1",AddressItem.Ref.AddressLine1);
			CompanyData3.Insert("address_line2",AddressItem.Ref.AddressLine2);
			CompanyData3.Insert("city",AddressItem.Ref.City);
			CompanyData3.Insert("state",string(AddressItem.Ref.state));
			CompanyData3.Insert("zip",AddressItem.Ref.ZIP);
			CompanyData3.Insert("country",string(AddressItem.Ref.Country));
			CompanyData3.Insert("phone",AddressItem.Ref.Phone);
			CompanyData3.Insert("cell",AddressItem.Ref.Cell);
			CompanyData3.Insert("email",AddressItem.Ref.Email);
			CompanyData3.Insert("sales_tax_code",AddressItem.Ref.SalesTaxCode);
			CompanyData3.Insert("notes",AddressItem.Ref.Notes);
			If AddressItem.Ref.DefaultShipping = True Then
				CompanyData3.Insert("default_shipping","true");
			Else
				CompanyData3.Insert("default_shipping","false");
			EndIf;
			If AddressItem.Ref.DefaultBilling = True Then
				CompanyData3.Insert("default_billing","true");
			Else
				CompanyData3.Insert("default_billing","false");
			EndIf;
			
			
			CompanyData2.Add(CompanyData3);
			Count = Count + 1;
		EndDo;
		
		DataAddresses = New Map();
		DataAddresses.Insert("addresses", CompanyData2);

	EndIf;
	
	CompanyData.Insert("lines",DataAddresses);
	
	Return CompanyData;
	
EndFunction

Procedure CreateItemCSV(Date, Date2, ItemDataSet) Export
	
	
	// add transactions 1-500
	
	For Each DataLine In ItemDataSet Do
				
		NewProduct = Catalogs.Products.CreateItem();
		NewProduct.Type = DataLine.ProductType;
		NewProduct.Code = DataLine.ProductCode;
		NewProduct.Description = DataLine.ProductDescription;
		NewProduct.IncomeAccount = DataLine.ProductIncomeAcct;
		NewProduct.InventoryOrExpenseAccount = DataLine.ProductInvOrExpenseAcct;
		NewProduct.COGSAccount = DataLine.ProductCOGSAcct;
		//NewProduct.PurchaseVATCode = Constants.DefaultPurchaseVAT.Get();
		//NewProduct.SalesVATCode = Constants.DefaultSalesVAT.Get();
		//NewProduct.api_code = GeneralFunctions.NextProductNumber();
		NewProduct.Category = DataLine.ProductCategory;
		NewProduct.UM = DataLine.ProductUoM;
		
		If DataLine.ProductCF1String <> "" Then 
			NewProduct.CF1String = DataLine.ProductCF1String;
		EndIf;
		NewProduct.CF1Num = DataLine.ProductCF1Num;
		
		If DataLine.ProductCF2String <> "" Then 
			NewProduct.CF2String = DataLine.ProductCF2String;
		EndIf;
		NewProduct.CF2Num = DataLine.ProductCF2Num;
		
		If DataLine.ProductCF3String <> "" Then 
			NewProduct.CF3String = DataLine.ProductCF3String;
		EndIf;
		NewProduct.CF3Num = DataLine.ProductCF3Num;
		
		If DataLine.ProductCF4String <> "" Then 
			NewProduct.CF4String = DataLine.ProductCF4String;
		EndIf;
		NewProduct.CF4Num = DataLine.ProductCF4Num;
		
		If DataLine.ProductCF5String <> "" Then 
			NewProduct.CF5String = DataLine.ProductCF5String;
		EndIf;
		NewProduct.CF5Num = DataLine.ProductCF5Num;

		If NewProduct.Type = Enums.InventoryTypes.Inventory Then
			NewProduct.CostingMethod = Enums.InventoryCosting.WeightedAverage;
		EndIf;
		NewProduct.Write();
		
		If DataLine.ProductPrice <> 0 Then
			RecordSet = InformationRegisters.PriceList.CreateRecordSet();
			RecordSet.Filter.Product.Set(NewProduct.Ref);
			RecordSet.Filter.Period.Set(Date);
			NewRecord = RecordSet.Add();
			NewRecord.Period = Date;
			NewRecord.Product = NewProduct.Ref;
			NewRecord.Price = DataLine.ProductPrice;
			RecordSet.Write();
		EndIf;
		
		If DataLine.ProductQty <> 0 Then
			IBB = Documents.InventoryBeginningBalances.CreateDocument();
			IBB.Product = NewProduct.Ref;
			IBB.Location = Catalogs.Locations.MainWarehouse;
			IBB.Quantity = DataLine.ProductQty;
			IBB.Value = Dataline.ProductValue;
			IBB.Date = Date2;
			IBB.Write(DocumentWriteMode.Posting);
		EndIf;
		
	EndDo;

	
EndProcedure

Procedure CreateCustomerVendorCSV(IncomeAccount, ExpenseAccount, ARAccount, APAccount, ItemDataSet) Export
	
	// add transactions 1-500
	
	For Each DataLine In ItemDataSet Do
		
		CreatingNewCompany = False;
		CompanyFound = Catalogs.Companies.FindByDescription(DataLine.CustomerDescription);
		If CompanyFound = Catalogs.Companies.EmptyRef() Then
			CreatingNewCompany = True;
			
			NewCompany = Catalogs.Companies.CreateItem();
	
			NewCompany.Description = DataLine.CustomerDescription;
			
			If DataLine.CustomerType = 0 Then
				NewCompany.Customer = True;
			ElsIf DataLine.CustomerType = 1 Then
				NewCompany.Vendor = True;
			ElsIf DataLine.CustomerType = 2 Then
				NewCompany.Customer = True;
				NewCompany.Vendor = True;
			Else
				NewCompany.Customer = True;
			EndIf;
			
			NewCompany.DefaultCurrency = Constants.DefaultCurrency.Get();
			If DataLine.CustomerTerms <> Catalogs.PaymentTerms.EmptyRef() Then
				NewCompany.Terms = DataLine.CustomerTerms;
			Else
				NewCompany.Terms = Catalogs.PaymentTerms.Net30;
			EndIf;
			NewCompany.Notes = DataLine.CustomerNotes;
			NewCompany.USTaxID = DataLine.CustomerVendorTaxID;
			
			If DataLine.CustomerCF1String <> "" Then 
				NewCompany.CF1String = DataLine.CustomerCF1String;
			EndIf;
			NewCompany.CF1Num = DataLine.CustomerCF1Num;

			If DataLine.CustomerCF2String <> "" Then 
				NewCompany.CF2String = DataLine.CustomerCF2String;
			EndIf;
			NewCompany.CF2Num = DataLine.CustomerCF2Num;

			If DataLine.CustomerCF3String <> "" Then 
				NewCompany.CF3String = DataLine.CustomerCF3String;
			EndIf;
			NewCompany.CF3Num = DataLine.CustomerCF3Num;

			If DataLine.CustomerCF4String <> "" Then 
				NewCompany.CF4String = DataLine.CustomerCF4String;
			EndIf;
			NewCompany.CF4Num = DataLine.CustomerCF4Num;

			If DataLine.CustomerCF5String <> "" Then 
				NewCompany.CF5String = DataLine.CustomerCF5String;
			EndIf;
			NewCompany.CF5Num = DataLine.CustomerCF5Num;

			If IncomeAccount <> ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
				NewCompany.IncomeAccount = IncomeAccount;
			Else
			EndIf;
			
			If ARAccount <> ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
				NewCompany.ARAccount = ARAccount;
			Else
			EndIf;
			
			If ExpenseAccount <> ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
				NewCompany.ExpenseAccount = ExpenseAccount;
			Else
			EndIf;
			
			If APAccount <> ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
				NewCompany.APAccount = APAccount;
			Else
			EndIf;
			
			If DataLine.CustomerSalesPerson <> Catalogs.SalesPeople.EmptyRef() Then
				NewCompany.SalesPerson = DataLine.CustomerSalesPerson;
			Else
			EndIf;
			
			If DataLine.CustomerWebsite <> "" Then 
				NewCompany.Website = DataLine.CustomerWebsite;
			EndIf;
			NewCompany.CF4Num = DataLine.CustomerCF4Num;
			
			If DataLine.CustomerPriceLevel <> Catalogs.PriceLevels.EmptyRef() Then
				NewCompany.PriceLevel = DataLine.CustomerPriceLevel;
			Else
			EndIf;
			
			NewCompany.Write();
			
		Else
			NewCompany = CompanyFound;
		EndIf;
		
		AddressLine = Catalogs.Addresses.CreateItem();
		AddressLine.Owner = NewCompany.Ref;
		If DataLine.CustomerAddressID = "" Then
			AddressLine.Description = "Primary";
		Else
			AddressLine.Description = DataLine.CustomerAddressID;
		EndIf;
		AddressLine.Salutation = DataLine.AddressSalutation;
		AddressLine.FirstName = DataLine.CustomerFirstName;
		AddressLine.MiddleName = DataLine.CustomerMiddleName;
		AddressLine.LastName = DataLine.CustomerLastName;
		AddressLine.Suffix = DataLine.AddressSuffix;
		AddressLine.JobTitle = DataLine.AddressJobTitle;
		AddressLine.Phone = DataLine.CustomerPhone;
		AddressLine.Cell = DataLine.CustomerCell;
		AddressLine.Fax = DataLine.CustomerFax;
		AddressLine.Email = DataLine.CustomerEmail;
		AddressLine.AddressLine1 = DataLine.CustomerAddressLine1;
		AddressLine.AddressLine2 = DataLine.CustomerAddressLine2;
		AddressLine.AddressLine3 = DataLine.CustomerAddressLine3;
		AddressLine.City = DataLine.CustomerCity;
		AddressLine.State = DataLine.CustomerState;
		AddressLine.Country = DataLine.CustomerCountry;
		AddressLine.ZIP = DataLine.CustomerZIP;
		AddressLine.Notes = DataLine.CustomerAddressNotes;
		AddressLine.DefaultShipping = DataLine.DefaultShippingAddress;
		AddressLine.DefaultBilling = DataLine.DefaultBillingAddress;
		If DataLine.AddressSalesPerson <> Catalogs.SalesPeople.EmptyRef() Then
			AddressLine.SalesPerson = DataLine.AddressSalesPerson;
		Else
		EndIf;
		AddressLine.CF1String = DataLine.AddressCF1String;
		AddressLine.CF2String = DataLine.AddressCF2String;
		AddressLine.CF3String = DataLine.AddressCF3String;
		AddressLine.CF4String = DataLine.AddressCF4String;
		AddressLine.CF5String = DataLine.AddressCF5String;

		AddressLine.Write();
				
	EndDo;

EndProcedure


Function EncodeToPercentStr(Str, AdditionalCharacters = "", ExcludeCharacters = "") Export
	
	// Define empty result.
	Result = "";
	
	// Define hex string.
	HexStr = "0123456789ABCDEF";
	MBytes = New Array;
	
	// Define RFC 3986 unreserved characters.
	Unreserved = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~"
	           + AdditionalCharacters;
	
	// Exclude characters from RFC 3986 reference string.
	For i = 1 To StrLen(ExcludeCharacters) Do
		RFC3986UnreservedCharacters =
		StrReplace(RFC3986UnreservedCharacters, Mid(ExcludeCharacters, i, 1), "");
	EndDo;

	// Recode string replacing chars out of unreserved.
	StrBuf = "";
	For i = 1 To StrLen(Str) Do
		
		// Get current char.
		Char = Mid(Str, i, 1);
		
		// Check char according to RFC 3986.
		If Find(Unreserved, Char) > 0 Then
			
			// Process buffer if previously used.
			If StrLen(StrBuf) > 0 Then
				
				// Convert buffer to an array of UTF-8 chars (bytes).
				MBCS = StrToUTF8(StrBuf, True);
				For Each MBC In MBCS Do
					// Convert byte to hex: // High half byte                   // Low half byte
					Result = Result + "%" + Mid(HexStr, Int(MBC / 16) + 1, 1) + Mid(HexStr, (MBC % 16) + 1, 1);
				EndDo;
				
				// Clear buffer.
				StrBuf = "";
			EndIf;
			
			// Unreserved char found.
			Result = Result + Char;
		Else
			
			// This is not an unreserved char.
			StrBuf = StrBuf + Char
		EndIf;
	EndDo;
	
	// Process buffer if previously used.
	If StrLen(StrBuf) > 0 Then
		
		// Convert buffer to an array of UTF-8 chars (bytes).
		MBCS = StrToUTF8(StrBuf, True);
		For Each MBC In MBCS Do
			// Convert byte to hex: // High half byte                   // Low half byte
			Result = Result + "%" + Mid(HexStr, Int(MBC / 16) + 1, 1) + Mid(HexStr, (MBC % 16) + 1, 1);
		EndDo;
		
		// Clear buffer.
		StrBuf = "";
	EndIf;
	
	// Return decoded string.
	Return Result;
	
EndFunction

Function StrToUTF8(Str, AsArray = False, UseBOM = False)
	
	// Define UTF-8 bytes array.
	MBCS = New Array;
	
	// Define source string parameters.
	If TypeOf(Str) = Type("Array") Then
		
		// Use passed unicode characters array directly.
		UCS = Str;
		
	ElsIf TypeOf(Str) = Type("String") Then
		
		// Create unicode characters array.
		If StrLen(Str) > 0 Then
			UCS = New Array(StrLen(Str));
			For i = 1 To StrLen(Str) Do
				UCS[i-1] = CharCode(Str, i);
			EndDo;
		Else
			UCS = New Array;
		EndIf;
		
	Else
		// Unknown passed type.
		UCS = New Array;
	EndIf;
	
	// Add BOM signature (if required).
	If UseBOM Then
		
		// Add BOM signature bytes to an array.
		MBCS.Add(239); // $EF
		MBCS.Add(187); // $BB;
		MBCS.Add(191); // $BF;
		
	EndIf;
	
	// Go thru string and encode chars.
	For i = 0 To UCS.Count()-1 Do
		
		// Get current char.
		Code = UCS[i];
		
		// Define char size.
		If Code < 0 Then
			// Skip symbol.
			
		ElsIf Code = 0 Then          // 0000.0000
			// Encode NUL char in overlong form (000) = 11 bits,
			// preventing mixing it with end-string character (00).
			// 000 -> 1100.0000 1000.0000 -> C080
			
			// Add high and low part.
			MBCS.Add(192);           // $C0
			MBCS.Add(128);           // $80
			
		ElsIf Code < 128     Then    // 0000.0001 .. 0000.007F
			// Encode ASCII char = 7 bits.
			// xx -> 0xxx.xxxx -> xx
			
			// Add byte.
			MBCS.Add(Code);          // ASCII code.
			
		ElsIf Code < 2048    Then    // 0000.0080 .. 0000.07FF
			// 2-bytes encoding = 11 bits.
			// 0xxx -> 110x.xxxx 10xx.xxxx -> Cx8x
			
			// Define high and low parts.
			HB = Int(Code / 64);     // High byte: SHR(Code, 6);
			LB = Code % 64;          // Low byte:  Code AND $0000.003F;
			
			// Add bytes to an array.
			MBCS.Add(192 + HB);      // $C0 OR HB
			MBCS.Add(128 + LB);      // $80 OR LB;
			
		ElsIf Code < 65536   Then    // 0000.0800 .. 0000.FFFF
			// 3-bytes encoding = 16 bits.
			// xxxx -> 1110.xxxx 10xx.xxxx 10xx.xxxx -> Ex8x8x
			
			// Define high, mid and low parts.
			HB = Int(Code / 4096);   // High byte: SHR(Code, 12);
			LW = Code % 4096;        // Low word:  Code AND $0000.0FFF;
			MB = Int(LW / 64);       // Mid byte:  SHR(Code, 6);
			LB = LW % 64;            // Low byte:  LW   AND $0000.003F;
			
			// Add bytes to an array.
			MBCS.Add(224 + HB);      // $E0 OR HB
			MBCS.Add(128 + MB);      // $80 OR MB;
			MBCS.Add(128 + LB);      // $80 OR LB;
			
		ElsIf Code < 1114112 Then    // 0001.0000 .. 0010.FFFF
			// 4-bytes encoding = 20½ bits.
			// 001x.xxxx -> 1111.0xxx 10xx.xxxx 10xx.xxxx 10xx.xxxx -> Fx8x8x8x
			
			// Define high, upper, mid and low parts.
			HB = Int(Code / 262144); // High byte: SHR(Code, 18);
			LP = Code % 262144;      // Low part:  Code AND $0003.FFFF;
			UB = Int(LP / 4096);     // Uppr byte: SHR(Code, 12);
			LW = LP % 4096;          // Low word:  LP   AND $0000.0FFF;
			MB = Int(LW / 64);       // Mid byte:  SHR(Coce, 6);
			LB = LW % 64;            // Low byte:  LW   AND $0000.003F;
			
			// Add bytes to an array.
			MBCS.Add(240 + HB);      // $F0 OR HB
			MBCS.Add(128 + UB);      // $80 OR UB;
			MBCS.Add(128 + MB);      // $80 OR MB;
			MBCS.Add(128 + LB);      // $80 OR LB;
			
		Else // Greater codes are restricted according to RFC 3629.
			
			// Skip symbol.
		EndIf;
	EndDo;
	
	// Format final result.
	If AsArray Then
		
		// Return ref to original array.
		Result = MBCS;
		
	Else
		// Encode array to a character string.
		Result = "";
		For i = 0 To MBCS.Count()-1 Do
			Result = Result + Char(MBCS[i]);
		EndDo;
	EndIf;
	
	// Return formatted value.
	Return Result;
	
EndFunction



Function GetUserName() Export
	
	Return SessionParameters.ACSUser;
	
EndFunction

Procedure SendWebhook(webhook_address, WebhookMap) Export
	
	Headers = New Map();
	Headers.Insert("Content-Type", "application/json");		
	ConnectionSettings = New Structure;
	Connection = InternetConnectionClientServer.CreateConnection(webhook_address, ConnectionSettings).Result;
	ResultBody = InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings, Headers, InternetConnectionClientServer.EncodeJSON(WebhookMap)).Result;

	
	//Headers = New Map();
	//Headers.Insert("Content-Type", "application/json");   
	//
	//HTTPRequest = New HTTPRequest(webhook_resource,Headers);
	//HTTPRequest.SetBodyFromString(InternetConnectionClientServer.EncodeJSON(WebhookMap));
	//
	//SSLConnection = New OpenSSLSecureConnection();
	//
	//HTTPConnection = New HTTPConnection(webhook_address,,,,,,SSLConnection);
	//Result = HTTPConnection.Post(HTTPRequest);	
	
EndProcedure

Function GetSystemTitle() Export
	
	Return Constants.SystemTitle.Get();	
	
EndFunction

Function GetCustomTemplate(TemplateName) Export
	
	Query = New Query;
	
	Query.Text = "Select Template AS Template
					|FROM
					|	InformationRegister.CustomPrintForms
					|WHERE
					|	TemplateName=&TemplateName";
	
	Query.Parameters.Insert("TemplateName", TemplateName);
		
	Cursor = Query.Execute().Choose();
	
	Result = Undefined;
	
	If Cursor.Next() Then
		Result = Cursor.Template.Get();
	Else
	EndIf;
	
	If TypeOf(Result) = Type("BinaryData") Then
		Return BinaryToSpreadsheetDocument(Result);
	Else
		Return Result;
	EndIf;
	
EndFunction

Function BinaryToSpreadsheetDocument(BinaryData) Export
	
	TempFileName = GetTempFileName();
	BinaryData.Write(TempFileName);
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.Read(TempFileName);
	If Not SafeMode() Then
		DeleteFiles(TempFileName);
	EndIf;
	
	Return SpreadsheetDocument;
	
EndFunction

Function GetLogo() Export
	
	Query = New Query;
	
	Query.Text = "Select Template AS Template
					|FROM
					|	InformationRegister.CustomPrintForms
					|WHERE
					|	ObjectName=&ObjectName
					|	AND	TemplateName=&TemplateName";
	
	Query.Parameters.Insert("ObjectName", "logo");
	Query.Parameters.Insert("TemplateName", "logo");
		
	Cursor = Query.Execute().Choose();
	
	Result = Undefined;
	
	If Cursor.Next() Then
		Result = Cursor.Template.Get();
	Else
	EndIf;
	
	Return Result;
	
EndFunction

Function GetFooter1() Export
	
	Query = New Query;
	
	Query.Text = "Select Template AS Template
					|FROM
					|	InformationRegister.CustomPrintForms
					|WHERE
					|	ObjectName=&ObjectName
					|	AND	TemplateName=&TemplateName";
	
	Query.Parameters.Insert("ObjectName", "footer1");
	Query.Parameters.Insert("TemplateName", "footer1");
		
	Cursor = Query.Execute().Choose();
	
	Result = Undefined;
	
	If Cursor.Next() Then
		Result = Cursor.Template.Get();
	Else
	EndIf;
	
	Return Result;
	
EndFunction

Function GetFooter2() Export
	
	Query = New Query;
	
	Query.Text = "Select Template AS Template
					|FROM
					|	InformationRegister.CustomPrintForms
					|WHERE
					|	ObjectName=&ObjectName
					|	AND	TemplateName=&TemplateName";
	
	Query.Parameters.Insert("ObjectName", "footer2");
	Query.Parameters.Insert("TemplateName", "footer2");
		
	Cursor = Query.Execute().Choose();
	
	Result = Undefined;
	
	If Cursor.Next() Then
		Result = Cursor.Template.Get();
	Else
	EndIf;
	
	Return Result;
	
EndFunction

Function GetFooter3() Export
	
	Query = New Query;
	
	Query.Text = "Select Template AS Template
					|FROM
					|	InformationRegister.CustomPrintForms
					|WHERE
					|	ObjectName=&ObjectName
					|	AND	TemplateName=&TemplateName";
	
	Query.Parameters.Insert("ObjectName", "footer3");
	Query.Parameters.Insert("TemplateName", "footer3");
		
	Cursor = Query.Execute().Choose();
	
	Result = Undefined;
	
	If Cursor.Next() Then
		Result = Cursor.Template.Get();
	Else
	EndIf;
	
	Return Result;
	
EndFunction



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
Function RetailPrice(ActualDate, Product, Customer) Export
	
	// item cat -> item cat + price level -> item -> item + price level 
	
	If Customer = Catalogs.Companies.EmptyRef() Then
		PriceLevel = Catalogs.PriceLevels.EmptyRef()
	Else
		PriceLevel = Customer.PriceLevel
	EndIf;
	
	item_cat_price = 0;
	If Product.Category = Catalogs.ProductCategories.EmptyRef() Then
	Else
		SelectParameters = New Structure;
		SelectParameters.Insert("Product", Catalogs.Products.EmptyRef());
		SelectParameters.Insert("ProductCategory", Product.Category);
		SelectParameters.Insert("PriceLevel", Catalogs.PriceLevels.EmptyRef());
		item_cat_price = InformationRegisters.PriceList.GetLast(ActualDate, SelectParameters).Price;
	EndIf;

	item_cat_price_level_price = 0;
	If Product.Category = Catalogs.ProductCategories.EmptyRef() OR PriceLevel = Catalogs.PriceLevels.EmptyRef() Then
	Else
		SelectParameters = New Structure;
		SelectParameters.Insert("Product", Catalogs.Products.EmptyRef());
		SelectParameters.Insert("ProductCategory", Product.Category);
		SelectParameters.Insert("PriceLevel", PriceLevel);
		item_cat_price_level_price = InformationRegisters.PriceList.GetLast(ActualDate, SelectParameters).Price;
	EndIf;

	item_price = 0;
	SelectParameters = New Structure;
	SelectParameters.Insert("Product", Product);
	SelectParameters.Insert("ProductCategory", Catalogs.ProductCategories.EmptyRef());
	SelectParameters.Insert("PriceLevel", Catalogs.PriceLevels.EmptyRef());
	item_price = InformationRegisters.PriceList.GetLast(ActualDate, SelectParameters).Price;
	
	item_price_level_price = 0;
	If PriceLevel = Catalogs.PriceLevels.EmptyRef() Then
	Else
		SelectParameters = New Structure;
		SelectParameters.Insert("Product", Product);
		SelectParameters.Insert("ProductCategory", Catalogs.ProductCategories.EmptyRef());
		SelectParameters.Insert("PriceLevel", PriceLevel);
		item_price_level_price = InformationRegisters.PriceList.GetLast(ActualDate, SelectParameters).Price;
	EndIf;

	If item_price_level_price <> 0 Then
		Return item_price_level_price
	ElsIf item_price <> 0 Then
		Return item_price
	ElsIf item_cat_price_level_price <> 0 Then
		Return item_cat_price_level_price
	ElsIf item_cat_price <> 0 Then
		Return item_cat_price
	Else
		Return 0;
	EndIf;	
	
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

Function GetDefaultCOGSAcct() Export
	
	Return Constants.COGSAccount.Get();
	
EndFunction

Function GetEmptyAcct() Export
	
	Return ChartsOfAccounts.ChartOfAccounts.EmptyRef();

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
Function LastCheckNumber(BankAccount) Export
	
		LastNumber = 0;
	//Checks check and invoice payment numbers where payment method is check and same bank account	
		Query = New Query("SELECT
		                  |	Check.PhysicalCheckNum AS Number
		                  |FROM
		                  |	Document.Check AS Check
		                  |WHERE
		                  |	Check.BankAccount = &BankAccount
		                  |	AND Check.PaymentMethod = VALUE(Catalog.PaymentMethods.Check)
		                  |
		                  |UNION ALL
		                  |
		                  |SELECT
		                  |	InvoicePayment.PhysicalCheckNum
		                  |FROM
		                  |	Document.InvoicePayment AS InvoicePayment
		                  |WHERE
		                  |	InvoicePayment.BankAccount = &BankAccount
		                  |	AND InvoicePayment.PaymentMethod = VALUE(Catalog.PaymentMethods.Check)
		                  |
		                  |ORDER BY
		                  |	Number DESC");
		Query.SetParameter("BankAccount", BankAccount);
		//Query.SetParameter("Number", Object.Number);
		QueryResult = Query.Execute();
		If QueryResult.IsEmpty() Then
			LastNumber = 999;
			//Object.PhysicalCheckNum = 1000;
		ElsIf
			QueryResult.Unload()[0][0] = 0 Then
			LastNumber = 999;
		Else
			LastNumber = QueryResult.Unload()[0][0];
		EndIf;

		Return LastNumber;
	
EndFunction

//Function NextProductNumber() Export
//	
//	Query = New Query("SELECT
//					  |	Products.api_code AS api_code
//					  |FROM
//					  |	Catalog.Products AS Products
//					  |
//					  |ORDER BY
//					  |	api_code DESC");
//	QueryResult = Query.Execute();
//	
//	If QueryResult.IsEmpty() Then
//		Return 1;
//	Else
//		Dataset = QueryResult.Unload();
//		LastNumber = Dataset[0][0];
//		Return LastNumber + 1;
//	EndIf;
//	
//EndFunction


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
	
	If QueryResult.IsEmpty() Then
		Return Catalogs.Addresses.EmptyRef();
	Else
		Dataset = QueryResult.Unload();
		Return Dataset[0][0];
	EndIf;
	
EndFunction

Function GetBillToAddress(Company) Export
	
	Query = New Query("SELECT
	                  |	Addresses.Ref
	                  |FROM
	                  |	Catalog.Addresses AS Addresses
	                  |WHERE
	                  |	Addresses.Owner = &Company
	                  |	AND Addresses.DefaultBilling = TRUE");
	Query.SetParameter("Company", Company);				  
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return Catalogs.Addresses.EmptyRef();
	Else
		Dataset = QueryResult.Unload();
		Return Dataset[0][0];
	EndIf;
	
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
Procedure CheckDoubleItems(Ref, LineItems, Columns, Filter = Undefined, Cancel) Export
	
	// Dump table part
	TableLineItems = LineItems.Unload(Filter, Columns);
	TableLineItems.Sort(Columns);
	
	// Define subsets of data to check
	EmptyItems   = New Structure(Columns);
	CurrentItems = New Structure(Columns);
	DoubledItems = New Structure(Columns);
	CompareItems = StrReplace(Columns, "LineNumber", "");
	//DisplayCodes = FunctionalOptionValue("DisplayCodes");
	DoublesCount = 0;
	Doubles      = "";
	RefMetadata  = Ref.Metadata();
	
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
							
						ElsIf Not ValueIsFilled(Value) Then
							Presentation = NStr("en = '<Empty>'");
							
						ElsIf TypeOf(Value) = Type("CatalogRef.Companies") Then
							Presentation = TrimAll(Value.Code) + " " + TrimAll(Value.Description);;
							
						ElsIf TypeOf(Value) = Type("CatalogRef.Products") Then
							Presentation = TrimAll(Value.Code) + " " + TrimAll(Value.Description);
							
						Else
							Presentation = TrimAll(Value);
						EndIf;
						
						// Generate field name presentation
						KeyPresentation = RefMetadata.TabularSections.LineItems.Attributes[Double.Key].Synonym;
						
						// Generate doubled items text
						DoublesText = DoublesText + ?(IsBlankString(DoublesText), "", ", ") + KeyPresentation + " '" + Presentation + "'";
					EndDo;
					
					// Generate message to user
					MessageText = NStr("en = '%1
					                         |doubled in lines: %2'");
					MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessageText, DoublesText, Doubles); 
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
				
			ElsIf Not ValueIsFilled(Value) Then
				Presentation = NStr("en = '<Empty>'");
				
			ElsIf TypeOf(Value) = Type("CatalogRef.Companies") Then
				Presentation = TrimAll(Value.Code) + " " + TrimAll(Value.Description);
				
			ElsIf TypeOf(Value) = Type("CatalogRef.Products") Then
				Presentation = TrimAll(Value.Code) + " " + TrimAll(Value.Description);
				
			Else
				Presentation = TrimAll(Value);
			EndIf;
			
			// Generate field name presentation
			KeyPresentation = RefMetadata.TabularSections.LineItems.Attributes[Double.Key].Synonym;
			
			// Generate doubled items text
			DoublesText = DoublesText + ?(IsBlankString(DoublesText), "", ", ") + KeyPresentation + " '" + Presentation + "'";
		EndDo;
		
		// Generate message to user
		MessageText = NStr("en = '%1
		                         |doubled in lines: %2'");
		MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessageText, DoublesText, Doubles); 
		CommonUseClientServer.MessageToUser(MessageText, Ref,,, Cancel);
		
	Else
		RemainingDoubles = DoublesCount + Number(FilledPropertyValues(DoubledItems, CompareItems)) - 10; // Quantity of errors, which are not displayed to user
		If RemainingDoubles > 0 Then
			// Generate message to user
			MessageText = NStr("en = 'There are also %1 error(s) found'");
			MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessageText, Format(RemainingDoubles, "NFD=0; NG=0")); 
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

//// converts a number into a 5 character string by adding leading zeros.
//// for example 15 -> "00015"
//// 
//Function LeadingZeros(Number) Export

//	StringNumber = String(Number);
//	ZerosNeeded = 5 - StrLen(StringNumber);
//	NumberWithZeros = "";
//	For i = 1 to ZerosNeeded Do
//		NumberWithZeros = NumberWithZeros + "0";
//	EndDo;
//	
//	Return NumberWithZeros + StringNumber;
//	
//EndFunction

// Moved from InfobaseUpdateOverridable

//Procedure creates:
// 1. Bank transaction category;
// 2. Business account for the category
//
// Parameters:
// CategoryCode - integer, Yodlee category code
// CategoryDescription - string, Yodlee category description
// CategoryType - string, Values: expense, income, transfer, uncategorized
// AccountType - EnumRef.AccountTypes. Attribute of a business account for the category
// CashFlowSection - EnumRef.CashFlowSections. Attribute of a business account for the category
// PrefefinedAccount - ChartOfAccountsRef.ChartOfAccounts. If it is filled - then there is no need to create a new business account. Should use an existing one.
//
Procedure AddBankTransactionCategoryAndAccount(CategoryCode, CategoryDescription, CategoryType, AccountType = Undefined, CashFlowSection = Undefined, AccountCode = Undefined, PredefinedAccount = Undefined)
	Request = New Query("SELECT
	                    |	BankTransactionCategories.Ref
	                    |FROM
	                    |	Catalog.BankTransactionCategories AS BankTransactionCategories
	                    |WHERE
	                    |	BankTransactionCategories.Code = &Code");
	Request.SetParameter("Code", CategoryCode);
	Res = Request.Execute();
	If Res.IsEmpty() Then
		CategoryObject = Catalogs.BankTransactionCategories.CreateItem();
	Else
		Sel = Res.Choose();
		Sel.Next();
		CategoryObject = Sel.Ref.GetObject();
	EndIf;
	CategoryObject.Code = CategoryCode;
	CategoryObject.Description = CategoryDescription;
	CategoryObject.CategoryType = CategoryType;
	
	If PredefinedAccount <> Undefined Then
		CategoryObject.Account = PredefinedAccount;
		CategoryObject.Write();
		return;
	EndIf;
	Request = New Query("SELECT
	                    |	ChartOfAccounts.Ref
	                    |FROM
	                    |	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
	                    |WHERE
	                    |	ChartOfAccounts.Description = &CategoryDescription
	                    |	AND ChartOfAccounts.AccountType = &AccountType
	                    |	AND ChartOfAccounts.CashFlowSection = &CashFlowSection");
	Request.SetParameter("CategoryDescription", CategoryDescription);
	Request.SetParameter("AccountType", AccountType);
	Request.SetParameter("CashFlowSection", CashFlowSection);
	Res = Request.Execute();
	If Not Res.IsEmpty() Then
		Sel = Res.Choose();
		Sel.Next();
		CategoryObject.Account = Sel.Ref;
		CategoryObject.Write();
		return;
	EndIf;
	
	AccountObject = ChartsOfAccounts.ChartOfAccounts.CreateAccount();
	AccountObject.Description 		= CategoryDescription;
	AccountObject.AccountType 		= AccountType;
	AccountObject.CashFlowSection 	= CashFlowSection;
	AccountObject.Code 				= AccountCode;
	AccountObject.Order 			= AccountObject.Code;
	AccountObject.Write();
	CategoryObject.Account = AccountObject.Ref;
	CategoryObject.Write();
EndProcedure

//Procedure creates:
// 1. Bank transaction categories;
// 2. Business accounts for bank transaction categories
Procedure AddBankTransactionCategoriesAndAccounts() Export
	
	AddBankTransactionCategoryAndAccount(1, "Uncategorized", "Uncategorized", , , ,ChartsOfAccounts.ChartOfAccounts.Expense);
	AddBankTransactionCategoryAndAccount(2, "Automotive Expenses", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6020");
	AddBankTransactionCategoryAndAccount(3, "Charitable Giving", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6030");
	AddBankTransactionCategoryAndAccount(4, "Child/Dependent Expenses", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6040");
	AddBankTransactionCategoryAndAccount(5, "Clothing/Shoes", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6050");
	AddBankTransactionCategoryAndAccount(6, "Education", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6060");
	AddBankTransactionCategoryAndAccount(7, "Entertainment", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6070");
	AddBankTransactionCategoryAndAccount(8, "Gasoline/Fuel", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6080");
	AddBankTransactionCategoryAndAccount(9, "Gifts", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6090");
	AddBankTransactionCategoryAndAccount(10, "Groceries", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6650");
	AddBankTransactionCategoryAndAccount(11, "Healthcare/Medical", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6110");
	AddBankTransactionCategoryAndAccount(12, "Home Maintenance", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6120");
	AddBankTransactionCategoryAndAccount(13, "Home Improvement", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6130");
	AddBankTransactionCategoryAndAccount(14, "Insurance", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6140");
	AddBankTransactionCategoryAndAccount(15, "Cable/Satellite Services", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6150");
	AddBankTransactionCategoryAndAccount(16, "Online Services", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6160");
	AddBankTransactionCategoryAndAccount(17, "Loans", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6170");
	AddBankTransactionCategoryAndAccount(18, "Mortgages", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6180");
	
	AddBankTransactionCategoryAndAccount(19, "Other Expenses", "expense", Enums.AccountTypes.OtherExpense, Enums.CashFlowSections.Operating, "6680");
	
	AddBankTransactionCategoryAndAccount(20, "Personal Care", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6220");
	AddBankTransactionCategoryAndAccount(21, "Rent", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6240");
	AddBankTransactionCategoryAndAccount(22, "Restaurants/Dining", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6260");
	AddBankTransactionCategoryAndAccount(23, "Travel", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6280");
	
	AddBankTransactionCategoryAndAccount(24, "Service Charges/Fees", "expense", , , ,ChartsOfAccounts.ChartOfAccounts.BankServiceCharge);
	
	AddBankTransactionCategoryAndAccount(25, "ATM/Cash Withdrawals", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6300");
	
	AddBankTransactionCategoryAndAccount(26, "Credit Card Payments", "transfer", Enums.AccountTypes.OtherCurrentLiability, Enums.CashFlowSections.Operating, "2600");
	
	AddBankTransactionCategoryAndAccount(27, "Deposits", "income", Enums.AccountTypes.Income, Enums.CashFlowSections.Operating, "4100");
	
	AddBankTransactionCategoryAndAccount(28, "Transfers", "transfer", Enums.AccountTypes.Bank, Enums.CashFlowSections.Operating, "1010");
	
	AddBankTransactionCategoryAndAccount(29, "Paychecks/Salary", "income", Enums.AccountTypes.Income, Enums.CashFlowSections.Operating, "4200");
	
	AddBankTransactionCategoryAndAccount(30, "Investment Income", "income", Enums.AccountTypes.Income, Enums.CashFlowSections.Operating, "4300");
	AddBankTransactionCategoryAndAccount(31, "Retirement Income", "income", Enums.AccountTypes.Income, Enums.CashFlowSections.Operating, "4400");
	
	AddBankTransactionCategoryAndAccount(32, "Other Income", "income", Enums.AccountTypes.OtherIncome, Enums.CashFlowSections.Operating, "8100");
	
	AddBankTransactionCategoryAndAccount(33, "Checks", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6320");
	AddBankTransactionCategoryAndAccount(34, "Hobbies", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6340");
	AddBankTransactionCategoryAndAccount(35, "Other Bills", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6360");
	
	AddBankTransactionCategoryAndAccount(36, "Securities Trades", "transfer", Enums.AccountTypes.Bank, Enums.CashFlowSections.Operating, "1020");
	
	AddBankTransactionCategoryAndAccount(37, "Taxes", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6380");
	AddBankTransactionCategoryAndAccount(38, "Telephone Services", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6400");
	AddBankTransactionCategoryAndAccount(39, "Utilities", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6420");
	
	AddBankTransactionCategoryAndAccount(40, "Savings", "transfer", Enums.AccountTypes.Bank, Enums.CashFlowSections.Operating, "1030");
	AddBankTransactionCategoryAndAccount(41, "Retirement Contributions", "DeferredCompensation", Enums.AccountTypes.Bank, Enums.CashFlowSections.Operating, "1040");
	
	AddBankTransactionCategoryAndAccount(42, "Pets/Pet Care", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6440");
	AddBankTransactionCategoryAndAccount(43, "Electronics", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6460");
	AddBankTransactionCategoryAndAccount(44, "General Merchandise", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6480");
	AddBankTransactionCategoryAndAccount(45, "Office Supplies", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6500");
	
	AddBankTransactionCategoryAndAccount(92, "Consulting", "income", Enums.AccountTypes.Income, Enums.CashFlowSections.Operating, "4500");
	AddBankTransactionCategoryAndAccount(94, "Sales", "income", , , , ChartsOfAccounts.ChartOfAccounts.Income);
	AddBankTransactionCategoryAndAccount(96, "Interest", "income", , , ,ChartsOfAccounts.ChartOfAccounts.BankInterestEarned);
	AddBankTransactionCategoryAndAccount(98, "Services", "income", Enums.AccountTypes.Income, Enums.CashFlowSections.Operating, "4600");
	
	AddBankTransactionCategoryAndAccount(100, "Advertising", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6520");
	AddBankTransactionCategoryAndAccount(102, "Business Miscellaneous", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6540");
	AddBankTransactionCategoryAndAccount(104, "Postage and Shipping", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6560");
	AddBankTransactionCategoryAndAccount(106, "Printing", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6580");
	AddBankTransactionCategoryAndAccount(108, "Dues and Subscriptions", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6600");
	AddBankTransactionCategoryAndAccount(110, "Office Maintenance", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6620");
	AddBankTransactionCategoryAndAccount(112, "Wages Paid", "expense", Enums.AccountTypes.Expense, Enums.CashFlowSections.Operating, "6640");
	
	AddBankTransactionCategoryAndAccount(114, "Expense Reimbursement", "income", Enums.AccountTypes.Income, Enums.CashFlowSections.Operating, "4700");
	
EndProcedure

// Procedure fills empty IB.
//
Procedure FirstLaunch() Export
	
	// mt_change
	If Constants.FirstLaunch.Get() = False Then
	
	BeginTransaction();
	
	    Constants.SalesInvoiceLastNumber.Set("1000");
		Constants.CashReceiptLastNumber.Set("1000");
		Constants.CashSaleLastNumber.Set("1000");
		Constants.DepositLastNumber.Set("1000");
		Constants.BankTransferLastNumber.Set("1000");
		Constants.WarehouseTransferLastNumber.Set("1000");
		Constants.CreditMemoLastNumber.Set("1000");
		Constants.SalesOrderLastNumber.Set("1000");
		Constants.PurchaseOrderLastNumber.Set("1000");
		Constants.GJEntryLastNumber.Set("1000");
		// Adding account types to predefined accounts and
		// assigning default posting accounts.
		
		Account = ChartsOfAccounts.ChartOfAccounts.BankAccount.GetObject();
		Account.AccountType = Enums.AccountTypes.Bank;
		Account.Currency = Catalogs.Currencies.USD;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Order = Account.Code;
		Account.Write();
		Constants.BankAccount.Set(Account.Ref);
		
		Account = ChartsOfAccounts.ChartOfAccounts.UndepositedFunds.GetObject();
		Account.AccountType = Enums.AccountTypes.OtherCurrentAsset;
		Account.Currency = Catalogs.Currencies.USD;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Order = Account.Code;
		Account.Write();
		Constants.UndepositedFundsAccount.Set(Account.Ref);
		
		Account = ChartsOfAccounts.ChartOfAccounts.AccountsReceivable.GetObject();
		Account.AccountType = Enums.AccountTypes.AccountsReceivable;
		Account.Currency = Catalogs.Currencies.USD;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Order = Account.Code;
		Account.Write();
		
		USDCurrency = Catalogs.Currencies.USD.GetObject();
		USDCurrency.DefaultARAccount = Account.Ref;
		
		Account = ChartsOfAccounts.ChartOfAccounts.Inventory.GetObject();
		Account.AccountType = Enums.AccountTypes.Inventory;
		Account.Currency = Catalogs.Currencies.USD;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Order = Account.Code;
		Account.Write();
		Constants.InventoryAccount.Set(Account.Ref);
		
		Account = ChartsOfAccounts.ChartOfAccounts.AccountsPayable.GetObject();
		Account.AccountType = Enums.AccountTypes.AccountsPayable;
		Account.Currency = Catalogs.Currencies.USD;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Order = Account.Code;
		Account.Write();
		
		USDCurrency.DefaultAPAccount = Account.Ref;
		USDCurrency.Write();
		
		Account = ChartsOfAccounts.ChartOfAccounts.TaxPayable.GetObject();
		Account.AccountType = Enums.AccountTypes.OtherCurrentLiability;
		Account.Currency = Catalogs.Currencies.USD;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Order = Account.Code;
		Account.Write();
		Constants.TaxPayableAccount.Set(Account.Ref);
				
		Account = ChartsOfAccounts.ChartOfAccounts.Income.GetObject();
		Account.AccountType = Enums.AccountTypes.Income;
		Account.Currency = Catalogs.Currencies.USD;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Order = Account.Code;
		Account.Write();
		Constants.IncomeAccount.Set(Account.Ref);
		
		Account = ChartsOfAccounts.ChartOfAccounts.COGS.GetObject();
		Account.AccountType = Enums.AccountTypes.CostOfSales;
		Account.Currency = Catalogs.Currencies.USD;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Order = Account.Code;
		Account.Write();
		Constants.COGSAccount.Set(Account.Ref);
		
		Account = ChartsOfAccounts.ChartOfAccounts.Equity.GetObject();
		Account.AccountType = Enums.AccountTypes.Equity;
		Account.Currency = Catalogs.Currencies.USD;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Order = Account.Code;
		Account.Write();
		
		Account = ChartsOfAccounts.ChartOfAccounts.RetainedEarnings.GetObject();
		Account.AccountType = Enums.AccountTypes.Equity;
		Account.Currency = Catalogs.Currencies.USD;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Order = Account.Code;
		Account.Write();

		Account = ChartsOfAccounts.ChartOfAccounts.BankServiceCharge.GetObject();
		Account.AccountType = Enums.AccountTypes.OtherExpense;
		Account.Currency = Catalogs.Currencies.USD;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Order = Account.Code;
		Account.Write();
		Constants.BankServiceChargeAccount.Set(Account.Ref);
		
		Account = ChartsOfAccounts.ChartOfAccounts.BankInterestEarned.GetObject();
		Account.AccountType = Enums.AccountTypes.OtherIncome;
		Account.Currency = Catalogs.Currencies.USD;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Order = Account.Code;
		Account.Write();
		Constants.BankInterestEarnedAccount.Set(Account.Ref);
		
		Account = ChartsOfAccounts.ChartOfAccounts.ExchangeGain.GetObject();
		Account.AccountType = Enums.AccountTypes.OtherIncome;
		Account.Currency = Catalogs.Currencies.USD;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Order = Account.Code;
		Account.Write();
		Constants.ExchangeGain.Set(Account.Ref);
		
		Account = ChartsOfAccounts.ChartOfAccounts.ExchangeLoss.GetObject();
		Account.AccountType = Enums.AccountTypes.OtherExpense;
		Account.Currency = Catalogs.Currencies.USD;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Order = Account.Code;
		Account.Write();
		Constants.ExchangeLoss.Set(Account.Ref);
		
		Account = ChartsOfAccounts.ChartOfAccounts.Expense.GetObject();
		Account.AccountType = Enums.AccountTypes.Expense;
		Account.Currency = Catalogs.Currencies.USD;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Order = Account.Code;
		Account.Write();
		Constants.ExpenseAccount.Set(Account.Ref);
		
		Account = ChartsOfAccounts.ChartOfAccounts.PurchaseLiability.GetObject();
		Account.AccountType = Enums.AccountTypes.OtherCurrentLiability;
		Account.Currency = Catalogs.Currencies.USD;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Order = Account.Code;
		Account.Write();
		Constants.PurchaseLiabilityAccount.Set(Account.Ref);
		
		Account = ChartsOfAccounts.ChartOfAccounts.CostVariance.GetObject();
		Account.AccountType = Enums.AccountTypes.CostOfSales;
		Account.Currency = Catalogs.Currencies.USD;
		Account.CashFlowSection = Enums.CashFlowSections.Operating;
		Account.Order = Account.Code;
		Account.Write();
		Constants.CostVarianceAccount.Set(Account.Ref);
					
		// Adding OurCompany's full name
		
		//OC = Catalogs.Companies.OurCompany.GetObject();
		//OC.Description = "Our company full name";
		//OC.Terms = Catalogs.PaymentTerms.Net30;
		//OC.Write();
		//
		//AddressLine = Catalogs.Addresses.CreateItem();
		//AddressLine.Owner = Catalogs.Companies.OurCompany;
		//AddressLine.Description = "Primary";
		//AddressLine.DefaultShipping = True;
		//AddressLine.DefaultBilling = True;
		//AddressLine.Write();
		
		// Setting default location, currency, and beginning balances date
		
		Constants.DefaultCurrency.Set(Catalogs.Currencies.USD);
		
		// Adding days to predefined payment terms and setting
		// a default payment term
				
		PT = Catalogs.PaymentTerms.Net30.GetObject();
		PT.Days = 30;
		PT.Write();
		
		PT = Catalogs.PaymentTerms.Consignment.GetObject();
		PT.Days = 0;
		PT.Write();

		PT = Catalogs.PaymentTerms.DueOnReceipt.GetObject();
		PT.Days = 0;
		PT.Write();

		
		PT = Catalogs.PaymentTerms.Net15.GetObject();
		PT.Days = 15;
		PT.Write();
						
		// Setting 1099 thresholds
		
		Cat1099 = Catalogs.USTaxCategories1099.Box1.GetObject();
		Cat1099.Threshold = 600;
		Cat1099.Write();
		
		Cat1099 = Catalogs.USTaxCategories1099.Box2.GetObject();
		Cat1099.Threshold = 10;
		Cat1099.Write();
		
		Cat1099 = Catalogs.USTaxCategories1099.Box7.GetObject();
		Cat1099.Threshold = 600;
		Cat1099.Write();
		
		Cat1099 = Catalogs.USTaxCategories1099.Box8.GetObject();
		Cat1099.Threshold = 10;
		Cat1099.Write();
		
		Cat1099 = Catalogs.USTaxCategories1099.Box9.GetObject();
		Cat1099.Threshold = 5000;
		Cat1099.Write();
		
		// Creating a user with full rights
		
		// mt_change
		
		//NewUser = InfoBaseUsers.CreateUser();
		//NewUser.Name = "Administrator";
		//Role = Metadata.Roles.Find("FullAccess");
		//NewUser.Roles.Add(Role);
		//NewUser.Write();
				
		// Assigning currency symbols
				
		Currency = Catalogs.Currencies.USD.GetObject();
		Currency.Symbol = "$";
		Currency.Write();
								
		// Setting Customer Name and Vendor Name constants
		
		Constants.CustomerName.Set("Customer");
		Constants.VendorName.Set("Vendor");
		
		// US186 - unapplied payment
		
		// Setting unaplied payment item
		//UnappliedPaymentItem                           = Catalogs.Products.CreateItem();
		//UnappliedPaymentItem.Code                      = "Unapplied payment";
		//UnappliedPaymentItem.Description               = "Unapplied payment";
		//UnappliedPaymentItem.Type                      = Enums.InventoryTypes.NonInventory;
		//UnappliedPaymentItem.UM                        = Catalogs.UM.each;
		//UnappliedPaymentItem.IncomeAccount             = ChartsOfAccounts.ChartOfAccounts.Income;
		//UnappliedPaymentItem.InventoryOrExpenseAccount = ChartsOfAccounts.ChartOfAccounts.Expense;
		//UnappliedPaymentItem.Write();
		
		// US186 - unapplied payment
		
		// Adding US States
		
		// 1 - 10
		
		NewState = Catalogs.States.CreateItem();
		NewState.Code = "AL";
		NewState.Description = "Alabama";
		NewState.Write();
		
		NewState = Catalogs.States.CreateItem();
		NewState.Code = "AK";
		NewState.Description = "Alaska";
		NewState.Write();
		
		NewState = Catalogs.States.CreateItem();
		NewState.Code = "AZ";
		NewState.Description = "Arizona";
		NewState.Write();
		
		NewState = Catalogs.States.CreateItem();
		NewState.Code = "AR";
		NewState.Description = "Arkansas";
		NewState.Write();

		NewState = Catalogs.States.CreateItem();
		NewState.Code = "CA";
		NewState.Description = "California";
		NewState.Write();

		NewState = Catalogs.States.CreateItem();
		NewState.Code = "CO";
		NewState.Description = "Colorado";
		NewState.Write();

		NewState = Catalogs.States.CreateItem();
		NewState.Code = "CT";
		NewState.Description = "Connecticut";
		NewState.Write();
		
		NewState = Catalogs.States.CreateItem();
		NewState.Code = "DE";
		NewState.Description = "Delaware";
		NewState.Write();

        NewState = Catalogs.States.CreateItem();
		NewState.Code = "FL";
		NewState.Description = "Florida";
		NewState.Write();
		
		NewState = Catalogs.States.CreateItem();
		NewState.Code = "GA";
		NewState.Description = "Georgia";
		NewState.Write();

		// 11 - 20
		
        NewState = Catalogs.States.CreateItem();
		NewState.Code = "HI";
		NewState.Description = "Hawaii";
		NewState.Write();

		NewState = Catalogs.States.CreateItem();
		NewState.Code = "ID";
		NewState.Description = "Idaho";
		NewState.Write();

	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "IL";
		NewState.Description = "Illinois";
		NewState.Write();

	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "IN";
		NewState.Description = "Indiana";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "IA";
		NewState.Description = "Iowa";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "KS";
		NewState.Description = "Kansas";
		NewState.Write();
		
	 	NewState = Catalogs.States.CreateItem();
		NewState.Code = "KY";
		NewState.Description = "Kentucky";
		NewState.Write();

		NewState = Catalogs.States.CreateItem();
		NewState.Code = "LA";
		NewState.Description = "Louisiana";
		NewState.Write();

	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "ME";
		NewState.Description = "Maine";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "MD";
		NewState.Description = "Maryland";
		NewState.Write();
		
		// 21 - 30
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "MA";
		NewState.Description = "Massachusetts";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "MI";
		NewState.Description = "Michigan";
		NewState.Write();

	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "MN";
		NewState.Description = "Minnesota";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "MS";
		NewState.Description = "Mississippi";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "MO";
		NewState.Description = "Missouri";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "MT";
		NewState.Description = "Montana";
		NewState.Write();
		
		NewState = Catalogs.States.CreateItem();
		NewState.Code = "NE";
		NewState.Description = "Nebraska";
		NewState.Write();

	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "NV";
		NewState.Description = "Nevada";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "NH";
		NewState.Description = "New Hampshire";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "NJ";
		NewState.Description = "New Jersey";
		NewState.Write();
		
		// 31 - 40
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "NM";
		NewState.Description = "New Mexico";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "NY";
		NewState.Description = "New York";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "NC";
		NewState.Description = "North Carolina";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "ND";
		NewState.Description = "North Dakota";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "OH";
		NewState.Description = "Ohio";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "OK";
		NewState.Description = "Oklahoma";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "OR";
		NewState.Description = "Oregon";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "PA";
		NewState.Description = "Pennsylvania";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "RI";
		NewState.Description = "Rhode Island";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "SC";
		NewState.Description = "South Carolina";
		NewState.Write();
		
		// 41 - 50 
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "SD";
		NewState.Description = "South Dakota";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "TN";
		NewState.Description = "Tennessee";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "TX";
		NewState.Description = "Texas";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "UT";
		NewState.Description = "Utah";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "VT";
		NewState.Description = "Vermont";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "VA";
		NewState.Description = "Virginia";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "WA";
		NewState.Description = "Washington";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "WV";
		NewState.Description = "West Virginia";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "WI";
		NewState.Description = "Wisconsin";
		NewState.Write();
		
	    NewState = Catalogs.States.CreateItem();
		NewState.Code = "WY";
		NewState.Description = "Wyoming";
		NewState.Write();
		
		// Countries
		
NewCountry = Catalogs.Countries.CreateItem();		
NewCountry.Description = "Afghanistan";
NewCountry.Code = "AF";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Åland Islands";
NewCountry.Code = "AX";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Albania";
NewCountry.Code = "AL";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Algeria";
NewCountry.Code = "DZ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "American Samoa";
NewCountry.Code = "AS";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Andorra";
NewCountry.Code = "AD";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Angola";
NewCountry.Code = "AO";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Anguilla";
NewCountry.Code = "AI";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Antarctica";
NewCountry.Code = "AQ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Antigua and Barbuda";
NewCountry.Code = "AG";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Argentina";
NewCountry.Code = "AR";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Armenia";
NewCountry.Code = "AM";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Aruba";
NewCountry.Code = "AW";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Australia";
NewCountry.Code = "AU";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Austria";
NewCountry.Code = "AT";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Azerbaijan";
NewCountry.Code = "AZ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Bahamas";
NewCountry.Code = "BS";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Bahrain";
NewCountry.Code = "BH";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Bangladesh";
NewCountry.Code = "BD";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Barbados";
NewCountry.Code = "BB";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Belarus";
NewCountry.Code = "BY";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Belgium";
NewCountry.Code = "BE";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Belize";
NewCountry.Code = "BZ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Benin";
NewCountry.Code = "BJ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Bermuda";
NewCountry.Code = "BM";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Bhutan";
NewCountry.Code = "BT";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Bolivia, Plurinational State of";
NewCountry.Code = "BO";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Bonaire, Sint Eustatius and Saba";
NewCountry.Code = "BQ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Bosnia and Herzegovina";
NewCountry.Code = "BA";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Botswana";
NewCountry.Code = "BW";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Bouvet Island";
NewCountry.Code = "BV";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Brazil";
NewCountry.Code = "BR";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "British Indian Ocean Territory";
NewCountry.Code = "IO";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Brunei Darussalam";
NewCountry.Code = "BN";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Bulgaria";
NewCountry.Code = "BG";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Burkina Faso";
NewCountry.Code = "BF";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Burundi";
NewCountry.Code = "BI";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Cambodia";
NewCountry.Code = "KH";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Cameroon";
NewCountry.Code = "CM";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Canada";
NewCountry.Code = "CA";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Cape Verde";
NewCountry.Code = "CV";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Cayman Islands";
NewCountry.Code = "KY";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Central African Republic";
NewCountry.Code = "CF";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Chad";
NewCountry.Code = "TD";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Chile";
NewCountry.Code = "CL";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "China";
NewCountry.Code = "CN";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Christmas Island";
NewCountry.Code = "CX";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Cocos (Keeling) Islands";
NewCountry.Code = "CC";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Colombia";
NewCountry.Code = "CO";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Comoros";
NewCountry.Code = "KM";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Congo";
NewCountry.Code = "CG";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Congo, the Democratic Republic of the";
NewCountry.Code = "CD";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Cook Islands";
NewCountry.Code = "CK";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Costa Rica";
NewCountry.Code = "CR";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Côte d'Ivoire";
NewCountry.Code = "CI";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Croatia";
NewCountry.Code = "HR";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Cuba";
NewCountry.Code = "CU";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Curaçao";
NewCountry.Code = "CW";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Cyprus";
NewCountry.Code = "CY";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Czech Republic";
NewCountry.Code = "CZ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Denmark";
NewCountry.Code = "DK";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Djibouti";
NewCountry.Code = "DJ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Dominica";
NewCountry.Code = "DM";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Dominican Republic";
NewCountry.Code = "DO";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Ecuador";
NewCountry.Code = "EC";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Egypt";
NewCountry.Code = "EG";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "El Salvador";
NewCountry.Code = "SV";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Equatorial Guinea";
NewCountry.Code = "GQ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Eritrea";
NewCountry.Code = "ER";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Estonia";
NewCountry.Code = "EE";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Ethiopia";
NewCountry.Code = "ET";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Falkland Islands (Malvinas)";
NewCountry.Code = "FK";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Faroe Islands";
NewCountry.Code = "FO";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Fiji";
NewCountry.Code = "FJ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Finland";
NewCountry.Code = "FI";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "France";
NewCountry.Code = "FR";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "French Guiana";
NewCountry.Code = "GF";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "French Polynesia";
NewCountry.Code = "PF";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "French Southern Territories";
NewCountry.Code = "TF";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Gabon";
NewCountry.Code = "GA";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Gambia";
NewCountry.Code = "GM";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Georgia";
NewCountry.Code = "GE";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Germany";
NewCountry.Code = "DE";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Ghana";
NewCountry.Code = "GH";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Gibraltar";
NewCountry.Code = "GI";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Greece";
NewCountry.Code = "GR";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Greenland";
NewCountry.Code = "GL";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Grenada";
NewCountry.Code = "GD";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Guadeloupe";
NewCountry.Code = "GP";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Guam";
NewCountry.Code = "GU";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Guatemala";
NewCountry.Code = "GT";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Guernsey";
NewCountry.Code = "GG";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Guinea";
NewCountry.Code = "GN";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Guinea-Bissau";
NewCountry.Code = "GW";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Guyana";
NewCountry.Code = "GY";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Haiti";
NewCountry.Code = "HT";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Heard Island and McDonald Islands";
NewCountry.Code = "HM";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Holy See (Vatican City State)";
NewCountry.Code = "VA";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Honduras";
NewCountry.Code = "HN";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Hong Kong";
NewCountry.Code = "HK";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Hungary";
NewCountry.Code = "HU";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Iceland";
NewCountry.Code = "IS";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "India";
NewCountry.Code = "IN";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Indonesia";
NewCountry.Code = "ID";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Iran, Islamic Republic of";
NewCountry.Code = "IR";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Iraq";
NewCountry.Code = "IQ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Ireland";
NewCountry.Code = "IE";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Isle of Man";
NewCountry.Code = "IM";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Israel";
NewCountry.Code = "IL";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Italy";
NewCountry.Code = "IT";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Jamaica";
NewCountry.Code = "JM";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Japan";
NewCountry.Code = "JP";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Jersey";
NewCountry.Code = "JE";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Jordan";
NewCountry.Code = "JO";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Kazakhstan";
NewCountry.Code = "KZ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Kenya";
NewCountry.Code = "KE";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Kiribati";
NewCountry.Code = "KI";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Korea, Democratic People's Republic of";
NewCountry.Code = "KP";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Korea, Republic of";
NewCountry.Code = "KR";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Kuwait";
NewCountry.Code = "KW";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Kyrgyzstan";
NewCountry.Code = "KG";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Lao People's Democratic Republic";
NewCountry.Code = "LA";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Latvia";
NewCountry.Code = "LV";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Lebanon";
NewCountry.Code = "LB";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Lesotho";
NewCountry.Code = "LS";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Liberia";
NewCountry.Code = "LR";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Libya";
NewCountry.Code = "LY";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Liechtenstein";
NewCountry.Code = "LI";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Lithuania";
NewCountry.Code = "LT";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Luxembourg";
NewCountry.Code = "LU";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Macao";
NewCountry.Code = "MO";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Macedonia, The Former Yugoslav Republic of";
NewCountry.Code = "MK";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Madagascar";
NewCountry.Code = "MG";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Malawi";
NewCountry.Code = "MW";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Malaysia";
NewCountry.Code = "MY";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Maldives";
NewCountry.Code = "MV";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Mali";
NewCountry.Code = "ML";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Malta";
NewCountry.Code = "MT";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Marshall Islands";
NewCountry.Code = "MH";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Martinique";
NewCountry.Code = "MQ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Mauritania";
NewCountry.Code = "MR";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Mauritius";
NewCountry.Code = "MU";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Mayotte";
NewCountry.Code = "YT";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Mexico";
NewCountry.Code = "MX";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Micronesia, Federated States of";
NewCountry.Code = "FM";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Moldova, Republic of";
NewCountry.Code = "MD";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Monaco";
NewCountry.Code = "MC";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Mongolia";
NewCountry.Code = "MN";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Montenegro";
NewCountry.Code = "ME";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Montserrat";
NewCountry.Code = "MS";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Morocco";
NewCountry.Code = "MA";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Mozambique";
NewCountry.Code = "MZ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Myanmar";
NewCountry.Code = "MM";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Namibia";
NewCountry.Code = "NA";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Nauru";
NewCountry.Code = "NR";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Nepal";
NewCountry.Code = "NP";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Netherlands";
NewCountry.Code = "NL";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "New Caledonia";
NewCountry.Code = "NC";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "New Zealand";
NewCountry.Code = "NZ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Nicaragua";
NewCountry.Code = "NI";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Niger";
NewCountry.Code = "NE";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Nigeria";
NewCountry.Code = "NG";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Niue";
NewCountry.Code = "NU";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Norfolk Island";
NewCountry.Code = "NF";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Northern Mariana Islands";
NewCountry.Code = "MP";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Norway";
NewCountry.Code = "NO";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Oman";
NewCountry.Code = "OM";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Pakistan";
NewCountry.Code = "PK";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Palau";
NewCountry.Code = "PW";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Palestine, State of";
NewCountry.Code = "PS";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Panama";
NewCountry.Code = "PA";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Papua New Guinea";
NewCountry.Code = "PG";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Paraguay";
NewCountry.Code = "PY";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Peru";
NewCountry.Code = "PE";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Philippines";
NewCountry.Code = "PH";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Pitcairn";
NewCountry.Code = "PN";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Poland";
NewCountry.Code = "PL";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Portugal";
NewCountry.Code = "PT";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Puerto Rico";
NewCountry.Code = "PR";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Qatar";
NewCountry.Code = "QA";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Réunion";
NewCountry.Code = "RE";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Romania";
NewCountry.Code = "RO";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Russian Federation";
NewCountry.Code = "RU";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Rwanda";
NewCountry.Code = "RW";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Saint Barthélemy";
NewCountry.Code = "BL";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Saint Helena, Ascension and Tristan da Cunha";
NewCountry.Code = "SH";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Saint Kitts and Nevis";
NewCountry.Code = "KN";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Saint Lucia";
NewCountry.Code = "LC";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Saint Martin (French part)";
NewCountry.Code = "MF";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Saint Pierre and Miquelon";
NewCountry.Code = "PM";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Saint Vincent and the Grenadines";
NewCountry.Code = "VC";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Samoa";
NewCountry.Code = "WS";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "San Marino";
NewCountry.Code = "SM";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Sao Tome and Principe";
NewCountry.Code = "ST";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Saudi Arabia";
NewCountry.Code = "SA";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Senegal";
NewCountry.Code = "SN";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Serbia";
NewCountry.Code = "RS";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Seychelles";
NewCountry.Code = "SC";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Sierra Leone";
NewCountry.Code = "SL";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Singapore";
NewCountry.Code = "SG";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Sint Maarten (Dutch part)";
NewCountry.Code = "SX";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Slovakia";
NewCountry.Code = "SK";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Slovenia";
NewCountry.Code = "SI";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Solomon Islands";
NewCountry.Code = "SB";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Somalia";
NewCountry.Code = "SO";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "South Africa";
NewCountry.Code = "ZA";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "South Georgia and the South Sandwich Islands";
NewCountry.Code = "GS";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "South Sudan";
NewCountry.Code = "SS";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Spain";
NewCountry.Code = "ES";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Sri Lanka";
NewCountry.Code = "LK";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Sudan";
NewCountry.Code = "SD";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Suriname";
NewCountry.Code = "SR";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Svalbard and Jan Mayen";
NewCountry.Code = "SJ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Swaziland";
NewCountry.Code = "SZ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Sweden";
NewCountry.Code = "SE";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Switzerland";
NewCountry.Code = "CH";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Syrian Arab Republic";
NewCountry.Code = "SY";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Taiwan, Province of China";
NewCountry.Code = "TW";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Tajikistan";
NewCountry.Code = "TJ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Tanzania, United Republic of";
NewCountry.Code = "TZ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Thailand";
NewCountry.Code = "TH";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Timor-Leste";
NewCountry.Code = "TL";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Togo";
NewCountry.Code = "TG";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Tokelau";
NewCountry.Code = "TK";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Tonga";
NewCountry.Code = "TO";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Trinidad and Tobago";
NewCountry.Code = "TT";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Tunisia";
NewCountry.Code = "TN";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Turkey";
NewCountry.Code = "TR";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Turkmenistan";
NewCountry.Code = "TM";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Turks and Caicos Islands";
NewCountry.Code = "TC";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Tuvalu";
NewCountry.Code = "TV";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Uganda";
NewCountry.Code = "UG";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Ukraine";
NewCountry.Code = "UA";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "United Arab Emirates";
NewCountry.Code = "AE";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "United Kingdom";
NewCountry.Code = "GB";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "United States";
NewCountry.Code = "US";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "United States Minor Outlying Islands";
NewCountry.Code = "UM";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Uruguay";
NewCountry.Code = "UY";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Uzbekistan";
NewCountry.Code = "UZ";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Vanuatu";
NewCountry.Code = "VU";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Venezuela, Bolivarian Republic of";
NewCountry.Code = "VE";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Viet Nam";
NewCountry.Code = "VN";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Virgin Islands, British";
NewCountry.Code = "VG";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Virgin Islands, U.S.";
NewCountry.Code = "VI";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Wallis and Futuna";
NewCountry.Code = "WF";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Western Sahara";
NewCountry.Code = "EH";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Yemen";
NewCountry.Code = "YE";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Zambia";
NewCountry.Code = "ZM";
NewCountry.Write();

NewCountry = Catalogs.Countries.CreateItem();
NewCountry.Description = "Zimbabwe";
NewCountry.Code = "ZW";
NewCountry.Write();
				
		Constants.CF1Type.Set("None");
		Constants.CF2Type.Set("None");
		Constants.CF3Type.Set("None");
		Constants.CF4Type.Set("None");
		Constants.CF5Type.Set("None");
		
		Constants.CF1CType.Set("None");
		Constants.CF2CType.Set("None");
		Constants.CF3CType.Set("None");
		Constants.CF4CType.Set("None");
		Constants.CF5CType.Set("None");	
		
		// mt_change	
		
	//Adding Yodlee transaction categories and respective business accounts 
	//AddBankTransactionCategoriesAndAccounts();
		
	CommitTransaction();
	
	Constants.FirstLaunch.Set(True);
	
EndIf;
	
EndProcedure // FirstLaunch()


