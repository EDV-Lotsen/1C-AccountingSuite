&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	BinaryLogo = GeneralFunctions.GetFooterPO("SOfooter1");
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	SOFooterImageAddr1 = TempStorageAddress;
	Items.SOFooterImageAddr1.PictureSize = PictureSize.AutoSize;
	
	BinaryLogo = GeneralFunctions.GetFooterPO("SOfooter2");
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	SOFooterImageAddr2 = TempStorageAddress;
	Items.SOFooterImageAddr2.PictureSize = PictureSize.AutoSize;

	BinaryLogo = GeneralFunctions.GetFooterPO("SOfooter3");
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	SOFooterImageAddr3 = TempStorageAddress;
	Items.SOFooterImageAddr3.PictureSize = PictureSize.AutoSize;

EndProcedure

&AtClient
Procedure SOUploadFooter1(Command)
	
	Var SelectedName;
	SOFooterImageAddr1 = "";
	
	NotifyDescription = New NotifyDescription("FileUploadSO1",ThisForm);
	BeginPutFile(NotifyDescription,,"",True);
	
	BinaryLogo = GeneralFunctions.GetFooterPO("SOfooter1");
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	SOFooterImageAddr1 = TempStorageAddress;
	
EndProcedure

&AtClient
Procedure FileUploadSO1(a,b,c,d) Export
	
	PlaceImageFilePO(b,"SOfooter1");
	
EndProcedure

&AtClient
Procedure SOUploadFooter2(Command)
	Var SelectedName;
	SOFooterImageAddr2 = "";
	
	NotifyDescription = New NotifyDescription("FileUploadSO2",ThisForm);
	BeginPutFile(NotifyDescription,,"",True);
	
	BinaryLogo = GeneralFunctions.GetFooterPO("SOfooter2");
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	SOFooterImageAddr2 = TempStorageAddress;

EndProcedure

&AtClient
Procedure FileUploadSO2(a,b,c,d) Export
	
	PlaceImageFilePO(b,"SOfooter2");
	
EndProcedure

&AtClient
Procedure SOUploadFooter3(Command)
	Var SelectedName;
	SOFooterImageAddr3 = "";
	
	NotifyDescription = New NotifyDescription("FileUploadSO3",ThisForm);
	BeginPutFile(NotifyDescription,,"",True);
	
	BinaryLogo = GeneralFunctions.GetFooterPO("SOfooter3");
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	SOFooterImageAddr3 = TempStorageAddress;

EndProcedure

&AtClient
Procedure FileUploadSO3(a,b,c,d) Export
	
	PlaceImageFilePO(b,"SOfooter3");
	
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