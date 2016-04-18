
////////////////////////////////////////////////////////////////////////////////
// 

&AtServer
// 
//
Function DefineIfThereAreRegisterRecordsByRegistrator() 
	
	QueryText = "";	
	DocumentRegisterRecords = Report.Document.Metadata().RegisterRecords;
	
	If DocumentRegisterRecords.Count() = 0 Then
		Return New ValueTable;
	EndIf;
	
	For Each RegisterRecord In DocumentRegisterRecords Do
		
		QueryText = QueryText + "
		|" + ?(QueryText = "", "", "UNION ALL ") + "
		|SELECT TOP 1 CAST(""" + RegisterRecord.FullName() 
		+  """ AS String(200)) AS Name From " + RegisterRecord.FullName() 
		+ " WHERE Recorder = &Recorder";
		
	EndDo;
	
	Query = New Query(QueryText);
	Query.SetParameter("Recorder", Report.Document);
	
	QueryTable = Query.Execute().Unload();
	QueryTable.Indexes.Add("Name");
	
	For Each TableRowMovements In QueryTable Do		
		TableRowMovements.Name = Upper(TrimAll(TableRowMovements.Name));
	EndDo;
	
	Return QueryTable;			
		
EndFunction

&AtServer
// 
//
Function DefineRegisterKind(RegisterMetadata)
	
	If Metadata.AccumulationRegisters.IndexOf(RegisterMetadata) >= 0 Then
		Return "Accumulation";
		
	ElsIf Metadata.InformationRegisters.IndexOf(RegisterMetadata) >= 0 Then
		Return "Information";	
		
	ElsIf Metadata.AccountingRegisters.IndexOf(RegisterMetadata) >= 0 Then
		Return "Accounting";
		
	Else
		Return "";
			
	EndIf;
    	
EndFunction

&AtServer
// 
//
Procedure GenerateFieldList(MetadataResource, TableOfFields, FieldList)
	
	For Each Resource In MetadataResource Do
		                           
		FieldList = FieldList + ", "+ Resource.Name;
		TableOfFields.Columns.Add(Resource.Name, , Resource.Synonym);
		
	EndDo;
			 
			 
EndProcedure

&AtServer
// 
//
Procedure AddPeriodToFieldList(TableOfFields, FieldList)
	
	FieldList = FieldList + ", Period";
	TableOfFields.Columns.Add("Period", , "Period");
	
EndProcedure

&AtServer
// 
//
Procedure ProcessDataOutputByArray(FieldList, ResourcesTable, TableOfDimensions, AttributesTable, TableKindOfMovements = Undefined, Val RegisterName, SynonymRegister)
	
	If Not ValueIsFilled(FieldList) Then
		Return;
	EndIf;
	
	Query = New Query;
    Query.Text = "SELECT " + FieldList +"
		|{SELECT " + FieldList +"}
		|FROM " + RegisterName + " AS Reg
		|WHERE Reg.Recorder = &ReportDocument
		|	 AND Reg.Active";
		
	Query.SetParameter("ReportDocument", Report.Document);	
        	
    TableQueryResult = Query.Execute().Unload();
	
	For Each ResultRow In TableQueryResult Do
		If TableKindOfMovements <> Undefined Then
			NewRow = TableKindOfMovements.Add();
			FillPropertyValues(NewRow, ResultRow);
		EndIf;
		NewRow = ResourcesTable.Add();
		FillPropertyValues(NewRow, ResultRow);
		NewRow = TableOfDimensions.Add();
		FillPropertyValues(NewRow, ResultRow);
		NewRow = AttributesTable.Add();
		FillPropertyValues(NewRow, ResultRow);
	EndDo; 
	
	Template = Reports.DocumentRegisterRecords.GetTemplate("Template");
	HeaderArea = Template.GetArea("ReportHeader");
		
	HeaderArea.Parameters.SynonymRegister = String(SynonymRegister);
	SpreadsheetDocument.Put(HeaderArea);
	SpreadsheetDocument.StartRowGroup();
	 
	ResultLineCount = TableQueryResult.Count();	
		
	If Report.ReportOutputMethods = 0 Then // Horizontal
	
		// 
		
		AreaTitleCell	 		= Template.GetArea("CellTitle");
		AreaCell			 		= Template.GetArea("Cell");
		AreaIndent 					= Template.GetArea("Indent1");
		
		SpreadsheetDocument.Put(AreaIndent);
		If TableKindOfMovements <> Undefined Then
			AreaTitleCell.Parameters.ColumnsTitle = "Record Type";
	        SpreadsheetDocument.Join(AreaTitleCell);
		EndIf;
		For Each Column In TableOfDimensions.Columns Do
			AreaTitleCell.Parameters.ColumnsTitle = Column.Title;
	        SpreadsheetDocument.Join(AreaTitleCell);
		EndDo; 
		For Each Column In ResourcesTable.Columns Do
			AreaTitleCell.Parameters.ColumnsTitle = Column.Title;
	        SpreadsheetDocument.Join(AreaTitleCell);
		EndDo;
	    For Each Column In AttributesTable.Columns Do
			AreaTitleCell.Parameters.ColumnsTitle = Column.Title;
	        SpreadsheetDocument.Join(AreaTitleCell);
		EndDo;
		
		For LineNumber = 1 To ResultLineCount Do
			
			SpreadsheetDocument.Put(AreaIndent);
			If TableKindOfMovements <> Undefined Then
				AreaCell.Parameters.Value = TableKindOfMovements[LineNumber-1].RecordType;
				SpreadsheetDocument.Join(AreaCell);
				If TableKindOfMovements[LineNumber-1].RecordType = AccumulationRecordType.Expense Then
					Area = SpreadsheetDocument.Area("Cell");
					Area.TextColor = New Color(255, 0, 0);
				Else
				    Area = SpreadsheetDocument.Area("Cell");
					Area.TextColor = New Color(0, 0, 255);
				EndIf;
			EndIf;
			For Each Column In TableOfDimensions.Columns Do
				Value = TableOfDimensions[LineNumber-1][Column.Name]; 
				AreaCell.Parameters.Value = Value;
		        If ValueIsFilled(Value) AND TypeOf(Value) <> Type("Date") AND TypeOf(Value) <> Type("Number")
					AND TypeOf(Value) <> Type("Boolean") AND TypeOf(Value) <> Type("String") Then
					AreaCell.Parameters.ValueDetails = Value;
				Else
					AreaCell.Parameters.ValueDetails = Undefined;				
				EndIf; 
		        SpreadsheetDocument.Join(AreaCell);
			EndDo; 
			For Each Column In ResourcesTable.Columns Do
				Value = ResourcesTable[LineNumber-1][Column.Name]; 
				AreaCell.Parameters.Value = Value;
				If ValueIsFilled(Value) AND TypeOf(Value) <> Type("Date") AND TypeOf(Value) <> Type("Number")
					AND TypeOf(Value) <> Type("Boolean") AND TypeOf(Value) <> Type("String") Then
					AreaCell.Parameters.ValueDetails = Value;
				Else
					AreaCell.Parameters.ValueDetails = Undefined;
				EndIf; 
		        SpreadsheetDocument.Join(AreaCell);
			EndDo; 
			For Each Column In AttributesTable.Columns Do
				Value = AttributesTable[LineNumber-1][Column.Name]; 
				AreaCell.Parameters.Value = Value;
		        If ValueIsFilled(Value) AND TypeOf(Value) <> Type("Date") AND TypeOf(Value) <> Type("Number")
					AND TypeOf(Value) <> Type("Boolean") AND TypeOf(Value) <> Type("String") Then
					AreaCell.Parameters.ValueDetails = Value;
				Else
					AreaCell.Parameters.ValueDetails = Undefined;				
				EndIf; 
		        SpreadsheetDocument.Join(AreaCell);
			EndDo; 
			
		EndDo; 
		
	Else
	
		// 
		
		If TableKindOfMovements <> Undefined Then
			HeaderArea 					= Template.GetArea("TableHeader");
			HeaderDetailsArea 				= Template.GetArea("DetailsHeader");
			AreaDetails 					= Template.GetArea("Details");
			AreaHeaderRecordKind 		= Template.GetArea("HeaderTablesRecordKind");
			HeaderAreaDetailsRecordKind 	= Template.GetArea("DetailsHeaderRecordKind");
			AreaDetailsRecordKind 		= Template.GetArea("DetailsRecordKind");
			AreaIndent 					= Template.GetArea("Indent");
		Else	
		    HeaderArea 					= Template.GetArea("TableHeader1");
			HeaderDetailsArea 				= Template.GetArea("DetailsHeader1");
			AreaDetails 					= Template.GetArea("Details1");
			AreaIndent 					= Template.GetArea("Indent2");
		EndIf;
		
			
		
		SpreadsheetDocument.Put(AreaIndent);
		
		If TableKindOfMovements <> Undefined Then
			SpreadsheetDocument.Join(AreaHeaderRecordKind);
		EndIf;
		SpreadsheetDocument.Join(HeaderArea);
	 	
		LineCountHeader = Max(ResourcesTable.Columns.Count(), TableOfDimensions.Columns.Count(), AttributesTable.Columns.Count());
		ThickLine = New Line(SpreadsheetDocumentCellLineType.Solid,2);
		ThinConnector = New Line(SpreadsheetDocumentCellLineType.Solid,1);
		
		For LineNumber = 1 To LineCountHeader Do
			
			HeaderDetailsArea.Parameters.Resources = "";
			HeaderDetailsArea.Parameters.Dimensions = "";
			HeaderDetailsArea.Parameters.Attributes = "";
			
			If ResourcesTable.Columns.Count() >= LineNumber Then
				HeaderDetailsArea.Parameters.Resources = ResourcesTable.Columns[LineNumber-1].Title;
			EndIf; 	
			If TableOfDimensions.Columns.Count() >= LineNumber Then
				HeaderDetailsArea.Parameters.Dimensions = TableOfDimensions.Columns[LineNumber-1].Title;
			EndIf; 	
			If AttributesTable.Columns.Count() >= LineNumber Then
				HeaderDetailsArea.Parameters.Attributes = AttributesTable.Columns[LineNumber-1].Title;
			EndIf;
						
			SpreadsheetDocument.Put(AreaIndent);
			If TableKindOfMovements <> Undefined Then
				SpreadsheetDocument.Join(HeaderAreaDetailsRecordKind);	
			EndIf;
			SpreadsheetDocument.Join(HeaderDetailsArea);	
						
			If LineNumber = LineCountHeader Then
			    If TableKindOfMovements <> Undefined Then
					Area = SpreadsheetDocument.Area("DetailsHeaderRecordKind");
					Area.Outline(ThickLine, , ThickLine, ThickLine);
					Area = SpreadsheetDocument.Area("DetailsHeader");
					Area.Outline(ThickLine, , ThickLine, ThickLine);
				Else	
					Area = SpreadsheetDocument.Area("DetailsHeader1");
					Area.Outline(ThickLine, , ThickLine, ThickLine);
				EndIf;
				
			EndIf; 
			
		EndDo; 
		
		For LineNumber = 1 To ResultLineCount Do
			
			FlagDisplayedRecordKind = False;
			
			For ColumnNumber = 1 To LineCountHeader Do
			
				AreaDetails.Parameters.Resources = "";
				AreaDetails.Parameters.Dimensions = "";
				AreaDetails.Parameters.Attributes = "";
				
				If ResourcesTable.Columns.Count() >= ColumnNumber Then
					ColumnName = ResourcesTable.Columns[ColumnNumber-1].Name;
					Value = ResourcesTable[LineNumber-1][ColumnName]; 
					AreaDetails.Parameters.Resources = Value;
					If ValueIsFilled(Value) AND TypeOf(Value) <> Type("Date") AND TypeOf(Value) <> Type("Number")
						AND TypeOf(Value) <> Type("Boolean") AND TypeOf(Value) <> Type("String") Then
						AreaDetails.Parameters.ResourcesDetails = Value;
					Else
						AreaDetails.Parameters.ResourcesDetails = Undefined;
					EndIf;
				EndIf; 	
				If TableOfDimensions.Columns.Count() >= ColumnNumber Then
					ColumnName = TableOfDimensions.Columns[ColumnNumber-1].Name;
					Value = TableOfDimensions[LineNumber-1][ColumnName]; 
					AreaDetails.Parameters.Dimensions = Value;
					If ValueIsFilled(Value) AND TypeOf(Value) <> Type("Date") AND TypeOf(Value) <> Type("Number")
						AND TypeOf(Value) <> Type("Boolean") AND TypeOf(Value) <> Type("String") Then
						AreaDetails.Parameters.DimensionsDetails = Value;
					Else
						AreaDetails.Parameters.DimensionsDetails = Undefined;
					EndIf;
				EndIf; 	
				If AttributesTable.Columns.Count() >= ColumnNumber Then
					ColumnName = AttributesTable.Columns[ColumnNumber-1].Name;
					Value = AttributesTable[LineNumber-1][ColumnName]; 
					AreaDetails.Parameters.Attributes = Value;
					If ValueIsFilled(Value) AND TypeOf(Value) <> Type("Date") AND TypeOf(Value) <> Type("Number")
						AND TypeOf(Value) <> Type("Boolean") AND TypeOf(Value) <> Type("String") Then
						AreaDetails.Parameters.AttributesDetails = Value;
					Else
						AreaDetails.Parameters.AttributesDetails = Undefined;
					EndIf;
				EndIf;
				
				SpreadsheetDocument.Put(AreaIndent);
				
				If TableKindOfMovements <> Undefined Then

					If FlagDisplayedRecordKind Then
						ParameterValue = "";
					Else
						ParameterValue = TableKindOfMovements[LineNumber-1]["RecordType"];
						FlagDisplayedRecordKind = True;
					EndIf;

					AreaDetailsRecordKind.Parameters.RecordType = ParameterValue;
					SpreadsheetDocument.Join(AreaDetailsRecordKind);

                    If ParameterValue = AccumulationRecordType.Expense Then
						Area = SpreadsheetDocument.Area("DetailsRecordKind");
						Area.TextColor = New Color(255, 0, 0);
					ElsIf ParameterValue = AccumulationRecordType.Receipt Then
					    Area = SpreadsheetDocument.Area("DetailsRecordKind");
						Area.TextColor = New Color(0, 0, 255);
					EndIf;
				EndIf;
				
				SpreadsheetDocument.Join(AreaDetails);
				
                If ColumnNumber = LineCountHeader Then
				    If TableKindOfMovements <> Undefined Then
						Area = SpreadsheetDocument.Area("DetailsRecordKind");
						Area.Outline(ThinConnector, , ThinConnector, ThinConnector);
                        Area = SpreadsheetDocument.Area("Details");
						Area.Outline(ThinConnector, , ThinConnector, ThinConnector);
                    Else
                        Area = SpreadsheetDocument.Area("Details1");
						Area.Outline(ThinConnector, , ThinConnector, ThinConnector);
					EndIf;
					
				EndIf;

			EndDo;
			
		EndDo; 
		
	EndIf;	
		
	SpreadsheetDocument.EndRowGroup();
			    	
EndProcedure

&AtServer
// 
//
Procedure DoOutputPostingJournal()
		
	Template 				= Reports.DocumentRegisterRecords.GetTemplate("Template");
	TemplateAccountingRegister = Reports.DocumentRegisterRecords.GetTemplate("TemplateAccountingRegister");
	HeaderArea 	= Template.GetArea("ReportHeader");
	AreaHeader 		= TemplateAccountingRegister.GetArea("Header");
	AreaDetails 		= TemplateAccountingRegister.GetArea("Details");
		
	HeaderArea.Parameters.SynonymRegister = "Accounting Register  ""General journal""";
	SpreadsheetDocument.Put(HeaderArea);
	SpreadsheetDocument.StartRowGroup();
	
    SpreadsheetDocument.Put(AreaHeader);	
	
	Query = New Query;
	
	//Query.Text =
	//"SELECT
	//|	GeneralJournal.Period      AS Period,
	//|	GeneralJournal.Recorder    AS Recorder,
	//|	GeneralJournal.LineNumber  AS LineNumber,
	//|	GeneralJournal.Active      AS Active,
	//|	GeneralJournal.Account     AS Account,
	//|	GeneralJournal.RecordType  AS RecordType,
	//|	GeneralJournal.Currency    AS Currency,
	//|	GeneralJournal.Amount      AS Amount,
	//|	GeneralJournal.AmountRC    AS AmountRC,
	//|	GeneralJournal.Memo        AS Memo
	//|FROM
	//|	AccountingRegister.GeneralJournal AS GeneralJournal
	//|WHERE
	//|	GeneralJournal.Recorder = &ReportDocument
	//|
	//|ORDER  BY
	//|	LineNumber";

	Query.Text =
	"SELECT
	|	GeneralJournal.Period,
	|	GeneralJournal.LineNumber,
	|	GeneralJournal.Account,
	|	CASE
	|		WHEN GeneralJournal.RecordType = VALUE(AccountingRecordType.Debit)
	|			THEN GeneralJournal.Currency
	|		ELSE VALUE(Catalog.Currencies.EmptyRef)
	|	END AS CurrencyDr,
	|	CASE
	|		WHEN GeneralJournal.RecordType = VALUE(AccountingRecordType.Debit)
	|			THEN GeneralJournal.Amount
	|		ELSE 0
	|	END AS AmountDr,
	|	CASE
	|		WHEN GeneralJournal.RecordType = VALUE(AccountingRecordType.Debit)
	|			THEN GeneralJournal.AmountRC
	|		ELSE 0
	|	END AS AmountRCDr,
	|	CASE
	|		WHEN GeneralJournal.RecordType = VALUE(AccountingRecordType.Credit)
	|			THEN GeneralJournal.Currency
	|		ELSE VALUE(Catalog.Currencies.EmptyRef)
	|	END AS CurrencyCr,
	|	CASE
	|		WHEN GeneralJournal.RecordType = VALUE(AccountingRecordType.Credit)
	|			THEN GeneralJournal.Amount
	|		ELSE 0
	|	END AS AmountCr,
	|	CASE
	|		WHEN GeneralJournal.RecordType = VALUE(AccountingRecordType.Credit)
	|			THEN GeneralJournal.AmountRC
	|		ELSE 0
	|	END AS AmountRCCr,
	|	GeneralJournal.RecordType,
	|	GeneralJournal.Memo
	|FROM
	|	AccountingRegister.GeneralJournal AS GeneralJournal
	|WHERE
	|	GeneralJournal.Recorder = &ReportDocument
	|
	|ORDER  BY
	|	LineNumber";
    
	Query.SetParameter("ReportDocument", 	Report.Document);	
			
	TableQueryResult = Query.Execute().Unload();
	For Each ResultRow In TableQueryResult Do
			
        FillPropertyValues(AreaDetails.Parameters, ResultRow);
        SpreadsheetDocument.Put(AreaDetails);

	EndDo; 
	
	SpreadsheetDocument.EndRowGroup();
			    	
EndProcedure

&AtServer                                              
// 
//
Procedure GenerateReport()
	
    If Not ValueIsFilled(Report.Document) Then
		Message = New UserMessage();
		Message.Text = NStr("en = 'Document is not selected!'");
		Message.Message();
		Return;
	EndIf;

	SetPrivilegedMode(True);
	
	SpreadsheetDocument.Clear();
	Template = Reports.DocumentRegisterRecords.GetTemplate("Template");
	DocumentRegisterRecords = Report.Document.Metadata().RegisterRecords;
		
	// 
	HeaderArea = Template.GetArea("MainTitle");
	HeaderArea.Parameters.Document = String(Report.Document);
	SpreadsheetDocument.Put(HeaderArea);

    // 
	RegisterRecordTable = DefineIfThereAreRegisterRecordsByRegistrator();
	
    OutputJournalPosts = False;
			
	// 
	For Each PropertiesOfObject In DocumentRegisterRecords Do
		
		// 
		RowInRegisterTable = RegisterRecordTable.Find(Upper(PropertiesOfObject.FullName()), "Name");
		
		If RowInRegisterTable = Undefined Then
			Continue;
		EndIf;
		
		RegisterType = DefineRegisterKind(PropertiesOfObject);
 		RegisterName = RegisterType + "Register" + "." + PropertiesOfObject.Name;
		SynonymRegister = RegisterType + " Register " + " """ + PropertiesOfObject.Synonym + """";
		
		If RegisterType = "Information" Or RegisterType = "Accumulation" Then
			
			FieldList = "";
			ResourcesTable = New ValueTable;                                            
			TableOfDimensions = New ValueTable;
			AttributesTable = New ValueTable;
			
			If RegisterType = "Information" AND PropertiesOfObject.InformationRegisterPeriodicity = Metadata.ObjectProperties.InformationRegisterPeriodicity.Nonperiodical Then
			Else
				AddPeriodToFieldList(TableOfDimensions, FieldList);
			EndIf;
			GenerateFieldList(PropertiesOfObject.Resources, ResourcesTable, FieldList);
            GenerateFieldList(PropertiesOfObject.Dimensions, TableOfDimensions, FieldList);
			GenerateFieldList(PropertiesOfObject.Attributes, AttributesTable, FieldList);
            FieldList = Right(FieldList, StrLen(FieldList)-2);
			
			If (RegisterType = "Accumulation") AND (PropertiesOfObject.RegisterType = Metadata.ObjectProperties.AccumulationRegisterType.Balance) Then
				FieldList = FieldList + ", RecordType";
				TableKindOfMovements = New ValueTable;
			    TableKindOfMovements.Columns.Add("RecordType", , "Record Type");
            	ProcessDataOutputByArray(FieldList, ResourcesTable, TableOfDimensions, AttributesTable, TableKindOfMovements, RegisterName, SynonymRegister);
			Else
                ProcessDataOutputByArray(FieldList, ResourcesTable, TableOfDimensions, AttributesTable, , RegisterName, SynonymRegister);
			EndIf; 
            
		ElsIf RegisterType = "Accounting" Then
         	
            OutputJournalPosts = True;

		EndIf;

	EndDo;	
	
	If OutputJournalPosts Then
		 DoOutputPostingJournal();
	EndIf;
		
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// 

&AtServer
// 
//
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("Document") Then
		Report.Document = Parameters.Document;
	EndIf; 
	
	Report.ReportOutputMethods = 0; // Horizontal
	GenerateReport();
	
EndProcedure

&AtClient
// 
//
Procedure MakeExecute()
	
	GenerateReport();
	
EndProcedure



