


&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
		HeadersMap = New Map();
		HeadersMap.Insert("Content-Type", "application/json");
		
		HTTPRequest = New HTTPRequest("/api/1/clusters/rs-ds039921/databases/dataset1cproduction/collections/pay?apiKey=" + ServiceParameters.MongoAPIKey(), HeadersMap);
		
		RequestBodyMap = New Map();
		
		//SymbolString = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"; //62
		//RandomString20 = "";
		//RNG = New RandomNumberGenerator;	
		//For i = 0 to 19 Do
		//	RN = RNG.RandomNumber(1, 62);
		//	RandomString20 = RandomString20 + Mid(SymbolString,RN,1);
		//EndDo;
		
		RequestBodyMap.Insert("token", Object.Token);
		RequestBodyMap.Insert("type","monthly");
		RequestBodyMap.Insert("data_key",Constants.publishable_temp.get());
		RequestBodyMap.Insert("data_amount",Object.Amount * 100);
		RequestBodyMap.Insert("data_name",Constants.SystemTitle.Get());
		RequestBodyMap.Insert("data_description","Monthly subscription $" + Object.Amount);
		RequestBodyMap.Insert("live_secret",Constants.secret_temp.Get());
		
		RequestBodyString = InternetConnectionClientServer.EncodeJSON(RequestBodyMap);
		
		HTTPRequest.SetBodyFromString(RequestBodyString,TextEncoding.ANSI); // ,TextEncoding.ANSI
		
		SSLConnection = New OpenSSLSecureConnection();
		
		HTTPConnection = New HTTPConnection("api.mongolab.com",,,,,,SSLConnection);
		Result = HTTPConnection.Post(HTTPRequest);
		ResponseBody = Result.GetBodyAsString(TextEncoding.UTF8);
		
		// send e-mail
		
 //   	Query = New Query("SELECT
 //   						 |	Addresses.Email
 //   						 |FROM
 //   						 |	Catalog.Addresses AS Addresses
 //   						 |WHERE
 //   						 |	Addresses.Owner = &Company
 //   						 |	AND Addresses.DefaultBilling = True");
 //   		Query.SetParameter("Company", Object.Company);
 //   		QueryResult = Query.Execute().Unload();
 //   	   Recipient = QueryResult[0][0];
 //
 //   	FormatHTML = "<a href=""https://pay.accountingsuite.com/invoice?token=" + RandomString20 + """>Pay invoice</a>";
 //   	
 //   	HeadersMap = New Map();
 //   	HeadersMap.Insert("Content-Type", "application/json");
 //   	
 //   	HTTPRequest = New HTTPRequest("/sendemail", HeadersMap);
 //   	
 //   	RequestBodyMap = New Map();		
 //   	RequestBodyMap.Insert("recipient",Recipient);
 //   	RequestBodyMap.Insert("sender_email",Constants.Email.Get());
 //   	RequestBodyMap.Insert("sender_name",Constants.SystemTitle.Get());
 //   	RequestBodyMap.Insert("subject",Constants.SystemTitle.Get() + " - Invoice " + Object.Number + " from " + Format(Object.Date,"DLF=D") + " - $" + Object.DocumentTotalRC);
 //   	RequestBodyMap.Insert("html_body",FormatHTML);
 //   	
 //   	RequestBodyString = InternetConnectionClientServer.EncodeJSON(RequestBodyMap);
 //   	
 //   	HTTPRequest.SetBodyFromString(RequestBodyString,TextEncoding.ANSI); // ,TextEncoding.ANSI
 //   	
 //   	SSLConnection = New OpenSSLSecureConnection();
 //   	
 //   	HTTPConnection = New HTTPConnection("pay.accountingsuite.com",,,,,,SSLConnection);
 //   	Result = HTTPConnection.Post(HTTPRequest);

EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
		If Object.Ref.IsEmpty() Then
	
			SymbolString = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"; //62
			RandomString20 = "";
			RNG = New RandomNumberGenerator;	
			For i = 0 to 19 Do
				RN = RNG.RandomNumber(1, 62);
				RandomString20 = RandomString20 + Mid(SymbolString,RN,1);
			EndDo;
			
			Object.Token = RandomString20;
			Object.URL = "https://pay.accountingsuite.com/monthly?token=" + Object.Token;
			
		EndIf;

EndProcedure
