
Function receivewebhook(jsonin)
	
	// logging
	
	test = Catalogs.APITesting.CreateItem();
	test.dataset = jsonin;
	test.Write();
	
	//
	
	ParsedJSON = InternetConnectionClientServer.DecodeJSON(jsonin);
	order_id = ParsedJSON.data.id;
	
	//test = Catalogs.APITesting.CreateItem();
	//test.dataset = product_id;
	//test.Write();

	//
	
	HeadersMap = New Map();
	
	// get user name from a constant
	// get api token from a constant
	// result = base64(username:token)
	// put in the header  "Basic " + result
	//
	HeadersMap.Insert("Authorization", "Basic " + Constants.bigcom_base64.Get());
	
	HTTPRequest = New HTTPRequest("orders/" + order_id + ".json", HeadersMap);
	//HTTPRequest.SetBodyFromString("product=" + ThisObject.Description,TextEncoding.ANSI);
	
	SSLConnection = New OpenSSLSecureConnection();
	
	// get API URL (e.g. "store-dshn8.mybigcommerce.com/api/v2/");
	//
	HTTPConnection = New HTTPConnection(Constants.bigcom_apipath.Get(),,,,,,SSLConnection);
	Result = HTTPConnection.Get(HTTPRequest);
	ResponseBody = Result.GetBodyAsString(TextEncoding.UTF8);
	
	test = Catalogs.APITesting.CreateItem();
	test.dataset = ResponseBody;
	test.Write();
	
EndFunction
