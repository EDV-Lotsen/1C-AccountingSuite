
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SelectedDocuments = Parameters.Refs;
	
	TempCompanyHolder = New Array();
	
	TempVT = New ValueTable;
    TempVT = DocumentSelectedList.Unload(); 
	
	TempCompanyVT = New ValueTable;
    TempCompanyVT = CompanyGroupList.Unload();
	
	For Each Document in SelectedDocuments Do
		NewRow = TempVT.Add();
		NewRow.Document = Document;
		NewRow.Company = Document.Company;
		NewRow.Num = Document.Number;
		
		If Constants.AddCCToGlobalCheck.Get() Then
		NewRow.CCTo = Constants.CCToGlobal.Get();
		EndIf;

		If Document.Company <> Catalogs.Companies.EmptyRef() Then
			
			ConfirmToEmail 	= CommonUse.GetAttributeValue(Document.ConfirmTo, "Email");
			ShipToEmail		= CommonUse.GetAttributeValue(Document.ShipTo, "Email");	
			NewRow.EmailTo = ?(ValueIsFilled(Document.ConfirmTo), ConfirmToEmail, ShipToEmail);
		EndIf;

		NewRow.Subject = Constants.SystemTitle.Get() + " - Invoice " + Document.Number + " from " + Format(Document.Date,"DLF=D") + " - $" + Format(Document.DocumentTotalRC,"NFD=2,NZ=0.00");

		ValueToFormData(TempVT,DocumentSelectedList);
		
		If TempCompanyHolder.Find(NewRow.Company) = Undefined Then
			NewCompanyRow = TempCompanyVT.Add();
			NewCompanyRow.Company = NewRow.Company;
			
			If Constants.AddCCToGlobalCheck.Get() Then
				NewCompanyRow.CCTo = Constants.CCToGlobal.Get();
			EndIf;

	
			Query = New Query();
			Query.Text =
			"SELECT
			|	Addresses.Email
			|FROM
			|	Catalog.Addresses AS Addresses
			|WHERE
			|	Addresses.Owner = &Owner
			|	AND Addresses.DefaultBilling = &DefaultBilling";
			Query.SetParameter("Owner", NewCompanyRow.Company);
			Query.SetParameter("DefaultBilling", True);
			Selection = Query.Execute().Unload();
			
			If Selection.Count() <> 0 Then
				  NewCompanyRow.EmailTo = Selection[0].Email;
			EndIf;

			NewCompanyRow.Subject = "Invoices from " + Constants.SystemTitle.Get();
			TempCompanyHolder.Add(NewRow.Company);
			
			ValueToFormData(TempCompanyVT,CompanyGroupList);
		EndIf;
		
	EndDo;	
		
EndProcedure

&AtClient
Procedure DocumentSelectedListOnActivateRow(Item)
	
	If EnableCompanyBatch = False Then	
		CurrentData = Items.DocumentSelectedList.CurrentData;
		
		EmailTo = CurrentData.EmailTo;
		CCTo = CurrentData.CCTo;
		Subject = CurrentData.Subject;
		Body = CurrentData.Body;
		If EnableCompanyBatch = False Then
			PrepareLabel = "Preparing Invoice " + CurrentData.Num;
		Else
		    PrepareCompanyLabel = CurrentData.Num;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SendEmail(Command)
	RefreshInterface();
	SendEmailAtServer();	        
EndProcedure


&AtServer
Procedure SendEmailAtServer()
	
If CheckAllEmail(EmailTo) = False OR CheckAllEmail(CCTo) = False Then
		Message("An invalid email has been used");
Else
		
	MailProfil = New InternetMailProfile; 
	      
	MailProfil.SMTPServerAddress = ServiceParameters.SMTPServer(); 
	MailProfil.SMTPUseSSL = ServiceParameters.SMTPUseSSL();
	MailProfil.SMTPPort = 465; 

	MailProfil.Timeout = 180; 

	MailProfil.SMTPPassword = ServiceParameters.SendGridPassword();

	MailProfil.SMTPUser = ServiceParameters.SendGridUserName();

	If EnableCompanyBatch = True Then
		
		// Email as attachments to one email
		
		ValidCheck = True;
		For Each Company In CompanyGroupList Do
			If Company.EmailTo = "" Then
				ValidCheck = False;
			EndIf;
		EndDo;	
		
		If ValidCheck = True Then
			
			For Each Company In CompanyGroupList Do
				
				Send = New InternetMailMessage;
				
				EAddresses = StringFunctionsClientServer.SplitStringIntoSubstringArray(Company.EmailTo, ",");
				For Each EmailAddress in EAddresses Do
					Send.To.Add(EmailAddress);
				EndDo;

				If Company.CCTo <> "" Then
					EAddresses = StringFunctionsClientServer.SplitStringIntoSubstringArray(Company.CCTo, ",");
					For Each EmailAddress in EAddresses Do
						Send.CC.Add(EmailAddress);
					EndDo;
				Endif;

				Send.From.Address = Constants.Email.Get();
				Send.From.DisplayName = Constants.SystemTitle.Get();
				Send.Subject = Company.Subject;
				     
				  
				FormatHTML = Documents.SalesInvoice.GetTemplate("HTMLTest").GetText();
				FormatHTML = StrReplace(FormatHTML,"object.company",Constants.SystemTitle.Get());
	  			   
				
				FormatHTML = StrReplace(FormatHTML,"Total: $object.balance","");
				FormatHTML = StrReplace(FormatHTML,"Due: object.duedate","");
				FormatHTML = StrReplace(FormatHTML,"<td align=""center"" valign=""middle"" class=""mcnButtonContent"" style=""font-family: Tahoma, Verdana, Segoe, sans-serif;font-size: 16px;padding: 15px;mso-table-lspace: 0pt;mso-table-rspace: 0pt;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;"">", "<td> ");
				FormatHTML = StrReplace(FormatHTML,"<a class=""mcnButton "" title=""Pay Invoice"" href=""payHTML"" target=""_self"" style=""font-weight: normal;letter-spacing: 1px;line-height: 100%;text-align: center;text-decoration: none;color: #FFFFFF;word-wrap: break-word;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;display: block;"">Pay Invoice</a>"," ");

				FormatHTML = StrReplace(FormatHTML,"Invoice # object.number","Invoices from " + Constants.SystemTitle.Get());

				// Email Body
				BodyWithBreaks = StrReplace(Company.Body,Chars.LF, "<br>");
				FormatHTML = StrReplace(FormatHTML,"object.note",BodyWithBreaks);
				   
					
				   
				Send.Texts.Add(FormatHTML,InternetMailTextType.HTML);
					
				For Each Document In DocumentSelectedList Do
				
					If Document.Company = Company.Company Then
						
						SD = New SpreadsheetDocument;

						Documents.SalesInvoice.Print(SD, "", Document.Document.Ref);
						
						FolderName = StrReplace(GetTempFileName(), ".tmp", "");
						CreateDirectory(FolderName);
						FileName = FolderName + "\" + Document.Document.Metadata().Synonym + " " + Document.Document.Number + " " + Format(Document.Document.Date, "DF=MM-dd-yyyy") + ".pdf";

						SD.Write(FileName, SpreadsheetDocumentFileType.PDF);

						Send.Attachments.Add(FileName, String(Document.Document.Ref));
						
					EndIf;
					
					RecordSet = InformationRegisters.DocumentLastEmail.CreateRecordSet();	
					RecordSet.Filter.Document.Set(Document.Document);


					NewRecordItem = RecordSet.Add();
					NewRecordItem.Document = Document.Document; 
					NewRecordItem.Date = CurrentSessionDate();
					NewRecordItem.RecipientEmail = EmailTo;

					RecordSet.Write()

				EndDo;
				

				Posta = New InternetMail; 
				Posta.Logon(MailProfil); 
				Posta.Send(send); 
				Posta.Logoff();
				
			EndDo;
		Else
			Message("An email field has not been filled for a company.");
		EndIf;
	Else
		
		// Email each individually
		
		ValidCheck = True;
		For Each Document In DocumentSelectedList Do
			If Document.EmailTo = "" Then
				ValidCheck = False;
			EndIf;
		EndDo;	
		
		If ValidCheck = True Then
			
			For Each Document In DocumentSelectedList Do
				
				CurObject = Document.Document.GetObject();

				If TypeOf(CurObject) = Type("DocumentObject.SalesInvoice") AND CurObject.PayHTML = "" Then
					
					//Find if sales invoice was already sent to be paid
					
					HeadersMap = New Map();	
					
					HTTPRequest = New HTTPRequest("", HeadersMap);
					
					SSLConnection = New OpenSSLSecureConnection();
					FindExistingInvoice = SessionParameters.TenantValue + " Invoice " + CurObject.Number + " from " + Format(CurObject.Date,"DLF=D");
					HTTPConnection = New HTTPConnection("api.mongolab.com/api/1/clusters/rs-ds039921/databases/dataset1cproduction/collections/pay?q={""data_description"": '" + FindExistingInvoice + "'}&apiKey=" + ServiceParameters.MongoAPIKey(),,,,,,SSLConnection);
					Result = HTTPConnection.Get(HTTPRequest);
					ResponseBody = Result.GetBodyAsString(TextEncoding.UTF8);
					ReformatedResponse = StrReplace(ResponseBody,"$","");
					ParsedJSON = InternetConnectionClientServer.DecodeJSON(ReformatedResponse);
					
					If (ParsedJSON.Count() > 0 AND Result.StatusCode <> 400) Then
						
						InvoiceToReplace = ParsedJSON[0]._id.oid;
						HeadersMap = New Map();			
						HTTPRequest = New HTTPRequest("", HeadersMap);	
						SSLConnection = New OpenSSLSecureConnection();
						HTTPConnection = New HTTPConnection("api.mongolab.com/api/1/clusters/rs-ds039921/databases/dataset1cproduction/collections/pay/" + InvoiceToReplace + "?apiKey=" + ServiceParameters.MongoAPIKey(),,,,,,SSLConnection);
						Result = HTTPConnection.Delete(HTTPRequest);
						ResponseBody = Result.GetBodyAsString(TextEncoding.UTF8);
						ReformatedResponse = StrReplace(ResponseBody,"$","");
						ParsedJSON = InternetConnectionClientServer.DecodeJSON(ReformatedResponse);
						
					EndIf;
					
					//Create invoice entry in Pay
					HeadersMap = New Map();
					HeadersMap.Insert("Content-Type", "application/json");
					
					HTTPRequest = New HTTPRequest("/api/1/clusters/rs-ds039921/databases/dataset1cproduction/collections/pay?apiKey=" + ServiceParameters.MongoAPIKey(), HeadersMap);
					
					RequestBodyMap = New Map();
					
					SymbolString = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"; //62
					RandomString20 = "";
					RNG = New RandomNumberGenerator;	
					For i = 0 to 19 Do
						RN = RNG.RandomNumber(1, 62);
						RandomString20 = RandomString20 + Mid(SymbolString,RN,1);
					EndDo;
											 
					RequestBodyMap.Insert("token",RandomString20);
					RequestBodyMap.Insert("type","invoice");
					RequestBodyMap.Insert("data_key",Constants.publishable_temp.get());
					
					//Balance Query
					Query = New Query;
					Query.Text = "SELECT
								 |	ISNULL(GeneralJournalBalance.AmountBalance, 0) AS Balance,
								 |	ISNULL(GeneralJournalBalance.AmountRCBalance, 0) AS BalanceRC
								 |FROM
								 |	Document.SalesInvoice AS DocumentSalesInvoice
								 |		LEFT JOIN AccountingRegister.GeneralJournal.Balance(, , , ExtDimension2 REFS Document.SalesInvoice) AS GeneralJournalBalance
								 |		ON (GeneralJournalBalance.Account = DocumentSalesInvoice.ARAccount)
								 |			AND (GeneralJournalBalance.ExtDimension1 = DocumentSalesInvoice.Company)
								 |			AND (GeneralJournalBalance.ExtDimension2 = DocumentSalesInvoice.Ref)
								 |WHERE
								 |	DocumentSalesInvoice.Ref = &SalesInvoice";
					Query.SetParameter("SalesInvoice", CurObject.Ref);
					
					QueryResult = Query.Execute().Unload();
					
					RequestBodyMap.Insert("data_amount",QueryResult[0].BalanceRC * 100);
					RequestBodyMap.Insert("data_name",Constants.SystemTitle.Get());
					RequestBodyMap.Insert("data_description",SessionParameters.TenantValue + " Invoice " + CurObject.Number + " from " + Format(CurObject.Date,"DLF=D"));
					RequestBodyMap.Insert("live_secret",Constants.secret_temp.Get());
					RequestBodyMap.Insert("paid","false");
					RequestBodyMap.Insert("api_code",String(CurObject.Ref.UUID()));
						
					RequestBodyString = InternetConnectionClientServer.EncodeJSON(RequestBodyMap);
					
					HTTPRequest.SetBodyFromString(RequestBodyString,TextEncoding.ANSI); // ,TextEncoding.ANSI
					
					SSLConnection = New OpenSSLSecureConnection();
					
					HTTPConnection = New HTTPConnection("api.mongolab.com",,,,,,SSLConnection);
					Result = HTTPConnection.Post(HTTPRequest);      
					
					CurObject.PayHTML = "https://pay.accountingsuite.com/invoice?token=" + RandomString20;
					
					HeadersMap = New Map();
					HeadersMap.Insert("Content-Type", "application/json");
							
				EndIf;				
				
				Send = New InternetMailMessage;
				
				EAddresses = StringFunctionsClientServer.SplitStringIntoSubstringArray(Document.EmailTo, ",");
				For Each EmailAddress in EAddresses Do
					Send.To.Add(EmailAddress);
				EndDo;

				If Document.CCTo <> "" Then
					EAddresses = StringFunctionsClientServer.SplitStringIntoSubstringArray(Document.CCTo, ",");
					For Each EmailAddress in EAddresses Do
						Send.CC.Add(EmailAddress);
					EndDo;
				Endif;

				Send.From.Address = Constants.Email.Get();
				Send.From.DisplayName = Constants.SystemTitle.Get();
				Send.Subject = Document.Subject;
				     
				  
				FormatHTML = Documents.SalesInvoice.GetTemplate("HTMLTest").GetText();
				
		  		If TypeOf(CurObject) = Type("DocumentObject.SalesInvoice") Then
			  
			 		FormatHTML = StrReplace(FormatHTML,"object.terms",CurObject.Terms);
				
				
					If Constants.secret_temp.Get() = "" Then
					  FormatHTML = StrReplace(FormatHTML,"<td align=""center"" valign=""middle"" class=""mcnButtonContent"" style=""font-family: Tahoma, Verdana, Segoe, sans-serif;font-size: 16px;padding: 15px;mso-table-lspace: 0pt;mso-table-rspace: 0pt;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;"">", "<td> ");
					  FormatHTML = StrReplace(FormatHTML,"<a class=""mcnButton "" title=""Pay Invoice"" href=""payHTML"" target=""_self"" style=""font-weight: normal;letter-spacing: 1px;line-height: 100%;text-align: center;text-decoration: none;color: #FFFFFF;word-wrap: break-word;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;display: block;"">Pay Invoice</a>"," ");
					Endif;			
					
					If CurObject.PayHTML = "" Then
					FormatHTML = StrReplace(FormatHTML,"<td align=""center"" valign=""middle"" class=""mcnButtonContent"" style=""font-family: Tahoma, Verdana, Segoe, sans-serif;font-size: 16px;padding: 15px;mso-table-lspace: 0pt;mso-table-rspace: 0pt;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;""><a class=""mcnButton "" title=""Pay Invoice"" href=""payHTML"" target=""_self"" style=""font-weight: normal;letter-spacing: 1px;line-height: 100%;text-align: center;text-decoration: none;color: #FFFFFF;word-wrap: break-word;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;display: block;"">Pay Invoice</a></td>", " ");
					Else
					FormatHTML = StrReplace(FormatHTML,"payHTML",CurObject.PayHTML);
					Endif;
					
					
					FormatHTML = StrReplace(FormatHTML,"object.refnum",CurObject.RefNum);
					FormatHTML = StrReplace(FormatHTML,"object.date",Format(CurObject.Date,"DLF=D"));
					FormatHTML = StrReplace(FormatHTML,"object.duedate",Format(CurObject.DueDate,"DLF=D"));
					FormatHTML = StrReplace(FormatHTML,"object.number",CurObject.Number);
					
					FormatHTML = StrReplace(FormatHTML,"object.company",CurObject.Company);
				 
					FormatHTML = StrReplace(FormatHTML,"object.total",Format(CurObject.DocumentTotalRC,"NFD=2"));
					   
					   
					Query = New Query();
					Query.Text =
					"SELECT
					|	SalesInvoice.Ref,
					|	SalesInvoice.DocumentTotal,
					|	SalesInvoice.SalesTax,
					|	SalesInvoice.LineItems.(
					|		Product,
					//|		Product.UM AS UM,
					|		ProductDescription,
					|		LineItems.Order.RefNum AS PO,
					|		QtyUnits,
					|		PriceUnits,
					|		LineTotal,
					|		Project
					|	),
					|	GeneralJournalBalance.AmountRCBalance AS Balance
					|FROM
					|	Document.SalesInvoice AS SalesInvoice
					|		LEFT JOIN AccountingRegister.GeneralJournal.Balance AS GeneralJournalBalance
					|		ON GeneralJournalBalance.ExtDimension1 = SalesInvoice.Company
					|			AND GeneralJournalBalance.ExtDimension2 = SalesInvoice.Ref
					|WHERE
					|	SalesInvoice.Ref IN(&Ref)";

					Query.SetParameter("Ref", CurObject.Ref);
					Selection = Query.Execute().Select();
				
				  	While Selection.Next() Do 	
				 		
					  objectBalance = 0;
					  If NOT Selection.Balance = NULL Then
							objectBalance = Selection.Balance;
					  Else
							objectBalance = 0;
					  EndIf;
					
				  	EndDo;	
						
				  	FormatHTML = StrReplace(FormatHTML,"object.balance",Format(objectBalance,"NFD = 2"));
					
					//Update Currency Symbol
					FormatHTML = StrReplace(FormatHTML,"$",CurObject.Ref.Currency.Symbol);
					
				EndIf;

				// Email Body
				BodyWithBreaks = StrReplace(Document.Body,Chars.LF, "<br>");
				FormatHTML = StrReplace(FormatHTML,"object.note",BodyWithBreaks);				
				   
				Send.Texts.Add(FormatHTML,InternetMailTextType.HTML);
					
						
				SD = New SpreadsheetDocument;

				If TypeOf(CurObject) = Type("DocumentObject.SalesInvoice") Then
				  Documents.SalesInvoice.Print(SD, "", CurObject.Ref);
				EndIf;
			  
			    FolderName = StrReplace(GetTempFileName(), ".tmp", "");
			    CreateDirectory(FolderName);
				FileName = FolderName + "\" + Document.Document.Metadata().Synonym + " " + Document.Document.Number + " " + Format(Document.Document.Date, "DF=MM-dd-yyyy") + ".pdf";

				SD.Write(FileName, SpreadsheetDocumentFileType.PDF);
				
				Send.Attachments.Add(FileName, String(Document.Document.Ref));
						
				Posta = New InternetMail; 
				Posta.Logon(MailProfil); 
				Posta.Send(send); 
				Posta.Logoff();
				
				RecordSet = InformationRegisters.DocumentLastEmail.CreateRecordSet();	
				RecordSet.Filter.Document.Set(CurObject.Ref);


			    NewRecordItem = RecordSet.Add();
			    NewRecordItem.Document = CurObject.Ref; 
			    NewRecordItem.Date = CurrentSessionDate();
			    NewRecordItem.RecipientEmail = EmailTo;

			    RecordSet.Write()

				
			EndDo;
			
		Else
			Message("An email field has not been filled for a document");		
		EndIf;

		
	EndIf;
EndIf;

	
EndProcedure


&AtClient
Procedure EnableCompanyBatchOnChange(Item)
	If EnableCompanyBatch = True Then	
		Items.DocumentSelectedList.Enabled = False;
		Items.CompanyGroupList.Enabled = True;
		Items.CompanyGroupList.Visible = True;
	Else
		Items.DocumentSelectedList.Enabled = True;
		Items.CompanyGroupList.Enabled = False;
		Items.CompanyGroupList.Visible = False;
	EndIf;

EndProcedure


&AtClient
Procedure CompanyGroupListOnActivateRow(Item)
	
	If EnableCompanyBatch = True Then
		CurrentData = Items.CompanyGroupList.RowData(Items.CompanyGroupList.CurrentRow);
		CompanyData = New Array();
		CompanyData.Add(CurrentData.EmailTo);
		CompanyData.Add(CurrentData.CCTo);
		CompanyData.Add(CurrentData.Subject);
		CompanyData.Add(CurrentData.Body);
		
		CompanyInvoiceString = "You are sending invoices ";
		DocumentCount = 1;
		For Each Document In DocumentSelectedList Do
			If DocumentCount = DocumentSelectedList.Count() AND DocumentCount > 1 Then
				CompanyInvoiceString = CompanyInvoiceString + " and " + Document.Num + " ";
			Else
				CompanyInvoiceString = CompanyInvoiceString + "" + Document.Num + ",";
			EndIf;
			DocumentCount = DocumentCount + 1;
		EndDo;
		CompanyInvoiceString = CompanyInvoiceString + "to " + CurrentData.Company;
		CompanyData.Add(CompanyInvoiceString);
		//UpdateFields(CompanyData);
		
		CurrentData = Items.CompanyGroupList.CurrentData;
		
		EmailTo = CurrentData.EmailTo;
		CCTo = CurrentData.CCTo;
		Subject = CurrentData.Subject;
		Body = CurrentData.Body;

		If EnableCompanyBatch = False Then
			PrepareLabel = "Preparing Invoice " + CurrentData.Num;
		Else
			PrepareCompanyLabel = CompanyInvoiceString;
		EndIf;


	EndIf;

EndProcedure


&AtClient
Procedure EmailToOnChange(Item)
	
	If EnableCompanyBatch = True Then		
		CompanyInfo = Items.CompanyGroupList.CurrentData;
		CompanyInfo.EmailTo = EmailTo;	
	Else
		DocumentInfo = Items.DocumentSelectedList.CurrentData;
		DocumentInfo.EmailTo = EmailTo;		
	EndIf;
	
EndProcedure


&AtClient
Procedure CCToOnChange(Item)
	
	If EnableCompanyBatch = True Then		
		CompanyInfo = Items.CompanyGroupList.CurrentData;
		CompanyInfo.CCTo = CCTo;	
	Else
		DocumentInfo = Items.DocumentSelectedList.CurrentData;
		DocumentInfo.CCTo = CCTo;		
	EndIf;

EndProcedure


&AtClient
Procedure SubjectOnChange(Item)
	
	If EnableCompanyBatch = True Then		
		CompanyInfo = Items.CompanyGroupList.CurrentData;
		CompanyInfo.Subject = Subject;	
	Else
		DocumentInfo = Items.DocumentSelectedList.CurrentData;
		DocumentInfo.Subject = Subject;		
	EndIf;

EndProcedure


&AtClient
Procedure BodyOnChange(Item)
	
	If EnableCompanyBatch = True Then		
		CompanyInfo = Items.CompanyGroupList.CurrentData;
		CompanyInfo.Body = Body;	
	Else
		DocumentInfo = Items.DocumentSelectedList.CurrentData;
		DocumentInfo.Body = Body;		
	EndIf;

EndProcedure


&AtClient
Procedure Choice1(Command)
	items.Group5.CurrentPage = items.IndividualEmail;
EndProcedure


&AtClient
Procedure Choice2(Command)
	items.Group5.CurrentPage = items.GroupEmail;
	EnableCompanyBatch = True;
EndProcedure


&AtClient
Procedure Back(Command)
	items.Group5.CurrentPage = items.ChoicePage;
	EnableCompanyBatch = False;
EndProcedure

&AtServer
Function CheckAllEmail(EmailString)
	If EmailString = "" Then
	Else
		// Remove spaces from string
		EmailString = StrReplace(EmailString," ","");
		Emails = StringFunctionsClientServer.SplitStringIntoSubstringArray(EmailString);
		If Emails.count() > 1 Then
			For Each Email In Emails Do
				If  NOT GeneralFunctions.EmailCheck(Email) Then
					Return False;
					Break;
				EndIf;
			EndDo;
		Else
			If NOT GeneralFunctions.EmailCheck(Emails[0]) Then
				Return False;	
			EndIf;
		EndIf;
	EndIf;
	
	Return True;
EndFunction


