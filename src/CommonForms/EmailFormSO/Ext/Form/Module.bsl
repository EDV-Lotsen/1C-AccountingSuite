
&AtClient
Procedure Send(Command)
	SendAtServer();
	RefreshInterface();
	ThisForm.Close();
EndProcedure

&AtServer
Procedure SendAtServer()
	
	//constants.Email.Set("ajlam88@gmail.com");

CurObject = OrderRef.GetObject();

	If EmailTo <> "" Then	 
		
	 	If constants.logoURL.Get() = "" Then
			 imagelogo = "http://www.accountingsuite.com/images/logo-a.png";
	 	Else
			 imagelogo = Constants.logoURL.Get();  
	 	Endif;
	 				 
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
	  FormatHTML2 = StrReplace(Documents.SalesOrder.GetTemplate("HTMLTest").GetText(),"object.terms",CurObject.Terms);
 	  	
		FormatHTML2 = StrReplace(FormatHTML2,"imagelogo",imagelogo);
		FormatHTML2 = StrReplace(FormatHTML2,"object.refnum",CurObject.RefNum);
		FormatHTML2 = StrReplace(FormatHTML2,"object.date",Format(CurObject.Date,"DLF=D"));
		//FormatHTML2 = StrReplace(FormatHTML2,"object.duedate",Format(CurObject.DueDate,"DLF=D"));
		FormatHTML2 = StrReplace(FormatHTML2,"object.number",CurObject.Number);
		
		FormatHTML2 = StrReplace(FormatHTML2,"object.company",CurObject.Company);
	 
		FormatHTML2 = StrReplace(FormatHTML2,"object.total",Format(CurObject.DocumentTotal,"NFD=2"));
	 
	  //Email Body
	  FormatHTML2 = StrReplace(FormatHTML2,"object.note",Body);
	 	  
			
	 	  
	 	  send.Texts.Add(FormatHTML2,InternetMailTextType.HTML);
			
		  If Constants.attach_pdfso.Get() = True Then
			  SD = New SpreadsheetDocument;
			  FileName = GetTempFileName(".PDF");
			  
			  Documents.SalesOrder.Print(SD, "", CurObject.Ref);
			  SD.Write(FileName, SpreadsheetDocumentFileType.PDF);
			  
			  Send.Attachments.Add(FileName, String(CurObject.Ref));
			EndIf;
	  
		  
		  Posta = New InternetMail; 
	 	  Posta.Logon(MailProfil); 
	 	  Posta.Send(send); 
	 	  Posta.Logoff(); 
		  
		  //Update last email message
		  DocObject = CurObject.ref.GetObject();
		  DocObject.EmailTo = CurObject.EmailTo;
		  //DocObject.LastEmail = "Last email on " + Format(CurrentDate(),"DLF=DT") + " to " + CurObject.EmailTo;	
		  DocObject.LastEmail = Format(CurrentDate(),"DLF=DT");
		  DocObject.Write(DocumentWriteMode.Posting);
		  //LastEmail.Read();
		  Message("Sales Order email has been sent");
	  Else
		  Message("The recipient email has not been specified");
	  Endif;


EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	OrderRef = Parameters.Ref;
	
	If Parameters.Ref.Company <> Catalogs.Companies.EmptyRef() Then	
		ConfirmToEmail 	= CommonUse.GetAttributeValue(Parameters.Ref.ConfirmTo, "Email");
		ShipToEmail		= CommonUse.GetAttributeValue(Parameters.Ref.ShipTo, "Email");	
		EmailTo = ?(ValueIsFilled(Parameters.Ref.ConfirmTo), ConfirmToEmail, ShipToEmail);
	EndIf;
	
	Subject = Constants.SystemTitle.Get() + " - Sales Order " + Parameters.Ref.Number + " from " + Format(Parameters.Ref.Date,"DLF=D") + " - $" + Format(Parameters.Ref.DocumentTotalRC,"NFD=2");

	SD = New SpreadsheetDocument;
	FileName = GetTempFileName(".PDF");

	Documents.SalesOrder.Print(SD, "", Parameters.Ref);
	SD.Write(FileName, SpreadsheetDocumentFileType.PDF);

	PreviewDisplay = SD;
	LastEmail = "Last email on " + OrderRef.LastEmail + " to " + OrderRef.EmailTo;
EndProcedure
