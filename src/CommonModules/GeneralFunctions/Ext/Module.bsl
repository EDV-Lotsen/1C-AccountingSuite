//////////////////////////////////////////////////////////////////////////////// 
// THIS MODULE CONTAINS GENERAL PURPOSE FUNCTIONS AND PROCEDURES
// 

Function GetSettingsPopUp() Export
	Return Constants.PopUpSettingsPage.Get();	
EndFunction

// Check that email address is valid for email.
Function EmailCheck(StringToCheck) Export
	
	StringLen = StrLen(StringToCheck);
	counter = 0;
	
	Digits = new Array();
	For i = 1 to StringLen Do	
		Digits.Add(Mid(StringToCheck,i,1));
	EndDo;
	
	While counter < StringLen Do
		CurrentChar = CharCode(Digits[counter]);
		If ValidCharCheck(CurrentChar) = False Then
			 Return False;
		EndIf;
		counter = counter + 1;
	EndDo;
	
	Template = ".+@.+\..+";
	RegExp = New COMObject("VBScript.RegExp");
	RegExp.MultiLine = False;
	RegExp.Global = True;
	RegExp.IgnoreCase = True;
	RegExp.Pattern = Template;
	If RegExp.Test(StringToCheck) Then
	     Return True;
	Else
	     Return False;
	EndIf;
	 
EndFunction

// Check that Char is within valid character ranges
Function ValidCharCheck(CharValue)
	
	If CharValue >= 64 AND CharValue <= 90 Then
		Return True;
	Elsif CharValue >= 97 AND CharValue <= 122 Then
		Return True;
	Elsif CharValue >= 48 AND CharValue <= 57 Then
		Return True;
	Elsif CharValue = 46 OR CharValue = 33 OR CharValue = 42 OR CharValue = 43 OR CharValue = 45 OR CharValue = 47 OR CharValue = 61 OR CharValue = 63 Then
		Return True;
	Elsif CharValue >=94 AND CharValue <= 96 Then
		Return True;
	Elsif CharValue >= 123 AND CharValue <= 126 Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

Function Increment(NumberToInc) Export
	
	Last = NumberToInc;
	LastCount = StrLen(Last);
	Digits = new Array();
	For i = 1 to LastCount Do	
		Digits.Add(Mid(Last,i,1));

	EndDo;
	
	NumPos = 9999;
	lengthcount = 0;
	firstnum = false;
	j = 0;
	While j < LastCount Do
		If NumCheck(Digits[LastCount - 1 - j]) Then
			if firstnum = false then //first number encountered, remember position
				firstnum = true;
				NumPos = LastCount - 1 - j;
				lengthcount = lengthcount + 1;
			Else
				If firstnum = true Then
					If NumCheck(Digits[LastCount - j]) Then //if the previous char is a number
						lengthcount = lengthcount + 1;  //next numbers, add to length.
					Else
						break;
					Endif;
				Endif;
			Endif;
						
		Endif;
		j = j + 1;
	EndDo;
	
	NewString = "";
	
	If lengthcount > 0 Then //if there are numbers in the string
		changenumber = Mid(Last,(NumPos - lengthcount + 2),lengthcount);
		NumVal = Number(changenumber);
		NumVal = NumVal + 1;
		StringVal = String(NumVal);
		StringVal = StrReplace(StringVal,",","");
		
		StringValLen = StrLen(StringVal);
		changenumberlen = StrLen(changenumber);
		LeadingZeros = Left(changenumber,(changenumberlen - StringValLen));

		LeftSide = Left(Last,(NumPos - lengthcount + 1));
		RightSide = Right(Last,(LastCount - NumPos - 1));
		NewString = LeftSide + LeadingZeros + StringVal + RightSide; //left side + incremented number + right side
		
	Endif;
	
	Next = NewString;

	return NewString;
	
EndFunction

&AtServer
Function NumCheck(CheckValue)
	 
	For i = 0 to  9 Do
		If CheckValue = String(i) Then
			Return True;
		Endif;
	EndDo;
		
	Return False;
		
EndFunction



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
		
	ReferencedObjects = FindByRef(ReferenceList);
	CoDeletedObjects  = New Array();
	
	i = 0;
	While i < ReferencedObjects.Count() Do
		//--//
		If TypeOf(ReferencedObjects[i][0]) = Type("ChartOfAccountsRef.ChartOfAccounts") And TypeOf(ReferencedObjects[i][1]) = Type("InformationRegisterRecordKey.HierarchyChartOfAccounts") Then
			ReferencedObjects.Delete(ReferencedObjects[i]);
		ElsIf TypeOf(ReferencedObjects[i][1]) = Type("InformationRegisterRecordKey.DocumentJournalOfCompanies") Then
			ReferencedObjects.Delete(ReferencedObjects[i]);
		ElsIf TypeOf(ReferencedObjects[i][1]) = Type("InformationRegisterRecordKey.DocumentLastEmail") Then
			ReferencedObjects.Delete(ReferencedObjects[i]);
		ElsIf TypeOf(ReferencedObjects[i][0]) = Type("CatalogRef.UnitSets") And TypeOf(ReferencedObjects[i][1]) = Type("CatalogRef.Units") Then
			CoDeletedObjects.Add(New Structure("Object, Type", ReferencedObjects[i][1], ReferencedObjects[i][2]));
			ReferencedObjects.Delete(ReferencedObjects[i]);
		ElsIf TypeOf(ReferencedObjects[i][0]) = Type("CatalogRef.Units") And TypeOf(ReferencedObjects[i][1]) = Type("CatalogRef.UnitSets") Then
			ReferencedObjects.Delete(ReferencedObjects[i]);
		ElsIf TypeOf(ReferencedObjects[i][0]) = Type("CatalogRef.Companies") And TypeOf(ReferencedObjects[i][1]) = Type("CatalogRef.Addresses") Then
			CoDeletedObjects.Add(New Structure("Object, Type", ReferencedObjects[i][1], ReferencedObjects[i][2]));
			ReferencedObjects.Delete(ReferencedObjects[i]);	
		ElsIf TypeOf(ReferencedObjects[i][0]) = TypeOf(ReferencedObjects[i][1]) Then
			If ReferencedObjects[i][0] = ReferencedObjects[i][1] Then
				ReferencedObjects.Delete(ReferencedObjects[i]);
			Else 
				i = i + 1;
			EndIf;
		ElsIf TypeOf(ReferencedObjects[i][1]) = Type("Undefined") Then
			ReferencedObjects.Delete(ReferencedObjects[i]);
		Else
			i = i + 1;
		EndIf;
	EndDo;
	
	// Delete subordinated referenced objects.
	If CoDeletedObjects.Count() > 0 And ReferencedObjects.Count() = 0 Then
		Try 
			i = 0;
			While i < CoDeletedObjects.Count() Do	
				Item = CoDeletedObjects[i]["Object"];
				If TypeOf(Item) = Type("CatalogRef.Addresses") Then 
					ObjToDel = Item.GetObject();
					ObjToDel.DataExchange.Load = True;
					ObjToDel.Delete();
					CoDeletedObjects.Delete(i);
				Else 
					Item.GetObject().Delete();
					CoDeletedObjects.Delete(i);
				EndIf;
			EndDo;
		Except 
			Cancel = True;
		EndTry;

	EndIf;
	
	If (ReferencedObjects.Count() = 0) And (CoDeletedObjects.Count() = 0) Then
		//If GeneralFunctionsReusable.DisableAuditLogValue() = False Then
			AuditLog.AuditLogDeleteBeforeDelete(SourceObj,False);
		//EndIf;
	Else
		MessageText = "Linked objects found: ";
		For Each Ref In ReferencedObjects Do
			MessageText = MessageText + Ref[2] + ":" + TrimAll(Ref[1]) + ", ";
		EndDo;
		For Each Ref In CoDeletedObjects Do
			MessageText = MessageText + Ref["Type"] + ":" + TrimAll(Ref["Object"]) + ", ";
		EndDo;
		StringLength = StrLen(MessageText);
		MessageText = Left(MessageText, StringLength - 2);
		Message(MessageText);
		Cancel = True;
	EndIf;
	
EndProcedure

// Try to clear posting, before delete document
// to pass all checks 
Procedure DocumentBeforeDeleteClearPostingCheck(Source, Cancel) Export
	
	If Source.DataExchange.Load Then 
		Return;
	EndIf;	
	
	If Source.Posted Then 
		Try
			Source.Write(DocumentWriteMode.UndoPosting);
			// Can be error with writting records AFTER posting.
			For each RecordSet in Source.RegisterRecords Do 
				IF DocumentPosting.WriteChangesOnly(RecordSet.AdditionalProperties) Then 
					RecordSet.AdditionalProperties.Clear();
				EndIf;	
			EndDo;	
		Except
			Cancel = True;
		EndTry;	
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

Procedure CreateCheckCSV(ItemDataSet) Export
	
	
	For Each DataLine In ItemDataSet Do
				
		
		NewCheck = Documents.Check.CreateDocument();
		NewCheck.Date = DataLine.CheckDate;
		NewCheck.Number = DataLine.CheckNumber;
		NewCheck.BankAccount = DataLine.CheckBankAccount;
		NewCheck.Memo = DataLine.CheckMemo;
		NewCheck.Company = DataLine.CheckVendor;
		NewCheck.DocumentTotalRC = DataLine.CheckLineAmount;
		NewCheck.DocumentTotal = DataLine.CheckLineAmount;
		NewCheck.ExchangeRate = 1;
		NewCheck.PaymentMethod = Catalogs.PaymentMethods.DebitCard;
		NewLine = NewCheck.LineItems.Add();
		NewLine.Account = DataLine.CheckLineAccount;
		//NewLine.AccountDescription = DataLine.CheckLineAccount.Description;
		NewLine.Amount = DataLine.CheckLineAmount;
		NewLine.Memo = DataLine.CheckLineMemo;
		NewCheck.Write();

		
	EndDo;

	
EndProcedure

Procedure CreateCustomerVendorCSV(ItemDataSet) Export
	
	// add transactions 1-500
	
	// add transactions 1-500
	Counter = 0;
	Counter10 = 0;
	MaxCount = ItemDataSet.count();
	For Each DataLine In ItemDataSet Do
		
		Counter = Counter + 1;
		Progress = Int((Counter/MaxCount)*10);
		If Counter10 <> Progress then
			Counter10 = Progress;
			LongActions.InformActionProgres(Counter10*10,"Current progress: "+(Counter10*10) +"%");
		EndIf;	
		
		Try

	
	//For Each DataLine In ItemDataSet Do
		
		CreatingNewCompany = False;
		CompanyFound = Catalogs.Companies.FindByDescription(DataLine.CustomerDescription);
		If CompanyFound = Catalogs.Companies.EmptyRef() Then
			CreatingNewCompany = True;
			
			NewCompany = Catalogs.Companies.CreateItem();
			
			If DataLine.CustomerCode = "" Then
				Numerator = Catalogs.DocumentNumbering.Companies.GetObject();
				NextNumber = GeneralFunctions.Increment(Numerator.Number);
				Numerator.Number = NextNumber;
				Numerator.Write();
				NewCompany.Code = NextNumber;
			Else
				NewCompany.Code = DataLine.CustomerCode
			EndIf;
					
			NewCompany.Description = DataLine.CustomerDescription;
			NewCompany.FullName = DataLine.CustomerFullName;
			
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
			
			NewCompany.Vendor1099 = DataLine.CustomerVendor1099;
			
			If DataLine.CustomerEIN_SSN <> Enums.FederalIDType.EmptyRef() Then
				NewCompany.FederalIDType = DataLine.CustomerEIN_SSN;
			EndIf;
			
			If DataLine.CustomerIncomeAccount <> ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
				NewCompany.IncomeAccount = DataLine.CustomerIncomeAccount;
			EndIf;
			
			If DataLine.CustomerExpenseAccount <> ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
				NewCompany.ExpenseAccount = DataLine.CustomerExpenseAccount;
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

			//If IncomeAccount <> ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
			//	NewCompany.IncomeAccount = IncomeAccount;
			//Else
			//EndIf;
			//
			//If ARAccount <> ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
			//	NewCompany.ARAccount = ARAccount;
			//Else
			//EndIf;
			//
			//If ExpenseAccount <> ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
			//	NewCompany.ExpenseAccount = ExpenseAccount;
			//Else
			//EndIf;
			//
			//If APAccount <> ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
			//	NewCompany.APAccount = APAccount;
			//Else
			//EndIf;
			
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
		
		Except
			ErrorText = "Document Line: "+Counter+ Chars.LF+ ErrorDescription();
			Raise ErrorText;
		EndTry;
				
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

Function GetCustomTemplate(ObjectName, TemplateName) Export
	
	Query = New Query;
	
	Query.Text = "Select Template AS Template
					|FROM
					|	InformationRegister.CustomPrintForms
					|WHERE
					|	ObjectName=&ObjectName
					|	AND	TemplateName=&TemplateName";
	
	Query.Parameters.Insert("ObjectName", ObjectName);
	Query.Parameters.Insert("TemplateName", TemplateName);
		
	Cursor = Query.Execute().Select();
	
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
		
	Cursor = Query.Execute().Select();
	
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
		
	Cursor = Query.Execute().Select();
	
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
		
	Cursor = Query.Execute().Select();
	
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
		
	Cursor = Query.Execute().Select();
	
	Result = Undefined;
	
	If Cursor.Next() Then
		Result = Cursor.Template.Get();
	Else
	EndIf;
	
	Return Result;
	
EndFunction

Function GetFooterPO(imagename) Export
	
	Query = New Query;
	
	Query.Text = "Select Template AS Template
					|FROM
					|	InformationRegister.CustomPrintForms
					|WHERE
					|	ObjectName=&ObjectName
					|	AND	TemplateName=&TemplateName";
	
	Query.Parameters.Insert("ObjectName", imagename);
	Query.Parameters.Insert("TemplateName", imagename);
		
	Cursor = Query.Execute().Select();
	
	Result = Undefined;
	
	If Cursor.Next() Then
		Result = Cursor.Template.Get();
	Else
	EndIf;
	
	Return Result;
	
EndFunction

Function GetDefaultLocation() Export
	
	Query = New Query("SELECT
					  |	Locations.Ref
					  |FROM
					  |	Catalog.Locations AS Locations
					  |WHERE
					  |	Locations.Default = &Default");
	Query.SetParameter("Default", True);
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return Catalogs.Locations.MainWarehouse.Ref;
	EndIf;
	Dataset = QueryResult.Unload();
	Return Dataset[0][0];
	
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
	
	// standard price -> item cat -> item cat + price level -> item -> item + price level 
	
	If Customer = Catalogs.Companies.EmptyRef() Then
		PriceLevel = Catalogs.PriceLevels.EmptyRef()
	Else
		PriceLevel = Customer.PriceLevel
	EndIf;
	
	standard_price = 0;
	If Product = Catalogs.Products.EmptyRef() Then
	Else
		standard_price = Product.Price;
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
	ElsIf standard_price <> 0 Then
		Return standard_price
	Else
		Return 0;
	EndIf;	
	
EndFunction

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

Function ProductLastCost(Product, Period = Undefined) Export
	
	Query = New Query("SELECT
	                  |	ItemLastCostsSliceLast.Cost AS Cost
	                  |FROM
	                  |	InformationRegister.ItemLastCosts.SliceLast(&Period, Product = &Product) AS ItemLastCostsSliceLast");
	Query.SetParameter("Period",  Period);
	Query.SetParameter("Product", Product);
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		Return Product.Cost;
	Else
		Dataset = QueryResult.Unload();
		Return Dataset[0][0];
	EndIf;
	
EndFunction

// Returns boundary for requesting registers' balances.
//
// Parameters:
//  Object - DocumentObject - Object requesting it's point in time.
//
// Returns:
//  Boundary, Undefined - actual boundary for requesting the balances.
//
Function GetDocumentPointInTime(Object) Export
	
	// Actual (operational) point.
	PointInTime = Undefined;
	
	// Define point in time for requesting the balances.
	If Object.Ref.IsEmpty() Then
		// The new document.
		If ValueIsFilled(Object.Date) And BegOfDay(Object.Date) < BegOfDay(CurrentSessionDate()) Then
			// New document in back-date.
			PointInTime = New Boundary(EndOfDay(Object.Date), BoundaryType.Including);
		Else
			// New actual document.
			PointInTime = Undefined;
		EndIf;
	Else
		// Document was already saved (but date can actually be changed).
		If Object.Ref.PointInTime().Date = Object.Date Then
			// The document date is preserved.
			PointInTime = New Boundary(New PointInTime(Object.Date, Object.Ref), BoundaryType.Excluding);
		Else
			// The document date was changed.
			PointInTime = New Boundary(New PointInTime(Object.Date, Object.Ref), BoundaryType.Including);
		EndIf;
	EndIf;
	
	// Return claculated boundary.
	Return PointInTime;
	
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

// Creates new value table and fill it from passed object data preserving fields data type.
// 
// Parameters:
//  Source   - Object    - Data for filling the value table.
//           - Structure - Structure containing keys as fields and values as contents.
//  Fields   - String    - Columns names to be created as fields and filled from the object.
//  Metadata - MetadataObjectCollection - Fields description data containing fields type.
//
// Returns:
//  ValueTable - The table containing the single row filled from the data source.
//
Function ValueTableCopyFrom(Source, Fields = "", Metadata = Undefined) Export
	
	// Create values table and define it's columns.
	Table = New ValueTable;
	Types = New Array(1);
	
	// Define table columns.
	If Not IsBlankString(Fields) Then
		// Create columns by the supplied fields list.
		FiledsList = StringFunctionsClientServer.SplitStringIntoSubstringArray(Fields, ",", True);
		For Each FieldName In FiledsList Do
			Field = TrimAll(FieldName);
			Types[0] = TypeOf(Source[Field]);
			Table.Columns.Add(Field, ?(Metadata = Undefined Or Metadata.Find(Field) = Undefined, New TypeDescription(Types), Metadata[Field].Type));
		EndDo;
		
	ElsIf Metadata <> Undefined Then
		// Create columns by the supplied metadata collection.
		For Each Meta In Metadata Do
			Table.Columns.Add(Meta.Name, Meta.Type);
		EndDo;
		
	ElsIf TypeOf(Source) = Type("Structure") Then
		// Create columns from structure keys.
		For Each Element In Source Do
			Types[0] = TypeOf(Element.Value);
			Table.Columns.Add(Element.Key, New TypeDescription(Types));
		EndDo;
	EndIf;
	
	// Add new row and fill it from source data;
	FillPropertyValues(Table.Add(), Source);
	
	// Return the filled values table.
	Return Table;
	
EndFunction

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

//Procedure finds a vacant code for a new g/l account in the passed interval
//Algorithm:
// First it tries to increment the maximum code of g/l accounts with the given account type by 10
// if the result value exceeds CodeEnd then it tries to find any vacant code in the passed interval
// if no vacant code is found then empty string is returned
//Parameters:
// CodeStart - string - the start code of an interval in the string format
// CodeEnd - String - the end code of an interval in the string format
// AccountType - EnumRef.AccountType - account type of the new g/l account
//Returns:
// String - the new vacant code. If not found then empty string
//
Function FindVacantCode(CodeStart, CodeEnd, AccountType, Parent) Export
	
	Request = New Query("SELECT
	                    |	ChartOfAccounts.Code,
	                    |	ChartOfAccounts.AccountType,
	                    |	ChartOfAccounts.Order
	                    |FROM
	                    |	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
	                    |WHERE
	                    |	ChartOfAccounts.Code >= &CodeStart
	                    |	AND ChartOfAccounts.Code < &CodeEnd
	                    |
	                    |ORDER BY
	                    |	ChartOfAccounts.Code DESC
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT
	                    |	ChartOfAccounts.Code,
	                    |	NOT ChartOfAccounts.Parent IS NULL 
	                    |		AND ChartOfAccounts.Parent <> VALUE(ChartOfAccounts.ChartOfAccounts.EmptyRef) AS IsSubaccount
	                    |FROM
	                    |	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
	                    |WHERE
	                    |	ChartOfAccounts.Ref = &Parent");
	Request.SetParameter("CodeStart", CodeStart);
	Request.SetParameter("CodeEnd", CodeEnd);
	Request.SetParameter("Parent", Parent);
	RequestResult = Request.ExecuteBatch();
	FoundAccounts = RequestResult[0].Unload();
	If RequestResult[1].IsEmpty() Then
		ParentAttributes = new Structure("Code, IsSubaccount", CodeStart, False);
	Else
		ParentAttributes	= RequestResult[1].Unload()[0];
	EndIf;
	FoundAccountsOfType = FoundAccounts.FindRows(New Structure("AccountType", AccountType));
	NewCode = CodeStart;
	If FoundAccountsOfType.Count() > 0 Then
		For Each AccountOfType In FoundAccountsOfType Do
			Try
				If Format(Number(TrimAll(AccountOfType.Code)), "NFD=; NG=0") = TrimAll(AccountOfType.Code) Then //Found digital code
					NumericalCode = Number(TrimAll(AccountOfType.Code));
					If ParentAttributes.IsSubaccount Then
						NumericalParentCode = Number(TrimAll(ParentAttributes.Code));
						NewCodeFound = False;
						While Not NewCodeFound Do
							NumericalParentCode = NumericalParentCode + 1;
							NewCode = Format(NumericalParentCode, "NFD=; NG=0");
							ExistingAccounts = FoundAccounts.FindRows(New Structure("Code", NewCode));
							If ExistingAccounts.Count() = 0 Then
								NewCodeFound = True;
							EndIf;
						EndDo;
						If NewCode >= CodeEnd Then
							NewCode = CodeStart;
						EndIf;
						Break;
					Else
						NumericalCodeAlligned = Int(NumericalCode/10)*10;
						NewCode = Format(NumericalCodeAlligned + 10 ,"NFD=; NG=0");
						If NewCode >= CodeEnd Then
							NewCode = CodeStart;
						EndIf;
						Break;
					EndIf;
				EndIf;
			Except
			EndTry;
		EndDo;
	EndIf;
	//Check if the new code is vacant
	ExistingAccounts = FoundAccounts.FindRows(New Structure("Code", NewCode));
	If ExistingAccounts.Count() = 0 Then
		return NewCode;
	EndIf;
	//If the new code is already in use
	//Start searching the vacant one from the very beginning
	CodeStartDigital = Number(CodeStart);
	CodeEndDigital = Number(CodeEnd);
	NewCode = "";
	For DigitalCode = CodeStartDigital To CodeEndDigital Do
		CurrentCode = Format(DigitalCode,"NFD=; NG=0");
		ExistingAccounts = FoundAccounts.FindRows(New Structure("Code", CurrentCode));
		If ExistingAccounts.Count() = 0 Then
			NewCode = CurrentCode;
			Break;
		EndIf;
	EndDo;
	return NewCode;
	
EndFunction

// Procedure fills empty IB.
//
Procedure FirstLaunch() Export
	
	// mt_change
	If Constants.FirstLaunch.Get() = False Then
		
		BeginTransaction();
		
		Constants.FullFeatureSet.Set(True);   
		Constants.FileStorageProcessing.Set(True);
		Constants.EnableReportIncomeStatementByClassAccrualBasis.Set(True);
		Constants.EnableReportsAccrualBasis.Set(True);
		Constants.EnableReportSalesByRepAccrualBasis.Set(True);
		
		Constants.QtyPrecision.Set(2);
		
		Constants.CopyDropshipPrintOptionsSO_PO.Set(True);
		
		Constants.PopUpSettingsPage.Set(True);
		
		//---set mainwarehouse as default--//
		MainLocation = Catalogs.Locations.MainWarehouse;
		MainObject = MainLocation.GetObject();
		MainObject.Default = True;
		MainObject.Write();
		
		Numerator = Catalogs.DocumentNumbering.JournalEntry.GetObject();
		Numerator.Number = 999;
		Numerator.Write();
		
		Numerator = Catalogs.DocumentNumbering.PurchaseOrder.GetObject();
		Numerator.Number = 999;
		Numerator.Write();
		
		Numerator = Catalogs.DocumentNumbering.SalesOrder.GetObject();
		Numerator.Number = 999;
		Numerator.Write();
		
		Numerator = Catalogs.DocumentNumbering.SalesInvoice.GetObject();
		Numerator.Number = 999;
		Numerator.Write();
		
		Numerator = Catalogs.DocumentNumbering.Quote.GetObject();
		Numerator.Number = 999;
		Numerator.Write();
		
		Numerator = Catalogs.DocumentNumbering.Shipment.GetObject();
		Numerator.Number = 999;
		Numerator.Write();
		
		Numerator = Catalogs.DocumentNumbering.Companies.GetObject();
		Numerator.Number = 999;
		Numerator.Write();
		
		Numerator = Catalogs.DocumentNumbering.ItemReceipt.GetObject();
		Numerator.Number = 999;
		Numerator.Write();
		
		Numerator = Catalogs.DocumentNumbering.Deposit.GetObject();
		Numerator.Number = 999;
		Numerator.Write();
		
		Numerator = Catalogs.DocumentNumbering.Assembly.GetObject();
		Numerator.Number = 999;
		Numerator.Write();
		
		Numerator = Catalogs.DocumentNumbering.PurchaseReturn.GetObject();
		Numerator.Number = 999;
		Numerator.Write();
		
		Numerator = Catalogs.DocumentNumbering.CreditMemo.GetObject();
		Numerator.Number = 999;
		Numerator.Write();
		
		// Set default currency
		Constants.DefaultCurrency.Set(Catalogs.Currencies.USD);
		
		// adding/removing/excluding accounts must be madden in CommonTemplate "COA_DefaultACS" 
		CreateChartOfAccounts();
		
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
		Cat1099.Code = 1;
		Cat1099.Threshold = 600;
		Cat1099.Write();
		
		Cat1099 = Catalogs.USTaxCategories1099.Box2.GetObject();
		Cat1099.Code = 2;
		Cat1099.Threshold = 10;
		Cat1099.Write();
		
		Cat1099 = Catalogs.USTaxCategories1099.Box3.GetObject();
		Cat1099.Code = 3;
		Cat1099.Threshold = 600;
		Cat1099.Write();
		
		Cat1099 = Catalogs.USTaxCategories1099.Box4.GetObject();
		Cat1099.Code = 4;
		Cat1099.Write();
		
		Cat1099 = Catalogs.USTaxCategories1099.Box5.GetObject();
		Cat1099.Code = 5;
		Cat1099.Write();
		
		Cat1099 = Catalogs.USTaxCategories1099.Box6.GetObject();
		Cat1099.Code = 6;
		Cat1099.Threshold = 600;
		Cat1099.Write();
		
		Cat1099 = Catalogs.USTaxCategories1099.Box7.GetObject();
		Cat1099.Code = 7;
		Cat1099.Threshold = 600;
		Cat1099.Write();
		
		Cat1099 = Catalogs.USTaxCategories1099.Box8.GetObject();
		Cat1099.Code = 8;
		Cat1099.Threshold = 10;
		Cat1099.Write();
		
		Cat1099 = Catalogs.USTaxCategories1099.Box9.GetObject();
		Cat1099.Code = 9;
		Cat1099.Threshold = 5000;
		Cat1099.Write();
		
		Cat1099 = Catalogs.USTaxCategories1099.Box10.GetObject();
		Cat1099.Code  = 10;
		Cat1099.Threshold = 600;
		Cat1099.Write();
		
		Cat1099 = Catalogs.USTaxCategories1099.Box13.GetObject();
		Cat1099.Code = 13;
		Cat1099.Write();
		
		Cat1099 = Catalogs.USTaxCategories1099.Box14.GetObject();
		Cat1099.Code = 14;
		Cat1099.Threshold = 600;
		Cat1099.Write();
		
		// Assigning currency symbols
		
		Currency = Catalogs.Currencies.USD.GetObject();
		Currency.Symbol = "$";
		Currency.Write();
		
		// Setting Customer Name and Vendor Name constants
		
		Constants.CustomerName.Set("Customer");
		Constants.VendorName.Set("Vendor");
		
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
		
		Constants.CF1AType.Set("None");
		Constants.CF2AType.Set("None");
		Constants.CF3AType.Set("None");
		Constants.CF4AType.Set("None");
		Constants.CF5AType.Set("None");
		
		
		Constants.SIFoot1Type.Set(Enums.TextOrImage.None);
		Constants.SIFoot2Type.Set(Enums.TextOrImage.None);
		Constants.SIFoot3Type.Set(Enums.TextOrImage.None);
		Constants.POFoot1Type.Set(Enums.TextOrImage.None);
		Constants.POFoot2Type.Set(Enums.TextOrImage.None);
		Constants.POFoot3Type.Set(Enums.TextOrImage.None);
		
		//Create "Default UoM Set"
		DefaultUoMSet = Catalogs.UnitSets.CreateItem();
		DefaultUoMSet.Description = "Each";
		DefaultUoMSet.Write();
		
		DefaultUnit = Catalogs.Units.CreateItem();
		DefaultUnit.Owner       = DefaultUoMSet.Ref;   // Set name
		DefaultUnit.Code        = "ea";                // Abbreviation
		DefaultUnit.Description = "Each";              // Unit name
		DefaultUnit.BaseUnit    = True;                // Base ref of set
		DefaultUnit.Factor      = 1;
		DefaultUnit.Write();
		
		DefaultUoMSet.DefaultReportUnit   = DefaultUnit.Ref;
		DefaultUoMSet.DefaultSaleUnit     = DefaultUnit.Ref;
		DefaultUoMSet.DefaultPurchaseUnit = DefaultUnit.Ref;
		DefaultUoMSet.Write();
		
		Constants.DefaultUoMSet.Set(DefaultUoMSet.Ref);
		
		//Set first month of fiscal year
		Constants.FirstMonthOfFiscalYear.Set(1);
		
		Constants.AccountingMethod.Set(Enums.AccountingMethod.Accrual);
		
		CommitTransaction();
		
		Constants.FirstLaunch.Set(True);
		
	EndIf;
	
EndProcedure // FirstLaunch()

// Procedure creates ChOA based on common template "COA_DefaultACS"
// Used in first launck wizard too.
Procedure CreateChartOfAccounts(EntityType = "CCorp", EnchancedIR = Undefined) Export
	MaxPageCounter = 1;
	COASettingList = GetCommonTemplate("COA_DefaultACS");
	
	// IF YOU NEED TO EXCLUDE CREATING OF CERTAIN ACCOUNT FROM FIRST LAUNCH
	// Either remove whole row from Template,
	// Or put "1" into the last column ("skip on processing") of the row.
	
	COAStruct = New Structure;
	COAStruct.Insert("Default");
	COAStruct.Insert("Code");
	COAStruct.Insert("Name");
	COAStruct.Insert("Type");
	COAStruct.Insert("Parent");
	COAStruct.Insert("RE");
	COAStruct.Insert("CC");
	COAStruct.Insert("IR");
	COAStruct.Insert("CFSection");
	// Reserved for Future
	COAStruct.Insert("Res2");
	COAStruct.Insert("Res3");
	
	COAStruct.Insert("CCorp");
	COAStruct.Insert("SCorp");
	COAStruct.Insert("SoleProp");
	COAStruct.Insert("Skip");
	
	If EnchancedIR = Undefined Then 
		EnchancedIR = True;
	EndIf;	
	
	For Count = 1 to COASettingList.TableHeight Do 
		
		
		COAStruct.Insert("Default",TrimAll(COASettingList.Area(count,1,count,1).Text));
		COAStruct.Insert("Code",TrimAll(COASettingList.Area(count,2,count,2).Text));
		COAStruct.Insert("Name",TrimAll(COASettingList.Area(count,3,count,3).Text));
		COAStruct.Insert("Type",TrimAll(COASettingList.Area(count,4,count,4).Text));
		COAStruct.Insert("Parent",TrimAll(COASettingList.Area(count,5,count,5).Text));
		COAStruct.Insert("RE",?(TrimAll(COASettingList.Area(count,6,count,6).Text) = "1",True,False));
		COAStruct.Insert("CC",?(TrimAll(COASettingList.Area(count,7,count,7).Text) = "1",True,False));
		COAStruct.Insert("IR",?(TrimAll(COASettingList.Area(count,8,count,8).Text) = "1",True,False));
		COAStruct.Insert("CFSection",TrimAll(COASettingList.Area(count,9,count,9).Text));
		// Reserved for Future use, can be changad to any other 
		COAStruct.Insert("Reserve2",TrimAll(COASettingList.Area(count,10,count,10).Text));
		COAStruct.Insert("Reserve3",TrimAll(COASettingList.Area(count,11,count,11).Text));
		
		COAStruct.Insert("CCorp",TrimAll(COASettingList.Area(count,12,count,12).Text));
		COAStruct.Insert("SCorp",TrimAll(COASettingList.Area(count,13,count,13).Text));
		COAStruct.Insert("SoleProp",TrimAll(COASettingList.Area(count,14,count,14).Text));
		COAStruct.Insert("Skip",?(TrimAll(COASettingList.Area(count,15,count,15).Text) = "1",True,False));
		
		If COAStruct.Code = "" Then
			Continue;
		EndIf;
		
		If COAStruct.Code = "Code" Then
			Continue;
		EndIf;
		
		If COAStruct.Skip Then
			Continue;
		EndIf;
		
		If COAStruct.IR and Not EnchancedIR Then
			Continue;
		EndIf;
		
		ExistingCOA = ChartsOfAccounts.ChartOfAccounts.FindByCode(COAStruct.Code);
		If ExistingCOA.IsEmpty() Then 
			NewAccount = ChartsOfAccounts.ChartOfAccounts.CreateAccount();
		Else 
			NewAccount = ExistingCOA.GetObject();
		EndIf;	
		NewAccount.Code = COAStruct.Code;
		
		If COAStruct.Parent <> "" Then
			NewAccount.Parent = ChartsOfAccounts.ChartOfAccounts.FindByCode(COAStruct.Parent);
		EndIf;
		
		TmpName = Undefined;
		If EntityType = "" Then 
			NewAccount.Description = COAStruct.Name;
		ElsIf COAStruct.Property(EntityType,TmpName) and ValueIsFilled(TmpName) Then 
			NewAccount.Description = TmpName;
		Else 	
			NewAccount.Description = COAStruct.Name;
		EndIf;	
		
		NewAccount.AccountType = Enums.AccountTypes[COAStruct.Type];
		
		If NewAccount.AccountType = GeneralFunctionsReusable.BankAccountType() OR
			NewAccount.AccountType = GeneralFunctionsReusable.ARAccountType() OR
			NewAccount.AccountType = GeneralFunctionsReusable.APAccountType() Then
			NewAccount.Currency = GeneralFunctionsReusable.DefaultCurrency();
		EndIf;
		
		If ValueIsFilled(COAStruct.CFSection) Then 
			NewAccount.CashFlowSection = Enums.CashFlowSections[COAStruct.CFSection];
		EndIf;
		
		NewAccount.Order = NewAccount.Code;
		NewAccount.CreditCard = COAStruct.CC;
		NewAccount.RetainedEarnings = COAStruct.RE;
		
		If NewAccount.AccountType = GeneralFunctionsReusable.ARAccountType() OR
			NewAccount.AccountType = GeneralFunctionsReusable.APAccountType() Then
			
			Dimension = NewAccount.ExtDimensionTypes.Find(ChartsOfCharacteristicTypes.Dimensions.Company, "ExtDimensionType");
			If Dimension = Undefined Then	
				NewType = NewAccount.ExtDimensionTypes.Insert(0);
				NewType.ExtDimensionType = ChartsOfCharacteristicTypes.Dimensions.Company;
			EndIf;	
			
			Dimension = NewAccount.ExtDimensionTypes.Find(ChartsOfCharacteristicTypes.Dimensions.Document, "ExtDimensionType");
			If Dimension = Undefined Then                 
				NewType = NewAccount.ExtDimensionTypes.Insert(1);
				NewType.ExtDimensionType = ChartsOfCharacteristicTypes.Dimensions.Document;
			EndIf;	
		EndIf;

		
		If TrimAll(NewAccount.Description) = "-" Then 
			Continue;
		EndIf;
		
		NewAccount.Write();
		
		CheckDefaulAccount(COAStruct.Default,NewAccount.Ref);
		
	EndDo;
	
EndProcedure	

// Fill default accounts with created account
Procedure CheckDefaulAccount(DefName, Account)
	
	Try // in production may not be some accounts
		If DefName = "BankAccount" Then 
			Constants.BankAccount.Set(Account);
			
		ElsIf DefName = "UndepositedFundsAccount" Then 	
			Constants.UndepositedFundsAccount.Set(Account);
			
		ElsIf DefName = "AccountsReceivable" Then 
			DefCur = Constants.DefaultCurrency.Get().GetObject();
			DefCur.DefaultARAccount = Account;
			DefCur.Write();
			
		ElsIf DefName = "InventoryAccount" Then 	
			Constants.InventoryAccount.Set(Account);
			
		ElsIf DefName = "AccountsPayable" Then 	
			DefCur = Constants.DefaultCurrency.Get().GetObject();
			DefCur.DefaultAPAccount = Account;
			DefCur.Write();
			
		ElsIf DefName = "DefaultPrepaymentAR" Then 	
			
			DefCur = Constants.DefaultCurrency.Get().GetObject();
			DefCur.DefaultPrepaymentAR = Account;
			DefCur.Write();	
			
		ElsIf DefName = "OCLAccount" Then 	
			Constants.OCLAccount.Set(Account);
			
		ElsIf DefName = "TaxPayableAccount" Then 	
			Constants.TaxPayableAccount.Set(Account);
			
		ElsIf DefName = "IncomeAccount" Then 	
			Constants.IncomeAccount.Set(Account);
			
		ElsIf DefName = "ShippingExpenseAccount" Then 	
			Constants.ShippingExpenseAccount.Set(Account);
			
		ElsIf DefName = "DiscountsAccount" Then 	
			Constants.DiscountsAccount.Set(Account);
			
		ElsIf DefName = "DiscountsReceived" Then 	
			Constants.DiscountsReceived.Set(Account);
			
		ElsIf DefName = "ExpenseAccount" Then 	
			Constants.ExpenseAccount.Set(Account);
			
		ElsIf DefName = "OpeningBalanceEquity" Then 	
			Constants.OpeningBalanceEquity.Set(Account);	
			
		ElsIf DefName = "ExchangeGainOrLoss" Then 	
			Constants.ExchangeLoss.Set(Account);	
			
		ElsIf DefName = "CostOfSales" Then 	
			Constants.COGSAccount.Set(Account);	
			
		ElsIf DefName = "ACS default" Then 	
			//Do nothing
		Else 	
			//Do nothing
		EndIf; 
	Except
	EndTry;
EndProcedure	

#Region Updating_Infobase_Version

//Procedure updates an infobase to the new configuration version
//
Procedure UpdateInfobase() Export
	SetPrivilegedMode(True);
	CurrentVersion 			= Constants.CurrentConfigurationVersion.Get();
	ConfigurationVersion 	= Metadata.Version;
	If Not InfobaseUpdateNeeded(CurrentVersion, ConfigurationVersion) Then
		return;
	EndIf;
	
	//Updating Infobase for the configuration version "1.1.40.01"
	If UpdateRequiredForVersion(ConfigurationVersion, CurrentVersion, "1.1.40.01") OR (NOT ValueIsFilled(CurrentVersion)) Then
		//Unmark all g/l accounts marked for deletion (caused by predefined accounts deletion)
		Try
			BeginTransaction(DataLockControlMode.Managed);
			//Lock ChartOfAccounts
			DLock = New DataLock();
			LockItem = DLock.Add("ChartOfAccounts.ChartOfAccounts");
			LockItem.Mode = DataLockMode.Exclusive;
			DLock.Lock();
			Request = New Query("SELECT
			                    |	ChartOfAccounts.Ref
			                    |FROM
			                    |	ChartOfAccounts.ChartOfAccounts AS ChartOfAccounts
			                    |WHERE
			                    |	ChartOfAccounts.DeletionMark = TRUE");
			Res = Request.Execute().Select();
			While Res.Next() Do
				AccountObject = Res.Ref.GetObject();
				AccountObject.DeletionMark = False;
				AccountObject.Write();
			EndDo;
			Constants.CurrentConfigurationVersion.Set(TrimAll(ConfigurationVersion));
			
			WriteLogEvent(
			InfobaseUpdateEvent(),
			EventLogLevel.Information,
			,
			,
			"Updating to the version ""1.1.40.01"" succeeded.");

		Except
			ErrorDescription = ErrorDescription();
			If TransactionActive() Then
				RollbackTransaction();
			EndIf;
			
			WriteLogEvent(
			InfobaseUpdateEvent(),
			EventLogLevel.Error,
			,
			,
			"Updating to the version ""1.1.40.01"". During the update an error occured: " + ErrorDescription);

			return;
		EndTry;
		CommitTransaction();
	EndIf;
	If UpdateRequiredForVersion(ConfigurationVersion, CurrentVersion, "1.1.41.01") Then
		
		BeginTransaction(DataLockControlMode.Managed);
	
		Try
		// Create new managed data lock.
		DataLock = New DataLock;
	
		// Set data lock parameters.
		LockItem = DataLock.Add("AccumulationRegister.UndepositedDocuments");
		LockItem.Mode = DataLockMode.Exclusive;
		// Set lock on the object.
		DataLock.Lock();

		//Post CashSale and CashReceipt documents
		Request = New Query("SELECT
		                    |	CashSale.Ref,
		                    |	CashSale.DocumentTotal AS Amount,
		                    |	CashSale.DocumentTotalRC AS AmountRC,
		                    |	CashSale.Date
		                    |FROM
		                    |	Document.CashSale AS CashSale
		                    |WHERE
		                    |	CashSale.DepositType = ""1""
		                    |	AND CashSale.DeletionMark = FALSE
		                    |	AND CashSale.Posted = TRUE
		                    |
		                    |UNION ALL
		                    |
		                    |SELECT
		                    |	CashReceipt.Ref,
		                    |	CashReceipt.CashPayment,
		                    |	CashReceipt.CashPayment,
		                    |	CashReceipt.Date
		                    |FROM
		                    |	Document.CashReceipt AS CashReceipt
		                    |WHERE
		                    |	CashReceipt.DepositType = ""1""
		                    |	AND CashReceipt.DeletionMark = FALSE
		                    |	AND CashReceipt.Posted = TRUE");
		Sel = Request.Execute().Select();
	
		While Sel.Next() Do
			UndepositedDocuments = AccumulationRegisters.UndepositedDocuments.CreateRecordSet();
		
			UndepositedDocuments.Filter.Recorder.Set(Sel.Ref, TRUE);
			Record = UndepositedDocuments.AddReceipt();
			Record.Period 	= Sel.Date;
			Record.Recorder = Sel.Ref;
			Record.Document = Sel.Ref;
			Record.Amount 	= Sel.Amount;
			Record.AmountRC = Sel.AmountRC;
		
			UndepositedDocuments.Write(TRUE);
		EndDo;
	
		//Post Deposit documents
		RequestDeposits = New Query("SELECT
		                            |	DepositLineItems.Ref AS Ref,
		                            |	DepositLineItems.Document,
		                            |	DepositLineItems.DocumentTotal AS Amount,
		                            |	DepositLineItems.DocumentTotalRC AS AmountRC,
		                            |	DepositLineItems.Ref.Date
		                            |FROM
		                            |	Document.Deposit.LineItems AS DepositLineItems
		                            |WHERE
		                            |	DepositLineItems.Ref.DeletionMark = FALSE
		                            |	AND DepositLineItems.Ref.Posted = TRUE
		                            |	AND DepositLineItems.Payment = TRUE
		                            |TOTALS BY
		                            |	Ref");
		Sel = RequestDeposits.Execute().Select(QueryResultIteration.ByGroups);
	
		While Sel.Next() Do
			UndepositedDocuments = AccumulationRegisters.UndepositedDocuments.CreateRecordSet();
			UndepositedDocuments.Filter.Recorder.Set(Sel.Ref, TRUE);
			
			UndepositedSel = Sel.Select(QueryResultIteration.Linear);
			
			While UndepositedSel.Next() Do
				Record = UndepositedDocuments.AddExpense();
				Record.Period 	= Sel.Date;
				Record.Recorder = Sel.Ref;
				Record.Document = UndepositedSel.Document;
				Record.Amount 	= UndepositedSel.Amount;
				Record.AmountRC = UndepositedSel.AmountRC;
			EndDo;
		
			UndepositedDocuments.Write(TRUE);
		EndDo;
		
		Constants.CurrentConfigurationVersion.Set(TrimAll(ConfigurationVersion));
		
		CommitTransaction();	
		WriteLogEvent(
			InfobaseUpdateEvent(),
			EventLogLevel.Information,
			,
			,
			"Updating to the version ""1.1.41.01"". Updating the Undeposited documents mechanism succeeded.");

		Except
		ErrorDescription = ErrorDescription();
		If TransactionActive() Then
			RollbackTransaction();
		EndIf;
			
		WriteLogEvent(
			InfobaseUpdateEvent(),
			EventLogLevel.Error,
			,
			,
			"Updating to the version ""1.1.41.01"". Updating the Undeposited documents mechanism failed. During the update an error occured: " + ErrorDescription);

		EndTry;
		
	EndIf;

	If UpdateRequiredForVersion(ConfigurationVersion, CurrentVersion, "1.1.42.01") Then
		Try
			BeginTransaction(DataLockControlMode.Managed);
			
			Constants.CurrentConfigurationVersion.Set(TrimAll(ConfigurationVersion));
			
			WriteLogEvent(
			InfobaseUpdateEvent(),
			EventLogLevel.Information,
			,
			,
			"Updating to the version ""1.1.42.01"" succeeded.");

		Except
			ErrorDescription = ErrorDescription();
			If TransactionActive() Then
				RollbackTransaction();
			EndIf;
			
			WriteLogEvent(
			InfobaseUpdateEvent(),
			EventLogLevel.Error,
			,
			,
			"Updating to the version ""1.1.42.01"". During the update an error occured: " + ErrorDescription);

			return;
		EndTry;
		CommitTransaction();
	EndIf;
	
	If UpdateRequiredForVersion(ConfigurationVersion, CurrentVersion, "1.1.43.01") Then
		Try
			Constants.CurrentConfigurationVersion.Set(TrimAll(ConfigurationVersion));
			
			WriteLogEvent(
			InfobaseUpdateEvent(),
			EventLogLevel.Information,
			,
			,
			"Updating to the version ""1.1.43.01"" succeeded.");

		Except
			ErrorDescription = ErrorDescription();
						
			WriteLogEvent(
			InfobaseUpdateEvent(),
			EventLogLevel.Error,
			,
			,
			"Updating to the version ""1.1.43.01"". During the update an error occured: " + ErrorDescription);

			return;
		EndTry;
	EndIf;
	
	If UpdateRequiredForVersion(ConfigurationVersion, CurrentVersion, "1.1.43.02") Then
		Try
			BeginTransaction(DataLockControlMode.Managed);
			
			//Update documents Statement to use currency
			UpdatingInformationRegisterDocumentJournalOfCompanies();
						
			Constants.CurrentConfigurationVersion.Set(TrimAll(ConfigurationVersion));
			
			WriteLogEvent(
			InfobaseUpdateEvent(),
			EventLogLevel.Information,
			,
			,
			"Updating to the version ""1.1.43.02"" succeeded.");

		Except
			ErrorDescription = ErrorDescription();
			If TransactionActive() Then
				RollbackTransaction();
			EndIf;
			
			WriteLogEvent(
			InfobaseUpdateEvent(),
			EventLogLevel.Error,
			,
			,
			"Updating to the version ""1.1.43.02"". During the update an error occured: " + ErrorDescription);

			return;
		EndTry;
		CommitTransaction();
	EndIf;
	
	If UpdateRequiredForVersion(ConfigurationVersion, CurrentVersion, "1.1.43.03") Then
		Try
			BeginTransaction(DataLockControlMode.Managed);
			
			//-----------------------------------
			//Correct numbering
			Selection = Catalogs.DocumentNumbering.Select();
			
			While Selection.Next() Do
				
				If Not ValueIsFilled(Selection.Number) Then
					Numerator = Selection.GetObject();
					Numerator.Number = 999;
					Numerator.Write();
				EndIf;
				
			EndDo;
			//-----------------------------------
			
			Constants.CurrentConfigurationVersion.Set(TrimAll(ConfigurationVersion));
			
			WriteLogEvent(
			InfobaseUpdateEvent(),
			EventLogLevel.Information,
			,
			,
			"Updating to the version ""1.1.43.03"" succeeded.");

		Except
			ErrorDescription = ErrorDescription();
			If TransactionActive() Then
				RollbackTransaction();
			EndIf;
			
			WriteLogEvent(
			InfobaseUpdateEvent(),
			EventLogLevel.Error,
			,
			,
			"Updating to the version ""1.1.43.03"". During the update an error occured: " + ErrorDescription);

			return;
		EndTry;
		CommitTransaction();
	EndIf;
	
	If UpdateRequiredForVersion(ConfigurationVersion, CurrentVersion, "1.1.43.04") Then
		Try
			BeginTransaction(DataLockControlMode.Managed);
			
			//-----------------------------------
			
			//first launch includes enabling of odata for new users
			LocationDefault = New Query("SELECT
			                            |	Locations.Ref
			                            |FROM
			                            |	Catalog.Locations AS Locations
			                            |WHERE
			                            |	Locations.Default = &Default");
			
			LocationDefault.SetParameter("Default", True);
			QueryExecute = LocationDefault.Execute();
			If QueryExecute.IsEmpty() Then
				MainObject = Catalogs.Locations.MainWarehouse.GetObject();
				MainObject.Default = True;
				MainObject.Write();
			EndIf;
			
			//-----------------------------------
			
			Constants.CurrentConfigurationVersion.Set(TrimAll(ConfigurationVersion));
			
			WriteLogEvent(
			InfobaseUpdateEvent(),
			EventLogLevel.Information,
			,
			,
			"Updating to the version ""1.1.43.04"" succeeded.");

		Except
			ErrorDescription = ErrorDescription();
			If TransactionActive() Then
				RollbackTransaction();
			EndIf;
			
			WriteLogEvent(
			InfobaseUpdateEvent(),
			EventLogLevel.Error,
			,
			,
			"Updating to the version ""1.1.43.04"". During the update an error occured: " + ErrorDescription);

			return;
		EndTry;
		CommitTransaction();
	EndIf;
	
	If UpdateRequiredForVersion(ConfigurationVersion, CurrentVersion, "1.1.43.06") Then
		Try
			BeginTransaction(DataLockControlMode.Managed);
			
			//-----------------------------------
			//************************ AR and AP updates ****************************
			//***************** Fill cash payment in Bill Payments ******************
			
			Query = New Query;
			Query.Text = 
			"SELECT
			|	InvoicePayment.Ref
			|FROM
			|	Document.InvoicePayment AS InvoicePayment";
			
			QueryResult = Query.Execute();
			SelectionDetailRecords = QueryResult.Select();
			While SelectionDetailRecords.Next() Do
				BillObject = SelectionDetailRecords.Ref.GetObject();
				
				TotalLinePayment = BillObject.LineItems.Total("Payment");
				TotalCredit = BillObject.Credits.Total("Payment");
				ExchangeRate = GeneralFunctions.GetExchangeRate(BillObject.Date,BillObject.Currency);
				BillObject.CashPayment = TotalLinePayment - TotalCredit;
				BillObject.DocumentTotalRC = (BillObject.CashPayment * ExchangeRate) + (TotalCredit * ExchangeRate);
				BillObject.DocumentTotal = BillObject.CashPayment + TotalCredit;
				If BillObject.CashPayment <> 0 Then 
					BillObject.DataExchange.Load = True;
					BillObject.Write(DocumentWriteMode.Write); 
					// Will be updated only documents objects.
					// Not records
				EndIf;
			EndDo;

			
			
			// update call goes here
			
			//-----------------------------------
			
			Constants.CurrentConfigurationVersion.Set(TrimAll(ConfigurationVersion));
			
			WriteLogEvent(
			InfobaseUpdateEvent(),
			EventLogLevel.Information,
			,
			,
			"Updating to the version ""1.1.43.06"" succeeded.");

		Except
			ErrorDescription = ErrorDescription();
			If TransactionActive() Then
				RollbackTransaction();
			EndIf;
			
			WriteLogEvent(
			InfobaseUpdateEvent(),
			EventLogLevel.Error,
			,
			,
			"Updating to the version ""1.1.43.06"". During the update an error occured: " + ErrorDescription);

			return;
		EndTry;
		CommitTransaction();
	EndIf;

	If UpdateRequiredForVersion(ConfigurationVersion, CurrentVersion, "1.1.44.02") Then
		Try
			BeginTransaction(DataLockControlMode.Managed);
			
			//Fill a full name of Vendor
			Query = New Query;
			Query.Text = 
			"SELECT
			|	Companies.Ref AS Company
			|FROM
			|	Catalog.Companies AS Companies
			|WHERE
			|	Companies.FullName = """"";
			
			QueryResult = Query.Execute();
			
			SelectionDetailRecords = QueryResult.Select();
			
			While SelectionDetailRecords.Next() Do
				CatalogObj = SelectionDetailRecords.Company.GetObject();
				CatalogObj.FullName = CatalogObj.Description;
				CatalogObj.Write();
			EndDo;
			//
			
			Constants.CurrentConfigurationVersion.Set(TrimAll(ConfigurationVersion));
			
			WriteLogEvent(
			InfobaseUpdateEvent(),
			EventLogLevel.Information,
			,
			,
			"Updating to the version ""1.1.44.02"" succeeded.");

		Except
			ErrorDescription = ErrorDescription();
			If TransactionActive() Then
				RollbackTransaction();
			EndIf;
			
			WriteLogEvent(
			InfobaseUpdateEvent(),
			EventLogLevel.Error,
			,
			,
			"Updating to the version ""1.1.44.02"". During the update an error occured: " + ErrorDescription);

			return;
		EndTry;
		CommitTransaction();
	EndIf;
	
	If UpdateRequiredForVersion(ConfigurationVersion, CurrentVersion, "1.1.44.03") Then
		Try
			BeginTransaction(DataLockControlMode.Managed);
			
			//Set Accounting method 
			Constants.AccountingMethod.Set(Enums.AccountingMethod.Accrual);
			//
			
			Constants.CurrentConfigurationVersion.Set(TrimAll(ConfigurationVersion));
			
			WriteLogEvent(
			InfobaseUpdateEvent(),
			EventLogLevel.Information,
			,
			,
			"Updating to the version ""1.1.44.03"" succeeded.");

		Except
			ErrorDescription = ErrorDescription();
			If TransactionActive() Then
				RollbackTransaction();
			EndIf;
			
			WriteLogEvent(
			InfobaseUpdateEvent(),
			EventLogLevel.Error,
			,
			,
			"Updating to the version ""1.1.44.03"". During the update an error occured: " + ErrorDescription);

			return;
		EndTry;
		CommitTransaction();
	EndIf;
	
	If UpdateRequiredForVersion(ConfigurationVersion, CurrentVersion, "1.1.45.02") Then
		// Update
		Try
			BeginTransaction(DataLockControlMode.Managed);
			
			// Fill "Remit to" address data in Catalog.Addresses, Document.Check and Document.InvoicePayment.
			UpdateRemitToAddressData();
			
			Constants.CurrentConfigurationVersion.Set(TrimAll(ConfigurationVersion));
			
			WriteLogEvent(
			InfobaseUpdateEvent(),
			EventLogLevel.Information,
			,
			,
			"Updating to the version ""1.1.45.02"" succeeded.");
		
		Except
			ErrorDescription = ErrorDescription();
			If TransactionActive() Then
				RollbackTransaction();
			EndIf;
			
			WriteLogEvent(
			InfobaseUpdateEvent(),
			EventLogLevel.Error,
			,
			,
			"Updating to the version ""1.1.45.02"". During the update an error occured: " + ErrorDescription);
			
			return;
		EndTry;
		CommitTransaction();
	EndIf;
	
	If UpdateRequiredForVersion(ConfigurationVersion, CurrentVersion, "1.1.45.06") Then
		Try
			BeginTransaction(DataLockControlMode.Managed);
			
			//Set Sales Order Pre-payments 
			Constants.UseSOPrepayment.Set(False);
			//
			
			Constants.CurrentConfigurationVersion.Set(TrimAll(ConfigurationVersion));
			
			WriteLogEvent(
			InfobaseUpdateEvent(),
			EventLogLevel.Information,
			,
			,
			"Updating to the version ""1.1.45.06"" succeeded.");

		Except
			ErrorDescription = ErrorDescription();
			If TransactionActive() Then
				RollbackTransaction();
			EndIf;
			
			WriteLogEvent(
			InfobaseUpdateEvent(),
			EventLogLevel.Error,
			,
			,
			"Updating to the version ""1.1.45.06"". During the update an error occured: " + ErrorDescription);

			return;
		EndTry;
		CommitTransaction();
	EndIf;
	
	If UpdateRequiredForVersion(ConfigurationVersion, CurrentVersion, "1.1.45.12") Then
		Try
			BeginTransaction(DataLockControlMode.Managed);
			
			Constants.FullFeatureSet.Set(True);   
			Constants.FileStorageProcessing.Set(True);
			Constants.EnableReportIncomeStatementByClassAccrualBasis.Set(True);
			Constants.EnableReportsAccrualBasis.Set(True);
			Constants.EnableReportSalesByRepAccrualBasis.Set(True);
			
			WriteLogEvent(
			InfobaseUpdateEvent(),
			EventLogLevel.Information,
			,
			,
			"Updating to the version ""1.1.45.12"" succeeded.");

		Except
			ErrorDescription = ErrorDescription();
			If TransactionActive() Then
				RollbackTransaction();
			EndIf;
			
			WriteLogEvent(
			InfobaseUpdateEvent(),
			EventLogLevel.Error,
			,
			,
			"Updating to the version ""1.1.45.12"". During the update an error occured: " + ErrorDescription);

			return;
		EndTry;
		CommitTransaction();
	EndIf;
	
EndProcedure

Function InfobaseUpdateNeeded(Val CurrentVersion, Val ConfigurationVersion)
	return (TrimAll(CurrentVersion) <> TrimAll(ConfigurationVersion)) AND (Not IsBlankString(ConfigurationVersion));
EndFunction

Function UpdateRequiredForVersion(ConfigurationVersion, CurrentVersion, UpdatingVersion)
	ConfigurationVersionLexemes = StringFunctionsClientServer.SplitStringIntoSubstringArray(ConfigurationVersion, ".");
	CurrentVersionLexemes = StringFunctionsClientServer.SplitStringIntoSubstringArray(CurrentVersion, ".");
	UpdatingVersionLexemes = StringFunctionsClientServer.SplitStringIntoSubstringArray(UpdatingVersion, ".");
	If (ConfigurationVersionLexemes.Count() <> 4) Or (CurrentVersionLexemes.Count() <> 4) 
		Or (UpdatingVersionLexemes.Count() <> 4) Then
		return False;
	EndIf;
	CurrentVersionUpdateRequired = False;
	//If CurrentVersion >= UpdatingVersion then update is not required
	For i = 0 To 3 Do
		If Number(CurrentVersionLexemes[i]) < Number(UpdatingVersionLexemes[i]) Then
			CurrentVersionUpdateRequired = True;
			Break;
		ElsIf Number(CurrentVersionLexemes[i]) > Number(UpdatingVersionLexemes[i]) Then
			CurrentVersionUpdateRequired = False;
			Break;
		EndIf;
	EndDo;
	If Not CurrentVersionUpdateRequired Then
		return False;
	EndIf;
	ConfigurationVersionUpdateRequired = True;
	//If ConfigurationVersion < UpdatingVersion then update is not required
	For i = 0 To 3 Do
		If Number(ConfigurationVersionLexemes[i]) > Number(UpdatingVersionLexemes[i]) Then
			ConfigurationVersionUpdateRequired = True;
			Break;
		ElsIf Number(ConfigurationVersionLexemes[i]) < Number(UpdatingVersionLexemes[i]) Then
			ConfigurationVersionUpdateRequired = False;
			Break;			
		EndIf;
	EndDo;
	return CurrentVersionUpdateRequired AND ConfigurationVersionUpdateRequired;
EndFunction

Function InfobaseUpdateEvent()
	return "Infobase.UpdatingInfobase";
EndFunction

#EndRegion

#Region Updating_Hierarchy_ChartOfAccounts

Procedure UpdatingHierarchyChartOfAccounts() Export
	
	If Constants.HierarchyChartOfAccountsUpdated.Get() = False Then
		
		BeginTransaction();
		/////////////////////////////////////////////////////////////////////
		ChartOfAccountsSelection = ChartsOfAccounts.ChartOfAccounts.Select();
		While ChartOfAccountsSelection.Next() Do
			WriteHierarchy(ChartOfAccountsSelection.Ref);
		EndDo;
		/////////////////////////////////////////////////////////////////////
		CommitTransaction();
		
		Constants.HierarchyChartOfAccountsUpdated.Set(True);
		
	EndIf;
	
EndProcedure //UpdatingHierarchyChartOfAccounts

Procedure WriteHierarchy(Item)
	
	IR = InformationRegisters.HierarchyChartOfAccounts.CreateRecordSet();
	IR.Filter.Account.Set(Item);
	
	NewIRecord = IR.Add();
	NewIRecord.Account = Item;
	NewIRecord.Route = GetHierarchy(Item, "/");
	
	IR.Write();
	
EndProcedure

Function GetHierarchy(Item, Route)
	
	Route = Route + Item.Code + "/";
	
	If ValueIsFilled(Item.Parent) Then
		GetHierarchy(Item.Parent, Route)	
	EndIf;	
	
	Return Route;	
	
EndFunction	

#EndRegion

#Region Updating_InformationRegister_DocumentJournalOfCompanies

//It's only for update documents Statement!!!
Procedure UpdatingInformationRegisterDocumentJournalOfCompanies() Export 
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	DocumentJournalOfCompanies.Document AS Document 
		|FROM
		|	InformationRegister.DocumentJournalOfCompanies AS DocumentJournalOfCompanies";
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		NotificationsServerFullRights.DocumentJournalOfCompaniesOnWrite(SelectionDetailRecords.Document, False);
	EndDo;
	
EndProcedure

#EndRegion

Procedure SetNumbering() Export
	
	If Catalogs.DocumentNumbering.PurchaseOrder.Number = "" Then
		Numerator = Catalogs.DocumentNumbering.PurchaseOrder.GetObject();
		Numerator.Number = "999";
		Numerator.Write();
	EndIf;
	
	If Catalogs.DocumentNumbering.SalesOrder.Number = "" Then
		Numerator = Catalogs.DocumentNumbering.SalesOrder.GetObject();
		Numerator.Number = "999";
		Numerator.Write();
	EndIf;
	
	If Catalogs.DocumentNumbering.SalesInvoice.Number = "" Then
		Numerator = Catalogs.DocumentNumbering.SalesInvoice.GetObject();
		Numerator.Number = "999";
		Numerator.Write();
	EndIf;
	
	If Catalogs.DocumentNumbering.Quote.Number = "" Then
		Numerator = Catalogs.DocumentNumbering.Quote.GetObject();
		Numerator.Number = "999";
		Numerator.Write();
	EndIf;
	
	If Catalogs.DocumentNumbering.Shipment.Number = "" Then
		Numerator = Catalogs.DocumentNumbering.Shipment.GetObject();
		Numerator.Number = "999";
		Numerator.Write();
	EndIf;
	
	If Catalogs.DocumentNumbering.Companies.Number = "" Then
		Numerator = Catalogs.DocumentNumbering.Companies.GetObject();
		Numerator.Number = "999";
		Numerator.Write();
	EndIf;
	
	If Catalogs.DocumentNumbering.ItemReceipt.Number = "" Then
		Numerator = Catalogs.DocumentNumbering.ItemReceipt.GetObject();
		Numerator.Number = "999";
		Numerator.Write();
	EndIf;
	
	If Catalogs.DocumentNumbering.Deposit.Number = "" Then
		Numerator = Catalogs.DocumentNumbering.Deposit.GetObject();
		Numerator.Number = "999";
		Numerator.Write();
	EndIf;
	
	If Catalogs.DocumentNumbering.Assembly.Number = "" Then
		Numerator = Catalogs.DocumentNumbering.Assembly.GetObject();
		Numerator.Number = "999";
		Numerator.Write();
	EndIf;
	
	If Catalogs.DocumentNumbering.PurchaseReturn.Number = "" Then
		Numerator = Catalogs.DocumentNumbering.PurchaseReturn.GetObject();
		Numerator.Number = "999";
		Numerator.Write();
	EndIf;
	
	If Catalogs.DocumentNumbering.CreditMemo.Number = "" Then
		Numerator = Catalogs.DocumentNumbering.CreditMemo.GetObject();
		Numerator.Number = "999";
		Numerator.Write();
	EndIf;
	
EndProcedure 

#Region Period_Manager

Function GetBeginOfFiscalYear(Val Date) Export
	
	Date = BegOfMonth(Date);
	
	BeginOfFiscalYear = '00010101';
	
	FirstMonthOfFiscalYear = Constants.FirstMonthOfFiscalYear.Get(); 
	
	If Month(Date) >= FirstMonthOfFiscalYear Then
		BeginOfFiscalYear = AddMonth(BegOfYear(Date), FirstMonthOfFiscalYear - 1);
	Else
		BeginOfFiscalYear = AddMonth(AddMonth(BegOfYear(Date), FirstMonthOfFiscalYear - 1), -12);
	EndIf;
	
	Return BeginOfFiscalYear;
	
EndFunction

Function GetCustomizedPeriodsList() Export
	
	AnotherFiscalYear = ?(Constants.FirstMonthOfFiscalYear.Get() <= 1, False, True);
	
	Array = New Array;
	
	Array.Add("All Dates"); 
	Array.Add("Custom"); 
	Array.Add("Today"); 
	
	//Array.Add("Yesterday"); 
	Array.Add("This Week"); 
	//Array.Add("This Week-to-date"); 
	Array.Add("This Month"); 
	//Array.Add("This Month-to-date"); 
	Array.Add("This Quarter"); 
	//Array.Add("This Quarter-to-date");
	If AnotherFiscalYear Then
		Array.Add("This Fiscal Year"); 
		Array.Add("This Calendar Year"); 
	Else
		Array.Add("This Year"); 
	EndIf;
	//Array.Add("This Year-to-date"); 
	//Array.Add("Last Week"); 
	//Array.Add("Last Week-to-date"); 
	Array.Add("Last Month"); 
	//Array.Add("Last Month-to-date"); 
	Array.Add("Last Quarter"); 
	//Array.Add("Last Quarter-to-date"); 
	If AnotherFiscalYear Then
		Array.Add("Last Fiscal Year"); 
		Array.Add("Last Calendar Year"); 
	Else
		Array.Add("Last Year"); 
	EndIf;
	//Array.Add("Last Year-to-date");
	
	Return Array;
	
EndFunction

Function GetDefaultPeriodVariant() Export 
	
	AnotherFiscalYear = ?(Constants.FirstMonthOfFiscalYear.Get() <= 1, False, True);
	
	If AnotherFiscalYear Then
		Return "This Fiscal Year";
	Else
		Return "This Year";
	EndIf;
	
	
EndFunction

Function GetCustomVariantName() Export 
	
	Return "Custom"; 
	
EndFunction

Procedure ChangeDatesByPeriod(PeriodVariant, PeriodStartDate, PeriodEndDate) Export
	
	CurrentDate            = CurrentSessionDate();
	DayIntoSeconds         = 86400;
	FirstMonthOfFiscalYear = Constants.FirstMonthOfFiscalYear.Get();
	FirstMonthOfFiscalYear = ?(FirstMonthOfFiscalYear = 0, 1, FirstMonthOfFiscalYear);
	
	If PeriodVariant = "All Dates" Or PeriodVariant = "" Then 
		PeriodStartDate = '19900101';
		PeriodEndDate = '20291231';
	ElsIf PeriodVariant = "Today" Then
		PeriodStartDate = CurrentDate;
		PeriodEndDate = CurrentDate;
	ElsIf PeriodVariant = "Yesterday" Then
		PeriodStartDate = CurrentDate - DayIntoSeconds;
		PeriodEndDate = CurrentDate - DayIntoSeconds;
		/////////////////////////////////////////////////
	ElsIf PeriodVariant = "This Week" Then
		PeriodStartDate = BegOfWeek(CurrentDate);
		PeriodEndDate = EndOfWeek(CurrentDate);
	ElsIf PeriodVariant = "This Week-to-date" Then
		PeriodStartDate = BegOfWeek(CurrentDate);
		PeriodEndDate = CurrentDate;
	ElsIf PeriodVariant = "This Month" Then
		PeriodStartDate = BegOfMonth(CurrentDate);
		PeriodEndDate = EndOfMonth(CurrentDate);
	ElsIf PeriodVariant = "This Month-to-date" Then
		PeriodStartDate = BegOfMonth(CurrentDate);
		PeriodEndDate = CurrentDate;
	ElsIf PeriodVariant = "This Quarter" Then
		PeriodStartDate = BegOfQuarter(CurrentDate);
		PeriodEndDate = EndOfQuarter(CurrentDate);
	ElsIf PeriodVariant = "This Quarter-to-date" Then
		PeriodStartDate = BegOfQuarter(CurrentDate);
		PeriodEndDate = CurrentDate;
	ElsIf PeriodVariant = "This Fiscal Year" Then
		
		If Month(CurrentDate) >= FirstMonthOfFiscalYear Then
			PeriodStartDate = Date(Year(CurrentDate), FirstMonthOfFiscalYear, 1);
			PeriodEndDate = EndOfMonth(AddMonth(PeriodStartDate, 11));
		Else
			PeriodStartDate = Date(Year(CurrentDate) - 1, FirstMonthOfFiscalYear, 1);
			PeriodEndDate = EndOfMonth(AddMonth(PeriodStartDate, 11));
		EndIf;
		
	ElsIf PeriodVariant = "This Year" Or PeriodVariant = "This Calendar Year" Then
		PeriodStartDate = BegOfYear(CurrentDate);
		PeriodEndDate = EndOfYear(CurrentDate);
	ElsIf PeriodVariant = "This Year-to-date" Then
		PeriodStartDate = BegOfYear(CurrentDate);
		PeriodEndDate = CurrentDate;
		/////////////////////////////////////////////////
	ElsIf PeriodVariant = "Last Week" Then
		PeriodStartDate = BegOfWeek(CurrentDate - DayIntoSeconds * 7);
		PeriodEndDate = EndOfWeek(CurrentDate - DayIntoSeconds * 7);
	ElsIf PeriodVariant = "Last Week-to-date" Then
		PeriodStartDate = BegOfWeek(CurrentDate - DayIntoSeconds * 7);
		PeriodEndDate = CurrentDate - DayIntoSeconds * 7;
	ElsIf PeriodVariant = "Last Month" Then
		PeriodStartDate = BegOfMonth(AddMonth(CurrentDate, -1));
		PeriodEndDate = EndOfMonth(AddMonth(CurrentDate, - 1));
	ElsIf PeriodVariant = "Last Month-to-date" Then
		PeriodStartDate = BegOfMonth(AddMonth(CurrentDate, -1));
		PeriodEndDate = AddMonth(CurrentDate, -1);
	ElsIf PeriodVariant = "Last Quarter" Then
		PeriodStartDate = BegOfQuarter(AddMonth(CurrentDate, -3));
		PeriodEndDate = EndOfQuarter(AddMonth(CurrentDate, -3));
	ElsIf PeriodVariant = "Last Quarter-to-date" Then
		PeriodStartDate = BegOfQuarter(AddMonth(CurrentDate, -3));
		PeriodEndDate = AddMonth(CurrentDate, -3);
	ElsIf PeriodVariant = "Last Fiscal Year" Then
		
		If Month(CurrentDate) >= FirstMonthOfFiscalYear Then
			PeriodStartDate = Date(Year(CurrentDate) - 1, FirstMonthOfFiscalYear, 1);
			PeriodEndDate = EndOfMonth(AddMonth(PeriodStartDate, 11));
		Else
			PeriodStartDate = Date(Year(CurrentDate) - 2, FirstMonthOfFiscalYear, 1);
			PeriodEndDate = EndOfMonth(AddMonth(PeriodStartDate, 11));
		EndIf;
		
	ElsIf PeriodVariant = "Last Year" Or PeriodVariant = "Last Calendar Year" Then
		PeriodStartDate = BegOfYear(AddMonth(CurrentDate, -12));
		PeriodEndDate = EndOfYear(AddMonth(CurrentDate, -12));
	ElsIf PeriodVariant = "Last Year-to-date" Then
		PeriodStartDate = BegOfYear(AddMonth(CurrentDate, -12));
		PeriodEndDate = AddMonth(CurrentDate, -12);
	EndIf;
	
EndProcedure

Procedure ChangePeriodIntoUserSettings(SettingsComposer, PeriodStartDate, PeriodEndDate) Export 
	
	ReportFormSettings = SettingsComposer.Settings;
	PeriodSettingID = ReportFormSettings.DataParameters.Items.Find("Period").UserSettingID;
	UserSettings = SettingsComposer.UserSettings.Items;
	
	UserSettings.Find(PeriodSettingID).Value = New StandardPeriod(PeriodStartDate, PeriodEndDate);
	UserSettings.Find(PeriodSettingID).Use = ?(ValueIsFilled(PeriodEndDate), True, False);

EndProcedure

Procedure ChangePeriodIntoReportForm(SettingsComposer, PeriodVariant, PeriodStartDate, PeriodEndDate) Export
	
	ReportFormSettings = SettingsComposer.Settings;
	PeriodSettingID = ReportFormSettings.DataParameters.Items.Find("Period").UserSettingID;
	UserSettings = SettingsComposer.UserSettings.Items;
	
	If Not UserSettings.Find(PeriodSettingID).Use Then
		PeriodVariant = "All Dates"; 
		PeriodStartDate = '00010101';
		PeriodEndDate = '00010101';
	Else
		NewPeriod = UserSettings.Find(PeriodSettingID).Value;
		
		PeriodVariant = "Custom"; 
		PeriodStartDate = NewPeriod.StartDate;
		PeriodEndDate = NewPeriod.EndDate;
	EndIf;
	
EndProcedure

#EndRegion

#Region Excel_Manager

Function GetExcelFile(FileName, SpreadsheetDocument) Export
	
	Structure = New Structure("FileName, Address");
	
	Structure.FileName = "" + GetCorrectSystemTitle() + " - " + FileName + ".xlsx"; 
	Structure.Address = GetFileName(SpreadsheetDocument); 
	
	Return Structure;	

EndFunction


Function GetCSVFile(FileName, SpreadsheetDocument) Export
	
	// Create file name and put the file in a temporary storage.
	Structure = New Structure("FileName, Address");
	Structure.FileName = "" + GetCorrectSystemTitle() + " - " + FileName + ".csv"; 
	Structure.Address  = SaveCSVFile(SpreadsheetDocument); 
	
	// Return the file description in a temporary storage.
	Return Structure;
	
EndFunction

Function SaveCSVFile(SpreadsheetDocument)
	
	// Save spreadsheet to the Excel file.
	TemporaryFileNameXLSX = SaveSpreadsheetToFile(SpreadsheetDocument, ".xlsx", SpreadsheetDocumentFileType.XLSX);
	TemporaryFileNameCSV  = GetTempFileName(".csv");
	
	// Update Excel format settings.
	Try
		COMExcel = New COMObject("Excel.Application"); 
		Doc = COMExcel.Application.Workbooks.Open(TemporaryFileNameXLSX); 
		
		Doc.SaveAs(TemporaryFileNameCSV, 6, , , , , , 2); //Change format to CSV (6)
		// Delete used temporary Exel file.
		DeleteFiles(TemporaryFileNameXLSX);
		Doc.Close(True);
	Except
	EndTry;
	
	// Put CSV file in a temporary storage.
	FileAddress = PutFileInTemporaryStorage(TemporaryFileNameCSV);
	
	// Delete used temporary CSV file.
	DeleteFiles(TemporaryFileNameCSV);
	
	// Return address of file in a storage.
	Return FileAddress;
	
EndFunction


Function SaveSpreadsheetToFile(SpreadsheetDocument, Extension, FileType)
	
	// Get temporary file name (a pointer to a new file).
	TemporaryFileName = GetTempFileName(Extension);
	
	// Save the spreadsheet to the temporary file.
	SpreadsheetDocument.Write(TemporaryFileName, FileType);
	
	// Return the pointer to a saved file.
	Return TemporaryFileName;
	
EndFunction

Function PutFileInTemporaryStorage(FileName)
	
	// Create a new binary data form the file.
	BinaryData = New BinaryData(FileName);
	
	// Put data into tempoarary storage. Return address in a storage.
	Return PutToTempStorage(BinaryData);
	
EndFunction

Function GetCorrectSystemTitle()
	
	SystemTitle = Constants.SystemTitle.Get();
	
	NewSystemTitle = "";
	
	For i = 1 To StrLen(SystemTitle) Do
		
		Char = Mid(SystemTitle, i, 1);
		
		If Find("#&\/:*?""<>|.", Char) > 0 Then
			NewSystemTitle = NewSystemTitle + " ";	
		Else
			NewSystemTitle = NewSystemTitle + Char;	
		EndIf;
		
	EndDo;	
	
	Return NewSystemTitle;
	
EndFunction

#EndRegion

#Region Unit_Manager 

Function GetBaseUnit(UnitSet) Export 
	
	Return Catalogs.Units.FindByAttribute("BaseUnit", True, , UnitSet);
		
EndFunction

#EndRegion

#Region Margin_Manager

Function GetMarginInformation(Product, Location, Quantity, LineTotal, Currency, ExchangeRate, DiscountPercent, Val LineItems) Export 
	
	QuantityFormat    = GeneralFunctionsReusable.DefaultQuantityFormat();
	//////////////////////////////////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////////////////////////////////
	Cost        = "";
	Margin      = "";
	MarginTotal = "";

	Query = New Query;
	Query.Text = "SELECT
	             |	ItemLastCostsSliceLast.Product,
	             |	ItemLastCostsSliceLast.Cost
	             |FROM
	             |	InformationRegister.ItemLastCosts.SliceLast(, Product IN (&Products)) AS ItemLastCostsSliceLast";

	Query.SetParameter("Products", LineItems.UnloadColumn("Product"));
	ItemLastCosts = Query.Execute().Unload();
	
	LastCostRow = ItemLastCosts.Find(Product, "Product");
	
	//Cost
	Cost = ?(LastCostRow <> Undefined, LastCostRow.Cost, 0);
	PriceFormat = GeneralFunctionsReusable.PriceFormatForOneItem(Product);
	Cost = "Cost " + Currency.Symbol + " " + Format(?(ExchangeRate = 0, 0, Cost / ExchangeRate), PriceFormat + "; NZ=0"); 
	
	//Margin
	LineTotalLC = ?(LastCostRow <> Undefined, LastCostRow.Cost, 0) * Quantity; 
	LineTotalLC = ?(ExchangeRate = 0, 0, LineTotalLC / ExchangeRate);
	
	LineTotalP = LineTotal - (LineTotal * DiscountPercent / 100);	
	
	MarginSum = Currency.Symbol + " " + Format(LineTotalP - LineTotalLC, "NFD=2; NZ=0.00"); 
	
	// It was mistake. This way is calculated Markup.
	//If LineTotalLC = 0 Then
	//	Margin = "Margin 0.00% / " + MarginSum;
	//Else
	//	Margin = "Margin " + Format((LineTotalP / LineTotalLC) * 100 - 100, "NFD=2; NZ=0.00") + "% / " + MarginSum;
	//EndIf;
	If LineTotalP = 0 Then
		MarginValue = 0;
	Else
		MarginValue = 100 - (LineTotalLC / LineTotalP) * 100;
	EndIf;
	
	Margin = "Margin " + Format(MarginValue, "NFD=2; NZ=0.00") + "% / " + MarginSum;
	
	//MarginTotal
	LineTotalLCSum = 0;
	LineTotalSum   = 0;
	
	For Each Item In LineItems Do
		
		LastCostRow = ItemLastCosts.Find(Item.Product, "Product");
		
		//LineTotalLCSum
		LineTotalLC = ?(LastCostRow <> Undefined, LastCostRow.Cost, 0) * Item.QtyUM; 
		LineTotalLC = ?(ExchangeRate = 0, 0, LineTotalLC / ExchangeRate);
		
		LineTotalLCSum = LineTotalLCSum + LineTotalLC;
		
		//LineTotalSum
		LineTotalP = Item.LineTotal - (Item.LineTotal * DiscountPercent / 100);	
		
		LineTotalSum = LineTotalSum + LineTotalP;
		
	EndDo;
	
	MarginSum = Currency.Symbol + " " + Format(LineTotalSum - LineTotalLCSum, "NFD=2; NZ=0.00"); 
	
	// It was mistake. This way is calculated Markup.
	//If LineTotalLCSum = 0 Then
	//	MarginTotal = "Total 0.00% / " + MarginSum;
	//Else
	//	MarginTotal = "Total " + Format((LineTotalSum / LineTotalLCSum) * 100 - 100, "NFD=2; NZ=0.00") + "% / " + MarginSum;
	//EndIf;
	If LineTotalLCSum = 0 Then
		MarginValue = 0;
	Else
		MarginValue = 100 - (LineTotalLCSum / LineTotalSum) * 100;
	EndIf;
	
	MarginTotal = "Total " + Format(MarginValue, "NFD=2; NZ=0.00") + "% / " + MarginSum;
	
	//////////////////////////////////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////////////////////////////////
	
	//////////////////////////////////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////////////////////////////////
	Query = New Query;
	
	Query.SetParameter("Ref", Product);
	Query.SetParameter("Type", Product.Type);
	Query.SetParameter("Location", Location);
	
	Query.Text = "SELECT
	             |	OrdersDispatchedBalance.Company AS Company,
	             |	OrdersDispatchedBalance.Order AS Order,
	             |	OrdersDispatchedBalance.Product AS Product,
	             |	OrdersDispatchedBalance.Location,
	             |	OrdersDispatchedBalance.Unit AS Unit,
	             |	CASE
	             |		WHEN &Type = VALUE(Enum.InventoryTypes.Inventory)
	             |			THEN CASE
	             |					WHEN OrdersDispatchedBalance.QuantityBalance - OrdersDispatchedBalance.ReceivedBalance > 0
	             |						THEN (OrdersDispatchedBalance.QuantityBalance - OrdersDispatchedBalance.ReceivedBalance) * OrdersDispatchedBalance.Unit.Factor
	             |					ELSE 0
	             |				END
	             |		WHEN &Type = VALUE(Enum.InventoryTypes.NonInventory)
	             |			THEN CASE
	             |					WHEN OrdersDispatchedBalance.QuantityBalance - OrdersDispatchedBalance.InvoicedBalance > 0
	             |						THEN (OrdersDispatchedBalance.QuantityBalance - OrdersDispatchedBalance.InvoicedBalance) * OrdersDispatchedBalance.Unit.Factor
	             |					ELSE 0
	             |				END
	             |		ELSE 0
	             |	END AS QtyOnPO,
	             |	0 AS QtyOnSO,
	             |	0 AS QtyOnHand
	             |INTO Table_OrdersDispatched_OrdersRegistered_InventoryJournal
	             |FROM
	             |	AccumulationRegister.OrdersDispatched.Balance(
	             |			,
	             |			Product = &Ref
	             |				AND Location = &Location) AS OrdersDispatchedBalance
	             |		LEFT JOIN InformationRegister.OrdersStatuses.SliceLast AS OrdersStatusesSliceLast
	             |		ON OrdersDispatchedBalance.Order = OrdersStatusesSliceLast.Order
	             |			AND (OrdersStatusesSliceLast.Status = VALUE(Enum.OrderStatuses.Open)
	             |				OR OrdersStatusesSliceLast.Status = VALUE(Enum.OrderStatuses.Backordered))
	             |
	             |UNION ALL
	             |
	             |SELECT
	             |	OrdersRegisteredBalance.Company,
	             |	OrdersRegisteredBalance.Order,
	             |	OrdersRegisteredBalance.Product,
	             |	OrdersRegisteredBalance.Location,
	             |	OrdersRegisteredBalance.Unit,
	             |	0,
	             |	CASE
	             |		WHEN &Type = VALUE(Enum.InventoryTypes.Inventory)
	             |			THEN CASE
	             |					WHEN OrdersRegisteredBalance.QuantityBalance - OrdersRegisteredBalance.ShippedBalance > 0
	             |						THEN (OrdersRegisteredBalance.QuantityBalance - OrdersRegisteredBalance.ShippedBalance) * OrdersRegisteredBalance.Unit.Factor
	             |					ELSE 0
	             |				END
	             |		WHEN &Type = VALUE(Enum.InventoryTypes.NonInventory)
	             |			THEN CASE
	             |					WHEN OrdersRegisteredBalance.QuantityBalance - OrdersRegisteredBalance.InvoicedBalance > 0
	             |						THEN (OrdersRegisteredBalance.QuantityBalance - OrdersRegisteredBalance.InvoicedBalance) * OrdersRegisteredBalance.Unit.Factor
	             |					ELSE 0
	             |				END
	             |		ELSE 0
	             |	END,
	             |	0
	             |FROM
	             |	AccumulationRegister.OrdersRegistered.Balance(
	             |			,
	             |			Product = &Ref
	             |				AND Location = &Location) AS OrdersRegisteredBalance
	             |		LEFT JOIN InformationRegister.OrdersStatuses.SliceLast AS OrdersStatusesSliceLast
	             |		ON OrdersRegisteredBalance.Order = OrdersStatusesSliceLast.Order
	             |			AND (OrdersStatusesSliceLast.Status = VALUE(Enum.OrderStatuses.Open)
	             |				OR OrdersStatusesSliceLast.Status = VALUE(Enum.OrderStatuses.Backordered))
	             |
	             |UNION ALL
	             |
	             |SELECT
	             |	NULL,
	             |	NULL,
	             |	InventoryJournalBalance.Product,
	             |	InventoryJournalBalance.Location,
	             |	NULL,
	             |	0,
	             |	0,
	             |	CASE
	             |		WHEN &Type = VALUE(Enum.InventoryTypes.Inventory)
	             |			THEN InventoryJournalBalance.QuantityBalance
	             |		WHEN &Type = VALUE(Enum.InventoryTypes.NonInventory)
	             |			THEN 0
	             |		ELSE 0
	             |	END
	             |FROM
	             |	AccumulationRegister.InventoryJournal.Balance(
	             |			,
	             |			Product = &Ref
	             |				AND Location = &Location) AS InventoryJournalBalance
	             |;
	             |
	             |////////////////////////////////////////////////////////////////////////////////
	             |SELECT
	             |	TableBalances.Product AS Product,
	             |	TableBalances.Location,
	             |	SUM(ISNULL(TableBalances.QtyOnPO, 0)) AS QtyOnPO,
	             |	SUM(ISNULL(TableBalances.QtyOnSO, 0)) AS QtyOnSO,
	             |	SUM(ISNULL(TableBalances.QtyOnHand, 0)) AS QtyOnHand,
	             |	CASE
	             |		WHEN &Type = VALUE(Enum.InventoryTypes.Inventory)
	             |			THEN SUM(ISNULL(TableBalances.QtyOnHand, 0)) + SUM(ISNULL(TableBalances.QtyOnPO, 0)) - SUM(ISNULL(TableBalances.QtyOnSO, 0))
	             |		WHEN &Type = VALUE(Enum.InventoryTypes.NonInventory)
	             |			THEN 0
	             |		ELSE 0
	             |	END AS QtyAvailableToPromise
	             |INTO TotalTable
	             |FROM
	             |	Table_OrdersDispatched_OrdersRegistered_InventoryJournal AS TableBalances
	             |
	             |GROUP BY
	             |	TableBalances.Product,
	             |	TableBalances.Location
	             |;
	             |
	             |////////////////////////////////////////////////////////////////////////////////
	             |SELECT
	             |	TotalTable.Product,
	             |	TotalTable.Location,
	             |	TotalTable.QtyOnPO,
	             |	TotalTable.QtyOnSO,
	             |	TotalTable.QtyOnHand,
	             |	TotalTable.QtyAvailableToPromise
	             |FROM
	             |	TotalTable AS TotalTable
	             |WHERE
	             |	(TotalTable.QtyOnPO <> 0
	             |			OR TotalTable.QtyOnSO <> 0
	             |			OR TotalTable.QtyOnHand <> 0
	             |			OR TotalTable.QtyAvailableToPromise <> 0)";
	
	
	SelectionDetailRecords = Query.Execute().Select();
	
	OnPO   = Format(0, QuantityFormat);
	OnSO   = Format(0, QuantityFormat);
	OnHand = Format(0, QuantityFormat);
	ATP    = Format(0, QuantityFormat);
	
	While SelectionDetailRecords.Next() Do
		
		OnPO   = Format(SelectionDetailRecords.QtyOnPO, QuantityFormat);
		OnSO   = Format(SelectionDetailRecords.QtyOnSO, QuantityFormat);
		OnHand = Format(SelectionDetailRecords.QtyOnHand, QuantityFormat);
		ATP    = Format(SelectionDetailRecords.QtyAvailableToPromise, QuantityFormat);
		
	EndDo;
	
	If Product.Type = Enums.InventoryTypes.Inventory Then
		QuantityInformation = "On PO: " + OnPO + " On SO: " + OnSO + " On hand: " + OnHand + " ATP: " + ATP;
	Else
		QuantityInformation = "On PO: " + OnPO + " On SO: " + OnSO;
	EndIf;
	//////////////////////////////////////////////////////////////////////////////////////////////////
	//////////////////////////////////////////////////////////////////////////////////////////////////
	
	BaseUnit =  GeneralFunctions.GetBaseUnit(Product.UnitSet).Code;
	
	Return Cost + " | " + Margin + " | " + MarginTotal + " | " + Location + " | Qty in " + BaseUnit + " " + QuantityInformation;
	
EndFunction

#EndRegion

Function ShowAddressDecoration(AddressRef) Export
	
	addressline1 = AddressRef.AddressLine1;
	If AddressRef.AddressLine1 <> "" AND (AddressRef.AddressLine2 <> "" OR AddressRef.AddressLine3 <> "") Then
		addressline1 = addressline1 + ", ";
	EndIf;
	addressline2 = AddressRef.AddressLine2;
	If AddressRef.AddressLine2 <> "" AND AddressRef.AddressLine3 <> "" Then
		addressline2 = addressline2 + ", ";
	EndIf;
	addressline3 = AddressRef.AddressLine3;
	//If AddressRef.AddressLine3 <> "" Then
	//	addressline3 = addressline3;
	//EndIf;
	city = AddressRef.City;
	If AddressRef.City <> "" AND (String(AddressRef.State.Code) <> "" OR AddressRef.ZIP <> "") Then
		city = city + ", ";
	EndIf;
	state = String(AddressRef.State.Code);
	If String(AddressRef.State.Code) <> "" Then
		state = state + "  ";
	EndIf;
	zip = AddressRef.ZIP;
	If AddressRef.ZIP <> "" Then
		zip = zip + Chars.LF;
	EndIf;
	country = String(AddressRef.Country.Description);
	If String(AddressRef.Country.Description) <> "" Then
		country = country;
	EndIf;
	
	If addressline1 <> "" OR addressline2 <> "" OR addressline3 <> "" Then 	
		Return addressline1 + addressline2 + addressline3 + Chars.LF + city + state + zip + country;
	Else
		Return city + state + zip + country;
	EndIf;
	
EndFunction

#Region User_and_Role_Management 

// Function to determine is user in Role, 
// Parameter: Role name
// If Yes, then return True
// Used for checking on client 
Function IsCurrentUserInRole(RoleName) Export 
	
	Return IsInRole(RoleName);
		
EndFunction

Function GetSystemTitle() Export
	
	Return Constants.SystemTitle.Get();	
	
EndFunction

Function GetFileName(SpreadsheetDocument)
	
	TemporaryFileName = GetTempFileName(".xlsx");
	
	SpreadsheetDocument.Write(TemporaryFileName, SpreadsheetDocumentFileType.XLSX);
	
	Try
		COMExcel = New COMObject("Excel.Application"); 
		Doc = COMExcel.Application.Workbooks.Open(TemporaryFileName); 
		
		Doc.Windows(1).DisplayWorkbookTabs = True;
		Doc.Windows(1).TabRatio = 0.5;
		COMExcel.ReferenceStyle = 1;
		
		Doc.Save();
		Doc.Close();
	Except
	EndTry;
	
	BinaryData = New BinaryData(TemporaryFileName);
	
	DeleteFiles(TemporaryFileName);
	
	Return PutToTempStorage(BinaryData);
	
EndFunction

#EndRegion

#Region Accrual_Basis_Reports

//Procedure sets correct value of constants to manage functional options which are using for Accrual Basis reporting.
Procedure UpdateVisibilityAccrualBasisReports() Export
	
	//1.
	AccountingMethod = Constants.AccountingMethod.Get();
	//EnableClasses    = Constants.EnableClasses.Get();
	FullFeatureSet   = Constants.FullFeatureSet.Get();
	
	//2.
	Constants.EnableReportsAccrualBasis.Set(True);
	Constants.EnableReportIncomeStatementByClassAccrualBasis.Set(True);
	Constants.EnableReportSalesByRepAccrualBasis.Set(True);
	
	//3.
	If AccountingMethod = Enums.AccountingMethod.Cash Then
		Constants.EnableReportsAccrualBasis.Set(False);
		Constants.EnableReportIncomeStatementByClassAccrualBasis.Set(False);
		Constants.EnableReportSalesByRepAccrualBasis.Set(False);
	EndIf;
	
	//If Not EnableClasses Then
	//	Constants.EnableReportIncomeStatementByClassAccrualBasis.Set(False);
	//EndIf;
	
	If Not FullFeatureSet Then
		Constants.EnableReportSalesByRepAccrualBasis.Set(False);
	EndIf;
		
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

// Functions called from UpdateInfobase().
//

// Procedure fills "Remit to" address data in Catalog.Addresses, Document.Check and Document.InvoicePayment.
//
Procedure UpdateRemitToAddressData()
	
	Query = New Query;
	Query.Text = "
		|SELECT
		|	Companies.Ref AS Company,
		|	Addresses.Ref AS Address
		|INTO TableCompaniesAddresses
		|FROM
		|	Catalog.Companies AS Companies
		|		INNER JOIN Catalog.Addresses AS Addresses
		|		ON Addresses.Owner = Companies.Ref
		|			AND Addresses.DefaultBilling
		|;
		|
		|/////////////////////////////////////
		|SELECT
		|	TableCompaniesAddresses.Address AS Address
		|FROM
		|	TableCompaniesAddresses AS TableCompaniesAddresses
		|;
		|
		|/////////////////////////////////////
		|SELECT
		|	Checks.Ref                      AS CheckRef,
		|	TableCompaniesAddresses.Address AS RemitTo
		|FROM
		|	Document.Check AS Checks
		|		LEFT JOIN TableCompaniesAddresses AS TableCompaniesAddresses
		|		ON TableCompaniesAddresses.Company = Checks.Company
		|WHERE
		|	NOT Checks.Company = VALUE(Catalog.Companies.EmptyRef)
		|	AND Checks.RemitTo = VALUE(Catalog.Addresses.EmptyRef) // Do not process documents with already filled RemitTo.
		|;
		|
		|/////////////////////////////////////
		|SELECT
		|	InvoicePayments.Ref             AS InvoicePaymentRef,
		|	TableCompaniesAddresses.Address AS RemitTo
		|FROM
		|	Document.InvoicePayment AS InvoicePayments
		|		LEFT JOIN TableCompaniesAddresses AS TableCompaniesAddresses
		|		ON TableCompaniesAddresses.Company = InvoicePayments.Company
		|WHERE
		|	NOT InvoicePayments.Company = VALUE(Catalog.Companies.EmptyRef)
		|	AND InvoicePayments.RemitTo = VALUE(Catalog.Addresses.EmptyRef) // Do not process documents with already filled RemitTo.";
	QueryResults = Query.ExecuteBatch();
	
	// Update Address catalog.
	AddressSelection = QueryResults[1].Select();
	While AddressSelection.Next() Do
		AddressObject = AddressSelection.Address.GetObject();
		AddressObject.DefaultRemitTo    = True;
		AddressObject.DataExchange.Load = True;
		AddressObject.Write();
	EndDo;
	
	// Update Payments.
	CheckSelection = QueryResults[2].Select();
	While CheckSelection.Next() Do
		CheckObject = CheckSelection.CheckRef.GetObject();
		CheckObject.RemitTo           = CheckSelection.RemitTo;
		CheckObject.DataExchange.Load = True;
		CheckObject.Write(DocumentWriteMode.Write);
	EndDo;
	
	// Update Bill payments.
	InvoicePaymentSelection = QueryResults[3].Select();
	While InvoicePaymentSelection.Next() Do
		InvoicePaymentObject = InvoicePaymentSelection.InvoicePaymentRef.GetObject();
		InvoicePaymentObject.RemitTo           = InvoicePaymentSelection.RemitTo;
		InvoicePaymentObject.DataExchange.Load = True;
		InvoicePaymentObject.Write(DocumentWriteMode.Write);
	EndDo;
	
EndProcedure

#EndRegion