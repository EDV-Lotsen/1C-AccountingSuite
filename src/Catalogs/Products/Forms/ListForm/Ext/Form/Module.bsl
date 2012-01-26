
&AtClient
Procedure ImportProducts(Command)
	
	Mode = FileDialogMode.Open;
	OpeningFileDialogue = New FileDialog(Mode);
	OpeningFileDialogue.FullFileName = "";
	Filter = "Excel(*.xlsx)|*.xlsx|Excel 97(*.xls)|*.xls";
	OpeningFileDialogue.Filter = Filter;
	OpeningFileDialogue.Multiselect = False;
	OpeningFileDialogue.Title = "Select file";
	If OpeningFileDialogue.Choose() Then
	    FilesArray = OpeningFileDialogue.SelectedFiles;
	    For Each FileName In FilesArray Do
	        Selection = New File(FileName);
	        //Message(FileName+"; Size = "+Selection.Size());
		EndDo;
		ImportData(Selection.FullName);
	Else
	    DoMessageBox("File(s) not selected!");
	EndIf;	

EndProcedure

&AtServer
Procedure ImportData(File)
		
	try
	      ExcelApp    = New  COMObject("Excel.Application");
	except
	      Message(ErrorDescription()); 
	      Message("Can't initialize Excel"); 
	      Return; 
	EndTry; 

	
	try 
	ExcelFile = ExcelApp.Workbooks.Open(File);

	NColumns =1;
	NRows =2; // not taking the header
	NPages = 1;
	For CurrentNumber = 1 To NPages Do 
		
		TotalNRows  = ExcelApp.Sheets(CurrentNumber).UsedRange.row + ExcelApp.Sheets(CurrentNumber).UsedRange.Rows.Count - 1;
		   
		   For n= 1 To   TotalNRows -1 Do
			   
			    LineTotal = 0;
				
				ExcelProduct = ExcelApp.Sheets(CurrentNumber).Cells(NRows,NColumns).Value; 
				Product = Catalogs.Products.FindByDescription(ExcelProduct);
				
				If Product.Description = "" AND Constants.AddProductsWhenImporting.Get() Then
					
					NewProduct = Catalogs.Products.CreateItem();
					ProductID = ExcelApp.Sheets(CurrentNumber).Cells(NRows,NColumns).Value; 
					NewProduct.Description = ProductID;
					ProductDescr = ExcelApp.Sheets(CurrentNumber).Cells(NRows,NColumns +1).Value;
					NewProduct.Descr = ProductDescr; 		   
					ProductType = Constants.ProductTypeImport.Get();
					NewProduct.Type = ProductType;
					If ProductType = Enums.InventoryTypes.Inventory Then
						NewProduct.CostingMethod = Constants.ProductCostingImport.Get();
					EndIf;
					NewProduct.Write();
					
					Message("Item imported:" + ExcelProduct);
					
				EndIf;
								
		   	NRows = NRows +1;
		EndDo;
		
	EndDo;
	except
	Message(ErrorDescription()); 
	ExcelApp.Application.Quit();
	endTry;
	
	ExcelApp.ActiveWorkbook.Close(False);
		
EndProcedure;

