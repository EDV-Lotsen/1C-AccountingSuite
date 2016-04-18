
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	IF Not Record.SourceRecordKey.Isempty() Then 
		TmpRecordManager = InformationRegisters.FileStorage.CreateRecordManager();
		TmpRecordManager.Object = Record.Object;
		TmpRecordManager.RecordID = Record.RecordID;
		TmpRecordManager.Read();
		BinaryData = TmpRecordManager.Storage.Get();		
		FileStorageAddress = PutToTempStorage(BinaryData,ThisForm.UUID);
		Items.FileNameText.Title = Record.FileName;
	Else 	
		Record.RecordID = "";
		Record.FileName = "";
		Record.FileSize = 0;
		FileStorageAddress = "";
		Items.FileNameText.Title = "Select file";
	EndIf;
	
	ErrorOnUpload = False;
	MaximumFileSizeToUpload = 50;
	Items.FileSizeWarning.TextColor = New Color (0,0,0);
	Items.FileSizeWarning.Title = "Maximum file size to upload is 50 MB.";
	
EndProcedure

&AtClient
Procedure FileNameStartChoice(Command)
	
	StandardProcessing = False;
	
	Notify = New NotifyDescription("FileUpload",ThisForm);
	BeginPutFile(Notify, "", "*.*", True, ThisForm.UUID);
	//ThisForm.Modified = True;
	
EndProcedure

&AtClient
Procedure FileUpload(Result, Address, SelectedFileName, AdditionalParameters) Export
	
	If Result = True Then 
		
		ValueArray = StringFunctionsClientServer.SplitStringIntoSubstringArray(SelectedFileName, "/",,"""");
		ValueArray = StringFunctionsClientServer.SplitStringIntoSubstringArray(ValueArray[ValueArray.Count() - 1], "\",,"""");
		
		Record.FileName = ValueArray[ValueArray.Count()  - 1];
		Items.FileNameText.Title = Record.FileName;
		
		If ValueIsFilled(Address) Then
			ReadSourceFile(Address);
		EndIf;
		ThisForm.Modified = True;
	Else 
		//ThisForm.Modified = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure ReadSourceFile(TempStorageAddress)
	
	BinaryData = GetFromTempStorage(TempStorageAddress);
	If BinaryData.Size() > MaximumFileSizeToUpload*1024*1204 Then
		Message("Selected file is bigger than "+MaximumFileSizeToUpload+" MB!!! Uploading process was terminated."); 
		ErrorOnUpload = True;
		Items.FileSizeWarning.TextColor = New Color (255,0,0);
		Items.FileSizeWarning.Title = "Upload error! Maximum file size to upload is 50 MB.";
		Return;
	EndIf;	
	Items.FileSizeWarning.TextColor = New Color (0,0,0);
	Items.FileSizeWarning.Title = "Maximum file size to upload is 50 MB.";
		
	ErrorOnUpload = False;
	
	Record.EditDate = CurrentDate();
	Record.FileSize = BinaryData.Size();
	Record.Author = TrimAll(UserName());
	FileStorageAddress = TempStorageAddress;
	If Not ValueIsFilled(Record.RecordID) Then 
		Record.RecordID = New UUID;
	EndIf;
	
	CheckMaximumTotalSizeofAllAttachements();
	
EndProcedure

&AtClient
Procedure SaveToDisk(Command)
	
	If ValueIsFilled(FileStorageAddress) Then 	
		GetFile(FileStorageAddress, Record.FileName);
	Else 
		Message("File in storage is empty");
	EndIf;	
	
EndProcedure

&AtClient
Procedure SaveToBase(Command)
	
	If Not ValueIsFilled(FileStorageAddress) Then 
		UserMessage = New UserMessage;
		Message("File wasn't selected. Please select file first!");
		Return;
	EndIf;	
	
	ThisForm.Write();
	Try
		ThisForm.FormOwner.Refresh();
	Except
	EndTry;	
	
	ThisForm.Close();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	If ValueIsFilled(Record.RecordID) Then 
		CheckMaximumTotalSizeofAllAttachements();
	Else	
		Notify = New NotifyDescription("FileUpload",ThisForm);
		BeginPutFile(Notify, "", "*.*", True, ThisForm.UUID);
		ThisForm.Modified = True;
	EndIf;
EndProcedure

&AtClient
Procedure ComandClose(Command)
	ThisForm.Close();
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Not ValueIsFilled(FileStorageAddress) Then 
		UserMessage = New UserMessage;
		Message("File wasn't selected. Please select file first!");
		Cancel = True;
		
	EndIf;	
	
	CheckMaximumTotalSizeofAllAttachements(Cancel);
	If Cancel Then
		Return;
	EndIf;
	
	BinaryData = GetFromTempStorage(FileStorageAddress);
	CurrentObject.Storage = New ValueStorage(BinaryData, New Deflation(9));

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	BeforeCloseAtServer();
EndProcedure

&AtServer
Procedure BeforeCloseAtServer()
	IF Record.SourceRecordKey.IsEmpty() And 
		(NOT ValueIsFilled(Record.RecordID)) And 
		ThisForm.Modified Then 
		ThisForm.Modified = False;
	EndIf;	
EndProcedure

&AtServer
Procedure CheckMaximumTotalSizeofAllAttachements(Cancel = false)
	
		Query = New Query;
		Query.Text = 
		"SELECT
		|	Sum(FileStorage.FileSize) AS FileSize
		|FROM
		|	InformationRegister.FileStorage AS FileStorage
		|WHERE
		|	FileStorage.Object <> &Object
		|	OR FileStorage.RecordID <> &RecordID";
		
		Query.SetParameter("Object", Record.Object);
		Query.SetParameter("RecordID", Record.RecordID);
		QueryResult = Query.Execute();
		SelectionDetailRecords = QueryResult.Select();
		TotalFilesize = Record.FileSize;
		While SelectionDetailRecords.Next() Do
			TotalFilesize = TotalFilesize + ?(ValueIsFilled(SelectionDetailRecords.FileSize), SelectionDetailRecords.FileSize, 0);
		EndDo;
		
		MaximumTotalFileSize = 2;
		If (TotalFilesize > MaximumTotalFileSize *1024*1024*1024) Then 
			Items.FormSaveToBase.Enabled = False;
			Message("Total size of all files in base can't exceed: " + MaximumTotalFileSize + " GB. Current total size of all files, including cuurent file is: " + Format(TotalFilesize/1024/1024/1024,"NFD=3") + " GB.");
			Cancel = True;
		Else 	
			Items.FormSaveToBase.Enabled = True;
		EndIf;
	
EndProcedure	
