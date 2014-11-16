
&AtClient
Procedure ReadTaxCodes(Command)
	
	Notify = New NotifyDescription("FileUpload",ThisForm);

	BeginPutFile(Notify, "", "*.xls", True, ThisForm.UUID);
	
EndProcedure

&AtServer
Procedure ImportTaxCodesAtServer(TempStorageAddress, FileType = "xls")
	
	BinaryData = GetFromTempStorage(TempStorageAddress);
	TempFileName = GetTempFileName(FileType);
	BinaryData.Write(TempFileName);

	Try
        Excel = New COMObject("Excel.Application");
        Excel.WorkBooks.Open(TempFileName);
        ExcelSheet = Excel.Sheets(1);
	Except
		ErrorDescription = ErrorDescription();
       	CommonUseClientServer.MessageToUser("An error occured. Details:" + ErrorDescription);
        return;
	EndTry;
	//Clear collections
	CodeDescription = New ValueTable();
	CodeDescription.Columns.Add("Code", New TypeDescription(New TypeDescription("String"),,,, New StringQualifiers(8)));
	CodeDescription.Columns.Add("Description", New TypeDescription(New TypeDescription("String"),,,, New StringQualifiers(100)));
	CodeDescription.Columns.Add("Order", New TypeDescription("Number"));
	CodeDescription.Columns.Add("TreeRow");
	TaxCodesTree.GetItems().Clear();
	CodeDescription.Clear();
	
	xlCellTypeLastCell = 11;
    ExcelLastRow = ExcelSheet.Cells.SpecialCells(xlCellTypeLastCell).Row;
	HierarchyMap = New Map();
	CurLevel = 0;
	For CurRow = Object.FirstRow To ExcelLastRow Do
		Code    				= TrimAll(ExcelSheet.Cells(CurRow, 1).Value);
		Description 			= TrimAll(ExcelSheet.Cells(CurRow, 2).Value);
		AdditionalInformation 	= TrimAll(ExcelSheet.Cells(CurRow, 3).Value);
		
		If IsBlankString(Description) Then
			Continue;
		EndIf;

		RowLevel = ExcelSheet.Rows(CurRow).OutlineLevel;	
		If RowLevel = 1 Then
			NewBranch = TaxCodesTree.GetItems().Add();
		Else
			ParentBranch 	= HierarchyMap.Get(RowLevel-1);	
			NewBranch		= ParentBranch.GetItems().Add();
		EndIf;
		HierarchyMap.Insert(RowLevel, NewBranch);
		NewBranch.TaxCode = Code;
		NewBranch.Description = Description;
		NewBranch.AdditionalInformation = AdditionalInformation;
		NewCD = CodeDescription.Add();
		NewCD.Code = Code;
		NewCD.Description = Description;
		NewCD.Order = CodeDescription.Count()-1;
		NewCD.TreeRow = NewBranch;
		If (TrimAll(NewBranch.TaxCode) <> TrimAll(Code)) Or (TrimAll(NewBranch.Description) <> TrimAll(Description)) Then
			CommonUseClientServer.MessageToUser(Code + " : " + Description + ". Code or Description are too long");
		EndIf;
	EndDo;
	
	//Find existing refs
	Request = New Query("SELECT
	                    |	CodeDescription.Code,
	                    |	CodeDescription.Description,
	                    |	CodeDescription.Order
	                    |INTO CodeDescription
	                    |FROM
	                    |	&CodeDescription AS CodeDescription
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT
	                    |	CodeDescription.Code,
	                    |	CodeDescription.Description,
	                    |	CodeDescription.Order,
	                    |	TaxCodesPredefined.Ref,
	                    |	TaxCodesPredefined.Parent
	                    |FROM
	                    |	CodeDescription AS CodeDescription
	                    |		LEFT JOIN Catalog.TaxCodesPredefined AS TaxCodesPredefined
	                    |		ON (CASE
	                    |				WHEN CodeDescription.Code = """"
	                    |					THEN CodeDescription.Description = TaxCodesPredefined.Description
	                    |				ELSE CodeDescription.Code = TaxCodesPredefined.Code
	                    |			END)");
	Request.SetParameter("CodeDescription", CodeDescription.Copy(, "Code, Description, Order"));
	CodeDescriptionRef = Request.Execute().Unload();
	For Each CDRItem In CodeDescriptionRef Do
		CodeDescription[CDRItem.Order].TreeRow.TaxCodeRef = CDRItem.Ref;
	EndDo;
	
EndProcedure

&AtClient
Procedure FileUpload(Result, Address, SelectedFileName, AdditionalParameters) Export
	
	If (Find(SelectedFileName, ".xls") = 0) And (Find(SelectedFileName, ".xlsx") = 0) Then
		ShowMessageBox(, "Please upload a valid Excel file (.xls, .xlsx)");
		return;
	EndIf;
	
	If ValueIsFilled(Address) Then
		ShowUserNotification("Reading file with  Microsoft Excel...");
		ImportTaxCodesAtServer(Address);
	EndIf;
	
	ShowMessageBox(,"Done!");
	
EndProcedure

&AtClient
Procedure WriteTaxCodesToDB(Command)
	WriteTaxCodesToDBAtServer();
EndProcedure

&AtServer
Procedure WriteTaxCodesToDBAtServer()
	
	UploadedItems = New ValueTable();
	UploadedItems.Columns.Add("TaxCodeRef", New TypeDescription("CatalogRef.TaxCodesPredefined"));
	WriteTaxCodeToTheDB(TaxCodesTree.GetItems());
		
EndProcedure

&AtServer 
Procedure WriteTaxCodeToTheDB(TreeItemsCollection)
	
	For Each TreeItem In TreeItemsCollection Do
		If Not ValueIsFilled(TreeItem.TaxCodeRef) Then
			TaxCodeObject = Catalogs.TaxCodesPredefined.CreateItem();				
		Else
			TaxCodeObject = TreeITem.TaxCodeRef.GetObject();
		EndIf;
		TreeItemParent = TreeItem.GetParent();
		ObjectParent = Catalogs.TaxCodesPredefined.EmptyRef();
		If TreeItemParent <> Undefined Then
			ObjectParent = TreeItemParent.TaxCodeRef;
		EndIf;
		TaxCodeObject.Code = TreeItem.TaxCode;
		TaxCodeObject.Description = TreeItem.Description;
		TaxCodeObject.AdditionalInformation = TreeItem.AdditionalInformation;
		TaxCodeObject.Parent = ObjectParent;
		TaxCodeObject.DataExchange.Load = True;
		TaxCodeObject.Write();
		TreeItem.TaxCodeRef = TaxCodeObject.Ref;
						
		WriteTaxCodeToTheDB(TreeItem.GetItems());
	EndDo;
	
EndProcedure

&AtServer
Procedure ClearCatalog(Parent = Undefined)
	
	Sel = Catalogs.TaxCodesPredefined.SelectHierarchically(Parent);
	While Sel.Next() Do
		Try
			ClearCatalog(Sel.Ref);
   			CurObject = Sel.GetObject();
   			CurObject.Delete();
		Except
			ErrorDescription = ErrorDescription();
			CommonUseClientServer.MessageToUser("Error occured while deleting obsolete predefined tax code: " + CurObject.Ref.Code + " " + CurObject.Ref.Description);
			CommonUseClientServer.MessageToUser("Details: " + ErrorDescription);
		EndTry;
	EndDo;
	
EndProcedure

&AtClient
Procedure ClearCatalogAtClient(Command)
	
	ClearCatalog();
	TaxCodesTree.GetItems().Clear();
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Object.FirstRow = 5;
	
EndProcedure
