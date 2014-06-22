&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	BinaryLogo = GeneralFunctions.GetFooterPO("POfooter1");
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	POFooterImageAddr1 = TempStorageAddress;
	Items.POFooterImageAddr1.PictureSize = PictureSize.AutoSize;
	
	BinaryLogo = GeneralFunctions.GetFooterPO("POfooter2");
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	POFooterImageAddr2 = TempStorageAddress;
	Items.POFooterImageAddr2.PictureSize = PictureSize.AutoSize;
	
	BinaryLogo = GeneralFunctions.GetFooterPO("POfooter3");
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	POFooterImageAddr3 = TempStorageAddress;
	Items.POFooterImageAddr3.PictureSize = PictureSize.AutoSize;
	
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
Procedure POUploadFooter1(Command)

	Var SelectedName;
	FooterImageAddr1 = "";
	
	NotifyDescription = New NotifyDescription("FileUploadPO1",ThisForm);
	BeginPutFile(NotifyDescription,,"",True);
	
	BinaryLogo = GeneralFunctions.GetFooterPO("POfooter1");
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	POFooterImageAddr1 = TempStorageAddress;
	
EndProcedure

&AtClient
Procedure POUploadFooter2(Command)

	Var SelectedName;
	FooterImageAddr1 = "";
	
	NotifyDescription = New NotifyDescription("FileUploadPO2",ThisForm);
	BeginPutFile(NotifyDescription,,"",True);
	
	BinaryLogo = GeneralFunctions.GetFooterPO("POfooter2");
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	POFooterImageAddr2 = TempStorageAddress;

	
EndProcedure

&AtClient
Procedure POUploadFooter3(Command)

	Var SelectedName;
	FooterImageAddr1 = "";
	
	NotifyDescription = New NotifyDescription("FileUploadPO3",ThisForm);
	BeginPutFile(NotifyDescription,,"",True);
	
	BinaryLogo = GeneralFunctions.GetFooterPO("POfooter3");
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	POFooterImageAddr3 = TempStorageAddress;

	
EndProcedure

&AtClient
Procedure FileUploadPO1(a,b,c,d) Export
	
	PlaceImageFilePO(b,"POfooter1");
	
EndProcedure

&AtClient
Procedure FileUploadPO2(a,b,c,d) Export
	
	PlaceImageFilePO(b,"POfooter2");
	
EndProcedure

&AtClient
Procedure FileUploadPO3(a,b,c,d) Export
	
	PlaceImageFilePO(b,"POfooter3");
	
EndProcedure

&AtServer
Procedure PlaceImageFilePO(TempStorageName,imagename)
	
	If NOT TempStorageName = Undefined Then
	
		BinaryData = GetFromTempStorage(TempStorageName);
				
		NewRow = InformationRegisters.CustomPrintForms.CreateRecordManager();
		NewRow.ObjectName = imagename;
		NewRow.TemplateName = imagename;
		NewRow.Template = New ValueStorage(BinaryData, New Deflation(9));
		NewRow.Write();	
		DeleteFromTempStorage(TempStorageName);
		
	EndIf;
	  	
EndProcedure

