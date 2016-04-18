&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	BinaryLogo = GeneralFunctions.GetFooterPO("CSfooter1");
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	CSFooterImageAddr1 = TempStorageAddress;
	Items.CSFooterImageAddr1.PictureSize = PictureSize.AutoSize;
	
	BinaryLogo = GeneralFunctions.GetFooterPO("CSfooter2");
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	CSFooterImageAddr2 = TempStorageAddress;
	Items.CSFooterImageAddr2.PictureSize = PictureSize.AutoSize;

	BinaryLogo = GeneralFunctions.GetFooterPO("CSfooter3");
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	CSFooterImageAddr3 = TempStorageAddress;
	Items.CSFooterImageAddr3.PictureSize = PictureSize.AutoSize;

EndProcedure

&AtClient
Procedure CSUploadFooter1(Command)
	
	Var SelectedName;
	CSFooterImageAddr1 = "";
	
	NotifyDescription = New NotifyDescription("FileUploadCS1",ThisForm);
	BeginPutFile(NotifyDescription,,"",True);
	
	BinaryLogo = GeneralFunctions.GetFooterPO("CSfooter1");
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	CSFooterImageAddr1 = TempStorageAddress;
	
EndProcedure

&AtClient
Procedure FileUploadCS1(a,b,c,d) Export
	
	PlaceImageFilePO(b,"CSfooter1");
	
EndProcedure

&AtClient
Procedure CSUploadFooter2(Command)
	Var SelectedName;
	CSFooterImageAddr2 = "";
	
	NotifyDescription = New NotifyDescription("FileUploadCS2",ThisForm);
	BeginPutFile(NotifyDescription,,"",True);
	
	BinaryLogo = GeneralFunctions.GetFooterPO("CSfooter2");
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	CSFooterImageAddr2 = TempStorageAddress;

EndProcedure

&AtClient
Procedure FileUploadCS2(a,b,c,d) Export
	
	PlaceImageFilePO(b,"CSfooter2");
	
EndProcedure

&AtClient
Procedure CSUploadFooter3(Command)
	Var SelectedName;
	CSFooterImageAddr3 = "";
	
	NotifyDescription = New NotifyDescription("FileUploadCS3",ThisForm);
	BeginPutFile(NotifyDescription,,"",True);
	
	BinaryLogo = GeneralFunctions.GetFooterPO("CSfooter3");
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	CSFooterImageAddr3 = TempStorageAddress;

EndProcedure

&AtClient
Procedure FileUploadCS3(a,b,c,d) Export
	
	PlaceImageFilePO(b,"CSfooter3");
	
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