
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	BinaryLogo = GeneralFunctions.GetFooterPO("QuoteFooter1");
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	QuoteFooterImageAddr1 = TempStorageAddress;
	Items.QuoteFooterImageAddr1.PictureSize = PictureSize.AutoSize;
	
	BinaryLogo = GeneralFunctions.GetFooterPO("QuoteFooter2");
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	QuoteFooterImageAddr2 = TempStorageAddress;
	Items.QuoteFooterImageAddr2.PictureSize = PictureSize.AutoSize;

	BinaryLogo = GeneralFunctions.GetFooterPO("QuoteFooter3");
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	QuoteFooterImageAddr3 = TempStorageAddress;
	Items.QuoteFooterImageAddr3.PictureSize = PictureSize.AutoSize;

EndProcedure

&AtClient
Procedure QuoteUploadFooter1(Command)
	
	Var SelectedName;
	QuoteFooterImageAddr1 = "";
	
	NotifyDescription = New NotifyDescription("FileUploadQuote1",ThisForm);
	BeginPutFile(NotifyDescription,,"",True);
	
	BinaryLogo = GeneralFunctions.GetFooterPO("QuoteFooter1");
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	QuoteFooterImageAddr1 = TempStorageAddress;
	
EndProcedure

&AtClient
Procedure FileUploadQuote1(a,b,c,d) Export
	
	PlaceImageFilePO(b,"QuoteFooter1");
	
EndProcedure

&AtClient
Procedure QuoteUploadFooter2(Command)
	Var SelectedName;
	QuoteFooterImageAddr2 = "";
	
	NotifyDescription = New NotifyDescription("FileUploadQuote2",ThisForm);
	BeginPutFile(NotifyDescription,,"",True);
	
	BinaryLogo = GeneralFunctions.GetFooterPO("QuoteFooter2");
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	QuoteFooterImageAddr2 = TempStorageAddress;

EndProcedure

&AtClient
Procedure FileUploadQuote2(a,b,c,d) Export
	
	PlaceImageFilePO(b,"QuoteFooter2");
	
EndProcedure

&AtClient
Procedure QuoteUploadFooter3(Command)
	Var SelectedName;
	QuoteFooterImageAddr3 = "";
	
	NotifyDescription = New NotifyDescription("FileUploadQuote3",ThisForm);
	BeginPutFile(NotifyDescription,,"",True);
	
	BinaryLogo = GeneralFunctions.GetFooterPO("QuoteFooter3");
	TempStorageAddress = PutToTempStorage(BinaryLogo,UUID);
	QuoteFooterImageAddr3 = TempStorageAddress;

EndProcedure

&AtClient
Procedure FileUploadQuote3(a,b,c,d) Export
	
	PlaceImageFilePO(b,"QuoteFooter3");
	
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
