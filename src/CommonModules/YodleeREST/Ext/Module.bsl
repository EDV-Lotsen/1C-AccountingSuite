////////////////////////////////////////////////////////////////////////////////
// Yodlee Integration REST: Server
//------------------------------------------------------------------------------
// Available on:
// - Server
//
////////////////////////////////////////////////////////////////////////////////

#Region PUBLIC_INTERFACE

// Logins user to Yodlee system
// Authenticates our cobrand credentials
// Records a session token, which expires every 100 minutes, to the DB
// Logs in the consumer(user). If it is a new yodlee consumer, it instead registers a new username/password
// Records a userSession token , which expires every 30 mins, to the DB
// Returns:
//  Structure :
//   Success - boolean - true if the function succeeded, false if the function  failed
//   ErrorDescription - string - if the function failed then contains a description of an error
Function LoginUser() Export
	
	Try
		ReturnStructure = New Structure("Success, ErrorDescription", False, "");
		If Not Constants.ServiceDB.Get() Then
			WriteLogEvent("Yodlee.LoginUser", EventLogLevel.Error,,, "User login failed. Login to Yodlee available only in the Service DB");
			ReturnStructure.success = False;
			ReturnStructure.ErrorDescription = "User login failed. Login to Yodlee available only in the Service DB";
			return ReturnStructure;
		EndIf;

		// Obtain Cob Session token
		// REST Method used: coblogin
		URLstring = "https://consolidatedsdk.yodlee.com/yodsoap/srest/yellowlabs/v1.0/authenticate/coblogin";
		InputParameters = New Structure();
		InputParameters.Insert("cobrandLogin",ServiceParameters.YodleeCobrandLogin());
		//InputParameters.Insert("cobrandLogin", "yellowlabsa");
		InputParameters.Insert("cobrandPassword",ServiceParameters.YodleeCobrandPassword());
		InputData = InternetConnectionClientServer.EncodeQueryData(InputParameters);
	
		ConnectionSettings = New Structure;
		Connection = InternetConnectionClientServer.CreateConnection(URLstring + "?" + InputData, ConnectionSettings).Result;
		ResultBody = InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings);
		
		ResultBodyJSON = ProcessRESTResult(ResultBody, ReturnStructure, "Yodlee.LoginUser", "Error occurred while obtaining CobSessionToken: ");
	
		If ResultBodyJSON = Undefined Then
			return ReturnStructure;
		Else
			cobSessionToken = ResultBodyJSON.cobrandConversationCredentials.sessionToken;
			Constants.YodleeCobSessionToken.Set(cobSessionToken);
		EndIf;

		// Obtain user session token
		UserName = Constants.YodleeUserName.Get();
		UserPassword = Constants.YodleeUserPassword.Get();
		
		If Not ValueIsFilled(UserName) Then //Register the new user
			Result = RegisterUser(cobSessionToken);
			If Result.success Then
				WriteLogEvent("Yodlee.LoginUser", EventLogLevel.Information,,, "User logged in successfully");
			Else
				WriteLogEvent("Yodlee.LoginUser", EventLogLevel.Error,,, "User login failed. Error message: " + Result.ErrorDescription);
			EndIf;
			return Result;
		Else // Login the user
			
			URLstring = "https://consolidatedsdk.yodlee.com/yodsoap/srest/yellowlabs/v1.0/authenticate/login";
		
			InputParameters = New Structure();
			InputParameters.Insert("cobSessionToken", cobSessionToken);
			InputParameters.Insert("login", UserName);
			InputParameters.Insert("password", UserPassword);
			InputData = InternetConnectionClientServer.EncodeQueryData(InputParameters);
		
			ConnectionSettings = New Structure;
			Connection = InternetConnectionClientServer.CreateConnection(URLstring + "?" + InputData, ConnectionSettings).Result;
			ResultBody = InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings);
			
			ResultBodyJSON = ProcessRESTResult(ResultBody, ReturnStructure, "Yodlee.LoginUser", "User login failed. Error message: ");
	
			If ResultBodyJSON = Undefined Then
				return ReturnStructure;
			Else
				SessionToken = ResultBodyJSON.userContext.conversationCredentials.sessionToken;
				Constants.YodleeUserSessionToken.Set(SessionToken);
				WriteLogEvent("Yodlee.LoginUser", EventLogLevel.Information,,, "User logged in successfully");
				ReturnStructure.success = True;
				return ReturnStructure;
			EndIf;

		EndIf;
		
	Except
		ErrorDescription = ErrorDescription();
		WriteLogEvent("Yodlee.LoginUser", EventLogLevel.Error,,, ErrorDescription);
		ReturnStructure.success 			= False;
		ReturnStructure.ErrorDescription 	= ErrorDescription;
		return ReturnStructure;
	EndTry;	
	
EndFunction

// Gets the details of the content service associated to the ID, which refers to a specific container(bank)
// Returns in data JSON string form 
Function GetContentServiceInfo1_Rest(contentServiceId) Export
	
	Try
		ReturnStructure = New Structure("Success, ErrorDescription, Result", False, "", Undefined);
		ItemIdDescription = "ContentServiceId: " + Format(contentServiceId, "NGS=' '; NZ=") + ".";
		If Not Constants.ServiceDB.Get() Then
			WriteLogEvent("Yodlee.GetContentServiceInfo1", EventLogLevel.Error,,, "Yodlee is available only in the Service DB");
			ReturnStructure.success = False;
			ReturnStructure.ErrorDescription = "Yodlee is available only in the Service DB";
			return ReturnStructure;
		EndIf;

		URLstring = "https://consolidatedsdk.yodlee.com/yodsoap/srest/yellowlabs/v1.0/jsonsdk/ContentServiceTraversal/getContentServiceInfo1";
		InputParameters = New Structure();
		InputParameters.Insert("cobSessionToken", Constants.YodleeCobSessionToken.Get());
		InputParameters.Insert("contentServiceId", ContentServiceID);
		InputParameters.Insert("reqSpecifier", "128");
		InputParameters.Insert("notrim", "true");
	
		InputData = InternetConnectionClientServer.EncodeQueryData(InputParameters);
		
		ConnectionSettings = New Structure;
		Connection = InternetConnectionClientServer.CreateConnection(URLstring + "?" + InputData, ConnectionSettings).Result;
	
		ResultBody = InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings);
	
		ResultBodyJSON = ProcessRESTResult(ResultBody, ReturnStructure, "Yodlee.GetContentServiceInfo1", ItemIdDescription);
	
		If ResultBodyJSON = Undefined Then
			return ReturnStructure;
		Else
			ReturnStructure.Result = ResultBodyJSON;
			return ReturnStructure;
		EndIf;
	Except
		ErrorDescription = ErrorDescription();
		WriteLogEvent("Yodlee.GetContentServiceInfo1", EventLogLevel.Error,,, ErrorDescription);
		ReturnStructure.success 			= False;
		ReturnStructure.ErrorDescription 	= ErrorDescription;
		return ReturnStructure;
	EndTry;
		
EndFunction

// Tells Yodlee to refresh the specified item.
// Returns a JSON string with statusCode
Function StartRefresh7_Rest(itemId, isMFA) Export
	
	Try
		ReturnStructure = New Structure("Success, ErrorDescription, Result", False, "", Undefined);
		ItemIdDescription = "ItemID: " + Format(itemId, "NGS=' '; NZ=") + ".";
		If Not Constants.ServiceDB.Get() Then
			WriteLogEvent("Yodlee.StartRefresh7", EventLogLevel.Error,,, "Yodlee is available only in the Service DB");
			ReturnStructure.success = False;
			ReturnStructure.ErrorDescription = "Yodlee is available only in the Service DB";
			return ReturnStructure;
		EndIf;

		URLstring = "https://consolidatedsdk.yodlee.com/yodsoap/srest/yellowlabs/v1.0/jsonsdk/Refresh/startRefresh7";
	
		InputParameters = New Structure();
		InputParameters.Insert("cobSessionToken", Constants.YodleeCobSessionToken.Get());
		InputParameters.Insert("userSessionToken", Constants.YodleeUserSessionToken.Get());
		InputParameters.Insert("itemId", itemId);
		If isMFA Then
			InputParameters.Insert("refreshParametersrefreshModerefreshMode", "MFA");
			InputParameters.Insert("refreshParametersrefreshModerefreshModeId", 1);
		Else
			InputParameters.Insert("refreshParametersrefreshModerefreshMode", "NORMAL");
			InputParameters.Insert("refreshParametersrefreshModerefreshModeId", 2);
		EndIf;
		InputParameters.Insert("refreshParametersrefreshPriority", 1); // High Priority 
	
		InputData = InternetConnectionClientServer.EncodeQueryData(InputParameters);
		InputData = StrReplace(InputData,"refreshParametersrefreshModerefreshMode","refreshParameters.refreshMode.refreshMode");
		InputData = StrReplace(InputData,"refreshParametersrefreshModerefreshModeId","refreshParameters.refreshMode.refreshModeId");
		InputData = StrReplace(InputData,"refreshParametersrefreshPriority","refreshParameters.refreshPriority");
	
		ConnectionSettings = New Structure;
		Connection = InternetConnectionClientServer.CreateConnection(URLstring + "?" + InputData, ConnectionSettings).Result;
	
		ResultBody = InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings);
	
		ResultBodyJSON = ProcessRESTResult(ResultBody, ReturnStructure, "Yodlee.StartRefresh7", ItemIdDescription);
	
		If ResultBodyJSON = Undefined Then
			return ReturnStructure;
		Else
			ReturnStructure.Result = ResultBodyJSON;
			return ReturnStructure;
		EndIf;
	Except
		ErrorDescription = ErrorDescription();
		WriteLogEvent("Yodlee.StartRefresh7", EventLogLevel.Error,,, ErrorDescription);
		ReturnStructure.success 			= False;
		ReturnStructure.ErrorDescription 	= ErrorDescription;
		return ReturnStructure;
	EndTry;

EndFunction

// Checks if the account is still being refreshed
// Returns a boolean value in a JSON string
Function IsItemRefreshing_REST(itemId) Export
	
	Try
		ReturnStructure = New Structure("Success, ErrorDescription, Result", False, "", Undefined);
		ItemIdDescription = "ItemID: " + Format(itemId, "NGS=' '; NZ=") + ".";
		If Not Constants.ServiceDB.Get() Then
			WriteLogEvent("Yodlee.IsItemRefreshing", EventLogLevel.Error,,, "Yodlee is available only in the Service DB");
			ReturnStructure.success = False;
			ReturnStructure.ErrorDescription = "Yodlee is available only in the Service DB";
			return ReturnStructure;
		EndIf;

		URLstring = "https://consolidatedsdk.yodlee.com/yodsoap/srest/yellowlabs/v1.0/jsonsdk/Refresh/isItemRefreshing";
		
		InputParameters = New Structure();
		InputParameters.Insert("cobSessionToken", Constants.YodleeCobSessionToken.Get());
		InputParameters.Insert("userSessionToken", Constants.YodleeUserSessionToken.Get());
		InputParameters.Insert("memItemId", itemId);
		InputData = InternetConnectionClientServer.EncodeQueryData(InputParameters);
	
		ConnectionSettings = New Structure;
		Connection = InternetConnectionClientServer.CreateConnection(URLstring + "?" + InputData, ConnectionSettings).Result;
	
		ResultBody = InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings);
		ResultBodyJSON = ProcessRESTResult(ResultBody, ReturnStructure, "Yodlee.IsItemRefreshing", ItemIdDescription);
	
		If ResultBodyJSON = Undefined Then
			return ReturnStructure;
		Else
			ReturnStructure.Result = ResultBodyJSON;
			return ReturnStructure;
		EndIf;
		
	Except
		ErrorDescription = ErrorDescription();
		WriteLogEvent("Yodlee.IsItemRefreshing", EventLogLevel.Error,,, ErrorDescription);
		ReturnStructure.success 			= False;
		ReturnStructure.ErrorDescription 	= ErrorDescription;
		return ReturnStructure;
	EndTry;
	
EndFunction

// Provides info for object recently refreshed
// Returns a Data JSON string
Function GetRefreshInfo1_REST(itemId) Export
	
	Try
		ReturnStructure = New Structure("Success, ErrorDescription, Result", False, "", Undefined);
		ItemIdDescription = "ItemID: " + Format(itemId, "NGS=' '; NZ=") + ".";
		If Not Constants.ServiceDB.Get() Then
			WriteLogEvent("Yodlee.GetRefreshInfo1", EventLogLevel.Error,,, "Yodlee is available only in the Service DB");
			ReturnStructure.success = False;
			ReturnStructure.ErrorDescription = "Yodlee is available only in the Service DB";
			return ReturnStructure;
		EndIf;

		URLstring = "https://consolidatedsdk.yodlee.com/yodsoap/srest/yellowlabs/v1.0/jsonsdk/Refresh/getRefreshInfo1";
					
		InputParameters = New Structure();
		InputParameters.Insert("cobSessionToken", Constants.YodleeCobSessionToken.Get());
		InputParameters.Insert("userSessionToken", Constants.YodleeUserSessionToken.Get());
		InputParameters.Insert("itemIds0", itemId);
	
		InputData = InternetConnectionClientServer.EncodeQueryData(InputParameters);
		InputData = StrReplace(InputData,"itemIds0","itemIds[0]");
	
		ConnectionSettings = New Structure;
		Connection = InternetConnectionClientServer.CreateConnection(URLstring + "?" + InputData, ConnectionSettings).Result;
	
		ResultBody = InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings);
		ResultBodyJSON = ProcessRESTResult(ResultBody, ReturnStructure, "Yodlee.GetRefreshInfo1", ItemIdDescription);
		
		If ResultBodyJSON = Undefined Then
			return ReturnStructure;
		Else
			ReturnStructure.Result = ResultBodyJSON;
			return ReturnStructure;
		EndIf;		
		
	Except
		ErrorDescription = ErrorDescription();
		WriteLogEvent("Yodlee.GetRefreshInfo1", EventLogLevel.Error,,, ErrorDescription);
		ReturnStructure.success 			= False;
		ReturnStructure.ErrorDescription 	= ErrorDescription;
		return ReturnStructure;
	EndTry;
	
EndFunction

// Retrieves details about an item(bank acocunt)
// Returns a Data JSON string
Function GetItemSummaryForItem1_REST(itemId) Export
	
	Try
		ReturnStructure = New Structure("Success, ErrorDescription, Result", False, "", Undefined);
		ItemIdDescription = "ItemID: " + Format(itemId, "NGS=' '; NZ=") + ".";
		If Not Constants.ServiceDB.Get() Then
			WriteLogEvent("Yodlee.GetItemSummaryForItem1", EventLogLevel.Error,,, "Yodlee is available only in the Service DB");
			ReturnStructure.success = False;
			ReturnStructure.ErrorDescription = "Yodlee is available only in the Service DB";
			return ReturnStructure;
		EndIf;

		URLstring = "https://consolidatedsdk.yodlee.com/yodsoap/srest/yellowlabs/v1.0/jsonsdk/DataService/getItemSummaryForItem1";
				
		InputParameters = New Structure();
		InputParameters.Insert("cobSessionToken", Constants.YodleeCobSessionToken.Get());
		InputParameters.Insert("userSessionToken", Constants.YodleeUserSessionToken.Get());
		InputParameters.Insert("itemId", itemId);
		InputParameters.Insert("dexstartLevel", 0);
		InputParameters.Insert("dexendLevel", 0);
		InputParameters.Insert("dexextentLevels0", 4);
		InputParameters.Insert("dexextentLevels1", 4);
	
		InputData = InternetConnectionClientServer.EncodeQueryData(InputParameters);
		InputData = StrReplace(InputData,"dexstartLevel","dex.startLevel");
		InputData = StrReplace(InputData,"dexendLevel","dex.endLevel");
		InputData = StrReplace(InputData,"dexextentLevels0","dex.extentLevels[0]");
		InputData = StrReplace(InputData,"dexextentLevels1","dex.extentLevels[1]");
	
		ConnectionSettings = New Structure;
		Connection = InternetConnectionClientServer.CreateConnection(URLstring + "?" + InputData, ConnectionSettings).Result;
	
		ResultBody = InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings);
		ResultBodyJSON = ProcessRESTResult(ResultBody, ReturnStructure, "Yodlee.GetItemSummaryForItem1", ItemIdDescription);
		
		If ResultBodyJSON = Undefined Then
			return ReturnStructure;
		Else
			ReturnStructure.Result = ResultBodyJSON;
			return ReturnStructure;
		EndIf;		
	
	Except
		ErrorDescription = ErrorDescription();
		WriteLogEvent("Yodlee.GetItemSummaryForItem1", EventLogLevel.Error,,, ErrorDescription);
		ReturnStructure.success 			= False;
		ReturnStructure.ErrorDescription 	= ErrorDescription;
		return ReturnStructure;
	EndTry;

EndFunction

// Gets the last FetchLimit transactions from LastDate to the current date of the given account
// Returns in a Data JSON string
Function ExecuteUserSearchRequest_REST(ItemAccountID, FromDate, ToDate = Undefined, StartRange, FetchLimit) Export
	
	Try
		ReturnStructure = New Structure("Success, ErrorDescription, Result", False, "", Undefined);
		ItemIdDescription = "ItemAccountID: " + Format(ItemAccountId, "NGS=' '; NZ=") + ".";
		If Not Constants.ServiceDB.Get() Then
			WriteLogEvent("Yodlee.ExecuteUserSearchRequest", EventLogLevel.Error,,, "Yodlee is available only in the Service DB");
			ReturnStructure.success = False;
			ReturnStructure.ErrorDescription = "Yodlee is available only in the Service DB";
			return ReturnStructure;
		EndIf;

		URLstring = "https://consolidatedsdk.yodlee.com/yodsoap/srest/yellowlabs/v1.0/jsonsdk/TransactionSearchService/executeUserSearchRequest";
		
		FromDateFormatted = Format(FromDate, "DF=MM-dd-yyyy");
		If ToDate <> Undefined Then
			ToDateFormatted = Format(ToDate, "DF=MM-dd-yyyy");
		EndIf;
		
		EndRange 	= StartRange + FetchLimit - 1;
				
		InputParameters = New Structure();
		InputParameters.Insert("cobSessionToken", Constants.YodleeCobSessionToken.Get());
		InputParameters.Insert("userSessionToken", Constants.YodleeUserSessionToken.Get());
		InputParameters.Insert("transactionSearchRequestcontainerType", "All");
		InputParameters.Insert("transactionSearchRequesthigherFetchLimit", EndRange);
		InputParameters.Insert("transactionSearchRequestlowerFetchLimit", StartRange);
		InputParameters.Insert("transactionSearchRequestresultRangeendNumber", EndRange);
		InputParameters.Insert("transactionSearchRequestresultRangestartNumber", StartRange);
		InputParameters.Insert("transactionSearchRequestfirstCall", ?(StartRange = 1, "true", "false"));
		InputParameters.Insert("transactionSearchRequestsearchClientsclientId", 1);
		InputParameters.Insert("transactionSearchRequestsearchClientsclientName", "DataSearchService");
		//InputParameters.Insert("transactionSearchRequestsearchClients", "DEFAULT_SERVICE_CLIENT");
		InputParameters.Insert("transactionSearchRequestsearchFiltercurrencyCode", "USD");
		InputParameters.Insert("transactionSearchRequestignoreUserInput", "true");
		InputParameters.Insert("transactionSearchRequestsearchFiltertransactionSplitType", "ALL_TRANSACTION");
		InputParameters.Insert("transactionSearchRequestsearchFilteritemAccountIdidentifier", ItemAccountID);
		If ToDate <> Undefined Then 
			InputParameters.Insert("transactionSearchRequestsearchFilterpostDateRangetoDate", ToDateFormatted);
		EndIf;
		InputParameters.Insert("transactionSearchRequestsearchFilterpostDateRangefromDate", FromDateFormatted);
					
		InputData = InternetConnectionClientServer.EncodeQueryData(InputParameters);
		InputData = StrReplace(InputData,"transactionSearchRequestcontainerType","transactionSearchRequest.containerType");
		InputData = StrReplace(InputData,"transactionSearchRequesthigherFetchLimit","transactionSearchRequest.higherFetchLimit");
		InputData = StrReplace(InputData,"transactionSearchRequestlowerFetchLimit","transactionSearchRequest.lowerFetchLimit");
		InputData = StrReplace(InputData,"transactionSearchRequestresultRangeendNumber","transactionSearchRequest.resultRange.endNumber");
		InputData = StrReplace(InputData,"transactionSearchRequestresultRangestartNumber","transactionSearchRequest.resultRange.startNumber");
		InputData = StrReplace(InputData,"transactionSearchRequestsearchFiltercurrencyCode","transactionSearchRequest.searchFilter.currencyCode");
		InputData = StrReplace(InputData,"transactionSearchRequestignoreUserInput","transactionSearchRequest.ignoreUserInput");
		InputData = StrReplace(InputData,"transactionSearchRequestsearchFilteritemAccountIdidentifier","transactionSearchRequest.searchFilter.itemAccountId.identifier");
		InputData = StrReplace(InputData,"transactionSearchRequestsearchFilterpostDateRangetoDate","transactionSearchRequest.searchFilter.postDateRange.toDate");
		InputData = StrReplace(InputData,"transactionSearchRequestsearchFilterpostDateRangefromDate","transactionSearchRequest.searchFilter.postDateRange.fromDate");
		InputData = StrReplace(InputData,"transactionSearchRequestfirstCall","transactionSearchRequest.firstCall");
		InputData = StrReplace(InputData,"transactionSearchRequestsearchClientsclientId","transactionSearchRequest.searchClients.clientId");
		InputData = StrReplace(InputData,"transactionSearchRequestsearchClientsclientName","transactionSearchRequest.searchClients.clientName");
		InputData = StrReplace(InputData,"transactionSearchRequestsearchClients","transactionSearchRequest.searchClients");
		InputData = StrReplace(InputData,"transactionSearchRequestsearchFiltertransactionSplitType","transactionSearchRequest.searchFilter.transactionSplitType");
		
		ConnectionSettings = New Structure;
		Connection = InternetConnectionClientServer.CreateConnection(URLstring + "?" + InputData, ConnectionSettings).Result;
		NumericFields = New Array();
		NumericFields.Add("transactionSearchRequest.searchFilter.itemAccountId.identifier");
		FixPossibleDatesAsNumeric(ConnectionSettings, NumericFields);
		ResultBody = InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings);
		ResultBody.Result = StrReplace(ResultBody.Result,"""transactionId"":","""transactionId"":""");
		ResultBody.Result = StrReplace(ResultBody.Result,",""containerType",""",""containerType");
		
		ResultBodyJSON = ProcessRESTResult(ResultBody, ReturnStructure, "Yodlee.ExecuteUserSearchRequest", ItemIdDescription);
		
		If ResultBodyJSON = Undefined Then
			return ReturnStructure;
		Else
			ReturnStructure.Result = ResultBodyJSON;
			return ReturnStructure;
		EndIf;		
		
	Except
		ErrorDescription = ErrorDescription();
		WriteLogEvent("Yodlee.ExecuteUserSearchRequest", EventLogLevel.Error,,, ErrorDescription);
		ReturnStructure.success 			= False;
		ReturnStructure.ErrorDescription 	= ErrorDescription;
		return ReturnStructure;
	EndTry;	
	
EndFunction

// Provides a list of fields needed to create a login form associated with the give contentServiceId
// Returns a data JSON string
Function GetLoginFormForContentService_REST(contentServiceId) Export 
	
	Try
		ReturnStructure = New Structure("Success, ErrorDescription, Result", False, "", Undefined);
		ItemIdDescription = "contentServiceId: " + Format(contentServiceId, "NGS=' '; NZ=") + ".";
		If Not Constants.ServiceDB.Get() Then
			WriteLogEvent("Yodlee.GetLoginFormForContentService", EventLogLevel.Error,,, "Yodlee is available only in the Service DB");
			ReturnStructure.success = False;
			ReturnStructure.ErrorDescription = "Yodlee is available only in the Service DB";
			return ReturnStructure;
		EndIf;

		URLstring = "https://consolidatedsdk.yodlee.com/yodsoap/srest/yellowlabs/v1.0/jsonsdk/ItemManagement/getLoginFormForContentService";
		
		InputParameters = New Structure();
		InputParameters.Insert("cobSessionToken", Constants.YodleeCobSessionToken.Get());
		InputParameters.Insert("contentServiceId", ContentServiceID);
		InputData = InternetConnectionClientServer.EncodeQueryData(InputParameters);
	
		ConnectionSettings = New Structure;
		Connection = InternetConnectionClientServer.CreateConnection(URLstring + "?" + InputData, ConnectionSettings).Result;
	
		ResultBody = InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings);
		
		ResultBodyJSON = ProcessRESTResult(ResultBody, ReturnStructure, "Yodlee.GetLoginFormForContentService", ItemIdDescription);
		
		If ResultBodyJSON = Undefined Then
			return ReturnStructure;
		Else
			ReturnStructure.Result = ResultBodyJSON;
			return ReturnStructure;
		EndIf;		
		
	Except
		ErrorDescription = ErrorDescription();
		WriteLogEvent("Yodlee.GetLoginFormForContentService", EventLogLevel.Error,,, ErrorDescription);
		ReturnStructure.success 			= False;
		ReturnStructure.ErrorDescription 	= ErrorDescription;
		return ReturnStructure;
	EndTry;	
	
EndFunction

// This REST API retrieves the intermediate response for MFA enabled sites and provides the MFA related field information 
// that can be one of the following types: image, security question, or token. 
Function GetMFAResponse_REST(itemId) Export
	
	Try
		ReturnStructure = New Structure("Success, ErrorDescription, Result", False, "", Undefined);
		ItemIdDescription = "ItemID: " + Format(itemId, "NGS=' '; NZ=") + ".";
		If Not Constants.ServiceDB.Get() Then
			WriteLogEvent("Yodlee.GetMFAResponse", EventLogLevel.Error,,, "Yodlee is available only in the Service DB");
			ReturnStructure.success = False;
			ReturnStructure.ErrorDescription = "Yodlee is available only in the Service DB";
			return ReturnStructure;
		EndIf;

		URLstring = "https://consolidatedsdk.yodlee.com/yodsoap/srest/yellowlabs/v1.0/jsonsdk/Refresh/getMFAResponse";
		
		InputParameters = New Structure();
		InputParameters.Insert("cobSessionToken", Constants.YodleeCobSessionToken.Get());
		InputParameters.Insert("userSessionToken", Constants.YodleeUserSessionToken.Get());
		InputParameters.Insert("itemId", itemId);
		InputData = InternetConnectionClientServer.EncodeQueryData(InputParameters);
	
		ConnectionSettings = New Structure;
		Connection = InternetConnectionClientServer.CreateConnection(URLstring + "?" + InputData, ConnectionSettings).Result;
	
		ResultBody = InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings);
		ResultBodyJSON = ProcessRESTResult(ResultBody, ReturnStructure, "Yodlee.GetMFAResponse", ItemIdDescription);
	
		If ResultBodyJSON = Undefined Then
			return ReturnStructure;
		Else
			ReturnStructure.Result = ResultBodyJSON;
			return ReturnStructure;
		EndIf;
		
	Except
		ErrorDescription = ErrorDescription();
		WriteLogEvent("Yodlee.GetMFAResponse", EventLogLevel.Error,,, ErrorDescription);
		ReturnStructure.success 			= False;
		ReturnStructure.ErrorDescription 	= ErrorDescription;
		return ReturnStructure;
	EndTry;
	
EndFunction

// This REST API is to be used to send the intermediate response given by the consumer to the site.
//
Function PutMFARequest_REST(itemId, ProgrammaticElems) Export
	
	Try
		ReturnStructure = New Structure("Success, ErrorDescription, Result", False, "", Undefined);
		ItemIdDescription = "ItemID: " + Format(itemId, "NGS=' '; NZ=") + ".";
		If Not Constants.ServiceDB.Get() Then
			WriteLogEvent("Yodlee.PutMFARequest", EventLogLevel.Error,,, "Yodlee is available only in the Service DB");
			ReturnStructure.success = False;
			ReturnStructure.ErrorDescription = "Yodlee is available only in the Service DB";
			return ReturnStructure;
		EndIf;

		URLstring = "https://consolidatedsdk.yodlee.com/yodsoap/srest/yellowlabs/v1.0/jsonsdk/Refresh/putMFARequest";
		
		InputParameters = New Structure();
		InputParameters.Insert("cobSessionToken", Constants.YodleeCobSessionToken.Get());
		InputParameters.Insert("userSessionToken", Constants.YodleeUserSessionToken.Get());
		InputParameters.Insert("itemId", itemId);
		For Each ProgrammaticElem In ProgrammaticElems Do 
			If ProgrammaticElem.ElementName = "Token" Then
				InputParameters.Insert("userResponseobjectInstanceType", "com.yodlee.core.mfarefresh.MFATokenResponse");
				InputParameters.Insert("userResponsetoken", ProgrammaticElem.ElementValue);
			ElsIf Find(ProgrammaticElem.ElementName, "Question") > 0 Then
				InputParameters.Insert("userResponseobjectInstanceType", "com.yodlee.core.mfarefresh.MFAQuesAnsResponse");
			EndIf;
		EndDo;
		
		InputData = InternetConnectionClientServer.EncodeQueryData(InputParameters);
		InputData = StrReplace(InputData, "userResponseobjectInstanceType", "userResponse.objectInstanceType");
		InputData = StrReplace(InputData, "userResponsetoken", "userResponse.token");
	
		ConnectionSettings = New Structure;
		Connection = InternetConnectionClientServer.CreateConnection(URLstring + "?" + InputData, ConnectionSettings).Result;
	
		ResultBody = InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings);
		ResultBodyJSON = ProcessRESTResult(ResultBody, ReturnStructure, "Yodlee.PutMFARequest", ItemIdDescription);
	
		If ResultBodyJSON = Undefined Then
			return ReturnStructure;
		Else
			ReturnStructure.Result = ResultBodyJSON;
			return ReturnStructure;
		EndIf;
		
	Except
		ErrorDescription = ErrorDescription();
		WriteLogEvent("Yodlee.PutMFARequest", EventLogLevel.Error,,, ErrorDescription);
		ReturnStructure.success 			= False;
		ReturnStructure.ErrorDescription 	= ErrorDescription;
		return ReturnStructure;
	EndTry;
	
EndFunction

Procedure StopRefresh_REST(itemId) Export
	
	Try
		ItemIdDescription = "ItemID: " + Format(itemId, "NGS=' '; NZ=") + ".";
		If Not Constants.ServiceDB.Get() Then
			WriteLogEvent("Yodlee.StopRefresh", EventLogLevel.Error,,, "Yodlee is available only in the Service DB");
		EndIf;

		URLstring = "https://consolidatedsdk.yodlee.com/yodsoap/srest/yellowlabs/v1.0/jsonsdk/Refresh/stopRefresh";
					
		InputParameters = New Structure();
		InputParameters.Insert("cobSessionToken", Constants.YodleeCobSessionToken.Get());
		InputParameters.Insert("userSessionToken", Constants.YodleeUserSessionToken.Get());
		InputParameters.Insert("itemId", itemId);
		InputParameters.Insert("reason", "101");
	
		InputData = InternetConnectionClientServer.EncodeQueryData(InputParameters);
			
		ConnectionSettings = New Structure;
		Connection = InternetConnectionClientServer.CreateConnection(URLstring + "?" + InputData, ConnectionSettings).Result;
	
		ResultBody = InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings);
						
	Except
		ErrorDescription = ErrorDescription();
		WriteLogEvent("Yodlee.StopRefresh", EventLogLevel.Error,,, ErrorDescription);
	EndTry;

EndProcedure

Function AddItem_GetFormFields(contentServiceId, TempStorageAddress) Export
	
	Try
		ReturnStructure = New Structure("ReturnValue, ProgrammaticElements, ProgrammaticElementsValidValues");
		
		ResultStructure = YodleeREST.LoginUser();
		If Not ResultStructure.success Then // Call SOAP method
			PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "Login failed...", 1), TempStorageAddress);
		EndIf;
		
		LoginFormDescription = GetLoginFormForContentService_REST(contentServiceId);
		
		FormFields = LoginFormDescription.Result.ComponentList; 
		ProgrammaticElements = New Array();
		ProgrammaticElementsValidValues = New Array();
		
		For Each fieldInfo In FormFields Do
			//Process FieldInfoSingle field
			If fieldInfo.fieldInfoType = "com.yodlee.common.FieldInfoSingle" Then
				dispValidValues = New Array();
				valValues 		= New Array();
				valueIdentifier 	= fieldInfo.valueIdentifier;
				NewPE	= New Structure("ElementName, ElementOriginalName, DisplayName, MaxLength, FieldType");
				ProgrammaticElements.Add(NewPE);
				FoundRows = FindRows(ProgrammaticElements, New Structure("ElementOriginalName", valueIdentifier));
				If FoundRows.Count()>0 Then
					Prefix = "Yodlee" + String(FoundRows.Count()) + "_";
				Else
					Prefix = "Yodlee_";
				EndIf;
				NewPE.ElementOriginalName = valueIdentifier;
				NewPE.ElementName = Prefix + valueIdentifier;
				NewPE.DisplayName 	= fieldInfo.DisplayName; 
				If fieldInfo.Property("displayValidValues") Then
					displayValidValues 	= fieldInfo.displayValidValues;
					i = 0;
					While i < displayValidValues.Count() Do
						Message(displayValidValues[i]);
						newPEValVal = New Structure("ValidValue, DisplayValidValue, ElementName, Serial");
						ProgrammaticElementsValidValues.Add(newPEValVal);
						newPEValVal.DisplayValidValue 	= displayValidValues[i];
						newPEValVal.ElementName 		= NewPE.ElementName;
						newPEValVal.Serial 				= i + 1;
						i = i + 1;
					EndDo;
				EndIf;
				If fieldInfo.Property("validValues") Then
					For i = 0 To fieldInfo.validValues.Count()-1 Do
						PEValValStr = FindRows(ProgrammaticElementsValidValues, New Structure("ElementName, Serial", NewPE.ElementName, i + 1));
						If PEValValStr.Count() > 0 Then
							PEValValStr[0].ValidValue = fieldInfo.validValues[i];
						EndIf;
					EndDo;
				EndIf;

				NewPE.MaxLength 			= fieldInfo.maxlength;
				NewPE.FieldType 			= GetFieldType(fieldInfo.fieldType);
				
			//Process FieldInfoMultiFixed field
			ElsIf fieldInfo.fieldInfoType = "com.yodlee.common.FieldInfoMultiFixed" Then
				//Message("========MultiFixed========");			
			EndIf;			
		EndDo;
		//Check if there is a single password field then add Re-enter field
		FoundRows = FindRows(ProgrammaticElements, New Structure("FieldType", 1));
		If FoundRows.Count() = 1 Then
			i = 0;
			While i < ProgrammaticElements.Count() Do
				If ProgrammaticElements[i].FieldType = 1 Then
					StructCopy = New FixedStructure(ProgrammaticElements[i]);
					NewPElt = New Structure(StructCopy);
					NewPElt.DisplayName = "Re-enter " + NewPElt.DisplayName;
					NewPElt.ElementName = "Yodlee1_" + NewPElt.ElementOriginalName;
					ProgrammaticElements.Insert(i + 1, NewPElt);
					Break;
				EndIf;
				i = i + 1;
			EndDo;
		EndIf;
		
		ReturnStructure.Insert("ReturnValue", True);
		ReturnStructure.Insert("ProgrammaticElements", ProgrammaticElements);
		ReturnStructure.Insert("ProgrammaticElementsValidValues", ProgrammaticElementsValidValues);
		ReturnStructure.Insert("ComponentList", FormFields);
		
		PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "Obtained MFA fields from server...", 1), TempStorageAddress);
		
	Except
		ErrorDescription = ErrorDescription();
		WriteLogEvent("Yodlee.AddItem_GetFormFields", EventLogLevel.Error,,, "contentServiceId:" + Format(contentServiceId, "NGS=' '; NZ=; NG=3,0") + ";" + ErrorDescription);
		ReturnStructure.ReturnValue = False;
		ReturnStructure.Status 		= "An unexpected error occurred. See log for details.";
		PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "An unexpected error occurred. See log for details.", 1), TempStorageAddress);
		
	EndTry;

	return ReturnStructure;
	
EndFunction

Function AddItem_AddItem(ServiceID, ProgrammaticElems, ComponentList, TempStorageAddress) Export
	
	Try
		ReturnStructure = new Structure("NewItemID", 0);
		ItemIdDescription = "Adding an account for the contentServiceId: " + Format(ServiceId, "NGS=' '; NZ=") + ".";
		
		URLstring = "https://consolidatedsdk.yodlee.com/yodsoap/srest/yellowlabs/v1.0/jsonsdk/ItemManagement/addItemForContentService1";
			
		InputParameters = New Structure();
		InputParameters.Insert("cobSessionToken", Constants.YodleeCobSessionToken.Get());
		InputParameters.Insert("userSessionToken", Constants.YodleeUserSessionToken.Get());
		InputParameters.Insert("contentServiceId", ServiceId);
		InputParameters.Insert("credentialFieldsenclosedType", "com.yodlee.common.FieldInfoSingle");
		InputParameters.Insert("shareCredentialsWithinSite", "true");
		InputParameters.Insert("startRefreshItemOnAddition", "true");
		
		InputData = InternetConnectionClientServer.EncodeQueryData(InputParameters);
		InputData = StrReplace(InputData,"credentialFieldsenclosedType","credentialFields.enclosedType");
		
		count = 0;
		For each credField in ComponentList Do
			InputData = InputData + "&" + "credentialFields[" + count + "]." + "valueIdentifier" + "=" + credField.valueIdentifier;
			
			ElementName = "Yodlee_" + credField.valueIdentifier;
			FoundRows = FindRows(ProgrammaticElems, New Structure("ElementName", ElementName));
			
			InputData = InputData + "&" + "credentialFields[" + count + "]." + "value" + "=" + FoundRows[0].ElementValue;
			InputData = InputData + "&" + "credentialFields[" + count + "]." + "valueMask" + "=" + credField.valueMask;
			InputData = InputData + "&" + "credentialFields[" + count + "]." + "fieldType.typeName" + "=" + credField.fieldType.typeName;
			InputData = InputData + "&" + "credentialFields[" + count + "]." + "size" + "=" + credField.size;
			InputData = InputData + "&" + "credentialFields[" + count + "]." + "maxlength" + "=" + credField.maxlength;
			InputData = InputData + "&" + "credentialFields[" + count + "]." + "name" + "=" + credField.name;
			InputData = InputData + "&" + "credentialFields[" + count + "]." + "displayName" + "=" + credField.displayName;
			InputData = InputData + "&" + "credentialFields[" + count + "]." + "isEditable" + "=" + credField.isEditable;
			InputData = InputData + "&" + "credentialFields[" + count + "]." + "isOptional" + "=" + credField.isOptional;
			InputData = InputData + "&" + "credentialFields[" + count + "]." + "isEscaped" + "=" + credField.isEscaped;
			InputData = InputData + "&" + "credentialFields[" + count + "]." + "helpText" + "=" + credField.helpText;
			InputData = InputData + "&" + "credentialFields[" + count + "]." + "isMFA" + "=" + credField.isMFA;
			InputData = InputData + "&" + "credentialFields[" + count + "]." + "isOptionalMFA" + "=" +	credField.isOptionalMFA;	
			count = count + 1;	
		EndDo;
		
		InputData = StrReplace(InputData, "=No", "=false");
		InputData = StrReplace(InputData, "=Yes", "=true");
		
		ConnectionSettings = New Structure;
		Connection = InternetConnectionClientServer.CreateConnection(URLstring + "?" + InputData, ConnectionSettings).Result;
		ResultBody = InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings);
		
		RESTReturnStructure = New Structure("Success, ErrorDescription, Result", False, "", Undefined);
		ResultBodyJSON = ProcessRESTResult(ResultBody, RESTReturnStructure, "Yodlee.AddItem_AddItem", ItemIdDescription);
		
		If ResultBodyJSON <> Undefined Then
			ReturnStructure.NewItemID = ResultBodyJSON.primitiveObj;
		EndIf;
		If ReturnStructure.NewItemID <> 0 Then
			PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "Bank account was added successfully...", 3), TempStorageAddress);
		Else
			PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "An error occured... Try to repeat the operation", 2), TempStorageAddress);
		EndIf;

	Except
		ErrorDescription = ErrorDescription();
		WriteLogEvent("Yodlee.AddItem_AddItem", EventLogLevel.Error,,, ErrorDescription);
		ReturnStructure.Insert("NewItemID", 0);
		PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "An error occured...", 2), TempStorageAddress);		
	EndTry;
	
	return ReturnStructure;

EndFunction

Function RefreshBankAccount(itemId, IsMFA = False, RefreshStarted = False) Export
		
	Try //without MFA first
		ReturnStructure = New Structure("Success, ErrorDescription, Result", False, "", Undefined);
		ItemIdDescription = "ItemID: " + Format(itemId, "NGS=' '; NZ=") + ".";
		If Not RefreshStarted Then
			ResultStructure = YodleeREST.StartRefresh7_REST(itemId, IsMFA);
			If Not ResultStructure.success Then
				WriteLogEvent("Yodlee.RefreshingBankAccounts", EventLogLevel.Error,,, ItemIdDescription + ResultStructure.ErrorDescription);
				return ResultStructure;
			Else
				JSONData = ResultStructure.Result;
				refreshStatus = JSONData.status;
			EndIf;
			If Not (refreshStatus = 4 Or refreshStatus = 2 Or refreshStatus = 8) Then 
				WriteLogEvent("Yodlee.RefreshingBankAccounts", EventLogLevel.Error,,, ItemIdDescription + " Refresh failed with the refresh status: " + Format(refreshStatus, "NGS=' '; NZ=") + ". " + "STATUS_UNKNOWN_CODE = 0
				|SUCCESS_NEXT_REFRESH_SCHEDULED_CODE = 1
				|REFRESH_ALREADY_IN_PROGRESS_CODE = 2
				|UNSUPPORTED_OPERATION_FOR_SHARED_ITEM_CODE = 3
				|SUCCESS_START_REFRESH_CODE = 4
				|ITEM_CANNOT_BE_REFRESHED_CODE = 5
				|ALREADY_REFRESHED_RECENTLY_CODE = 6
				|UNSUPPORTED_OPERATION_FOR_CUSTOM_ITEM_CODE = 7
				|SUCCESS_REFRESH_WAIT_FOR_MFA_CODE = 8");
				ReturnStructure.Success = False;
				If RefreshStatus = 6 Then
					ReturnStructure.ErrorDescription = "The item has been refreshed very recently."; 	
				Else
					ReturnStructure.ErrorDescription = "Refresh failed with the refresh status: " + Format(refreshStatus, "NGS=' '; NZ="); 
				EndIf;
				return ReturnStructure;
			EndIf;
		EndIf;
		
		// 8 - SUCCESS_REFRESH_WAIT_FOR_MFA_CODE 
		// 4 - The refresh has been successfully initiated
		// 2 - The refresh is already in progress for this item 
		//If refreshStatus = 4 Or refreshStatus = 2 Then 
		If Not IsMFA Then //NORMAL Refresh Mode
			
			ResultStructure = ProcessNormalRefresh(itemId, itemIdDescription);
			return ResultStructure;
			
		Else //MFA Refresh Mode
			
			ResultStructure = ProcessMFARefresh(itemId, itemIdDescription);
			While ResultStructure.Success And Not ResultStructure.IsMessageAvailable Do
				ResultStructure = ProcessMFARefresh(itemId, itemIdDescription);
			EndDo;
			return ResultStructure;
			
		EndIf;
		
	Except
		ErrorDescription = ErrorDescription();
		ReturnStructure.Success = False;
		ReturnStructure.ErrorDescription = ErrorDescription;
		WriteLogEvent("Yodlee.RefreshingBankAccounts", EventLogLevel.Error,,, ItemIdDescription + ErrorDescription);
	EndTry;
	
	Return ReturnStructure;
	
EndFunction

Function ProcessNormalRefresh(itemId, itemIdDescription)
	
	Try
		
		ReturnStructure = New Structure("Success, ErrorDescription, Result", False, "", Undefined);

		ResultStructure = YodleeREST.IsItemRefreshing_REST(itemId);
		If Not ResultStructure.success Then
			return ResultStructure;
		Else
			JSONData = ResultStructure.Result;
		EndIf;

		While JSONData.primitiveObj Do
			ResultStructure = YodleeREST.IsItemRefreshing_REST(itemId);
			If Not ResultStructure.success Then
				return ResultStructure;
			Else
				JSONData = ResultStructure.Result;
			EndIf;
		EndDo;
		ResultStructure = YodleeREST.GetRefreshInfo1_REST(itemId);
		If Not ResultStructure.success Then
			return ResultStructure;
		Else
			ResultBodyJSON = ResultStructure.Result;
		EndIf;
		While ResultBodyJSON[0].statusCode = 801 or ResultBodyJSON[0].statusCode = 802 Do
			ResultStructure = YodleeREST.GetRefreshInfo1_REST(itemId);
			If Not ResultStructure.success Then
				return ResultStructure;
			Else
				ResultBodyJSON = ResultStructure.Result;
			EndIf;
		EndDo;
			
		If ResultBodyJSON[0].statusCode = 0 Then
			WriteLogEvent("Yodlee.RefreshingBankAccounts", EventLogLevel.Information,,, ItemIdDescription + " Refresh has successfully finished");
			ReturnStructure.Success = True;
		Else
			WriteLogEvent("Yodlee.RefreshingBankAccounts", EventLogLevel.Error,,, ItemIdDescription + " Refresh failed with the status code: " + Format(ResultBodyJSON[0].statusCode, "NGS=' '; NZ="));
			ReturnStructure.Success = False;
			ReturnStructure.ErrorDescription = ItemIdDescription + " Refresh failed with the status code: " + Format(ResultBodyJSON[0].statusCode, "NGS=' '; NZ=");
		EndIf;
	
	Except
		ErrorDescription = ErrorDescription();
		ReturnStructure.Success = False;
		ReturnStructure.ErrorDescription = ErrorDescription;
		WriteLogEvent("Yodlee.RefreshingBankAccounts", EventLogLevel.Error,,, ItemIdDescription + ErrorDescription);
	EndTry;
	return ReturnStructure;	

EndFunction

Function ProcessMFARefresh(itemId, itemIdDescription)
	
	Try
		ReturnStructure = New Structure("Success, IsMessageAvailable, ErrorDescription, Result, MFARefreshSucceeded, ProgrammaticElements, ProgrammaticElementsValidValues", False, True, "", Undefined, False);
		
		ResultStructure = YodleeREST.GetMFAResponse_REST(itemId);
		
		If Not ResultStructure.success Then
			return ResultStructure;
		Else
			JSONData = ResultStructure.Result;
		EndIf;
		
		If JSONData.Property("ErrorCode") Then
			If JSONData.ErrorCode = 0 Then //MFA refresh succeeded
				ResultStructure = ProcessNormalRefresh(itemId, itemIdDescription);
				ResultStructure.Insert("MFARefreshSucceeded", True);
				ResultStructure.Insert("IsMessageAvailable", True);
				return ResultStructure;
			Else
				ResultStructure.Success = False;
				ResultStructure.ErrorDescription = "Error while refreshing an account with an error code: " + JSONData.ErrorCode;
				WriteLogEvent("Yodlee.Refresh_ProcessMFA", EventLogLevel.Error,,, ResultStructure.ErrorDescription);
				return ResultStructure;
			EndIf;
		EndIf;
		
		If JSONData.isMessageAvailable = False Then //Repeat GetMFAResponse
			ResultStructure.Success = True;
			ResultStructure.IsMessageAvailable = False;
			return ResultStructure;
		EndIf;
			
			ArrOfElements = New Array();

			If JSONData.fieldInfo.mfaFieldInfoType = "TOKEN_ID" Then
				
				ArrOfElements = New Array();
				RowStruct = New Structure("ElementName, ElementOriginalName, BigOr, DisplayName, MaxLength, FieldType");
				RowStruct.ElementName = "Token";
				RowStruct.ElementOriginalName = "Token";
				RowStruct.BigOr = false;
				RowStruct.DisplayName = JSONData.fieldInfo.displayString;
				RowStruct.MaxLength = JSONData.fieldInfo.maximumLength;
				RowStruct.FieldType = 0; //Text
				ArrOfElements.Add(RowStruct);
			
			ElsIf JSONData.fieldInfo.mfaFieldInfoType = "SECURITY_QUESTION" Then
				
				ArrOfElements = New Array();
				For Each QaAValue In JSONData.fieldInfo.questionAndAnswerValues Do
					RowStruct = New Structure("ElementName, ElementOriginalName, BigOr, DisplayName, MaxLength, FieldType");
					RowStruct.ElementName = "Question_" + String(QaAValue.sequence);
					RowStruct.ElementOriginalName = "Question_" + String(QaAValue.sequence);
					RowStruct.BigOr = false;
					RowStruct.DisplayName = QaAValue.question;
					RowStruct.MaxLength = 40;
					RowStruct.FieldType = 0; //Text
					ArrOfElements.Add(RowStruct);
				EndDo;
				
			EndIf;
			//If RefreshProcess.fieldInfoType = "TokenIdFieldInfo" Then
			//	ArrOfElements = New Array();
			//	RowStruct = New Structure("ElementName, ElementOriginalName, BigOr, DisplayName, MaxLength, FieldType");
			//	RowStruct.ElementName = "Token";
			//	RowStruct.ElementOriginalName = "Token";
			//	RowStruct.BigOr = false;
			//	RowStruct.DisplayName = RefreshProcess.CurrentQuestion;
			//	RowStruct.MaxLength = 40;
			//	RowStruct.FieldType = 0; //Text
			//	ArrOfElements.Add(RowStruct);
			//		
			//ElsIf RefreshProcess.fieldInfoType = "ImageFieldInfo" Then
			//	ReturnStructure.ReturnValue = False;
			//	ReturnStructure.Status = "CAPTCHA images are not supported";
			//	ReturnStructure.IsMFA = False;
			//	WriteLogEvent("Yodlee.RefreshItem_ProcessMFA", EventLogLevel.Error,,, "CAPTCHA images are not supported. ItemID:" + String(ItemID));
			//	If TempStorageAddress <> Undefined Then
			//		PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "Error on obtaining MFA fields...", 4), TempStorageAddress);
			//	EndIf;
			//	return ReturnStructure;
			//ElsIf RefreshProcess.fieldInfoType = "SecurityQuestionFieldInfo" Then
			//	ArrOfElements = New Array();
			//	For i = 0 To (RefreshProcess.totalNumberOfQuestions - 1) Do 
			//		RowStruct = New Structure("ElementName, ElementOriginalName, BigOr, DisplayName, MaxLength, FieldType");
			//		RowStruct.ElementName = "Question_" + String(i);
			//		RowStruct.ElementOriginalName = "Question_" + String(i);
			//		RowStruct.BigOr = false;
			//		RowStruct.DisplayName = RefreshProcess.GetQuestion(i);
			//		RowStruct.MaxLength = 40;
			//		RowStruct.FieldType = 0; //Text
			//		ArrOfElements.Add(RowStruct);
			//	EndDo;
			//EndIf;
			
			ArrOfValidValues = New Array();
			
			ReturnStructure.Insert("Success", True);
			ReturnStructure.Insert("ReturnValue", True);
			ReturnStructure.Insert("IsMFA", True);
			ReturnStructure.Insert("ItemID", ItemID);
			ReturnStructure.Insert("ProgrammaticElements", ArrOfElements);
			ReturnStructure.Insert("ProgrammaticElementsValidValues", ArrOfValidValues);
			AnswerTimeout = 0;
			ReadStructureValueSafely(AnswerTimeout, JSONData, "timeOutTime");
			ReturnStructure.Insert("AnswerTimeout", AnswerTimeout/1000);
			ReturnStructure.Insert("startTime", CurrentUniversalDate());
			//If TempStorageAddress <> Undefined Then
			//	PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "Obtained MFA fields...", 4), TempStorageAddress);
			//EndIf;
			return ReturnStructure;

			
	Except
		ErrorDescription = ErrorDescription();	
		WriteLogEvent("Yodlee.Refresh_ProcessMFA", EventLogLevel.Error,,, itemIdDescription + ErrorDescription);
		ReturnStructure.Success = False;
		ReturnStructure.ErrorDescription = ErrorDescription;
	EndTry;                                                 
	return ReturnStructure;

EndFunction

Function GetYodleeTransactions(ItemAccountID, FromDate, ToDate = Undefined) Export
	Try
		ItemIdDescription = "ItemAccountID: " + Format(ItemAccountId, "NGS=' '; NZ=") + ".";
		ReturnStructure = New Structure("Success, ErrorDescription, Result", False, "", Undefined);
		If Not Constants.ServiceDB.Get() Then
			WriteLogEvent("Yodlee.GetYodleeTransactions", EventLogLevel.Error,,, "Yodlee is available only in the Service DB");
			ReturnStructure.success = False;
			ReturnStructure.ErrorDescription = "Yodlee is available only in the Service DB";
			return ReturnStructure;
		EndIf;
		WriteLogEvent("Yodlee.GetYodleeTransactions", EventLogLevel.Information,,, ItemIdDescription + "Obtaining of bank transactions from Yodlee has started");
		
		StartRange = 1;
		FetchLimit = 500;
		
		ResultStructure = ExecuteUserSearchRequest_REST(ItemAccountID, FromDate, ToDate, StartRange, FetchLimit);
		If Not ResultStructure.success Then
			WriteLogEvent("Yodlee.GetYodleeTransactions", EventLogLevel.Error,,, ResultStructure.ErrorDescription);
			return ResultStructure;
		EndIf;
		ResultBodyJSON = ResultStructure.Result;
		If ResultBodyJSON.numberOfHits = 0 Then
			ReturnStructure.Success = True;
			ReturnStructure.Result = New Array();
			return ReturnStructure;
		EndIf;
		CountOfAllTransactions 	= ResultBodyJSON.countOfAllTransaction;
		TotalTransactionsReceived = 0;
		NewTransactions = New Array();
		While CountOfAllTransactions > TotalTransactionsReceived Do
			//Upload new transactions
			For i = 0 To ResultBodyJSON.SearchResult.Transactions.Count() - 1 Do
				NewTransactions.Add(ResultBodyJSON.SearchResult.Transactions[i]);
			EndDo;
			TotalTransactionsReceived = TotalTransactionsReceived + FetchLimit;
			If CountOfAllTransactions > TotalTransactionsReceived Then
				StartRange = StartRange + FetchLimit;
				ResultStructure = ExecuteUserSearchRequest_REST(ItemAccountID, FromDate, ToDate, StartRange, FetchLimit);
				If Not ResultStructure.success Then
					WriteLogEvent("Yodlee.GetYodleeTransactions", EventLogLevel.Error,,, ResultStructure.ErrorDescription);
					return ResultStructure;
				EndIf;
				ResultBodyJSON = ResultStructure.Result;
			EndIf;
		EndDo;
		//Test++++
		For Each NT In NewTransactions Do
			NT.Insert("TransactionID", NT.ViewKey.TransactionID);
		EndDo;
		//Test----
		ReturnStructure.Success = True;
		ReturnStructure.Result	= NewTransactions;
		return ReturnStructure;
	Except
		ErrorDescription = ErrorDescription();
		WriteLogEvent("Yodlee.GetYodleeTransactions", EventLogLevel.Error,,, ErrorDescription);
		ReturnStructure.success 			= False;
		ReturnStructure.ErrorDescription 	= ErrorDescription;
		return ReturnStructure;
	EndTry;
	
EndFunction

Function UpdateTransactions(BankAccount, ItemAccountID, FromDate, ToDate = Undefined) Export
	
	Try
		ItemIdDescription = "ItemAccountID: " + Format(ItemAccountId, "NGS=' '; NZ=") + ".";
		ReturnStructure = New Structure("Success, ErrorDescription, Result", False, "", Undefined);
		WriteLogEvent("Yodlee.UpdateTransactions", EventLogLevel.Information,, BankAccount, ItemIdDescription + "Bank transactions update has started");
		
		FromDate = MAX(BankAccount.UploadStartDate, FromDate);
		If ToDate <> Undefined Then
			ToDate = MAX(BankAccount.UploadStartDate, ToDate);
		EndIf;
		ResultStructure = YodleeRest.GetYodleeTransactions(BankAccount.itemAccountId, FromDate, ToDate);
		If Not ResultStructure.success Then
			WriteLogEvent("Yodlee.GetYodleeTransactions", EventLogLevel.Error,, BankAccount, ResultStructure.ErrorDescription);
			return ResultStructure;
		EndIf;
		YodleeTransactions = ResultStructure.Result;
					
		TransactionsRS = InformationRegisters.BankTransactions.CreateRecordSet();
		Transactions = TransactionsRS.Unload();
		Transactions.Clear();
		For Each YodleeTran In YodleeTransactions Do
			//Upload only Posted transactions
			If YodleeTran.status.statusId <> 1 Then
				Continue;
			EndIf;
						
			NewTran 	= Transactions.Add();
							
			//NewTran.TransactionDate = YodleeTran.transactionDate;
			ReadStructureValueSafely(NewTran.TransactionDate, YodleeTran, "transactionDate");
			NewTran.BankAccount 	= BankAccount;
					
			//NewTran.Description = YodleeTran.description.description;
			ReadStructureValueSafely(NewTran.Description, YodleeTran, "description", "description");
			ReadStructureValueSafely(NewTran.SimpleDescription, YodleeTran, "description", "simpleDescription");
			ReadStructureValueSafely(NewTran.MerchantName, YodleeTran, "description", "merchantName");
			If YodleeTran.transactionBaseType = "credit" Then
				//NewTran.Amount 			= YodleeTran.amount.amount;
				ReadStructureValueSafely(NewTran.Amount, YodleeTran, "amount", "amount");
			ElsIf YodleeTran.transactionBaseType = "debit" Then
				//NewTran.Amount 			= -1 * YodleeTran.amount.amount;
				ReadStructureValueSafely(NewTran.Amount, YodleeTran, "amount", "amount");
				NewTran.Amount 	= -1 * NewTran.Amount;
			EndIf;
			NewTran.YodleeTransactionID	= YodleeTran.viewKey.transactionId;
		
			NewTran.PostDate 			= Date(Left(StrReplace(YodleeTran.postDate, "-",""), 8));
			ReadStructureValueSafely(NewTran.Price, YodleeTran, "price", "amount");
			ReadStructureValueSafely(NewTran.Quantity, YodleeTran, "quantity", "");
			ReadStructureValueSafely(NewTran.RunningBalance, YodleeTran, "runningBalance", "");
			ReadStructureValueSafely(NewTran.CurrencyCode, YodleeTran, "amount", "currencyCode");
			ReadStructureValueSafely(NewTran.CategoryID, YodleeTran, "category", "categoryId");
			ReadStructureValueSafely(NewTran.Type, YodleeTran, "transactionBaseType", "");
			ReadStructureValueSafely(NewTran.CheckNumber, YodleeTran, "CheckNumber", "checkNumber");
	
		EndDo;
	
		Transactions.Columns.TransactionDate.Name = "PostDate1";
		Transactions.Columns.PostDate.Name = "TransactionDate";
		Transactions.Columns.PostDate1.Name = "PostDate";
		//Record Transactions to database
		TransactionDates = Transactions.Copy(,"TransactionDate");
		TransactionDates.GroupBy("TransactionDate");
		//By dates
		For Each TranDate IN TransactionDates Do
			Try
				// Update the database in transaction.
				BeginTransaction(DataLockControlMode.Managed);
				// Lock the register records preventing reading old schedule data.
				Rows = New Array();
				Rows.Add(TranDate);
				DataSource = TransactionDates.Copy(Rows);
				DocumentPosting.LockDataSourceBeforeWrite("InformationRegister.BankTransactions", DataSource, DataLockMode.Exclusive);

				CurDate = TranDate.TransactionDate;
				TRS = InformationRegisters.BankTransactions.CreateRecordSet();
				TDFilter = TRS.Filter.TransactionDate;
				BAFilter = TRS.Filter.BankAccount;
				BAFilter.Use = True;
				BAFilter.ComparisonType = ComparisonType.Equal;
				BAFilter.Value = BankAccount;
				TDFilter.Use = True;
				TDFilter.ComparisonType = ComparisonType.Equal;
				TDFilter.Value = CurDate;
				TRS.Read();
				ValueTable_TRS = TRS.Unload();

				TransactionsPerDate = Transactions.FindRows(New Structure("TransactionDate", CurDate));
				For Each TranPerDate IN TransactionsPerDate Do
					FoundTransaction = ValueTable_TRS.FindRows(New Structure("YodleeTransactionID", TranPerDate.YodleeTransactionID));
					If FoundTransaction.Count() > 0 Then
						//Check if found transaction has been already accepted
						//In this case no changes are allowed, excepting the amount or the Currency code have changed
						If FoundTransaction[0].Accepted Then
							If (FoundTransaction[0].Amount <> TranPerDate.Amount) 
								OR (FoundTransaction[0].CurrencyCode <> TranPerDate.CurrencyCode) 
								OR (FoundTransaction[0].TransactionDate <> TranPerDate.TransactionDate) Then
								FillPropertyValues(FoundTransaction[0], TranPerDate, "TransactionDate, Description, Amount, CategoryID, PostDate, Price, Quantity, RunningBalance, CurrencyCode, Type, SimpleDescription, MerchantName");
							Else
								FillPropertyValues(FoundTransaction[0], TranPerDate, "CategoryID, PostDate, Price, Quantity, RunningBalance, Type");
							EndIf;
						Else
							FillPropertyValues(FoundTransaction[0], TranPerDate, "BankAccount, TransactionDate, Description, Amount, CategoryID, PostDate, Price, Quantity, RunningBalance, CurrencyCode, Type, CheckNumber, SimpleDescription, MerchantName");
						EndIf;
					Else
						NewTRSRow = ValueTable_TRS.Add();
						FillPropertyValues(NewTRSRow, TranPerDate);
						NewTRSRow.ID = New UUID();
					EndIf;
				EndDo;
				TRS.Load(ValueTable_TRS);
				TRS.Write(True);

				CommitTransaction();
			Except
				If TransactionActive() Then
					RollbackTransaction();
				EndIf;
				ReturnStructure.Success = false;
				Reason = ErrorDescription();
				ReturnStructure.ErrorDescription = "Not all bank transactions were successfully downloaded. Please repeat operation." + Chars.LF + "Reason: " + Reason;
				WriteLogEvent("Yodlee.UpdateTransactions", EventLogLevel.Error,, BankAccount, ReturnStructure.ErrorDescription);
				return ReturnStructure;
			EndTry;
		EndDo;
	Except
		ErrorDescription = ErrorDescription();
		WriteLogEvent("Yodlee.UpdateTransactions", EventLogLevel.Error,, BankAccount, ErrorDescription);
		ReturnStructure.success 			= False;
		ReturnStructure.ErrorDescription 	= ErrorDescription;
		return ReturnStructure;
	EndTry;
	
	ReturnStructure.Success = True;
	return ReturnStructure;
	
EndFunction

Function UpdateBankAccount(itemID, TransactionsFromDate = Undefined, TransactionsToDate = Undefined) Export
	
	Try
		ReturnStructure = New Structure("Success, ErrorDescription, Result", False, "", Undefined);
		ItemIdDescription = "ItemID: " + Format(ItemId, "NGS=' '; NZ=") + ".";
		
		ResultStructure = YodleeREST.GetItemSummaryForItem1_REST(itemID);
		If Not ResultStructure.success Then
			return ResultStructure;
		Else
			JSONData = ResultStructure.Result;
		EndIf;
		
		Request = New Query("SELECT
		                    |	BankAccounts.Ref,
		                    |	BankAccounts.ItemID,
		                    |	BankAccounts.ItemAccountID
		                    |FROM
		                    |	Catalog.BankAccounts AS BankAccounts
		                    |WHERE
		                    |	BankAccounts.ItemID = &ItemID");
		Request.SetParameter("ItemID", itemID);
		Sel = Request.Execute();
		//Fill bank accounts with the updated properties
		BankAccntsSel = Sel.Select();
				
		While BankAccntsSel.Next() Do
			
			BankAccountUpdated = False;
			For each account in JSONData.itemData.accounts Do
				If account.itemAccountId = BankAccntsSel.itemAccountId Then
					
					BankObject 							= BankAccntsSel.Ref.GetObject();
			
					BankObject.RefreshStatusCode 		= JSONData.refreshInfo.statusCode;
			
					UTCUpdatedSecs						= JSONData.refreshInfo.lastUpdatedTime;
					BankObject.LastUpdatedTimeUTC		= UTCUpdatedSecs;
					UTCUpdateAttemptSecs				= JSONData.refreshInfo.lastUpdateAttemptTime;
					BankObject.LastUpdateAttemptTimeUTC = UTCUpdateAttemptSecs;
					UTCNextUpdateSecs					= JSONData.refreshInfo.nextUpdateTime;
					BankObject.NextUpdateTimeUTC 		= UTCNextUpdateSecs;

					BankObject.YodleeAccount 			= True;
					BankObject.Write();

					If JSONData.contentServiceInfo.containerInfo.containerName = "bank" Then
						If account.Property("currentBalance") Then
							BankObject.CurrentBalance = account.currentBalance.amount;
						ElsIf account.Property("availableBalance") Then
							BankObject.CurrentBalance = account.availableBalance.amount;
						EndIf;
					
						If account.Property("availableBalance") Then
							BankObject.AvailableBalance = account.availableBalance.amount; 
						ElsIf account.Property("currentBalance") Then
							BankObject.AvailableBalance = account.currentBalance.amount;
						EndIf;
					ElsIf JSONData.contentServiceInfo.containerInfo.ContainerName = "credits" Then
						If account.Property("availableCredit") Then
							BankObject.AvailableBalance		= account.availableCredit.amount;
						EndIf;
						If account.Property("runningBalance") Then
							BankObject.CurrentBalance		= account.runningBalance.amount;
						EndIf;
						If account.Property("totalCreditLine") Then
							BankObject.CreditCard_TotalCreditline	= account.totalCreditLine.amount;
						EndIf;
						If account.Property("amountDue") Then
							BankObject.CreditCard_AmountDue	= account.amountDue.amount;
						EndIf;
					EndIf;	
					BankObject.Write();
					BankAccountUpdated = True;
					//Upload the new transactions
					If TransactionsFromDate <> Undefined Then
						FromDate = TransactionsFromDate;
					Else
						FromDate = BegOfDay(BankObject.TransactionsRefreshTimeUTC - 7*24*3600);
					EndIf;
					ResultStructure = YodleeRest.UpdateTransactions(BankObject.Ref, BankObject.ItemAccountId, FromDate, TransactionsToDate);
					If ResultStructure.Success Then
						BankObject.TransactionsRefreshTimeUTC = CurrentUniversalDate();
						BankObject.Write();
					EndIf;
				
				EndIf;
			EndDo;
			If Not BankAccountUpdated Then
				BankObject 	= BankAccntsSel.Ref.GetObject();	
				BankObject.YodleeAccount = False;
				BankObject.Write();
			EndIf;
		EndDo;
	Except
		ErrorDescription = ErrorDescription();
		WriteLogEvent("Yodlee.UpdateBankAccount", EventLogLevel.Error,,, ItemIdDescription + ErrorDescription);
		ReturnStructure.success 			= False;
		ReturnStructure.ErrorDescription 	= ErrorDescription;
		return ReturnStructure;
	EndTry;
	
	If Constants.YodleeCreateDocuments.Get() Then
		YodleeDownloadingTransactionsAtServer();
	EndIf;
	
	ReturnStructure.Success = True;
	return ReturnStructure;

EndFunction

// Gets the last FetchLimit transactions from LastDate to the current date of the given account
// Returns in a Data JSON string
Function ExecuteUserSearchRequest_NoDecode(ItemAccountID, FromDate, ToDate = Undefined, StartRange, FetchLimit) Export
	
	Try
		ReturnStructure = New Structure("Success, ErrorDescription, Result", False, "", Undefined);
		ItemIdDescription = "ItemAccountID: " + Format(ItemAccountId, "NGS=' '; NZ=") + ".";
		If Not Constants.ServiceDB.Get() Then
			WriteLogEvent("Yodlee.ExecuteUserSearchRequest", EventLogLevel.Error,,, "Yodlee is available only in the Service DB");
			ReturnStructure.success = False;
			ReturnStructure.ErrorDescription = "Yodlee is available only in the Service DB";
			return ReturnStructure;
		EndIf;

		URLstring = "https://consolidatedsdk.yodlee.com/yodsoap/srest/yellowlabs/v1.0/jsonsdk/TransactionSearchService/executeUserSearchRequest";
		
		FromDateFormatted = Format(FromDate, "DF=MM-dd-yyyy");
		If ToDate <> Undefined Then
			ToDateFormatted = Format(ToDate, "DF=MM-dd-yyyy");
		EndIf;
		
		EndRange 	= StartRange + FetchLimit - 1;
				
		InputParameters = New Structure();
		InputParameters.Insert("cobSessionToken", Constants.YodleeCobSessionToken.Get());
		InputParameters.Insert("userSessionToken", Constants.YodleeUserSessionToken.Get());
		InputParameters.Insert("transactionSearchRequestcontainerType", "All");
		InputParameters.Insert("transactionSearchRequesthigherFetchLimit", EndRange);
		InputParameters.Insert("transactionSearchRequestlowerFetchLimit", StartRange);
		InputParameters.Insert("transactionSearchRequestresultRangeendNumber", EndRange);
		InputParameters.Insert("transactionSearchRequestresultRangestartNumber", StartRange);
		InputParameters.Insert("transactionSearchRequestfirstCall", ?(StartRange = 1, "true", "false"));
		InputParameters.Insert("transactionSearchRequestsearchClientsclientId", 1);
		InputParameters.Insert("transactionSearchRequestsearchClientsclientName", "DataSearchService");
		//InputParameters.Insert("transactionSearchRequestsearchClients", "DEFAULT_SERVICE_CLIENT");
		InputParameters.Insert("transactionSearchRequestsearchFiltercurrencyCode", "USD");
		InputParameters.Insert("transactionSearchRequestignoreUserInput", "true");
		InputParameters.Insert("transactionSearchRequestsearchFiltertransactionSplitType", "ALL_TRANSACTION");
		InputParameters.Insert("transactionSearchRequestsearchFilteritemAccountIdidentifier", ItemAccountID);
		If ToDate <> Undefined Then 
			InputParameters.Insert("transactionSearchRequestsearchFilterpostDateRangetoDate", ToDateFormatted);
		EndIf;
		InputParameters.Insert("transactionSearchRequestsearchFilterpostDateRangefromDate", FromDateFormatted);
					
		InputData = InternetConnectionClientServer.EncodeQueryData(InputParameters);
		InputData = StrReplace(InputData,"transactionSearchRequestcontainerType","transactionSearchRequest.containerType");
		InputData = StrReplace(InputData,"transactionSearchRequesthigherFetchLimit","transactionSearchRequest.higherFetchLimit");
		InputData = StrReplace(InputData,"transactionSearchRequestlowerFetchLimit","transactionSearchRequest.lowerFetchLimit");
		InputData = StrReplace(InputData,"transactionSearchRequestresultRangeendNumber","transactionSearchRequest.resultRange.endNumber");
		InputData = StrReplace(InputData,"transactionSearchRequestresultRangestartNumber","transactionSearchRequest.resultRange.startNumber");
		InputData = StrReplace(InputData,"transactionSearchRequestsearchFiltercurrencyCode","transactionSearchRequest.searchFilter.currencyCode");
		InputData = StrReplace(InputData,"transactionSearchRequestignoreUserInput","transactionSearchRequest.ignoreUserInput");
		InputData = StrReplace(InputData,"transactionSearchRequestsearchFilteritemAccountIdidentifier","transactionSearchRequest.searchFilter.itemAccountId.identifier");
		InputData = StrReplace(InputData,"transactionSearchRequestsearchFilterpostDateRangetoDate","transactionSearchRequest.searchFilter.postDateRange.toDate");
		InputData = StrReplace(InputData,"transactionSearchRequestsearchFilterpostDateRangefromDate","transactionSearchRequest.searchFilter.postDateRange.fromDate");
		InputData = StrReplace(InputData,"transactionSearchRequestfirstCall","transactionSearchRequest.firstCall");
		InputData = StrReplace(InputData,"transactionSearchRequestsearchClientsclientId","transactionSearchRequest.searchClients.clientId");
		InputData = StrReplace(InputData,"transactionSearchRequestsearchClientsclientName","transactionSearchRequest.searchClients.clientName");
		InputData = StrReplace(InputData,"transactionSearchRequestsearchClients","transactionSearchRequest.searchClients");
		InputData = StrReplace(InputData,"transactionSearchRequestsearchFiltertransactionSplitType","transactionSearchRequest.searchFilter.transactionSplitType");
		
		ConnectionSettings = New Structure;
		Connection = InternetConnectionClientServer.CreateConnection(URLstring + "?" + InputData, ConnectionSettings).Result;
		NumericFields = New Array();
		NumericFields.Add("transactionSearchRequest.searchFilter.itemAccountId.identifier");
		FixPossibleDatesAsNumeric(ConnectionSettings, NumericFields);
		ResultBody = InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings);
						
		ReturnStructure.Result = ResultBody.Result;
		return ReturnStructure;
		
	Except
		ErrorDescription = ErrorDescription();
		WriteLogEvent("Yodlee.ExecuteUserSearchRequest", EventLogLevel.Error,,, ErrorDescription);
		ReturnStructure.success 			= False;
		ReturnStructure.ErrorDescription 	= ErrorDescription;
		return ReturnStructure;
	EndTry;	
	
EndFunction

Function GetEarliestTransactionDate(ItemAccountID, FromDate)
	
	Try
				
		StartRange 	= 1;
		FetchLimit 	= 500;
		ToDate		= Undefined;
		
		EarliestDate = '00010101';
		ResultStructure = ExecuteUserSearchRequest_NoDecode(ItemAccountID, FromDate, ToDate, StartRange, FetchLimit);
		If Not ResultStructure.success Then
			return EarliestDate;
		EndIf;
		
		//While CountOfAllTransactions > TotalTransactionsReceived Do
		//	//Upload new transactions
		//	For i = 0 To ResultBodyJSON.SearchResult.Transactions.Count() - 1 Do
		//		NewTransactions.Add(ResultBodyJSON.SearchResult.Transactions[i]);
		//	EndDo;
		//	TotalTransactionsReceived = TotalTransactionsReceived + FetchLimit;
		//	If CountOfAllTransactions > TotalTransactionsReceived Then
		//		StartRange = StartRange + FetchLimit;
		//		ResultStructure = ExecuteUserSearchRequest_REST(ItemAccountID, FromDate, ToDate, StartRange, FetchLimit);
		//		If Not ResultStructure.success Then
		//			WriteLogEvent("Yodlee.GetYodleeTransactions", EventLogLevel.Error,,, ResultStructure.ErrorDescription);
		//			return ResultStructure;
		//		EndIf;
		//		ResultBodyJSON = ResultStructure.Result;
		//	EndIf;
		//EndDo;
		////Test++++
		//For Each NT In NewTransactions Do
		//	NT.Insert("TransactionID", NT.ViewKey.TransactionID);
		//EndDo;
		////Test----
		
		return EarliestDate;
	Except
		ErrorDescription = ErrorDescription();
		WriteLogEvent("Yodlee.GetYodleeTransactions", EventLogLevel.Error,,, ErrorDescription);
		return '00010101';
	EndTry;

EndFunction

Function ObtainBankAccounts(itemID, ObtainBankTransactions = False) Export
	
	Try
		ReturnStructure = New Structure("Success, ErrorDescription, Result", False, "", Undefined);
		ItemIdDescription = "ItemID: " + Format(ItemId, "NGS=' '; NZ=") + ".";
		
		ResultStructure = YodleeREST.GetItemSummaryForItem1_REST(itemID);
		If Not ResultStructure.success Then
			return ResultStructure;
		Else
			JSONData = ResultStructure.Result;
		EndIf;
		
		ArrayOfAccounts = New Array;
		For each account in JSONData.itemData.accounts Do
			
			AccountDescription = New Structure("Description, ItemID, ItemAccountID, Type, LastUpdatedTimeUTC, LastUpdateAttemptTimeUTC, NextUpdateTimeUTC, CurrentBalance, AvailableBalance, RefreshStatusCode, CreditCard_TotalCreditline, CreditCard_AmountDue, CreditCard_Type, BankTransactions, UploadStartDate");
			
			AccountNumber = "";
			ReadStructureValueSafely(AccountNumber, account, "accountNumber");
			AccountDescription.Description 				= JSONData.itemDisplayName + ?(IsBlankString(AccountNumber), "", ":" + AccountNumber);
			AccountDescription.ItemId 					= itemID;
			AccountDescription.ItemAccountID 			= account.itemAccountId;
			ReadStructureValueSafely(AccountDescription.Type, account, "acctType");
			
			AccountDescription.RefreshStatusCode 		= JSONData.refreshInfo.statusCode;
			
			UTCUpdatedSecs						= JSONData.refreshInfo.lastUpdatedTime;
			AccountDescription.LastUpdatedTimeUTC		= UTCUpdatedSecs;
			UTCUpdateAttemptSecs				= JSONData.refreshInfo.lastUpdateAttemptTime;
			AccountDescription.LastUpdateAttemptTimeUTC = UTCUpdateAttemptSecs;
			UTCNextUpdateSecs					= JSONData.refreshInfo.nextUpdateTime;
			AccountDescription.NextUpdateTimeUTC 		= UTCNextUpdateSecs;
					
			If JSONData.contentServiceInfo.containerInfo.containerName = "bank" Then
				If account.Property("currentBalance") Then
					AccountDescription.CurrentBalance = account.currentBalance.amount;
				ElsIf account.Property("availableBalance") Then
					AccountDescription.CurrentBalance = account.availableBalance.amount;
				EndIf;
					
				If account.Property("availableBalance") Then
					AccountDescription.AvailableBalance = account.availableBalance.amount; 
				ElsIf account.Property("currentBalance") Then
					AccountDescription.AvailableBalance = account.currentBalance.amount;
				EndIf;
			ElsIf JSONData.contentServiceInfo.containerInfo.ContainerName = "credits" Then
				If account.Property("availableCredit") Then
					AccountDescription.AvailableBalance		= account.availableCredit.amount;
				EndIf;
				If account.Property("runningBalance") Then
					AccountDescription.CurrentBalance		= account.runningBalance.amount;
				EndIf;
				If account.Property("totalCreditLine") Then
					AccountDescription.CreditCard_TotalCreditline	= account.totalCreditLine.amount;
				EndIf;
				If account.Property("amountDue") Then
					AccountDescription.CreditCard_AmountDue	= account.amountDue.amount;
				EndIf;
				ReadStructureValueSafely(AccountDescription.CreditCard_Type, account, "cardType");
			EndIf;	
			
//{{MRG[ <-> ]
			//FromDate = AddMonth(CurrentDate(), -12);
			//ResultStructure = YodleeRest.GetYodleeTransactions(AccountDescription.itemAccountId, FromDate);
			//If ResultStructure.success Then
			//	AccountDescription.BankTransactions = ResultStructure.Result;
			//	//Define the earliest date in transactions
			//	If AccountDescription.BankTransactions.Count() > 0 Then
			//		TranDate1 = AccountDescription.BankTransactions[0];
			//		TranDate2 = AccountDescription.BankTransactions[AccountDescription.BankTransactions.Count() - 1];
			//		EarliestDate = ?(TranDate1.postDate < TranDate2.postDate, TranDate1.postDate, TranDate2.postDate);
			//		AccountDescription.UploadStartDate = EarliestDate;
			//	EndIf;
			//	
			//EndIf;
//}}MRG[ <-> ]
//{{MRG[ <-> ]
//			FromDate = AddMonth(CurrentDate(), -12);
//			ResultStructure = YodleeRest.GetYodleeTransactions(AccountDescription.itemAccountId, FromDate);
//			If ResultStructure.success Then
//				AccountDescription.BankTransactions = ResultStructure.Result;
//				//Define the earliest date in transactions
//				If AccountDescription.BankTransactions.Count() > 0 Then
//					TranDate1 = AccountDescription.BankTransactions[0];
//					TranDate2 = AccountDescription.BankTransactions[AccountDescription.BankTransactions.Count() - 1];
//					EarliestDate = ?(TranDate1.postDate < TranDate2.postDate, TranDate1.postDate, TranDate2.postDate);
//					AccountDescription.UploadStartDate = EarliestDate;
//				EndIf;
//			EndIf;
//}}MRG[ <-> ]
			//FromDate = AddMonth(CurrentDate(), -12);
			//EarliestDate = YodleeREST.GetEarliestTransactionDate(AccountDescription.itemAccountId, FromDate);

			ArrayOfAccounts.Add(AccountDescription);
		EndDo;
		ReturnStructure.Result = ArrayOfAccounts;
		ReturnStructure.Success = True;
		
	Except
		ErrorDescription = ErrorDescription();
		WriteLogEvent("Yodlee.UpdateBankAccount", EventLogLevel.Error,,, ItemIdDescription + ErrorDescription);
		ReturnStructure.success 			= False;
		ReturnStructure.ErrorDescription 	= ErrorDescription;
		return ReturnStructure;
	EndTry;
	
	return ReturnStructure;

EndFunction

Procedure RefreshBankAccounts() Export
	
	WriteLogEvent("Yodlee.RefreshingBankAccounts", EventLogLevel.Information,,, "The refresh of bank accounts has started");
	
	ResultStructure = YodleeREST.LoginUser();
	If Not ResultStructure.success Then
		WriteLogEvent("Yodlee.RefreshingBankAccounts", EventLogLevel.Error,,, ResultStructure.ErrorDescription);
		WriteLogEvent("Yodlee.RefreshingBankAccounts", EventLogLevel.Information,,, "The refresh of bank accounts has finished");
		return;
	EndIf;
	
	TotalSuccessfulRefreshes 	= 0;
	TotalFailedRefreshes		= 0;
	CurrentTimeUTC				= CurrentUniversalDate();
	
	Request = new Query("SELECT
	                    |	BankAccounts.Ref,
	                    |	BankAccounts.ItemID AS ItemID,
	                    |	BankAccounts.ItemAccountID
	                    |FROM
	                    |	Catalog.BankAccounts AS BankAccounts
	                    |WHERE
	                    |	BankAccounts.ItemID <> 0
	                    |	AND BankAccounts.ItemAccountID <> 0
	                    |	AND BankAccounts.LastUpdatedTimeUTC < &RecentRefresh
	                    |TOTALS BY
	                    |	ItemID");
	Request.SetParameter("RecentRefresh", CurrentUniversalDate()-30*60); //30 minutes						
	
	Sel = Request.Execute().Select(QueryResultIteration.ByGroups);
	
	While Sel.Next() Do
		
		itemID = Sel.ItemID;
		ItemIdDescription = "ItemID:" + Format(itemID, "NGS=' '; NZ=") + ".";
		WriteLogEvent("Yodlee.RefreshingBankAccounts", EventLogLevel.Information,,, "Processing itemID:" + Format(itemID, "NGS=' '; NZ="));
		//Check when bank account was refreshed and does it support non-MFA account
		ResultStructure = YodleeREST.GetItemSummaryForItem1_REST(itemId);
		If Not ResultStructure.success Then
			WriteLogEvent("Yodlee.RefreshingBankAccounts", EventLogLevel.Information,,, ItemIdDescription + ResultStructure.ErrorDescription);
			Continue;
		Else
			JSONData = ResultStructure.Result;
			If JSONData.Property("Key") Then
				WriteLogEvent("Yodlee.RefreshingBankAccounts", EventLogLevel.Warning,,, "Bank accounts with the itemID:" + Format(itemID, "NGS=' '; NZ=") + " are not found at Yodlee");
				Continue;
			EndIf;
			If JSONData.refreshInfo.refreshMode <> "NORMAL" Then	
				WriteLogEvent("Yodlee.RefreshingBankAccounts", EventLogLevel.Warning,,, "Bank accounts with the itemID:" + Format(itemID, "NGS=' '; NZ=") + " don't support non-MFA refreshes");
				Continue;
			EndIf;
		EndIf;

		ResultStructure = YodleeREST.RefreshBankAccount(itemID);
				
		ResultStructure = YodleeREST.GetItemSummaryForItem1_REST(itemID);
		If Not ResultStructure.success Then
			TotalFailedRefreshes = TotalFailedRefreshes + 1; 
			Continue;
		Else
			JSONData = ResultStructure.Result;
		EndIf;
		
		//Fill bank accounts with the updated properties
		BankAccntsSel = Sel.Select(QueryResultIteration.Linear);
		While BankAccntsSel.Next() Do
			
			BankObject 							= BankAccntsSel.Ref.GetObject();
			
			BankObject.RefreshStatusCode 		= JSONData.refreshInfo.statusCode;
			
			UTCUpdatedSecs						= JSONData.refreshInfo.lastUpdatedTime;
			BankObject.LastUpdatedTimeUTC		= UTCUpdatedSecs;
			UTCUpdateAttemptSecs				= JSONData.refreshInfo.lastUpdateAttemptTime;
			BankObject.LastUpdateAttemptTimeUTC = UTCUpdateAttemptSecs;
			UTCNextUpdateSecs					= JSONData.refreshInfo.nextUpdateTime;
			BankObject.NextUpdateTimeUTC 		= UTCNextUpdateSecs;

			BankObject.YodleeAccount 			= True;
			BankObject.Write();
			
			If (CurrentTimeUTC - BankObject.LastUpdatedTimeUTC) < 6*3600 Then
				TotalSuccessfulRefreshes 	= TotalSuccessfulRefreshes + 1;
			Else
				TotalFailedRefreshes		= TotalFailedRefreshes + 1;
			EndIf;
	
			For each account in JSONData.itemData.accounts Do
				If account.itemAccountId = BankObject.itemAccountId Then
					If JSONData.contentServiceInfo.containerInfo.containerName = "bank" Then
						If account.Property("currentBalance") Then
							BankObject.CurrentBalance = account.currentBalance.amount;
						ElsIf account.Property("availableBalance") Then
							BankObject.CurrentBalance = account.availableBalance.amount;
						EndIf;
					
						If account.Property("availableBalance") Then
							BankObject.AvailableBalance = account.availableBalance.amount; 
						ElsIf account.Property("currentBalance") Then
							BankObject.AvailableBalance = account.currentBalance.amount;
						EndIf;
					ElsIf JSONData.contentServiceInfo.containerInfo.ContainerName = "credits" Then
						If account.Property("availableCredit") Then
							BankObject.AvailableBalance		= account.availableCredit.amount;
						EndIf;
						If account.Property("runningBalance") Then
							BankObject.CurrentBalance		= account.runningBalance.amount;
						EndIf;
						If account.Property("totalCreditLine") Then
							BankObject.CreditCard_TotalCreditline	= account.totalCreditLine.amount;
						EndIf;
						If account.Property("amountDue") Then
							BankObject.CreditCard_AmountDue	= account.amountDue.amount;
						EndIf;
					EndIf;	
					BankObject.Write();
					//Upload the new transactions
					FromDate = BegOfDay(BankObject.TransactionsRefreshTimeUTC - 7*24*3600);
					ResultStructure = YodleeRest.UpdateTransactions(BankObject.Ref, BankObject.ItemAccountId, FromDate);
					If ResultStructure.Success Then
						BankObject.TransactionsRefreshTimeUTC = CurrentUniversalDate();
						BankObject.Write();
					EndIf;
				
				EndIf;
			EndDo;

		EndDo;
		
	EndDo;
	
	WriteLogEvent("Yodlee.RefreshingBankAccountsResults", EventLogLevel.Information,,, "The refresh of bank accounts has finished. Successfully refreshed:" + Format(TotalSuccessfulRefreshes, "NGS=' '; NZ=") + " accounts. Failed to refresh:" + Format(TotalFailedRefreshes, "NGS=' '; NZ=") + " accounts.");
	
	If Constants.YodleeCreateDocuments.Get() Then
		YodleeDownloadingTransactionsAtServer();
	EndIf;
	
EndProcedure

// For the temorary usage. Checks whether a bank account supports the non-MFA refresh
// If it supports, then more reliable REST method is called
// Otherwise (for an MFA refresh) the SOAP method is used
// Parameters:
//  ItemID - number - bank account ID
//  TempStorageAddress - string - the address of the temporary storage
//
Procedure RefreshBankAccountWithSOAPOrREST(ItemID, TempStorageAddress, TransactionsFromDate = Undefined, TransactionsToDate = Undefined) Export
	
	Try
		ResultStructure = YodleeREST.LoginUser();
		If Not ResultStructure.success Then // Call SOAP method
			//Prepare data for background execution
			ProcParameters = New Array;
 			ProcParameters.Add(ItemID);
			ProcParameters.Add(Undefined);
			ProcParameters.Add(Undefined);
 			ProcParameters.Add(TempStorageAddress);
	
			//Performing background operation
			//JobTitle = NStr("en = 'Starting the refresh bank account process'");
			//Job = BackgroundJobs.Execute("Yodlee.RefreshItem", ProcParameters, , JobTitle);
			Yodlee.RefreshItem(ItemID, , , TempStorageAddress);
			return;
		EndIf;
	
		UseSOAP = False;
		ResultStructure = YodleeREST.GetItemSummaryForItem1_REST(itemId);
		If Not ResultStructure.success Then
			UseSOAP = True;
		Else
			JSONData = ResultStructure.Result;
			If JSONData.Property("Key") Then
				UseSOAP = True;			
			EndIf;
			If JSONData.refreshInfo.refreshMode <> "NORMAL" Then	
				UseSOAP = True;
			EndIf;
		EndIf;

		If UseSOAP Then
			Yodlee.RefreshItem(ItemID, , , TempStorageAddress);
			return;
		EndIf;
		
		RefreshResultStructure = YodleeREST.RefreshBankAccount(itemID);
		
		//Update bank account attributes and upload new transactions
		UpdateResultStructure = YodleeREST.UpdateBankAccount(itemID, TransactionsFromDate, TransactionsToDate);
		
		//Finish refresh
		ReturnStructure = New Structure("ReturnValue, Status, IsMFA");
		ReturnStructure.ReturnValue = RefreshResultStructure.Success And UpdateResultStructure.Success;
		ReturnStructure.Status 		= RefreshResultStructure.ErrorDescription + ?(IsBlankString(RefreshResultStructure.ErrorDescription), "", Chars.LF) + UpdateResultStructure.ErrorDescription;
		ReturnStructure.IsMFA		= False;
		PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "The refresh has finished...", 9), TempStorageAddress);
		
	Except
		ErrorDescription = ErrorDescription();
		WriteLogEvent("Yodlee.RefreshBankAccountWithSOAPOrREST", EventLogLevel.Error,,, "ItemID:" + Format(ItemID, "NGS=' '; NZ=; NG=3,0") + ";" + ErrorDescription);
		ReturnStructure = New Structure("ReturnValue, Status, IsMFA");
		ReturnStructure.ReturnValue = False;
		ReturnStructure.Status 		= "An unexpected error occurred. See log for details.";
		ReturnStructure.IsMFA		= False;
		PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "The refresh has finished...", 3), TempStorageAddress);
		
	EndTry;
	
EndProcedure

// Parameters:
//  ItemID - number - bank account ID
//  TempStorageAddress - string - the address of the temporary storage
//
Procedure RefreshItem(ItemID, TempStorageAddress, TransactionsFromDate = Undefined, TransactionsToDate = Undefined) Export
	
	Try
		ReturnStructure = New Structure("ReturnValue, Status, IsMFA");
		
		ResultStructure = YodleeREST.GetRefreshInfo1_REST(itemId);

		//ResultStructure = YodleeREST.GetItemSummaryForItem1_REST(itemId);
		//
		If Not ResultStructure.success Then
			ReturnStructure.ReturnValue = False;
			ReturnStructure.Status = "Our apologies, but we can't connect your bank at the moment. Our team is working on resolving this";
			ReturnSTructure.IsMFA = False;
			PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "The refresh has finished...", 1), TempStorageAddress);
			return;
		EndIf;
		
		JSONData = ResultStructure.Result;
		//If JSONData.Property("Key") Then
		//	ReturnStructure.ReturnValue = False;
		//	ReturnStructure.Status = "Our apologies, but we can't connect your bank at the moment. Our team is working on resolving this";
		//	ReturnSTructure.IsMFA = False;
		//	PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "The refresh has finished...", 1), TempStorageAddress);
		//	return;
		//EndIf;
		
		If JSONData[0].refreshMode = "NORMAL" Then	
			
			RefreshResultStructure = YodleeREST.RefreshBankAccount(itemID, False, True);
			RefreshResultStructure.Insert("IsMFA", False);
			
		Else //MFA
			
			RefreshResultStructure = YodleeREST.RefreshBankAccount(itemID, True, True);
			RefreshResultStructure.Insert("IsMFA", True);
			
		EndIf;
		
		If RefreshResultStructure.Success Then
			If RefreshResultStructure.IsMFA = False Or (RefreshResultStructure.IsMFA = True And RefreshResultStructure.MFARefreshSucceeded) Then
				//Update bank account attributes and upload new transactions
				BankAccountsStructure = YodleeREST.ObtainBankAccounts(itemID);
				//Finish refresh. Go to the assigning of G/L accounts
				ReturnStructure.ReturnValue = RefreshResultStructure.Success And BankAccountsStructure.Success;
				ReturnStructure.Status 		= RefreshResultStructure.ErrorDescription + ?(IsBlankString(RefreshResultStructure.ErrorDescription), "", Chars.LF) + BankAccountsStructure.ErrorDescription;
				ReturnStructure.IsMFA		= RefreshResultStructure.IsMFA;
				ReturnStructure.Insert("BankAccounts", BankAccountsStructure.Result);
				PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "The refresh has finished...", 2), TempStorageAddress);
			Else
				//Present MFA form to the user
				PutToTempStorage(New Structure("Params, CurrentStatus, Step", RefreshResultStructure, "Obtained MFA fields...", 3), TempStorageAddress);
			EndIf;
		Else
			ReturnStructure.ReturnValue = False;
			ReturnStructure.Status 		= "Our apologies, but we can't connect your bank at the moment. Our team is working on resolving this";
			ReturnStructure.IsMFA		= False;
			PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "The refresh has finished...", 2), TempStorageAddress);
		EndIf;
		
	Except
		ErrorDescription = ErrorDescription();
		WriteLogEvent("Yodlee.RefreshItem", EventLogLevel.Error,,, "ItemID:" + Format(ItemID, "NGS=' '; NZ=; NG=3,0") + ";" + ErrorDescription);
		ReturnStructure.ReturnValue = False;
		ReturnStructure.Status 		= "Our apologies, but we can't connect your bank at the moment. Our team is working on resolving this";
		ReturnStructure.IsMFA		= False;
		PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "The refresh has finished...", 2), TempStorageAddress);
		
	EndTry;
	
EndProcedure

//Continues the refresh after a user filled in required MFA fields
//Parameters:
// ProgrammaticElems - structure. Contains answer from the user
// Params - returned from notify params:
//   ItemID - ID of the account being updated
//Return value:
// Structure - returns the following properties:
//	ReturnValue - boolean - true if succeeded
// 	Status - refresh status description
//	IsMFA - whether refresh requires MFA response or not
//	ProgrammaticElements - array of structures, containing MFA fields description
//	ProgrammaticElementsValidValues - array of structures, containing predefined set of possible values
//
Function ContinueMFARefresh(ProgrammaticElems, Params, TempStorageAddress = Undefined) Export
	Try
		ReturnStructure = New Structure("ReturnValue, Status, IsMFA");
		ItemIdDescription = "ItemID: " + Format(Params.itemId, "NGS=' '; NZ=") + ".";
		
		If TypeOf(ProgrammaticElems) <> Type("Array") Then
			WriteLogEvent("Yodlee.ContinueMFARefresh", EventLogLevel.Error,,, "Parameter ""ProgrammaticElems"" in the ContinueMFARefresh function is not of type ""Array""");	
			ReturnStructure.Insert("ReturnValue", False);
			ReturnStructure.Insert("Status", "User input is empty");
			If TempStorageAddress <> Undefined Then
				PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, ReturnStructure.Status, 3), TempStorageAddress);
			EndIf;
			return ReturnStructure;
		EndIf;
		
		ResultStructure = YodleeREST.PutMFARequest_REST(Params.itemID, ProgrammaticElems);
		
		ErrorOccurred = False;
		If Not ResultStructure.Success Then
			ErrorOccurred = True;
		ElsIf Not ResultStructure.Result.primitiveObj Then
			ErrorOccurred = True;
		EndIf;
		If ErrorOccurred Then
			ReturnStructure.ReturnValue = False;
			ReturnStructure.Status 		= "Our apologies, but we can't connect your bank at the moment. Please, try to repeat the operation after a while";
			ReturnStructure.IsMFA		= True;
			PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "The refresh has finished...", 3), TempStorageAddress);
			return ReturnStructure;
		EndIf;
		
		//RefreshProcess = YodleeMain.RefreshProcess;
		//If RefreshProcess.fieldInfoType = "TokenIdFieldInfo" Then
		//	If ProgrammaticElems.Count() > 0 Then
		//		Elem = FindElementByName(ProgrammaticElems, "Token");
		//		If Elem <> Undefined Then
		//			RefreshProcess.currentAnswer = Elem.ElementValue;
		//		EndIf;
		//	EndIf;
		//ElsIf RefreshProcess.fieldInfoType = "SecurityQuestionFieldInfo" Then
		//	For i = 0 To (RefreshProcess.totalNumberOfQuestions - 1) Do
		//		Elem = FindElementByName(ProgrammaticElems, "Question_" + String(i));
		//		If Elem <> Undefined Then
		//			RefreshProcess.AppendAnswer(i, Elem.ElementValue);
		//		EndIf;
		//	EndDo;
		//EndIf;
	
		//RefreshProcess = YodleeMain.refreshItem_putMFARequest(Params.ItemId, RefreshProcess);
		//If TempStorageAddress <> Undefined Then
		//	PutToTempStorage(New Structure("Params, CurrentStatus, Step", , "Getting MFA response from the server", 3), TempStorageAddress);
		//EndIf;
		
		RefreshResultStructure = ProcessMFARefresh(Params.ItemId, itemIdDescription);
		While RefreshResultStructure.Success And Not RefreshResultStructure.IsMessageAvailable Do
			RefreshResultStructure = ProcessMFARefresh(Params.itemId, itemIdDescription);
		EndDo;
		RefreshResultStructure.Insert("IsMFA", True);
		
		If RefreshResultStructure.Success Then
			If RefreshResultStructure.MFARefreshSucceeded Then
				//Update bank account attributes and upload new transactions
				BankAccountsStructure = YodleeREST.ObtainBankAccounts(Params.itemID);
				//Finish refresh. Go to the assigning of G/L accounts
				ReturnStructure.ReturnValue = RefreshResultStructure.Success And BankAccountsStructure.Success;
				ReturnStructure.Status 		= RefreshResultStructure.ErrorDescription + ?(IsBlankString(RefreshResultStructure.ErrorDescription), "", Chars.LF) + BankAccountsStructure.ErrorDescription;
				ReturnStructure.IsMFA		= RefreshResultStructure.IsMFA;
				ReturnStructure.Insert("BankAccounts", BankAccountsStructure.Result);
				PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "The refresh has finished...", 2), TempStorageAddress);
			Else
				//Present MFA form to the user
				PutToTempStorage(New Structure("Params, CurrentStatus, Step", RefreshResultStructure, "Obtained MFA fields...", 3), TempStorageAddress);
			EndIf;
		Else
			ReturnStructure.ReturnValue = False;
			ReturnStructure.Status 		= "Our apologies, but we can't connect your bank at the moment. Our team is working on resolving this";
			ReturnStructure.IsMFA		= True;
			PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "The refresh has finished...", 3), TempStorageAddress);
		EndIf; 
		
	Except
		ErrorDescription = ErrorDescription();	
		WriteLogEvent("Yodlee.ContinueMFARefresh", EventLogLevel.Error,,, itemIdDescription + ErrorDescription);
		ReturnStructure.ReturnValue = False;
		ReturnStructure.Status 		= "Our apologies, but we can't connect your bank at the moment. Our team is working on resolving this";
		ReturnStructure.IsMFA		= False;
		PutToTempStorage(New Structure("Params, CurrentStatus, Step", ReturnStructure, "The refresh has finished...", 3), TempStorageAddress);
	EndTry;
	return ReturnStructure;
	
EndFunction

Procedure MarkBankAccountAsDisconnected(ItemID, ItemAccountID) Export
	
	RecordSet = InformationRegisters.DisconnectedBankAccounts.CreateRecordSet();
	ItemIdFilter = RecordSet.Filter.ItemID;
	ItemAccountIDFilter = RecordSet.Filter.ItemAccountID;
	ItemIDFilter.Use = True;
	ItemIDFilter.ComparisonType = ComparisonType.Equal;
	ItemIDFilter.Value = ItemID;
	ItemAccountIDFilter.Use = True;
	ItemAccountIDFilter.ComparisonType = ComparisonType.Equal;
	ItemAccountIDFilter.Value = ItemAccountID;
	NewRecord = RecordSet.Add();
	NewRecord.Active = True;
	NewRecord.ItemID = ItemID;
	NewRecord.ItemAccountID = ItemAccountID;
	RecordSet.Write(True);

EndProcedure

Procedure MarkBankAccountAsConnected(ItemID, ItemAccountID) Export
	
	RecordSet = InformationRegisters.DisconnectedBankAccounts.CreateRecordSet();
	ItemIdFilter = RecordSet.Filter.ItemID;
	ItemAccountIDFilter = RecordSet.Filter.ItemAccountID;
	ItemIDFilter.Use = True;
	ItemIDFilter.ComparisonType = ComparisonType.Equal;
	ItemIDFilter.Value = ItemID;
	ItemAccountIDFilter.Use = True;
	ItemAccountIDFilter.ComparisonType = ComparisonType.Equal;
	ItemAccountIDFilter.Value = ItemAccountID;
	RecordSet.Write(True);

EndProcedure

#EndRegion

#Region PRIVATE_IMPLEMENTATION

//Check for a user registration
//If a user is not registered then register a user
// Parameters:
//  cobSessionToken - string - COB session token to be passed to the Yodlee
// Returns:
//  Structure :
//   Success - boolean - true if the function succeeded, false if the function  failed
//   ErrorDescription - string - if the function failed then contains a description of an error
Function RegisterUser(cobSessionToken)
	Try
		// First time use. Register a user
		ReturnStructure = New Structure("success, ErrorDescription", False, "");
		Tenant		= SessionParameters.TenantValue;
		UserName 	= "User_" + TrimAll(Tenant);
		UserPassword = GeneratePassword(20);
		URLstring = "https://consolidatedsdk.yodlee.com/yodsoap/srest/yellowlabs/v1.0/jsonsdk/UserRegistration/register3";

		InputParameters = New Structure();
		InputParameters.Insert("cobSessionToken", cobSessionToken);
		InputParameters.Insert("userCredentialsloginName", UserName);
		InputParameters.Insert("userCredentialspassword", UserPassword);
		InputParameters.Insert("userCredentialsobjectInstanceType", "com.yodlee.ext.login.PasswordCredentials");
		InputParameters.Insert("userProfileemailAddress", Constants.Email.Get());
		InputData = InternetConnectionClientServer.EncodeQueryData(InputParameters);
		
		InputData = StrReplace(InputData,"userCredentialsloginName", "userCredentials.loginName");
		InputData = StrReplace(InputData,"userCredentialspassword", "userCredentials.password");
		InputData = StrReplace(InputData,"userProfileemailAddress", "userProfile.emailAddress");
		InputData = StrReplace(InputData,"userCredentialsobjectInstanceType", "userCredentials.objectInstanceType");
		
		ConnectionSettings = New Structure;
		Connection = InternetConnectionClientServer.CreateConnection(URLstring + "?" + InputData, ConnectionSettings).Result;
		ResultBody = InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings);
		
		ResultBodyJSON = ProcessRESTResult(ResultBody, ReturnStructure, "Yodlee.RegisterUser", "An error occured while registering a user """ + UserName + """ with tenant " + Tenant + ". Error message: ");
	
		If ResultBodyJSON = Undefined Then
			return ReturnStructure;
		Else
			Constants.YodleeUserName.Set(UserName);
			Constants.YodleeUserPassword.Set(UserPassword);
			sessionToken = ResultBodyJSON.userContext.conversationCredentials.sessionToken;
			Constants.YodleeUserSessionToken.Set(sessionToken);
			WriteLogEvent("Yodlee.RegisterUser", EventLogLevel.Information,,, "Successfully registered user """ + UserName + """ with tenant " + Tenant);
			ReturnStructure.success = True;
			return ReturnStructure;
		EndIf;

		//// Exception handling
		//If ResultBody.Result = Undefined Then
		//	// Return error description.
		//	ReturnStructure.success = False;
		//	ReturnStructure.ErrorDescription = ResultBody.Description;
		//	WriteLogEvent("Yodlee.RegisterUser", EventLogLevel.Error,,, "An error occured while registering a user """ + UserName + """ with tenant " + Tenant + ". Error message: " + ResultBody.Description);
		//	Return ReturnStructure;
		//EndIf;
		//
		//LoginResultJSON = InternetConnectionClientServer.DecodeJSON(ResultBody.Result);

		//If LoginResultJSON.Property("Error") Then
		//	// Return error description.
		//	ReturnStructure.success 		= False;
		//	ErrorDetails						= GetErrorDetails(LoginResultJSON);
		//	ReturnStructure.ErrorDescription 	= ErrorDetails;
		//	WriteLogEvent("Yodlee.RegisterUser", EventLogLevel.Error,,, "An error occured while registering a user """ + UserName + """ with tenant " + Tenant + ". Error message: " + ErrorDetails);
		//	return ReturnStructure;
		//Else
		//	// record the new login to the database
		//	Constants.YodleeUserName.Set(UserName);
		//	Constants.YodleeUserPassword.Set(UserPassword);
		//	sessionToken = LoginResultJSON.userContext.conversationCredentials.sessionToken;
		//	Constants.YodleeUserSessionToken.Set(sessionToken);
		//	WriteLogEvent("Yodlee.RegisterUser", EventLogLevel.Information,,, "Successfully registered user """ + UserName + """ with tenant " + Tenant);
		//	ReturnStructure.success = True;
		//	return ReturnStructure;
		//EndIf;

	Except
		ErrorDescription = ErrorDescription();
		WriteLogEvent("Yodlee.RegisterUser", EventLogLevel.Error,,, ErrorDescription);
		ReturnStructure.Success = False;
		ReturnStructure.ErrorDescription = ErrorDescription;
		return ReturnStructure;
	EndTry;
	
EndFunction

Function ProcessRESTResult(ResultBody, ReturnStructure, LogEvent, LogMessageTitle)
	
	// Exception handling
	If ResultBody.Result = Undefined Then
		// Return error description.
		ReturnStructure.success = False;
		ReturnStructure.ErrorDescription = ResultBody.Description;
		WriteLogEvent(LogEvent, EventLogLevel.Error,,, LogMessageTitle + ResultBody.Description);
		Return Undefined;
	EndIf;
	ResultBodyJSON = InternetConnectionClientServer.DecodeJSON(ResultBody.Result);
	
	If LogEvent <> "Yodlee.ExecuteUserSearchRequest" Then //Do not check obtained bank transactions
		//Ensure that  ItemID and ItemAccountID are numeric values (may be inetrpreted as UNIX dates) and perform conversions
		NumericFields = New Array();
		NumericFields.Add("itemID");
		NumericFields.Add("itemAccountID");
		FixPossibleDatesAsNumeric(ResultBodyJSON, NumericFields);
	EndIf;
	
	If ResultBodyJSON = Undefined Then
		// Return error description.
		ReturnStructure.success 			= False;
		ErrorDetails						= "The response format doesn't match JSON: " + ?(StrLen(ResultBody.Result) < 1000, ResultBody.Result, Left(ResultBody.Result, 1000));
		ReturnStructure.ErrorDescription 	= ErrorDetails;
		WriteLogEvent(LogEvent, EventLogLevel.Error,,, LogMessageTitle + ErrorDetails);
		return Undefined;
	ElsIf TypeOf(ResultBodyJSON) = Type("Structure") 
		And (ResultBodyJSON.Property("Error") Or ResultBodyJSON.Property("ErrorOccurred") 
		Or (ResultBodyJSON.Property("ErrorCode") AND Upper(LogEvent) <> Upper("Yodlee.GetMFAResponse"))) Then
		// Return error description.
		ReturnStructure.success 			= False;
		ErrorDetails						= GetErrorDetails(ResultBodyJSON);
		ReturnStructure.ErrorDescription 	= ErrorDetails;
		WriteLogEvent(LogEvent, EventLogLevel.Error,,, LogMessageTitle + ErrorDetails);
		return Undefined;
	Else
		ReturnStructure.success = True;
		return ResultBodyJSON;
	EndIf;
		
EndFunction

Procedure FixPossibleDatesAsNumeric(ResultBodyJSON, NumericFields)
	
	If TypeOf(ResultBodyJSON) = Type("Array") Then
		For Each ArrayItem In ResultBodyJSON Do
			If (TypeOf(ArrayItem) = Type("Structure")) Or (TypeOf(ArrayItem) = Type("Array")) Then
				FixPossibleDatesAsNumeric(ArrayItem, NumericFields);
			EndIf;
		EndDo;
		return;
	EndIf;
	
	For Each NumField In NumericFields Do
		If TypeOf(ResultBodyJSON) = Type("Structure") Then
			If Find(NumField, ".") > 0  Then//For value lists numfields can be with dots name.name1.name2...
				Continue;
			EndIf;
			If ResultBodyJSON.Property(NumField) Then
				If TypeOf(ResultBodyJSON[NumField]) = Type("Date") Then
					ResultBodyJSON[NumField] = ResultBodyJSON[NumField] - Date("19700101");
				EndIf;
			EndIf;		
		ElsIf TypeOf(ResultBodyJSON) = Type("ValueList") Then
			For Each ValueListItem In ResultBodyJSON Do
				If ValueListItem.Presentation = NumField Then
					If TypeOf(ValueListItem.Value) = Type("Date") Then
						ValueListItem.Value = ValueListItem.Value - Date("19700101"); 
					EndIf;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	//Check if there are fields of types: structure or array. If there are then process its members
	For Each JSONField In ResultBodyJSON Do
		If (TypeOf(JSONField.Value) = Type("Structure")) Or (TypeOf(JSONField.Value) = Type("Array")) Or (TypeOf(JSONField.Value) = Type("ValueList")) Then
			FixPossibleDatesAsNumeric(JSONField.Value, NumericFields);
		EndIf;
	EndDo;

EndProcedure

Procedure ReadStructureValueSafely(DestValue, SrcStruct, Prop1, Prop2 = Undefined)
	
	Try
		Prop1Value = Undefined;
		Prop2Value = Undefined;
		If SrcStruct.Property(Prop1, Prop1Value) Then
			If Prop2 = Undefined Then
				DestValue = Prop1Value;
			Else
				If Prop1Value.Property(Prop2, Prop2Value) Then
					DestValue = Prop2Value;
				Else
					return;
				EndIf;
			EndIf;
		Else
			return;
		EndIf;
	Except
		return;
	EndTry;
	
EndProcedure

Function GeneratePassword(PasswordLength)   
	SymbolString = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"; //62
	Password = "";
	RNG = New RandomNumberGenerator;	
	For i = 0 to PasswordLength-1 Do
		RN = RNG.RandomNumber(1, 62);
		Password = Password + Mid(SymbolString,RN,1);
	EndDo;
 	return Password; 
EndFunction

Function GetErrorDetails(ResultBodyJSON)
	
	ErrorDescription = "";
	If ResultBodyJSON.Property("Error") Then
		// Return error description.
		If TypeOf(ResultBodyJSON.Error) = Type("Array") Then
			For Each Error In ResultBodyJSON.Error Do
				ErrorDescription = ErrorDescription + ?(StrLen(ErrorDescription) > 0, Chars.LF, "") + Error.ErrorDetail;
			EndDo;
		EndIf;
	EndIf;
	If ResultBodyJSON.Property("ErrorOccurred") Then
		Try ErrorDescription = ErrorDescription + "Exception type: " + ResultBodyJSON.exceptionType + ";" + Chars.LF Except EndTry;
		Try ErrorDescription = ErrorDescription + "Message: " + ResultBodyJSON.message + ";" + Chars.LF Except EndTry;
		Try ErrorDescription = ErrorDescription + "Reference code: " + ResultBodyJSON.referenceCode + ";" Except EndTry;
	EndIf;
	If ResultBodyJSON.Property("ErrorCode") Then
		Try ErrorDescription = ErrorDescription + "Exception detail: " + ResultBodyJSON.errorDetail + ";" Except EndTry;
	EndIf;
	return ErrorDescription;

EndFunction

//Find structures in array
Function FindRows(PE, SearchStruct)
	FoundRows = New Array();
	For Each PEStr In PE Do
		FoundAll = True;
		For Each SearchElement In SearchStruct Do
			If PEStr[SearchElement.Key] <> SearchElement.Value Then
				FoundAll = False;
				Break;
			EndIf;
		EndDo;
		If FoundAll Then
			FoundRows.Add(PEStr);
		EndIf;
	EndDo;
	Return FoundRows;
EndFunction

Function GetFieldType(FieldTypeStructure)
	If TypeOf(FieldTypeStructure) <> Type("Structure") Then
		return -1;
	EndIf;
	If Not FieldTypeStructure.Property("typeName") Then
		return -1;
	EndIf;
	UTypeName = Upper(FieldTypeStructure.typeName);
	If Find(UtypeName, "TEXT") > 0 Then
		return 0;
	ElsIf Find(UtypeName, "PASSWORD") > 0 Then
		return 1;
	ElsIf Find(UtypeName, "OPTIONS") > 0 Then
		return 2;
	ElsIf Find(UtypeName, "CHECKBOX") > 0 Then
		return 3;
	ElsIf Find(UtypeName, "RADIO") > 0 Then
		return 4;
	ElsIf Find(UtypeName, "LOGIN") > 0 Then
		return 5;
	ElsIf Find(UtypeName, "URL") > 0 Then
		return 6;
	ElsIf Find(UtypeName, "HIDDEN") > 0 Then
		return 7;
	ElsIf Find(UtypeName, "IMAGE_URL") > 0 Then
		return 8;
	ElsIf Find(UtypeName, "CONTENT_URL") > 0 Then
		return 9;
	ElsIf Find(UtypeName, "CUSTOM") > 0 Then
		return 10;
	ElsIf Find(UtypeName, "CLUDGE") > 0 Then
		return 11;
	Else
		return -1;
	EndIf;
EndFunction

#EndRegion

#Region FUNCTIONS_TO_REVIEW
////////////////////////////////////////////////////////////////////////////////
// Functions to review
//------------------------------------------------------------------------------

// REST Method used: coblogin
// Authenticates our cobrand credentials
// Returns a session token, which expires every 100 minutes
Function GetCobSessionToken() Export
	
	URLstring = "https://consolidatedsdk.yodlee.com/yodsoap/srest/yellowlabs/v1.0/authenticate/coblogin";
	InputParameters = New Structure();
	InputParameters.Insert("cobrandLogin",ServiceParameters.YodleeCobrandLogin());
	InputParameters.Insert("cobrandPassword",ServiceParameters.YodleeCobrandPassword());
	InputData = InternetConnectionClientServer.EncodeQueryData(InputParameters);
	
	ConnectionSettings = New Structure;
	Connection = InternetConnectionClientServer.CreateConnection(URLstring + "?" + InputData, ConnectionSettings).Result;
	ResultBody = InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings);
	If ResultBody.Result = Undefined Then
		// Return error description.
		Return ResultBody;
	EndIf;
	ResultBodyJSON = InternetConnectionClientServer.DecodeJSON(ResultBody.Result);
	
	Return ResultBodyJSON.cobrandConversationCredentials.sessionToken;
		
EndFunction

// REST method used: login or register3
// Logs in the consumer(user). If it is a new yodlee consumer, it instead registers a new username/password
// Returns a userSession token, which expires every 30 mins
Function GetUserSessionToken(cobSessionToken) Export
	
	Try
		URLstring = "https://consolidatedsdk.yodlee.com/yodsoap/srest/yellowlabs/v1.0/authenticate/login";
		
		InputParameters = New Structure();
		InputParameters.Insert("cobSessionToken", cobSessionToken);
		InputParameters.Insert("login", Constants.YodleeUserName.Get());
		InputParameters.Insert("password", Constants.YodleeUserPassword.Get());
		InputData = InternetConnectionClientServer.EncodeQueryData(InputParameters);
		
		ConnectionSettings = New Structure;
		Connection = InternetConnectionClientServer.CreateConnection(URLstring + "?" + InputData, ConnectionSettings).Result;
		LoginResult = InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings).Result;
		LoginResultJSON = InternetConnectionClientServer.DecodeJSON(LoginResult);
		
		Return LoginResultJSON.userContext.conversationCredentials.sessionToken;
		
	Except
		
		UserName = "User" + String(SessionParameters.TenantValue);
		UserPassword = GeneratePassword(20);
		URLstring = "https://consolidatedsdk.yodlee.com/yodsoap/srest/yellowlabs/v1.0/jsonsdk/UserRegistration/register3";

		InputParameters = New Structure();
		InputParameters.Insert("cobSessionToken", cobSessionToken);
		InputParameters.Insert("userCredentialsloginName", UserName);
		InputParameters.Insert("userCredentialspassword", UserPassword);
		InputParameters.Insert("userCredentialsobjectInstanceType", "com.yodlee.ext.login.PasswordCredentials");
		InputParameters.Insert("userProfileemailAddress", Constants.Email.Get());
		InputData = InternetConnectionClientServer.EncodeQueryData(InputParameters);
		
		InputData = StrReplace(InputData,"userCredentialsloginName", "userCredentials.loginName");
		InputData = StrReplace(InputData,"userCredentialspassword", "userCredentials.password");
		InputData = StrReplace(InputData,"userProfileemailAddress", "userProfile.emailAddress");
		InputData = StrReplace(InputData,"userCredentialsobjectInstanceType", "userCredentials.objectInstanceType");
		
		ConnectionSettings = New Structure;
		Connection = InternetConnectionClientServer.CreateConnection(URLstring + "?" + InputData, ConnectionSettings).Result;
		LoginResult = InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings).Result;
		LoginResultJSON = InternetConnectionClientServer.DecodeJSON(LoginResult);
		
		Constants.YodleeUserName.Set(UserName);
		Constants.YodleeUserPassword.Set(UserPassword);
		
		Return LoginResultJSON.userContext.conversationCredentials.sessionToken;
		
	EndTry;
	
EndFunction

// Provides a list of fields needed to create a login form associated with the give contentServiceId
// Returns a data JSON string
Function GetLoginFormForContentService(cobSessionToken, contentServiceId) Export 
	
	URLstring = "https://consolidatedsdk.yodlee.com/yodsoap/srest/yellowlabs/v1.0/jsonsdk/ItemManagement/getLoginFormForContentService";
		
	InputParameters = New Structure();
	InputParameters.Insert("cobSessionToken", cobSessionToken);
	InputParameters.Insert("contentServiceId", ContentServiceID);
	InputData = InternetConnectionClientServer.EncodeQueryData(InputParameters);
	
	ConnectionSettings = New Structure;
	Connection = InternetConnectionClientServer.CreateConnection(URLstring + "?" + InputData, ConnectionSettings).Result;
	
	Return InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings).Result;
		
EndFunction

// Gets the details of the content service associated to the ID, which refers to a specific container(bank)
// Returns in data JSON string form 
Function GetContentServiceInfo1(cobSessionToken, contentServiceId) Export
	
	URLstring = "https://consolidatedsdk.yodlee.com/yodsoap/srest/yellowlabs/v1.0/jsonsdk/ContentServiceTraversal/getContentServiceInfo1";
	InputParameters = New Structure();
	InputParameters.Insert("cobSessionToken", cobSessionToken);
	InputParameters.Insert("contentServiceId", ContentServiceID);
	InputParameters.Insert("reqSpecifier", "128");
	InputParameters.Insert("notrim", "true");
	
	InputData = InternetConnectionClientServer.EncodeQueryData(InputParameters);
	
	ConnectionSettings = New Structure;
	Connection = InternetConnectionClientServer.CreateConnection(URLstring + "?" + InputData, ConnectionSettings).Result;
	
	Return InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings).Result;
	
EndFunction

// Tells Yodlee to refresh the specified item.
// Returns a JSON string with statusCode
Function StartRefresh7(cobSessionToken, userSessionToken, itemId, isMFA) Export
	
	URLstring = "https://consolidatedsdk.yodlee.com/yodsoap/srest/yellowlabs/v1.0/jsonsdk/Refresh/startRefresh7";
	
	InputParameters = New Structure();
	InputParameters.Insert("cobSessionToken", cobSessionToken);
	InputParameters.Insert("userSessionToken", userSessionToken);
	InputParameters.Insert("itemId", itemId);
	If isMFA Then
		InputParameters.Insert("refreshParametersrefreshModerefreshMode", "MFA");
		InputParameters.Insert("refreshParametersrefreshModerefreshModeId", 1);
	Else
		InputParameters.Insert("refreshParametersrefreshModerefreshMode", "NORMAL");
		InputParameters.Insert("refreshParametersrefreshModerefreshModeId", 2);
	EndIf;
	InputParameters.Insert("refreshParametersrefreshPriority", 1); // High Priority 
	
	InputData = InternetConnectionClientServer.EncodeQueryData(InputParameters);
	InputData = StrReplace(InputData,"refreshParametersrefreshModerefreshMode","refreshParameters.refreshMode.refreshMode");
	InputData = StrReplace(InputData,"refreshParametersrefreshModerefreshModeId","refreshParameters.refreshMode.refreshModeId");
	InputData = StrReplace(InputData,"refreshParametersrefreshPriority","refreshParameters.refreshPriority");
	
	ConnectionSettings = New Structure;
	Connection = InternetConnectionClientServer.CreateConnection(URLstring + "?" + InputData, ConnectionSettings).Result;
	
	Return InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings).Result;
	
EndFunction

// Checks if the account is still being refreshed
// Returns a boolean value in a JSON string
Function IsItemRefreshing(cobSessionToken, userSessionToken, itemId) Export
	
	URLstring = "https://consolidatedsdk.yodlee.com/yodsoap/srest/yellowlabs/v1.0/jsonsdk/Refresh/isItemRefreshing";
		
	InputParameters = New Structure();
	InputParameters.Insert("cobSessionToken", cobSessionToken);
	InputParameters.Insert("userSessionToken", userSessionToken);
	InputParameters.Insert("memItemId", itemId);
	InputData = InternetConnectionClientServer.EncodeQueryData(InputParameters);
	
	ConnectionSettings = New Structure;
	Connection = InternetConnectionClientServer.CreateConnection(URLstring + "?" + InputData, ConnectionSettings).Result;
	
	Return InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings).Result;

	
EndFunction

// Provides info for object recently refreshed
// Returns a Data JSON string
Function GetRefreshInfo1(cobSessionToken, userSessionToken, itemId) Export
	URLstring = "https://consolidatedsdk.yodlee.com/yodsoap/srest/yellowlabs/v1.0/jsonsdk/Refresh/getRefreshInfo1";
					
	InputParameters = New Structure();
	InputParameters.Insert("cobSessionToken", cobSessionToken);
	InputParameters.Insert("userSessionToken", userSessionToken);
	InputParameters.Insert("itemIds0", itemId);
	
	InputData = InternetConnectionClientServer.EncodeQueryData(InputParameters);
	InputData = StrReplace(InputData,"itemIds0","itemIds[0]");
	
	ConnectionSettings = New Structure;
	Connection = InternetConnectionClientServer.CreateConnection(URLstring + "?" + InputData, ConnectionSettings).Result;
	
	Return InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings).Result;
	
EndFunction

// Retrieves details about an item(bank acocunt)
// Returns a Data JSON string
Function GetItemSummaryForItem1(cobSessionToken, userSessionToken, itemId) Export
	
	URLstring = "https://consolidatedsdk.yodlee.com/yodsoap/srest/yellowlabs/v1.0/jsonsdk/DataService/getItemSummaryForItem1";
				
	InputParameters = New Structure();
	InputParameters.Insert("cobSessionToken", cobSessionToken);
	InputParameters.Insert("userSessionToken", userSessionToken);
	InputParameters.Insert("itemId", itemId);
	InputParameters.Insert("dexstartLevel", 0);
	InputParameters.Insert("dexendLevel", 0);
	InputParameters.Insert("dexextentLevels0", 4);
	InputParameters.Insert("dexextentLevels1", 4);
	
	InputData = InternetConnectionClientServer.EncodeQueryData(InputParameters);
	InputData = StrReplace(InputData,"dexstartLevel","dex.startLevel");
	InputData = StrReplace(InputData,"dexendLevel","dex.endLevel");
	InputData = StrReplace(InputData,"dexextentLevels0","dex.extentLevels[0]");
	InputData = StrReplace(InputData,"dexextentLevels1","dex.extentLevels[1]");

	
	ConnectionSettings = New Structure;
	Connection = InternetConnectionClientServer.CreateConnection(URLstring + "?" + InputData, ConnectionSettings).Result;
	
	Return InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings).Result;
	
EndFunction

// Gets the last 100 transactions from LastDate to the current date of the given account
// Returns in a Data JSON string
Function ExecuteUserSearchRequest(cobSessionToken, userSessionToken, ItemAccountID, LastDate ) Export
	
	URLstring = "https://consolidatedsdk.yodlee.com/yodsoap/srest/yellowlabs/v1.0/jsonsdk/TransactionSearchService/executeUserSearchRequest";
	
	currentDate = TurnDateIntoStr(String(CurrentSessionDate()));
	fromDate = TurnDateIntoStr(String(LastDate));

	InputParameters = New Structure();
	InputParameters.Insert("cobSessionToken", cobSessionToken);
	InputParameters.Insert("userSessionToken", userSessionToken);
	InputParameters.Insert("transactionSearchRequestcontainerType", "All");
	InputParameters.Insert("transactionSearchRequesthigherFetchLimit", "500");
	InputParameters.Insert("transactionSearchRequestlowerFetchLimit", "1");
	InputParameters.Insert("transactionSearchRequestresultRangeendNumber", "200");
	InputParameters.Insert("transactionSearchRequestresultRangestartNumber", "1");
	InputParameters.Insert("transactionSearchRequestsearchFiltercurrencyCode", "USD");
	InputParameters.Insert("transactionSearchRequestignoreUserInput", "true");
	InputParameters.Insert("transactionSearchRequestsearchFilteritemAccountIdidentifier", ItemAccountID);
	InputParameters.Insert("transactionSearchRequestsearchFilterpostDateRangetoDate", currentDate);
	//InputParameters.Insert("transactionSearchRequestsearchFilterpostDateRangetoDate", "12-15-2014");
	InputParameters.Insert("transactionSearchRequestsearchFilterpostDateRangefromDate", fromDate);
	//InputParameters.Insert("transactionSearchRequestsearchFilterpostDateRangefromDate", "01--2015");
	
	InputData = InternetConnectionClientServer.EncodeQueryData(InputParameters);
	InputData = StrReplace(InputData,"transactionSearchRequestcontainerType","transactionSearchRequest.containerType");
	InputData = StrReplace(InputData,"transactionSearchRequesthigherFetchLimit","transactionSearchRequest.higherFetchLimit");
	InputData = StrReplace(InputData,"transactionSearchRequestlowerFetchLimit","transactionSearchRequest.lowerFetchLimit");
	InputData = StrReplace(InputData,"transactionSearchRequestresultRangeendNumber","transactionSearchRequest.resultRange.endNumber");
	InputData = StrReplace(InputData,"transactionSearchRequestresultRangestartNumber","transactionSearchRequest.resultRange.startNumber");
	InputData = StrReplace(InputData,"transactionSearchRequestsearchFiltercurrencyCode","transactionSearchRequest.searchFilter.currencyCode");
	InputData = StrReplace(InputData,"transactionSearchRequestignoreUserInput","transactionSearchRequest.ignoreUserInput");
	InputData = StrReplace(InputData,"transactionSearchRequestsearchFilteritemAccountIdidentifier","transactionSearchRequest.searchFilter.itemAccountId.identifier");
	InputData = StrReplace(InputData,"transactionSearchRequestsearchFilterpostDateRangetoDate","transactionSearchRequest.searchFilter.postDateRange.toDate");
	InputData = StrReplace(InputData,"transactionSearchRequestsearchFilterpostDateRangefromDate","transactionSearchRequest.searchFilter.postDateRange.fromDate");
	
	ConnectionSettings = New Structure;
	Connection = InternetConnectionClientServer.CreateConnection(URLstring + "?" + InputData, ConnectionSettings).Result;
	ResultStr = InternetConnectionClientServer.SendRequest(Connection, "Post", ConnectionSettings).Result;
	ResultStr = StrReplace(ResultStr,"""transactionId"":","""transactionId"":""");
	ResultStr = StrReplace(ResultStr,",""containerType",""",""containerType");
	
	Return ResultStr;
	
EndFunction

Function TurnDateIntoStr(DateStr)
	DateStr = Left(DateStr, Find(DateStr," ") - 1);
	
	Month = Left(DateStr, Find(DateStr,"/") - 1);
	Remaining = Right(DateStr, StrLen(DateStr) - Find(DateStr,"/"));
	Day = Left(Remaining, Find(Remaining,"/") - 1);
	Year = Right(Remaining, StrLen(Remaining) - Find(Remaining,"/"));
	
	If StrLen(Month) = 1 Then
		Month = "0" + Month;	
	EndIf;
	
	If StrLen(Day) = 1 Then
		Day = "0" + Day;	
	EndIf;
	
	Return Month + "-" + Day + "-" + Year;
		
EndFunction

#EndRegion

#Region CREATE_DOCUMENTS

Procedure YodleeDownloadingTransactionsAtServer()
	
	BeginTransaction();

	//--//
	Block = New DataLock();
	LockItem = Block.Add("InformationRegister.BankTransactions");
	LockItem.Mode = DataLockMode.Exclusive;
	Block.Lock();
	//--//
	
	Query = New Query;
	Query.Text = "SELECT
	             |	BankTransactions.TransactionDate,
	             |	BankTransactions.BankAccount,
	             |	BankTransactions.Company,
	             |	BankTransactions.ID,
	             |	BankTransactions.Description,
	             |	BankTransactions.Amount,
	             |	BankTransactions.Category,
	             |	BankTransactions.Document,
	             |	BankTransactions.Accepted,
	             |	BankTransactions.Hidden,
	             |	BankTransactions.OriginalID,
	             |	BankTransactions.YodleeTransactionID,
	             |	BankTransactions.Class,
	             |	BankTransactions.Project,
	             |	BankTransactions.CheckNumber,
	             |	BankTransactions.SimpleDescription,
	             |	BankTransactions.MerchantName,
	             |	BankTransactions.PostDate,
	             |	BankTransactions.Price,
	             |	BankTransactions.Quantity,
	             |	BankTransactions.RunningBalance,
	             |	BankTransactions.CurrencyCode,
	             |	BankTransactions.CategoryID,
	             |	BankTransactions.Type,
	             |	BankTransactions.CategorizedCompanyNotAccepted,
	             |	BankTransactions.CategorizedCategoryNotAccepted,
	             |	BankTransactions.OrderID,
	             |	BankTransactions.Imported
	             |FROM
	             |	InformationRegister.BankTransactions AS BankTransactions
	             |WHERE
	             |	BankTransactions.Accepted = FALSE
	             |	AND BankTransactions.Document = UNDEFINED
	             |	AND BankTransactions.YodleeTransactionID <> 0";
				 
	VT = Query.Execute().Unload();//-------------------------------------------------------------VT	
	
	//
	UpdatedData = New ValueTable;
	UpdatedData.Columns.Add("Bank");
	UpdatedData.Columns.Add("BankAccount");
	UpdatedData.Columns.Add("DateBeginOfMonth");
	
	TableOfRules = GetTableOfRules();//? BatchResult = Query.ExecuteBatch(); VT = BatchResult[0].Unload();
	
	Try
						
		For Each CurrentRow In VT Do
			
			//------------------------------------------------------------------------------------------------
			If CurrentRow.Amount > 0 Then
				CurrentRow.Category     = CurrentRow.BankAccount.DefaultDepositAccount;
			Else
				
				CurrentRow.Company      = GetCompanyByMatch(CurrentRow.Description, TableOfRules);
				
				If CurrentRow.Company.Vendor And ValueIsFilled(CurrentRow.Company.ExpenseAccount) Then
					CurrentRow.Category = CurrentRow.Company.ExpenseAccount;
				ElsIf CurrentRow.Company.Customer And ValueIsFilled(CurrentRow.Company.IncomeAccount) Then
					CurrentRow.Category = CurrentRow.Company.IncomeAccount;
				Else
					CurrentRow.Category = CurrentRow.BankAccount.DefaultCheckAccount;
				EndIf;
				
			EndIf;
			//------------------------------------------------------------------------------------------------
			
			CreateDoc(CurrentRow, UpdatedData);	
		EndDo;
		
	Except
		
		ErrorDescription = ErrorDescription();
		
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		
		//
		WriteLogEvent(
		"Yodlee.UpdateDownloadedTransactions",
		EventLogLevel.Error,
		,
		,
		NStr("en = 'Error description: '") + ErrorDescription);
		
		Return;
		
	EndTry;	
	
	CommitTransaction();
	
	//------------------------------------------------------------
	UpdatedData.GroupBy("Bank, BankAccount, DateBeginOfMonth");  
	
	For Each NewRow In UpdatedData Do
		Amounts = GetStructureOfAmounts(); 
		
		FillBankTransactions(NewRow.Bank, NewRow.BankAccount, NewRow.DateBeginOfMonth, Amounts);
		RecordTotalsToBankRec(NewRow.BankAccount, NewRow.DateBeginOfMonth, Amounts);
		
		//Save ProcessingMonth constant
		Constants.CFO_ProcessingMonth.Set(EndOfMonth(NewRow.DateBeginOfMonth));
	EndDo;

EndProcedure

//-----------------------------------------------

Function GetTableOfRules()
	
	VT = New ValueTable;
	
	Query = New Query;
	Query.Text = "SELECT
	             |	Companies.Ref AS Company,
	             |	Companies.ImportMatch AS Rule
	             |FROM
	             |	Catalog.Companies AS Companies
	             |WHERE
	             |	Companies.ImportMatch <> """"
	             |	AND Companies.DeletionMark = FALSE";
	
	VT = Query.Execute().Unload();
	
	For Each LineVT In VT Do
		LineVT.Rule = StrReplace(LineVT.Rule, "\", "\\");
		LineVT.Rule = StrReplace(LineVT.Rule, "_", "\_");
		LineVT.Rule = StrReplace(LineVT.Rule, "[", "\[");
		LineVT.Rule = StrReplace(LineVT.Rule, "]", "\]");
		LineVT.Rule = StrReplace(LineVT.Rule, "^", "\^");
		LineVT.Rule = StrReplace(LineVT.Rule, "%", "\%");
		
		LineVT.Rule = StrReplace(LineVT.Rule, "*", "%");
	EndDo;
	
	Return VT;
	
EndFunction

Function GetCompanyByMatch(SearchString, TableOfRules)
	
	FoundCompany = Catalogs.Companies.EmptyRef();
	
	Query = New Query;
	Query.Text = "SELECT
	             |	RulesTable.Rule AS Rule,
	             |	RulesTable.Company AS Company
	             |INTO RulesTable
	             |FROM
	             |	&TableOfRules AS RulesTable
	             |
	             |INDEX BY
	             |	Rule
	             |;
	             |
	             |////////////////////////////////////////////////////////////////////////////////
	             |SELECT
	             |	RulesTable.Company
	             |FROM
	             |	RulesTable AS RulesTable
	             |WHERE
	             |	&ImportMatch LIKE RulesTable.Rule ESCAPE ""\""";
	
	Query.SetParameter("TableOfRules", TableOfRules);
	Query.SetParameter("ImportMatch", SearchString);
	
	SelectionDetailRecords = Query.Execute().Select();
	
	If SelectionDetailRecords.Count() = 1 Then
		
		While SelectionDetailRecords.Next() Do
			FoundCompany = SelectionDetailRecords.Company;
		EndDo;
		
	EndIf;
	
	Return FoundCompany; 
	
EndFunction

Function GetStructureOfAmounts()
	
	Return New Structure("BalanceStart, BalanceEnd, DepositsTotal, DepositsEntered, PaymentsTotal, PaymentsEntered", 0, 0, 0, 0, 0, 0);   
	
EndFunction

//-------------------------------------------------

Procedure CreateDoc(Tran, UpdatedData)
		
	If Tran.Amount = 0
		Or (Not ValueIsFilled(Tran.Category))
		Or (Not ValueIsFilled(Tran.TransactionDate))
		Then
		Return;
	EndIf;
	
	//--//
	If Tran.Amount < 0 Then//Create Check
		Tran.Document = Create_DocumentCheck(Tran);
	ElsIf Tran.Amount > 0 Then//Create Deposit
		Tran.Document = Create_DocumentDeposit(Tran);
	Else
		Return;
	EndIf;
	
	//
	NewRow = UpdatedData.Add();
	NewRow.Bank             = Tran.BankAccount;
	NewRow.BankAccount      = Tran.BankAccount.AccountingAccount;
	NewRow.DateBeginOfMonth = BegOfMonth(Tran.TransactionDate);
	
	//Update current row to a information register
	BTRecordset = InformationRegisters.BankTransactions.CreateRecordSet();
	BTRecordset.Filter.ID.Set(Tran.ID);
	BTRecordset.Read();
	
	For Each NewRecord In BTRecordset Do 
		FillPropertyValues(NewRecord, Tran);
		//NewRecord.TransactionDate = BegOfMonth(Tran.TransactionDate);	//Alexander
		NewRecord.Accepted 		  = True;
		//--//NewRecord.OrderID		= Tran.Sequence;
	EndDo;
	
	BTRecordset.Write(True);
	
EndProcedure

Function Create_DocumentCheck(Tran)	
	
	NewCheck = Documents.Check.CreateDocument();
	NewCheck.Date = BegOfMonth(Tran.TransactionDate);
	
	If ValueIsFilled(Tran.CheckNumber) Then
		NewCheck.Number = Tran.CheckNumber;
	EndIf;
	NewCheck.BankAccount 		= Tran.BankAccount.AccountingAccount;
	NewCheck.Memo 				= Tran.Description;
	NewCheck.Company 			= Tran.Company;
	NewCheck.DocumentTotal 		= -Tran.Amount;
	NewCheck.DocumentTotalRC 	= -Tran.Amount;
	NewCheck.ExchangeRate 		= 1;
	Try
		RefNum = Number(Tran.CheckNumber);
	Except
		RefNum = 0;
	EndTry;
	If (RefNum > 100) And (RefNum < 99999999) Then
		NewCheck.PaymentMethod 	= Catalogs.PaymentMethods.Check;
	Else
		NewCheck.PaymentMethod	= Catalogs.PaymentMethods.DebitCard;
	EndIf;
	NewCheck.Project			= Tran.Project;
	NewCheck.gh_date 			= Tran.TransactionDate;
	NewCheck.AutoGenerated		= True;
	
	NewCheck.LineItems.Clear();
	NewLine = NewCheck.LineItems.Add();
	NewLine.Account 			= Tran.Category;
	NewLine.Amount 				= -Tran.Amount;
	NewLine.Memo 				= Tran.Description;
	NewLine.Class				= Tran.Class;
	NewLine.Project 			= Tran.Project;
	
	NewCheck.AdditionalProperties.Insert("AllowCheckNumber", True);
	NewCheck.AdditionalProperties.Insert("CFO_ProcessMonth_AllowWrite", True);
	NewCheck.Write(DocumentWriteMode.Posting);
	
	Return NewCheck.Ref;
	
EndFunction

Function Create_DocumentDeposit(Tran)
	
	NewDeposit = Documents.Deposit.CreateDocument();
	NewDeposit.Date 			= BegOfMonth(Tran.TransactionDate);
	NewDeposit.Number           = Tran.CheckNumber;
	NewDeposit.BankAccount 		= Tran.BankAccount.AccountingAccount;
	NewDeposit.Memo 			= Tran.Description;
	NewDeposit.DocumentTotal 	= Tran.Amount;
	NewDeposit.DocumentTotalRC 	= Tran.Amount;
	NewDeposit.TotalDeposits	= 0;
	NewDeposit.TotalDepositsRC	= 0;
	NewDeposit.gh_date			= Tran.TransactionDate;
	NewDeposit.AutoGenerated	= True;
		
	NewDeposit.Accounts.Clear();
	NewLine = NewDeposit.Accounts.Add();
	NewLine.Account 			= Tran.Category;
	NewLine.Memo 				= Tran.Description;
	NewLine.Company				= Tran.Company;
	NewLine.Amount 				= Tran.Amount;
	NewLine.Class 				= Tran.Class;
	NewLine.Project 			= Tran.Project;
	
	NewDeposit.AdditionalProperties.Insert("CFO_ProcessMonth_AllowWrite", True);
	NewDeposit.Write(DocumentWriteMode.Posting);
	
	Return NewDeposit.Ref;
	
EndFunction

//-----------------------------------------------

Procedure FillBankTransactions(Bank, BankAccount, DateBeginOfMonth, Amounts)
	
	Request = New Query();
	Request.Text = "SELECT ALLOWED
	               |	GeneralJournalBalanceAndTurnovers.Recorder AS Recorder,
	               |	GeneralJournalBalanceAndTurnovers.Period AS Period,
	               |	GeneralJournalBalanceAndTurnovers.AmountRCClosingBalance AS AmountRCClosingBalance,
	               |	GeneralJournalBalanceAndTurnovers.Recorder.PointInTime AS RecorderPointInTime,
	               |	GeneralJournalBalanceAndTurnovers.AmountRCOpeningBalance AS AmountRCOpeningBalance
	               |INTO Recorders
	               |FROM
	               |	AccountingRegister.GeneralJournal.BalanceAndTurnovers(&DateStart, &DateEnd, Recorder, , Account = &Account, , ) AS GeneralJournalBalanceAndTurnovers
	               |
	               |INDEX BY
	               |	Recorder
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT ALLOWED
	               |	Recorders.Recorder AS Recorder,
	               |	Recorders.Period AS Period,
	               |	Recorders.AmountRCClosingBalance AS AmountRCClosingBalance,
	               |	Recorders.RecorderPointInTime AS RecorderPointInTime
	               |INTO RecordersWithClassesAndProjects
	               |FROM
	               |	Recorders AS Recorders
	               |WHERE
	               |	NOT Recorders.Recorder IS NULL 
	               |	AND Recorders.Recorder <> UNDEFINED
	               |	AND NOT Recorders.Recorder REFS Document.GeneralJournalEntry
	               |
	               |INDEX BY
	               |	Recorder
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT ALLOWED
	               |	GeneralJournal.Recorder AS Document,
	               |	GeneralJournal.Period AS Period,
	               |	CASE
	               |		WHEN GeneralJournal.RecordType = VALUE(AccountingRecordType.Debit)
	               |			THEN GeneralJournal.AmountRC
	               |		ELSE 0
	               |	END AS Deposit,
	               |	CASE
	               |		WHEN GeneralJournal.RecordType = VALUE(AccountingRecordType.Credit)
	               |			THEN GeneralJournal.AmountRC
	               |		ELSE 0
	               |	END AS Payment,
	               |	BankTransactions.ID AS TransactionID,
	               |	BankTransactions.OrderID AS Sequence,
	               |	RecordersWithClassesAndProjects.AmountRCClosingBalance AS AmountClosingBalance,
	               |	RecordersWithClassesAndProjects.RecorderPointInTime AS RecorderPointInTime
	               |FROM
	               |	RecordersWithClassesAndProjects AS RecordersWithClassesAndProjects
	               |		LEFT JOIN AccountingRegister.GeneralJournal AS GeneralJournal
	               |			LEFT JOIN AccountingRegister.GeneralJournal AS GeneralJournal1
	               |			ON GeneralJournal.Recorder = GeneralJournal1.Recorder
	               |				AND GeneralJournal.Account <> GeneralJournal1.Account
	               |				AND (GeneralJournal.AmountRC = GeneralJournal1.AmountRC
	               |					OR GeneralJournal.AmountRC = -1 * GeneralJournal1.AmountRC)
	               |		ON RecordersWithClassesAndProjects.Recorder = GeneralJournal.Recorder
	               |			AND (GeneralJournal.Account = &Account)
	               |		LEFT JOIN InformationRegister.BankTransactions AS BankTransactions
	               |		ON RecordersWithClassesAndProjects.Recorder = BankTransactions.Document
	               |			AND (BankTransactions.BankAccount = &Bank)
	               |
	               |ORDER BY
	               |	Period,
	               |	Sequence,
	               |	GeneralJournal.Recorder.gh_date
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT ALLOWED
	               |	BankReconciliation.BeginningBalance AS ReconcilliationBeginningBalance,
	               |	BankReconciliation.payments AS payments,
	               |	BankReconciliation.deposits AS deposits,
	               |	BankReconciliation.Ref AS Ref
	               |FROM
	               |	(SELECT
	               |		MAX(BankReconciliation.Date) AS Date
	               |	FROM
	               |		Document.BankReconciliation AS BankReconciliation
	               |	WHERE
	               |		BankReconciliation.BankAccount = &Account
	               |		AND BankReconciliation.Posted = TRUE
	               |		AND BankReconciliation.Date <= ENDOFPERIOD(&BankRegisterDateStart, MONTH)
	               |		AND BankReconciliation.Date >= BEGINOFPERIOD(&BankRegisterDateStart, MONTH)) AS LatestReconcilliation
	               |		INNER JOIN Document.BankReconciliation AS BankReconciliation
	               |		ON LatestReconcilliation.Date = BankReconciliation.Date
	               |			AND (BankReconciliation.BankAccount = &Account)
	               |			AND (BankReconciliation.Posted)
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT ALLOWED
	               |	BankReconciliation.BeginningBalance AS BeginningBalance,
	               |	BankReconciliation.payments AS payments,
	               |	BankReconciliation.deposits AS deposits,
	               |	BankReconciliation.EndingBalance AS EndingBalance,
	               |	LatestReconcilliation.Date AS Date
	               |FROM
	               |	(SELECT
	               |		MAX(BankReconciliation.Date) AS Date
	               |	FROM
	               |		Document.BankReconciliation AS BankReconciliation
	               |	WHERE
	               |		BankReconciliation.BankAccount = &Account
	               |		AND BankReconciliation.Posted = TRUE
	               |		AND BankReconciliation.Date < BEGINOFPERIOD(&BankRegisterDateStart, MONTH)) AS LatestReconcilliation
	               |		INNER JOIN Document.BankReconciliation AS BankReconciliation
	               |		ON LatestReconcilliation.Date = BankReconciliation.Date
	               |			AND (BankReconciliation.BankAccount = &Account)
	               |			AND (BankReconciliation.Posted)
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	ISNULL(MAX(BankTransactions.OrderID), 0) AS OrderID
	               |FROM
	               |	InformationRegister.BankTransactions AS BankTransactions
	               |WHERE
	               |	BankTransactions.BankAccount = &Bank
	               |	AND BankTransactions.TransactionDate <= ENDOFPERIOD(&BankRegisterDateStart, MONTH)
	               |	AND BankTransactions.TransactionDate >= BEGINOFPERIOD(&BankRegisterDateStart, MONTH)";
	
	Request.SetParameter("BankRegisterDateStart", DateBeginOfMonth);					   
	Request.SetParameter("Account", BankAccount);
	Request.SetParameter("Bank", Bank);
	Request.SetParameter("DateStart", New Boundary(DateBeginOfMonth, BoundaryType.Including));
	Request.SetParameter("DateEnd", New Boundary(EndOfMonth(DateBeginOfMonth), BoundaryType.Including));
	
	BatchResult			= Request.ExecuteBatch();
	BankTransactions 	= BatchResult[2].Unload();
	
	/////////
	/////////
	/////////
	//Fill bank account balances
	BankBalances = BatchResult[3].Unload(); 
	If BankBalances.Count() > 0 Then
		Amounts.BalanceStart  = BankBalances[0].ReconcilliationBeginningBalance;
		Amounts.DepositsTotal = BankBalances[0].deposits;
		Amounts.PaymentsTotal = BankBalances[0].payments;
	Else
		BankBalancesPreviousPeriod = BatchResult[4].Unload();
		If BankBalancesPreviousPeriod.Count() > 0 Then
			Amounts.BalanceStart = BankBalancesPreviousPeriod[0].EndingBalance;
		Else
			Amounts.BalanceStart = 0;
		EndIf;
	EndIf;
	
	//Recalculating totals
	Amounts.DepositsEntered = BankTransactions.Total("Deposit");
	Amounts.PaymentsEntered = BankTransactions.Total("Payment");
	Amounts.BalanceEnd		= Amounts.BalanceStart + Amounts.DepositsTotal - Amounts.PaymentsTotal;
	/////////
	/////////
	/////////
	
	/////////
	/////////
	/////////
	//Fix the current order in the Sequence column
	LastIndex 	= 0;
	LastIndexes = BatchResult[5].Unload(); 
	If LastIndexes.Count() > 0 Then
		LastIndex = LastIndexes[0].OrderID;
	EndIf;
	
	RowsToRecord = New Array();
	
	For Each BankTransaction In BankTransactions Do
		If BankTransaction.Sequence = 0 Then
			LastIndex = LastIndex + 1;
			BankTransaction.Sequence = LastIndex;
			//Saving OrderId to the database
			RowsToRecord.Add(BankTransaction);
		EndIf;
		
	EndDo;
	
	//Record order information to the database
	If RowsToRecord.Count() > 0 Then
		BTRecordset = InformationRegisters.BankTransactions.CreateRecordSet();
		For Each RowToRecord In RowsToRecord Do
			BTRecordset.Clear();
			BTRecordSet.Filter.Reset();
			BTRecordset.Filter.ID.Set(RowToRecord.TransactionID);
			BTRecordset.Read();
			For Each Rec In BTRecordset Do
				Rec.OrderID = RowToRecord.Sequence;
			EndDo;
			BTRecordset.Write(True);
		EndDo;
	EndIf;
	/////////
	/////////
	/////////
	
EndProcedure

Procedure RecordTotalsToBankRec(BankAccount, DateBeginOfMonth, Amounts)
	
	Try
		BeginTransaction(DataLockControlMode.Managed);
		
		Block = New DataLock();
		LockItem = Block.Add("Document.BankReconciliation");
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		Request = New Query("SELECT ALLOWED
		|	BankReconciliation.Ref,
		|	BankReconciliation.Date AS Date
		|FROM
		|	(SELECT
		|		MAX(BankReconciliation.Date) AS Date
		|	FROM
		|		Document.BankReconciliation AS BankReconciliation
		|	WHERE
		|		BankReconciliation.BankAccount = &Account
		|		AND BankReconciliation.Posted = TRUE
		|		AND BankReconciliation.Date <= ENDOFPERIOD(&BankRegisterDateStart, MONTH)
		|		AND BankReconciliation.Date >= BEGINOFPERIOD(&BankRegisterDateStart, MONTH)) AS LatestReconcilliation
		|		INNER JOIN Document.BankReconciliation AS BankReconciliation
		|		ON LatestReconcilliation.Date = BankReconciliation.Date
		|			AND (BankReconciliation.BankAccount = &Account)
		|			AND (BankReconciliation.Posted)
		|
		|ORDER BY
		|	Date");
		
		Request.SetParameter("BankRegisterDateStart", DateBeginOfMonth);
		Request.SetParameter("Account", BankAccount);
		Res = Request.Execute();
		
		If Res.IsEmpty() Then
			BRDocument = Documents.BankReconciliation.CreateDocument();
			BRDocument.Date        = EndOfMonth(DateBeginOfMonth);
			BRDocument.BankAccount = BankAccount;
		Else
			Sel = Res.Select();
			Sel.Next();
			Ref = Sel.Ref;
			BRDocument = Ref.GetObject();
		EndIf;
		
		BRDocument.BeginningBalance = Amounts.BalanceStart;
		BRDocument.EndingBalance	= Amounts.BalanceEnd;
		BRDocument.payments			= Amounts.PaymentsTotal;
		BRDocument.deposits			= Amounts.DepositsTotal;
		BRDocument.Difference		= Amounts.BalanceEnd - Amounts.BalanceStart - Amounts.DepositsEntered + Amounts.PaymentsEntered;
		BRDocument.AdditionalProperties.Insert("CFO_ProcessMonth_AllowWrite", True);
		BRDocument.Write(DocumentWriteMode.Posting);
		
	Except
		ErrorDescription = ErrorDescription();
		
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
		
		WriteLogEvent(
		"Yodlee.UpdateDownloadedTransactions",
		EventLogLevel.Error,
		,
		,
		NStr("en = 'Error description: '") + ErrorDescription);
		
	EndTry;
	
	CommitTransaction();
			
EndProcedure

#EndRegion
