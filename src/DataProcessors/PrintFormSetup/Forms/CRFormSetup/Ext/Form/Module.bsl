&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	BinaryLogo = GeneralFunctions.GetFooterPO("CRfooter1");
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	CRFooterImageAddr1 = TempStorageAddress;
	Items.CRFooterImageAddr1.PictureSize = PictureSize.AutoSize;
	
	BinaryLogo = GeneralFunctions.GetFooterPO("CRfooter2");
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	CRFooterImageAddr2 = TempStorageAddress;
	Items.CRFooterImageAddr2.PictureSize = PictureSize.AutoSize;

	BinaryLogo = GeneralFunctions.GetFooterPO("CRfooter3");
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	CRFooterImageAddr3 = TempStorageAddress;
	Items.CRFooterImageAddr3.PictureSize = PictureSize.AutoSize;

EndProcedure

&AtClient
Procedure CRUploadFooter1(Command)
	
	Var SelectedName;
	CRFooterImageAddr1 = "";
	
	NotifyDescription = New NotifyDescription("FileUploadCR1",ThisForm);
	BeginPutFile(NotifyDescription,,"",True);
	
	BinaryLogo = GeneralFunctions.GetFooterPO("CRfooter1");
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	CRFooterImageAddr1 = TempStorageAddress;
	
EndProcedure

&AtClient
Procedure FileUploadCR1(a,b,c,d) Export
	
	PlaceImageFilePO(b,"CRfooter1");
	
EndProcedure

&AtClient
Procedure CRUploadFooter2(Command)
	Var SelectedName;
	CRFooterImageAddr2 = "";
	
	NotifyDescription = New NotifyDescription("FileUploadCR2",ThisForm);
	BeginPutFile(NotifyDescription,,"",True);
	
	BinaryLogo = GeneralFunctions.GetFooterPO("CRfooter2");
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	CRFooterImageAddr2 = TempStorageAddress;

EndProcedure

&AtClient
Procedure FileUploadCR2(a,b,c,d) Export
	
	PlaceImageFilePO(b,"CRfooter2");
	
EndProcedure

&AtClient
Procedure CRUploadFooter3(Command)
	Var SelectedName;
	CRFooterImageAddr3 = "";
	
	NotifyDescription = New NotifyDescription("FileUploadCR3",ThisForm);
	BeginPutFile(NotifyDescription,,"",True);
	
	BinaryLogo = GeneralFunctions.GetFooterPO("CRfooter3");
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	CRFooterImageAddr3 = TempStorageAddress;

EndProcedure

&AtClient
Procedure FileUploadCR3(a,b,c,d) Export
	
	PlaceImageFilePO(b,"CRfooter3");
	
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