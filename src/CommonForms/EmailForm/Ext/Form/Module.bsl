
&AtClient
Procedure Send(Command)
	SendAtServer();
	RefreshInterface();
	ThisForm.Close();
EndProcedure

&AtServer
Procedure SendAtServer()

CurObject = DocumentRef.GetObject();
	
	If EmailTo <> "" Then
		If TypeOf(CurObject) = Type("DocumentObject.SalesInvoice") AND CurObject.PayHTML = "" Then
			
			//Find if sales invoice was already sent to be paid
			HeadersMap = New Map();	
			
			HTTPRequest = New HTTPRequest("", HeadersMap);
			
			SSLConnection = New OpenSSLSecureConnection();
			FindExistingInvoice = SessionParameters.TenantValue + " Invoice " + CurObject.Number + " from " + Format(CurObject.Date,"DLF=D");
			HTTPConnection = New HTTPConnection("api.mongolab.com/api/1/databases/dataset1c/collections/pay?q={""data_description"": '" + FindExistingInvoice + "'}&apiKey=" + ServiceParameters.MongoAPIKey(),,,,,,SSLConnection);
			Result = HTTPConnection.Get(HTTPRequest);
			ResponseBody = Result.GetBodyAsString(TextEncoding.UTF8);
			ReformatedResponse = StrReplace(ResponseBody,"$","");
			ParsedJSON = InternetConnectionClientServer.DecodeJSON(ReformatedResponse);
			
			If (ParsedJSON.Count() > 0 AND Result.StatusCode <> 400) Then
				
				InvoiceToReplace = ParsedJSON[0]._id.oid;
				HeadersMap = New Map();			
				HTTPRequest = New HTTPRequest("", HeadersMap);	
				SSLConnection = New OpenSSLSecureConnection();
				HTTPConnection = New HTTPConnection("api.mongolab.com/api/1/databases/dataset1c/collections/pay/" + InvoiceToReplace + "?apiKey=" + ServiceParameters.MongoAPIKey(),,,,,,SSLConnection);
				Result = HTTPConnection.Delete(HTTPRequest);
				ResponseBody = Result.GetBodyAsString(TextEncoding.UTF8);
				ReformatedResponse = StrReplace(ResponseBody,"$","");
				ParsedJSON = InternetConnectionClientServer.DecodeJSON(ReformatedResponse);
				
			EndIf;
			
			//Create invoice entry in Pay
			HeadersMap = New Map();
			HeadersMap.Insert("Content-Type", "application/json");
			
			HTTPRequest = New HTTPRequest("/api/1/databases/dataset1c/collections/pay?apiKey=" + ServiceParameters.MongoAPIKey(), HeadersMap);
			
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
			//ResponseBody = Result.GetBodyAsString(TextEncoding.UTF8);
			// send e-mail					
			FormatHTML = "<a href=""https://pay.accountingsuite.com/invoice?token=" + RandomString20 + """>Pay invoice</a>";
			CurObject.PayHTML = "https://pay.accountingsuite.com/invoice?token=" + RandomString20;
			
			HeadersMap = New Map();
			HeadersMap.Insert("Content-Type", "application/json");
					
		EndIf;		 
	 				 
 	  MailProfil = New InternetMailProfile; 
 	  	   
   	  MailProfil.SMTPServerAddress = ServiceParameters.SMTPServer(); 
 	  MailProfil.SMTPUseSSL = ServiceParameters.SMTPUseSSL();
 	  MailProfil.SMTPPort = 465; 
 	  
 	  MailProfil.Timeout = 180; 
 	  
	  MailProfil.SMTPPassword = ServiceParameters.SendGridPassword();
 	  
	  MailProfil.SMTPUser = ServiceParameters.SendGridUserName();
 	  
 	  
 	  send = New InternetMailMessage; 
	  
	  If EmailTo <> "" Then
		EAddresses = StringFunctionsClientServer.SplitStringIntoSubstringArray(EmailTo, ",");
		For Each EmailAddress in EAddresses Do
			send.To.Add(EmailAddress);
		EndDo;
	  Endif;
	  
	  If CCTo <> "" Then
		EAddresses = StringFunctionsClientServer.SplitStringIntoSubstringArray(CCTo, ",");
		For Each EmailAddress in EAddresses Do
			send.CC.Add(EmailAddress);
		EndDo;
	  Endif;
	
 	  send.From.Address = Constants.Email.Get();
 	  send.From.DisplayName = Constants.SystemTitle.Get();
 	  send.Subject = Subject;
	   	  
	  If TypeOf(CurObject) = Type("DocumentObject.SalesInvoice") Then
		  
		  FormatHTML2 = StrReplace(Documents.SalesInvoice.GetTemplate("HTMLTest").GetText(),"object.terms",CurObject.Terms);
		  
		  If Constants.secret_temp.Get() = "" Then
			  FormatHTML2 = StrReplace(FormatHTML2,"<td align=""center"" valign=""middle"" class=""mcnButtonContent"" style=""font-family: Tahoma, Verdana, Segoe, sans-serif;font-size: 16px;padding: 15px;mso-table-lspace: 0pt;mso-table-rspace: 0pt;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;"">", "<td> ");
			  FormatHTML2 = StrReplace(FormatHTML2,"<a class=""mcnButton "" title=""Pay Invoice"" href=""payHTML"" target=""_self"" style=""font-weight: normal;letter-spacing: 1px;line-height: 100%;text-align: center;text-decoration: none;color: #FFFFFF;word-wrap: break-word;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;display: block;"">Pay Invoice</a>"," ");
		  Endif;

			If CurObject.PayHTML = "" Then
				FormatHTML2 = StrReplace(FormatHTML2,"<td align=""center"" valign=""middle"" class=""mcnButtonContent"" style=""font-family: Tahoma, Verdana, Segoe, sans-serif;font-size: 16px;padding: 15px;mso-table-lspace: 0pt;mso-table-rspace: 0pt;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;""><a class=""mcnButton "" title=""Pay Invoice"" href=""payHTML"" target=""_self"" style=""font-weight: normal;letter-spacing: 1px;line-height: 100%;text-align: center;text-decoration: none;color: #FFFFFF;word-wrap: break-word;-ms-text-size-adjust: 100%;-webkit-text-size-adjust: 100%;display: block;"">Pay Invoice</a></td>", " ");
			Else
				FormatHTML2 = StrReplace(FormatHTML2,"payHTML",CurObject.PayHTML);
			Endif;
			FormatHTML2 = StrReplace(FormatHTML2,"object.refnum",CurObject.RefNum);
			FormatHTML2 = StrReplace(FormatHTML2,"object.date",Format(CurObject.Date,"DLF=D"));
			FormatHTML2 = StrReplace(FormatHTML2,"object.duedate",Format(CurObject.DueDate,"DLF=D"));
			FormatHTML2 = StrReplace(FormatHTML2,"object.number",CurObject.Number);
			
			FormatHTML2 = StrReplace(FormatHTML2,"object.company",CurObject.Company);
		 
			FormatHTML2 = StrReplace(FormatHTML2,"object.total",Format(CurObject.DocumentTotalRC,"NFD=2"));
			   
			   
			Query = New Query();
			Query.Text =
			"SELECT
			|	SalesInvoice.Ref,
			|	SalesInvoice.DocumentTotal,
			|	SalesInvoice.SalesTax,
			|	SalesInvoice.LineItems.(
			|		Product,
			|		Product.UM AS UM,
			|		ProductDescription,
			|		LineItems.Order.RefNum AS PO,
			|		Quantity,
			|		Price,
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
				
		  FormatHTML2 = StrReplace(FormatHTML2,"object.balance",Format(objectBalance,"NFD = 2"));
		  
	  Elsif TypeOf(CurObject) = Type("DocumentObject.SalesOrder") Then
		  
		  FormatHTML2 = StrReplace(Documents.SalesOrder.GetTemplate("HTMLTest").GetText(),"object.terms",CurObject.Terms);
		  FormatHTML2 = StrReplace(FormatHTML2,"object.number",CurObject.Number);
		  FormatHTML2 = StrReplace(FormatHTML2,"object.date",Format(CurObject.Date,"DLF=D"));
		  FormatHTML2 = StrReplace(FormatHTML2,"object.company",CurObject.Company);
		  FormatHTML2 = StrReplace(FormatHTML2,"object.total",Format(CurObject.DocumentTotal,"NFD=2"));
		  
	  Elsif TypeOf(CurObject) = Type("DocumentObject.Quote") Then
		  
		  FormatHTML2 = StrReplace(Documents.Quote.GetTemplate("QuoteEmailHTML").GetText(),"object.terms",CurObject.Terms);
		  FormatHTML2 = StrReplace(FormatHTML2,"object.number",CurObject.Number);
		  FormatHTML2 = StrReplace(FormatHTML2,"object.date",Format(CurObject.Date,"DLF=D"));
		  FormatHTML2 = StrReplace(FormatHTML2,"object.company",CurObject.Company);
		  FormatHTML2 = StrReplace(FormatHTML2,"object.total",Format(CurObject.DocumentTotal,"NFD=2"));
		  
	  Elsif TypeOf(CurObject) = Type("DocumentObject.CashReceipt") Then
		  
		  FormatHTML2 = StrReplace(Documents.CashReceipt.GetTemplate("HTMLTest").GetText(),"object.terms","");//,"object.terms",CurObject.Terms);
		  FormatHTML2 = StrReplace(FormatHTML2,"object.number",CurObject.Number);
		  FormatHTML2 = StrReplace(FormatHTML2,"object.date",Format(CurObject.Date,"DLF=D"));
		  FormatHTML2 = StrReplace(FormatHTML2,"object.company",CurObject.Company);
		  FormatHTML2 = StrReplace(FormatHTML2,"object.total",Format(CurObject.CashPayment,"NFD=2"));
		  
	  Elsif TypeOf(CurObject) = Type("DocumentObject.PurchaseOrder") Then
		  
		  FormatHTML2 = StrReplace(Documents.PurchaseOrder.GetTemplate("HTMLTest").GetText(),"object.terms","");
		  FormatHTML2 = StrReplace(FormatHTML2,"object.number",CurObject.Number);
		  FormatHTML2 = StrReplace(FormatHTML2,"object.date",Format(CurObject.Date,"DLF=D"));
		  FormatHTML2 = StrReplace(FormatHTML2,"object.company",CurObject.Company);
		  FormatHTML2 = StrReplace(FormatHTML2,"object.total",Format(CurObject.DocumentTotal,"NFD=2"));
	  else
		  
		  
	  EndIf;
		  
	  //Update Currency Symbol
	  FormatHTML2 = StrReplace(FormatHTML2,"$",CurObject.Ref.Currency.Symbol);
	  
	  //Email Body
	  FormatHTML2 = StrReplace(FormatHTML2,"object.note",Body);
	 	  
			
	 	  
	 	  send.Texts.Add(FormatHTML2,InternetMailTextType.HTML);
			
		  SD = New SpreadsheetDocument;
		  FileName = GetTempFileName(".PDF");
		  
		  If TypeOf(CurObject) = Type("DocumentObject.SalesInvoice") Then
		  	Documents.SalesInvoice.Print(SD, "", CurObject.Ref);
		  Elsif TypeOf(CurObject) = Type("DocumentObject.CashReceipt") Then
			Documents.CashReceipt.Print(SD, "", CurObject.Ref);
		  Elsif TypeOf(CurObject) = Type("DocumentObject.SalesOrder") Then
			Documents.SalesOrder.Print(SD, "", CurObject.Ref);
		  Elsif TypeOf(CurObject) = Type("DocumentObject.Quote") Then
			Documents.Quote.Print(SD, "", CurObject.Ref);
		  Elsif TypeOf(CurObject) = Type("DocumentObject.PurchaseOrder") Then
			Documents.PurchaseOrder.Print(SD, "", CurObject.Ref);
		  Else
		  EndIf;
		  
		  SD.Write(FileName, SpreadsheetDocumentFileType.PDF);
		  
		  Send.Attachments.Add(FileName, String(CurObject.Ref));
	  
		  
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

	  Else
		  Message("The recipient email has not been specified");
	  Endif;

EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
		
	DocumentRef = Parameters.Ref;
	DocObject = DocumentRef.GetObject();
	DocumentType = "";
	SD = New SpreadsheetDocument;
	
	//Switch display between document types
	If TypeOf(DocObject) = Type("DocumentObject.SalesInvoice") Then
		Body = DocObject.EmailNote;
		DocumentType = "Invoice";
		Documents.SalesInvoice.Print(SD, "", Parameters.Ref);
	Elsif TypeOf(DocObject) = Type("DocumentObject.CashReceipt") Then
		DocumentType = "Cash Receipt";
		Items.Decoration1.Title = "Cash Receipt";
		Body = DocObject.EmailNote;
		Documents.CashReceipt.Print(SD, "", Parameters.Ref);	
	Elsif TypeOf(DocObject) = Type("DocumentObject.SalesOrder") Then
		DocumentType = "Sales Order";
		Items.Decoration1.Title = "Sales Order";
		//Body = DocObject.EmailNote;
		Documents.SalesOrder.Print(SD, "", Parameters.Ref);
	Elsif TypeOf(DocObject) = Type("DocumentObject.Quote") Then
		DocumentType = "Quote";
		Items.Decoration1.Title = "Quote";
		Body = DocObject.EmailNote;
		Documents.Quote.Print(SD, "", Parameters.Ref);
	Elsif TypeOf(DocObject) = Type("DocumentObject.PurchaseOrder") Then
		DocumentType = "Purchase Order";
		Items.Decoration1.Title = "Purchase Order";
		Body = DocObject.EmailNote;
		Documents.PurchaseOrder.Print(SD, "", Parameters.Ref);
	EndIf;
		
	If Parameters.Ref.Company <> Catalogs.Companies.EmptyRef() Then
		If TypeOf(DocObject) = Type("DocumentObject.SalesInvoice") OR TypeOf(DocObject) = Type("DocumentObject.SalesOrder")  
				OR TypeOf(DocObject) = Type("DocumentObject.Quote") Then
			ConfirmToEmail 	= CommonUse.GetAttributeValue(Parameters.Ref.ConfirmTo, "Email");
			ShipToEmail		= CommonUse.GetAttributeValue(Parameters.Ref.ShipTo, "Email");	
			EmailTo = ?(ValueIsFilled(Parameters.Ref.ConfirmTo), ConfirmToEmail, ShipToEmail);
		ElsIf TypeOf(DocObject) = Type("DocumentObject.CashReceipt") Then
			QueryAddr = New Query();
			   QueryAddr.Text =
			   "SELECT
			   |	Addresses.Email
			   |FROM
			   |	Catalog.Addresses AS Addresses
			   |WHERE
			   |	Addresses.Owner = &Owner
			   |	AND Addresses.DefaultBilling = &DefaultBilling";
			   QueryAddr.SetParameter("Owner", Parameters.Ref.Company);
			   QueryAddr.SetParameter("DefaultBilling", True);
			   SelectionAddr = QueryAddr.Execute().Unload();
			EmailTo = SelectionAddr[0].Email;
		ElsIf TypeOf(DocObject) = Type("DocumentObject.PurchaseOrder") Then
			EmailTo = CommonUse.GetAttributeValue(Parameters.Ref.CompanyAddress, "Email");	
		EndIf;
	
	EndIf;
	
	If TypeOf(DocObject) = Type("DocumentObject.CashReceipt") Then
		Subject = Constants.SystemTitle.Get() + " - " + DocumentType + " " + Parameters.Ref.Number + " from " + Format(Parameters.Ref.Date,"DLF=D") + " - $" + Format(Parameters.Ref.CashPayment,"NFD=2");
	Else
		Subject = Constants.SystemTitle.Get() + " - " + DocumentType + " " + Parameters.Ref.Number + " from " + Format(Parameters.Ref.Date,"DLF=D") + " - $" + Format(Parameters.Ref.DocumentTotalRC,"NFD=2");
	EndIf;
	
	FileName = GetTempFileName(".PDF");	
	SD.Write(FileName, SpreadsheetDocumentFileType.PDF);
	PreviewDisplay = SD;
	
	Query = New Query();
	Query.Text = "SELECT
	             |	DocumentLastEmail.Date,
	             |	DocumentLastEmail.RecipientEmail
	             |FROM
	             |	InformationRegister.DocumentLastEmail AS DocumentLastEmail
	             |WHERE
	             |	DocumentLastEmail.Document = &Ref";
	Query.SetParameter("Ref",Parameters.Ref);
	Selection = Query.Execute().Unload();
	If Selection.Count() <> 0 Then
		LastEmail = "Last email on " + Selection[0].Date + " to " + Selection[0].RecipientEmail;
	EndIf;
	
EndProcedure
