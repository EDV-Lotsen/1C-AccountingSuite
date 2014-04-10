
////////////////////////////////////////////////////////////////////////////////
// Document filling: Server module
//------------------------------------------------------------------------------
// Available on:
// - Server
// - External Connection
//

////////////////////////////////////////////////////////////////////////////////
#Region PUBLIC_INTERFACE

//------------------------------------------------------------------------------
// Preparing the document data before filling an object

// Save additional document parameters required for data query before filling an object
//
// Parameters:
//  AdditionalProperties           - Structure   - Additional object parameters containing required attributes and tables.
//    * Filling                    - Structure   - The filling data key.
//      ** FillingData             - Structure   - Filling data, types and references to fill.
//      ** FillingTables           - Structure   - Data structures containing tables for filling the document data.
//        *** Table_Check          - ValueTable  - Data table containing attributes for iniqueless checking and totals counting.
//      ** CheckAttributes         - Structure   - Structure containing attributes for filling and aggregate or checking function.
//      ** StructTempTablesManager - Structure   - Structure containing temporary tables manager used for filling data query.
//        *** TempTablesManager    - TempTablesManager - Temporary tables manager used for filling data query.
//    * Ref                        - DocumentRef - Reference of document to be filled.
//  DocumentParameters             - Structure   - Structure of object attributes, required for document filling to be packed into AdditionalProperties.
//  FillingData                    - DocumentRef - Filling data, usually Ref to base document.
//                                 - Array       - Array of Refs to fill the document from.
//  Cancel                         - Boolean     - Flag of cancel document filling.
//
Procedure PrepareDataStructuresBeforeFilling(AdditionalProperties, DocumentParameters, FillingData, Cancel) Export
	WarnOnNoData = False;
	
	// Check filling data according to BasedOn types.
	TypedFillingData = GetTypedFillingStructure(DocumentParameters.Ref, FillingData, DocumentParameters.Metadata.BasedOn);
	If TypedFillingData.Count() = 0 Then
		If WarnOnNoData Then
			MessageText = NStr("en = 'Failed to generate the %1, filling data is not provided.'");
			MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessageText,
			                                                                       DocumentParameters.Metadata.Presentation()); 
			CommonUseClientServer.MessageToUser(MessageText, DocumentParameters.Ref,,, Cancel);
		Else // Quiet filling cancel (without user warning).
			Cancel = True;
		EndIf;
		
		Return;
	EndIf;
	
	// Cache document attributes minimizing data requests - pack filling parameters into AdditionalProperties.
	For Each DocumentParameter In DocumentParameters Do
		AdditionalProperties.Insert(DocumentParameter.Key, DocumentParameter.Value);
	EndDo;
	
	// Filling - Structure containing data to be transferred on the server and fill the document
	AdditionalProperties.Insert("Filling", New Structure);
	
	// Specify source data for filling the document
	AdditionalProperties.Filling.Insert("FillingData", TypedFillingData);
	
	// FillingTables - Structure containing document tables data for filling the document
	AdditionalProperties.Filling.Insert("FillingTables", New Structure);
	
	// TempTablesManager - Temporary tables manager, containing document data requested for filling document data.
	AdditionalProperties.Filling.Insert("StructTempTablesManager", New Structure("TempTablesManager", New TempTablesManager));
	
EndProcedure

// Clear used additional document data passed as additional properties.
//
// Parameters:
//  AdditionalProperties - Structure   - Additional object parameters containing required attributes and tables.
//    * FillingTables    - Structure   - Data structures containing tables for filling the document data.
//      ** Table_Check   - ValueTable  - Data table containing attributes for iniqueless checking and totals counting.
//    * CheckAttributes  - Structure   - Structure containing attributes for filling and aggregate or checking function.
//    * Ref              - DocumentRef - Reference of document to be filled.
//
Procedure ClearDataStructuresAfterFilling(AdditionalProperties) Export
	
	// Dispose used temporary tables managers.
	AdditionalProperties.Filling.StructTempTablesManager.TempTablesManager.Close();
	
EndProcedure

//------------------------------------------------------------------------------
// Check document data consistency during filling an object

// Check documents attributes uniqueness on filling an object.
//
// Parameters:
//  AdditionalProperties   - Structure   - Additional object parameters containing required attributes and tables.
//    * Filling            - Structure   - The filling data key.
//      ** FillingTables   - Structure   - Data structures containing tables for filling the document data.
//        *** Table_Check  - ValueTable  - Data table containing attributes for iniqueless checking and totals counting.
//      ** CheckAttributes - Structure   - Structure containing attributes for filling and aggregate or checking function.
//    * Ref                - DocumentRef - Reference of document to be filled.
//  Cancel                 - Boolean     - Flag of cancel further document filling.
//
Procedure CheckDataStructuresOnFilling(AdditionalProperties, Cancel) Export
	Var TableCheck, CheckAttributes;
	
	// Get table of grouped attributes.
	AdditionalProperties.Filling.FillingTables.Property("Table_Check", TableCheck);
	AdditionalProperties.Filling.Property("CheckAttributes", CheckAttributes);
	
	// Check quantity of grouped strings (versions of a header).
	HeaderVersionsCount = TableCheck.Count();
	If HeaderVersionsCount = 0 Then
		MessageText = NStr("en = 'Failed to generate the %1, filling data is not suitable for filling.'");
		MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessageText,
		                                                                       AdditionalProperties.Metadata.Presentation()); 
		CommonUseClientServer.MessageToUser(MessageText, AdditionalProperties.Ref,,, Cancel);
		
	ElsIf (HeaderVersionsCount > 0) And (CheckAttributes.Count() > 0) Then
		CompaniesName = LocalizedCompaniesName(AdditionalProperties.Ref);
		For Each Attribute In CheckAttributes Do
			If Attribute.Value <> "Check" Then Continue; EndIf;
			
			// Check uniqueness by selected attributes.
			Selection = TableCheck.Copy(, Attribute.Key);
			Selection.GroupBy(Attribute.Key);
			If Selection.Count() > 1 Then // Double found.
				
				// Convert value to it's presentation.
				DoublesText = "";
				For Each Row In Selection Do
					
					// Convert value to it's presentation.
					Value = Row[Attribute.Key];
					If Not ValueIsFilled(Value) Then
						Presentation = NStr("en = '<Empty>'");
						
					ElsIf TypeOf(Value) = Type("CatalogRef.Companies") Then
						Presentation = TrimAll(Value.Code) + " " + TrimAll(Value.Description);
						
					ElsIf TypeOf(Value) = Type("CatalogRef.Products") Then
						Presentation = TrimAll(Value.Code) + " " + TrimAll(Value.Description);
						
					Else
						Presentation = TrimAll(Value);
					EndIf;
					
					// Generate doubled items text.
					DoublesText = DoublesText + ?(IsBlankString(DoublesText), "", ", ") + " '" + Presentation + "'";
				EndDo;
				
				MessageText  = NStr("en = 'Selected documents have different %1: %2'");
				MessageText  = StringFunctionsClientServer.SubstituteParametersInString(MessageText,
				               ?(Attribute.Key = "Company", CompaniesName, Lower(AdditionalProperties.Metadata.Attributes[Attribute.Key].Synonym) + " values"),
				               DoublesText);
				CommonUseClientServer.MessageToUser(MessageText, AdditionalProperties.Ref,,, Cancel);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

// Creates structure containing types of filling (as keys) and filling data (as values).
//
// Parameters:
//  Ref              - DocumentRef    - Reference to the document to be filled.
//  FillingData      - DocumentRef    - Filling data, usually Ref to base document.
//                   - Array          - Array of Refs to fill the document from.
//  BasedOn          - MetadataObject - Metadata of document, containing list of data sources, to fill document from.
//  ExcludedTypesStr - String         - Comma-separated string containing base reference types to skip during filling.
//
// Returns:
//  Structure        - Filling data, types and references to fill.
//
Function GetTypedFillingStructure(Ref, FillingData, BasedOn, ExcludedTypesStr = Undefined)
	Var Values;
	
	// Create returning structure.
	FillingStructure = New Structure;
	
	// Create description of available filling types.
	ArrayOfBasedOnTypes = New Array;
	For Each Base In BasedOn Do
		ArrayOfBasedOnTypes.Add(Type(StrReplace(Base.FullName(), ".", "Ref.")));
	EndDo;
	BasedOnTypes = New TypeDescription(ArrayOfBasedOnTypes);
	
	// Create description of excluded filling types.
	ArrayOfExcludedTypes = New Array;
	ListOfExcludedTypes  = StringFunctionsClientServer.SplitStringIntoSubstringArray(ExcludedTypesStr);
	For Each ExcludedType In ListOfExcludedTypes Do
		ArrayOfExcludedTypes.Add(Type(StrReplace(ExcludedType, ".", "Ref.")));
	EndDo;
	ExcludedTypes = New TypeDescription(ArrayOfExcludedTypes);
	
	// Universal value collections.
	If TypeOf(FillingData) = Type("Array") 
	Or TypeOf(FillingData) = Type("Structure")
	Or TypeOf(FillingData) = Type("Map")
	Then
		
		// Determine type of values.
		For Each Data In FillingData Do
			
			// Define filling value.
			If TypeOf(Data) = Type("KeyAndValue") Then
				Value = Data.Value;
			Else
				Value = Data;
			EndIf;
			
			// Add data source to filling structure.
			If  BasedOnTypes.ContainsType(TypeOf(Value))
			And Not ExcludedTypes.ContainsType(TypeOf(Value)) Then
				
				If Not BadSourceRef(Ref, Value) Then
					FillingStructureKey = StrReplace(Metadata.FindByType(TypeOf(Value)).FullName(), ".", "_");
					If FillingStructure.Property(FillingStructureKey, Values) Then
						Values.Add(Value);
					Else
						Values = New Array;
						Values.Add(Value);
						FillingStructure.Insert(FillingStructureKey, Values);
					EndIf;
				EndIf;
				
			ElsIf Not ExcludedTypes.ContainsType(TypeOf(Value)) Then // Failed passed parameters.
				MessageText = NStr("en = 'Failed to generate the %1 on the base of %2.'");
				MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessageText,
				                                                                       Metadata.FindByType(TypeOf(Ref)).Presentation(),
				                                                                       String(Value));
				CommonUseClientServer.MessageToUser(MessageText, Ref);
			EndIf;
		EndDo;
		
	Else // Assume passed single value.
		
		// Add data source to filling structure.
		Value = FillingData;
		If  BasedOnTypes.ContainsType(TypeOf(Value))
		And Not ExcludedTypes.ContainsType(TypeOf(Value)) Then
			If Not BadSourceRef(Ref, Value) Then
				FillingStructure.Insert(StrReplace(Metadata.FindByType(TypeOf(Value)).FullName(), ".", "_"), Value);
			EndIf;
			
		ElsIf Not ExcludedTypes.ContainsType(TypeOf(Value)) Then // Failed passed parameters
			MessageText = NStr("en = 'Failed to generate the %1 on the base of %2.'");
			MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessageText,
			                                                                       Metadata.FindByType(TypeOf(Ref)).Presentation(),
			                                                                       String(Value));
			CommonUseClientServer.MessageToUser(MessageText, Ref);
		EndIf;
	EndIf;
	
	// Return resulting structure.
	Return FillingStructure;
	
EndFunction

// Checks validity of single passed document Value while filling of referenced document Ref.
//
// Parameters:
//  Ref     - DocumentRef - Reference of document to be filled.
//  Value   - DocumentRef - Filling data, usually Ref of base document.
//
// Returns:
//  Boolean - True: Check failed, Cancel further filling; False: Check passed.
//
Function BadSourceRef(Ref, Value)
	
	// Check reference for deletion mark.
	RefCheckFailed = False;
	If Value.DeletionMark Then
		MessageText = NStr("en = '%1 %2 marked for deletion.'");
		MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessageText,
		                                                                       CommonUse.ObjectKindByType(TypeOf(Value)),
		                                                                       String(Value));
		CommonUseClientServer.MessageToUser(MessageText, Ref,,, RefCheckFailed);
		
		Return True;
	EndIf;
	
	// Check documents posted.
	If Documents.AllRefsType().ContainsType(TypeOf(Value)) And Not Value.Posted Then
		MessageText = NStr("en = 'Document %1 is not posted.'");
		MessageText = StringFunctionsClientServer.SubstituteParametersInString(MessageText,
		                                                                       String(Value));
		CommonUseClientServer.MessageToUser(MessageText, Ref,,, RefCheckFailed);
	EndIf;
	
	Return RefCheckFailed;
	
EndFunction

// Returns localized companies name depending on filling document Ref.
//
// Parameters:
//  Ref    - DocumentRef - Reference of document to be filled.
//
// Returns:
//  String - Localized companies name.
//
Function LocalizedCompaniesName(Ref)
	
	If	// Sales documents.
		TypeOf(Ref) = Type("DocumentRef.CashReceipt") Or
		TypeOf(Ref) = Type("DocumentRef.CashSale") Or
		TypeOf(Ref) = Type("DocumentRef.SalesInvoice") Or
		TypeOf(Ref) = Type("DocumentRef.SalesOrder") Or
		TypeOf(Ref) = Type("DocumentRef.SalesReturn")
	Then
		CompanyName = Lower(GeneralFunctionsReusable.GetCustomerName())+"s";
		
	ElsIf
		// Purchase documents.
		TypeOf(Ref) = Type("DocumentRef.Check") Or
		TypeOf(Ref) = Type("DocumentRef.InvoicePayment") Or
		TypeOf(Ref) = Type("DocumentRef.PurchaseInvoice") Or
		TypeOf(Ref) = Type("DocumentRef.PurchaseOrder") Or
		TypeOf(Ref) = Type("DocumentRef.PurchaseReturn")
	Then
		CompanyName = Lower(GeneralFunctionsReusable.GetVendorName())+"s";
		
	Else
		// All other applications.
		CompanyName = NStr("en = 'Companies'");
	EndIf;
	
	// Return properly localized company name.
	Return CompanyName;
	
EndFunction

#EndRegion
