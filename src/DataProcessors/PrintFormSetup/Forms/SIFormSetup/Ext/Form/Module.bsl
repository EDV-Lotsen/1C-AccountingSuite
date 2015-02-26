
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	//BinaryLogo = GeneralFunctions.GetLogo();
	//TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	//ImageAddress = TempStorageAddress;
	//Items.image.PictureSize = PictureSize.AutoSize;
	
	BinaryLogo = GeneralFunctions.GetFooter1();
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	FooterImageAddr1 = TempStorageAddress;
	Items.FooterImageAddr1.PictureSize = PictureSize.AutoSize;
	
	BinaryLogo = GeneralFunctions.GetFooter2();
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	FooterImageAddr2 = TempStorageAddress;
	Items.FooterImageAddr2.PictureSize = PictureSize.AutoSize;

	BinaryLogo = GeneralFunctions.GetFooter3();
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	FooterImageAddr3 = TempStorageAddress;
	Items.FooterImageAddr3.PictureSize = PictureSize.AutoSize;
	
	EndProcedure

&AtClient
Procedure UploadLogo(Command)
	
	Var SelectedName;
	ImageAddress = "";
	
	NotifyDescription = New NotifyDescription("FileUpload",ThisForm);
	BeginPutFile(NotifyDescription,,"",True);
	
	//BinaryLogo = GeneralFunctions.GetLogo();
	//TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	//ImageAddress = TempStorageAddress;
	
EndProcedure

&AtClient
Procedure FileUpload(a,b,c,d) Export
	
	PlaceImageFile(b);
	
EndProcedure

&AtServer
Procedure PlaceImageFile(TempStorageName)
	
	If NOT TempStorageName = Undefined Then
	
		BinaryData = GetFromTempStorage(TempStorageName);
		
		///
		
		HeadersMap = New Map();
		HeadersMap.Insert("Authorization", "Client-ID " + ServiceParameters.ImgurClientID());
		
		HTTPRequest = New HTTPRequest("/3/image", HeadersMap);
		HTTPRequest.SetBodyFromBinaryData(BinaryData);
		
		SSLConnection = New OpenSSLSecureConnection();
		
		HTTPConnection = New HTTPConnection("api.imgur.com",,,,,,SSLConnection); //imgur-apiv3.p.mashape.com
		Result = HTTPConnection.Post(HTTPRequest);
		ResponseBody = Result.GetBodyAsString(TextEncoding.UTF8);
		ResponseJSON = InternetConnectionClientServer.DecodeJSON(ResponseBody);
		image_url = ResponseJSON.data.link;
		// Ctrl + _
		ConstantsSet.logoURL = image_url;
		
	    ///
		
		NewRow = InformationRegisters.CustomPrintForms.CreateRecordManager();
		NewRow.ObjectName = "logo";
		NewRow.TemplateName = "logo";
		NewRow.Template = New ValueStorage(BinaryData, New Deflation(9));
		NewRow.Write();	
		DeleteFromTempStorage(TempStorageName);
		
	EndIf;
	
	BinaryLogo = GeneralFunctions.GetLogo();
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	ImageAddress = TempStorageAddress;
  	
EndProcedure

&AtClient
Procedure UploadFooter1(Command) Export

	Var SelectedName;
	FooterImageAddr1 = "";
	
	NotifyDescription = New NotifyDescription("FileUpload1",ThisForm);
	BeginPutFile(NotifyDescription,,"",True);
	
	BinaryLogo = GeneralFunctions.GetFooter1();
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	FooterImageAddr1 = TempStorageAddress;

EndProcedure

&AtClient
Procedure FileUpload1(a,b,c,d) Export
	
	PlaceImageFile1(b);
	
EndProcedure

&AtServer
Procedure PlaceImageFile1(TempStorageName)
	
	If NOT TempStorageName = Undefined Then
	
		BinaryData = GetFromTempStorage(TempStorageName);
				
		NewRow = InformationRegisters.CustomPrintForms.CreateRecordManager();
		NewRow.ObjectName = "footer1";
		NewRow.TemplateName = "footer1";
		NewRow.Template = New ValueStorage(BinaryData, New Deflation(9));
		NewRow.Write();	
		DeleteFromTempStorage(TempStorageName);
		
	EndIf;
	
	//BinaryLogo = GeneralFunctions.GetLogo();
	//TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	//ImageAddress = TempStorageAddress;
  	
EndProcedure

&AtClient
Procedure UploadFooter2(Command) Export
	
	Var SelectedName;
	ImageAddress = "";
	
	NotifyDescription = New NotifyDescription("FileUpload2",ThisForm);
	BeginPutFile(NotifyDescription,,"",True);
	
	//BinaryLogo = GeneralFunctions.GetLogo();
	//TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	//ImageAddress = TempStorageAddress;
	
EndProcedure

&AtClient
Procedure FileUpload2(a,b,c,d) Export
	
	PlaceImageFile2(b);
	
EndProcedure

&AtServer
Procedure PlaceImageFile2(TempStorageName)
	
	If NOT TempStorageName = Undefined Then
	
		BinaryData = GetFromTempStorage(TempStorageName);
				
		NewRow = InformationRegisters.CustomPrintForms.CreateRecordManager();
		NewRow.ObjectName = "footer2";
		NewRow.TemplateName = "footer2";
		NewRow.Template = New ValueStorage(BinaryData, New Deflation(9));
		NewRow.Write();	
		DeleteFromTempStorage(TempStorageName);
		
	EndIf;
	
	//BinaryLogo = GeneralFunctions.GetLogo();
	//TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	//ImageAddress = TempStorageAddress;
  	
EndProcedure


&AtClient
Procedure UploadFooter3(Command) Export

	Var SelectedName;
	ImageAddress = "";
	
	NotifyDescription = New NotifyDescription("FileUpload3",ThisForm);
	BeginPutFile(NotifyDescription,,"",True);
	
	//BinaryLogo = GeneralFunctions.GetLogo();
	//TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	//ImageAddress = TempStorageAddress;

EndProcedure

&AtClient
Procedure FileUpload3(a,b,c,d) Export
	
	PlaceImageFile3(b);
	
EndProcedure

&AtServer
Procedure PlaceImageFile3(TempStorageName)
	
	If NOT TempStorageName = Undefined Then
	
		BinaryData = GetFromTempStorage(TempStorageName);
				
		NewRow = InformationRegisters.CustomPrintForms.CreateRecordManager();
		NewRow.ObjectName = "footer3";
		NewRow.TemplateName = "footer3";
		NewRow.Template = New ValueStorage(BinaryData, New Deflation(9));
		NewRow.Write();	
		DeleteFromTempStorage(TempStorageName);
		
	EndIf;
	  	
EndProcedure

&AtClient
Procedure SIShowSVCOnChange(Item)
	If ConstantsSet.SIShowSVCCol Then 
		ConstantsSet.SIShowClassCol    = False;
		ConstantsSet.SIShowDiscountCol = False;
	EndIf;;
EndProcedure

&AtClient
Procedure SIShowClassColOnChange(Item)
	If ConstantsSet.SIShowClassCol Then 
		ConstantsSet.SIShowSVCCol      = False;
		ConstantsSet.SIShowDiscountCol = False;
	EndIf;
EndProcedure

&AtClient
Procedure SIShowDiscountColOnChange(Item)
	If ConstantsSet.SIShowDiscountCol Then 
		ConstantsSet.SIShowClassCol = False;
		ConstantsSet.SIShowSVCCol   = False;
	EndIf;
EndProcedure
