
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	BinaryLogo = GeneralFunctions.GetFooterPO("ShipmentFooter1");
	TempStorageAddress = PutToTempStorage(BinaryLogo);
	FooterImageAddr1 = TempStorageAddress;
	Items.FooterImageAddr1.PictureSize = PictureSize.AutoSize;
	
	BinaryLogo = GeneralFunctions.GetFooterPO("ShipmentFooter2");
	TempStorageAddress = PutToTempStorage(BinaryLogo);
	FooterImageAddr2 = TempStorageAddress;
	Items.FooterImageAddr2.PictureSize = PictureSize.AutoSize;

	BinaryLogo = GeneralFunctions.GetFooterPO("ShipmentFooter3");
	TempStorageAddress = PutToTempStorage(BinaryLogo);
	FooterImageAddr3 = TempStorageAddress;
	Items.FooterImageAddr3.PictureSize = PictureSize.AutoSize;
	
EndProcedure


&AtClient
Procedure UploadFooter1(Command) Export

	FooterImageAddr1 = "";
	
	NotifyDescription = New NotifyDescription("FileUpload", ThisForm, "ShipmentFooter1");
	BeginPutFile(NotifyDescription,,"",True);
	
EndProcedure

&AtClient
Procedure UploadFooter2(Command) Export
	
	FooterImageAddr2 = "";
	
	NotifyDescription = New NotifyDescription("FileUpload", ThisForm, "ShipmentFooter2");
	BeginPutFile(NotifyDescription,,"",True);
	
EndProcedure

&AtClient
Procedure UploadFooter3(Command) Export

	FooterImageAddr3 = "";
	
	NotifyDescription = New NotifyDescription("FileUpload", ThisForm, "ShipmentFooter3");
	BeginPutFile(NotifyDescription,,"",True);

EndProcedure


&AtClient
Procedure FileUpload(a,b,c,d) Export
	
	PlaceImageFile(b, d);
	
	BinaryLogo = GeneralFunctions.GetFooterPO(d);
	TempStorageAddress = PutToTempStorage(BinaryLogo);
	
	If d = "ShipmentFooter1" Then  
		FooterImageAddr1 = TempStorageAddress;
	ElsIf d = "ShipmentFooter2" Then  
		FooterImageAddr2 = TempStorageAddress;
	ElsIf d = "ShipmentFooter3" Then  
		FooterImageAddr3 = TempStorageAddress;
	EndIf;
	
EndProcedure

&AtServer
Procedure PlaceImageFile(TempStorageName, ImageName)
	
	If NOT TempStorageName = Undefined Then
	
		BinaryData = GetFromTempStorage(TempStorageName);
				
		NewRow = InformationRegisters.CustomPrintForms.CreateRecordManager();
		NewRow.ObjectName = ImageName;
		NewRow.TemplateName = ImageName;
		NewRow.Template = New ValueStorage(BinaryData, New Deflation(9));
		NewRow.Write();	
		DeleteFromTempStorage(TempStorageName);
		
	EndIf;
	  	
EndProcedure

&AtClient
Procedure ShipmentShowSVCOnChange(Item)
	If ConstantsSet.ShipmentShowSVCCol Then 
		ConstantsSet.ShipmentShowClassCol = False;
	EndIf;
EndProcedure

&AtClient
Procedure ShipmentShowClassColOnChange(Item)
	If ConstantsSet.ShipmentShowClassCol Then 
		ConstantsSet.ShipmentShowSVCCol = False;
	EndIf;
EndProcedure
