&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	BinaryLogo = GeneralFunctions.GetFooterPO("CMfooter1");
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	CMFooterImageAddr1 = TempStorageAddress;
	Items.CMFooterImageAddr1.PictureSize = PictureSize.AutoSize;
	
	BinaryLogo = GeneralFunctions.GetFooterPO("CMfooter2");
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	CMFooterImageAddr2 = TempStorageAddress;
	Items.CMFooterImageAddr2.PictureSize = PictureSize.AutoSize;

	BinaryLogo = GeneralFunctions.GetFooterPO("CMfooter3");
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	CMFooterImageAddr3 = TempStorageAddress;
	Items.CMFooterImageAddr3.PictureSize = PictureSize.AutoSize;

EndProcedure

&AtClient
Procedure CMUploadFooter1(Command)
	
	Var SelectedName;
	CMFooterImageAddr1 = "";
	
	NotifyDescription = New NotifyDescription("FileUploadCM1",ThisForm);
	BeginPutFile(NotifyDescription,,"",True);
	
	BinaryLogo = GeneralFunctions.GetFooterPO("CMfooter1");
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	CMFooterImageAddr1 = TempStorageAddress;
	
EndProcedure

&AtClient
Procedure FileUploadCM1(a,b,c,d) Export
	
	PlaceImageFilePO(b,"CMfooter1");
	
EndProcedure

&AtClient
Procedure CMUploadFooter2(Command)
	Var SelectedName;
	CMFooterImageAddr2 = "";
	
	NotifyDescription = New NotifyDescription("FileUploadCM2",ThisForm);
	BeginPutFile(NotifyDescription,,"",True);
	
	BinaryLogo = GeneralFunctions.GetFooterPO("CMfooter2");
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	CMFooterImageAddr2 = TempStorageAddress;

EndProcedure

&AtClient
Procedure FileUploadCM2(a,b,c,d) Export
	
	PlaceImageFilePO(b,"CMfooter2");
	
EndProcedure

&AtClient
Procedure CMUploadFooter3(Command)
	Var SelectedName;
	CMFooterImageAddr3 = "";
	
	NotifyDescription = New NotifyDescription("FileUploadCM3",ThisForm);
	BeginPutFile(NotifyDescription,,"",True);
	
	BinaryLogo = GeneralFunctions.GetFooterPO("CMfooter3");
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	CMFooterImageAddr3 = TempStorageAddress;

EndProcedure

&AtClient
Procedure FileUploadCM3(a,b,c,d) Export
	
	PlaceImageFilePO(b,"CMfooter3");
	
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