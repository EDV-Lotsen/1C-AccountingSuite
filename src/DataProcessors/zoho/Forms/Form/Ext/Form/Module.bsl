
&AtClient
Procedure SendRequest(Command)
	ShowMessageBox(Undefined, SendRequestAtServer());
EndProcedure

&AtServer
Function SendRequestAtServer()
	
	// Set request parameters.
	RequestParameters = New Structure;
	RequestParameters.Insert("authtoken", Constants.zoho_auth_token.Get());
	RequestParameters.Insert("scope",     "crmapi");
	RequestParameters.Insert("id",        "731865000000332074");
	
	// Apply parameters to the connection settings (override URL).
	ConnectionSettings = New Structure("Parameters, ParametersDecoded");
	ConnectionSettings.Parameters        = InternetConnectionClientServer.EncodeQueryData(RequestParameters);
	ConnectionSettings.ParametersDecoded = RequestParameters;
	
	// Define CA certificate.
	SecureConnection = Undefined; // Here CA certificate must be applied!
	
	// Create HTTP secure connection.
	Connection = InternetConnectionClientServer.CreateConnection("https://crm.zoho.com/crm/private/json/SalesOrders/getRecordById", ConnectionSettings, SecureConnection).Result;
	
	// Send request and get server response.
	Response = InternetConnectionClientServer.SendRequest(Connection, "Get", ConnectionSettings).Result;
	
	// Decode JSON data.
	JSON = InternetConnectionClientServer.DecodeJSON(Response);
	
	Header = JSON.response.result.SalesOrders.row.FL;
	NumOfRows = Header.Count();
	Lines = New Structure();
	For i = 0 To NumOfRows - 1 Do
		test = Header[i].val;
		If Header[i].val = "Product Details" Then
			Lines = Header[i];
		ElsIf Header[i].val = "SO Number" Then
			so_number = Header[i].content;
		ElsIf Header[i].val = "Account Name" Then
			account_name = Header[i].content;
		ElsIf Header[i].val = "Created Time" Then
			created_time = Header[i].content;
		ElsIf Header[i].val = "Grand Total" Then
			grand_total = Number(Header[i].content);
		EndIf
	EndDo;
	Customer = Catalogs.Companies.FindByDescription(account_name);
	Lines = Lines.product;
	
	NewSO = Documents.SalesOrder.CreateDocument();
	NewSO.Company = Customer;
	//NewSO.CompanyCode = Customer.Code;
	NewSO.Date = created_time;
	NewSO.Location = Catalogs.Locations.MainWarehouse;
	NewSO.DocumentTotal = grand_total;
	NewSO.DocumentTotalRC = grand_total;
	Query = New Query("SELECT
	                  |	Addresses.Ref
	                  |FROM
	                  |	Catalog.Addresses AS Addresses
	                  |WHERE
	                  |	Addresses.Owner = &Customer
	                  |	AND Addresses.DefaultShipping = True");
	Query.SetParameter("Customer", Customer);
	Dataset = Query.Execute().Unload();
	NewSO.ShipTo = Dataset[0][0];
	NewSO.ExchangeRate = 1;
	NewSO.Memo = so_number;
	NewSO.Currency = Constants.DefaultCurrency.Get();
	
	NumOfLines = Lines.Count();
	For i = 0 To NumOfLines - 1 Do
		ProductLine = Lines[i].FL;
		
		PLRows = ProductLine.Count();
			For z = 0 To PLRows - 1 Do
			test = ProductLine[z].val;
			If ProductLine[z].val = "Product Name" Then
				product_name = ProductLine[z].content;
			ElsIf ProductLine[z].val = "Quantity" Then
				qty = Number(ProductLine[z].content);
			ElsIf ProductLine[z].val = "List Price" Then
				list_price = Number(ProductLine[z].content);
			EndIf;
				
		EndDo;
		
		SOLine = NewSO.LineItems.Add();
		SOLine.Product = Catalogs.Products.FindByCode(product_name);
		SOLine.ProductDescription = SOLine.Product.Description;
		SOLine.Price = list_price;
		SOLine.Quantity = qty;
		SOLine.LineTotal = list_price * qty;
		SOLine.SalesTaxType = US_FL.GetSalesTaxType(SOLine.Product);
		SOLine.VATCode = CommonUse.GetAttributeValue(SOLine.Product, "SalesVATCode");
	
	EndDo;
	
	NewSO.Write();
	
	
	// Display response to the user.
	//Return Response;
	
EndFunction
