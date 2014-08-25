
&AtClient
Procedure Send(Command)
	SendAtServer();
	RefreshInterface();
	ThisForm.Close();
EndProcedure

&AtServer
Procedure SendAtServer()
	
	JobParameters = New Array;
	JobParameters.Add(DocumentRef);
	JobParameters.Add(EmailTo);
	JobParameters.Add(CCTo);
	JobParameters.Add(Subject);
	BodyWithBreaks = StrReplace(Body,Chars.LF, "<br>");
	JobParameters.Add(BodyWithBreaks);

	BackgroundJobs.Execute("EmailHandling.SendEmail", JobParameters,, "Sending email");

EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	//constants.Email.Set("ajlam88@gmail.com");		
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
		Body = DocObject.EmailNote;
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
	Elsif TypeOf(DocObject) = Type("DocumentObject.SalesReturn") Then
		DocumentType = "Credit Memo";
		Items.Decoration1.Title = "Credit Memo";
		Body = DocObject.EmailNote;
		Documents.SalesReturn.Print(SD, "", Parameters.Ref);
	Elsif TypeOf(DocObject) = Type("DocumentObject.CashSale") Then
		DocumentType = "Cash Sale";
		Items.Decoration1.Title = "Cash Sale";
		Body = DocObject.EmailNote;
		Documents.CashSale.Print(SD, "", Parameters.Ref);
	EndIf;
		
	If Parameters.Ref.Company <> Catalogs.Companies.EmptyRef() Then
		If TypeOf(DocObject) = Type("DocumentObject.SalesInvoice") OR TypeOf(DocObject) = Type("DocumentObject.SalesOrder")  
				OR TypeOf(DocObject) = Type("DocumentObject.Quote") Then
			ConfirmToEmail 	= CommonUse.GetAttributeValue(Parameters.Ref.ConfirmTo, "Email");
			ShipToEmail		= CommonUse.GetAttributeValue(Parameters.Ref.ShipTo, "Email");	
			EmailTo = ?(ValueIsFilled(Parameters.Ref.ConfirmTo), ConfirmToEmail, ShipToEmail);
		ElsIf TypeOf(DocObject) = Type("DocumentObject.CashReceipt") OR TypeOf(DocObject) = Type("DocumentObject.SalesReturn") Then
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
		ElsIf TypeOf(DocObject) = Type("DocumentObject.CashSale") Then
			EmailTo = CommonUse.GetAttributeValue(Parameters.Ref.ShipTo, "Email");
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
