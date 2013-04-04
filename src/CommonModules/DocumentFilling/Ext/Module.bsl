
////////////////////////////////////////////////////////////////////////////////
// Document filling: Server call
//------------------------------------------------------------------------------
// Available on:
// - Server
// - Server call from client
//

////////////////////////////////////////////////////////////////////////////////
// INTERNAL PRIVATE FUNCTIONS

// Creates structure containing types of filling (as keys) and filling data (as values).
// 
// Parameters:
// 	FillingData      - Passed filling data, usually Ref to base document or an array of Refs to fill from
// 	BasedOn          - Metadata of document, containing list of data sources, to fill document from
//  ExcludedTypesStr - Comma-separated string containing base reference types to skip during filling
//
// Value returned:
// 	Structure of filling data - types and data to fill
//
Function GetTypedFillingStructure(Ref, FillingData, BasedOn, ExcludedTypesStr = Undefined)
	Var Values;

	// Create returning structure
	FillingStructure = New Structure;
	
	// Create description of available filling types
	ArrayOfBasedOnTypes = New Array;
	For Each Base In BasedOn Do
		ArrayOfBasedOnTypes.Add(Type(StrReplace(Base.FullName(), ".", "Ref.")));
	EndDo;
	BasedOnTypes = New TypeDescription(ArrayOfBasedOnTypes);
	
	// Create description of excluded filling types
	ArrayOfExcludedTypes = New Array;
	ListOfExcludedTypes  = StringFunctionsClientServer.DecomposeStringIntoSubstringsArray(ExcludedTypesStr);
	For Each ExcludedType In ListOfExcludedTypes Do
		ArrayOfExcludedTypes.Add(Type(StrReplace(ExcludedType, ".", "Ref.")));
	EndDo;
	ExcludedTypes = New TypeDescription(ArrayOfExcludedTypes);
	
	// Universal value collections
	If TypeOf(FillingData) = Type("Array") 
	Or TypeOf(FillingData) = Type("Structure")
	Or TypeOf(FillingData) = Type("Map")
	Then
	
		// Determine type of values
		For Each Data In FillingData Do
			
			// Define filling value
			If TypeOf(Data) = Type("KeyAndValue") Then
				Value = Data.Value;
			Else
				Value = Data;
			EndIf;
			
			// Add data source to filling structure
			If  BasedOnTypes.ContainsType(TypeOf(Value))
			And Not ExcludedTypes.ContainsType(TypeOf(Value)) Then
			
				If Not CheckSingleValue(Ref, Value) Then
					FillingStructureKey = StrReplace(Metadata.FindByType(TypeOf(Value)).FullName(), ".", "_");
					If FillingStructure.Property(FillingStructureKey, Values) Then
						Values.Add(Value);
					Else
						Values = New Array;
						Values.Add(Value);
						FillingStructure.Insert(FillingStructureKey, Values);
					EndIf;
				EndIf;
				
			ElsIf Not ExcludedTypes.ContainsType(TypeOf(Value)) Then // Failed passed parameters
				MessageText = NStr("en = 'Failed to generate the %1 on the base of %2.'");
				MessageText = StringFunctionsClientServer.SubstitureParametersInString(MessageText,
				                                                                       Metadata.FindByType(TypeOf(Ref)).Presentation(),
																					   String(Value)); 
				CommonUseClientServer.MessageToUser(MessageText, Ref);
			EndIf;
		EndDo;
		
	Else // Assume passed single value
			
		// Add data source to filling structure
		Value = FillingData;
		If  BasedOnTypes.ContainsType(TypeOf(Value))
		And Not ExcludedTypes.ContainsType(TypeOf(Value)) Then
			If Not CheckSingleValue(Ref, Value) Then
				FillingStructure.Insert(StrReplace(Metadata.FindByType(TypeOf(Value)).FullName(), ".", "_"), Value);
			EndIf;
			
		ElsIf Not ExcludedTypes.ContainsType(TypeOf(Value)) Then // Failed passed parameters
			MessageText = NStr("en = 'Failed to generate the %1 on the base of %2.'");
			MessageText = StringFunctionsClientServer.SubstitureParametersInString(MessageText,
			                                                                       Metadata.FindByType(TypeOf(Ref)).Presentation(),
																				   String(Value)); 
			CommonUseClientServer.MessageToUser(MessageText, Ref);
		EndIf;
	EndIf;
	
	// Return resulting structure
	Return FillingStructure;
	
EndFunction

// Checks single passed referencial Value while filling of Ref
Function CheckSingleValue(Ref, Value)
	
	// Check references for deletion mark
	RefCheckFailed = False;
	If Value.DeletionMark Then
		MessageText = NStr("en = '%1 %2 marked for deletion.'");
		MessageText = StringFunctionsClientServer.SubstitureParametersInString(MessageText,
		                                                                       CommonUse.ObjectClassByType(TypeOf(Ref)),
																			   String(Value)); 
		CommonUseClientServer.MessageToUser(MessageText, Ref,,, RefCheckFailed);
		
		Return True;
	EndIf;
	
	// Check documents posted
	If Documents.AllRefsType().ContainsType(TypeOf(Value)) And Not Value.Posted Then
		MessageText = NStr("en = 'Document %1 is not posted.'");
		MessageText = StringFunctionsClientServer.SubstitureParametersInString(MessageText,
																			   String(Value)); 
		CommonUseClientServer.MessageToUser(MessageText, Ref,,, RefCheckFailed);
	EndIf;
	
	Return RefCheckFailed;
EndFunction

////////////////////////////////////////////////////////////////////////////////
// EXPORTED PUBLIC FUNCTIONS

//------------------------------------------------------------------------------
// Preparing the document data before filling an object

// Save additional document parameters required for data query before filling an object
//
// Parameters:
// 	AdditionalProperties - Structure of additional object parameters containing required attributes and tables
// 	DocumentParameters	 - Structure of object attributes, inaccessible on the server call to be packed into AdditionalProperties
//  FillingData          - Arbitrary, source data for filling the document, usually Ref to a base document
//  Cancel               - Boolean, flag of cancel document filling
//
Procedure PrepareDataStructuresBeforeFilling(AdditionalProperties, DocumentParameters, FillingData, Cancel) Export
	WarnOnNoData = False;
	
	// Check filling data according to BasedOn types
	TypedFillingData = GetTypedFillingStructure(DocumentParameters.Ref, FillingData, DocumentParameters.Metadata.BasedOn);
	If TypedFillingData.Count() = 0 Then
		If WarnOnNoData Then
			MessageText = NStr("en = 'Failed to generate the %1, filling data is not provided.'");
			MessageText = StringFunctionsClientServer.SubstitureParametersInString(MessageText,
			                                                                       DocumentParameters.Metadata.Presentation()); 
			CommonUseClientServer.MessageToUser(MessageText, DocumentParameters.Ref,,, Cancel);
		Else // Forced setting of cancel
			Cancel = True;
		EndIf;
		
		Return;
	EndIf;
	
	// Cache document attributes minimizing data requests - pack posting parameters into AdditionalProperties
	For Each DocumentParameter In DocumentParameters Do
		AdditionalProperties.Insert(DocumentParameter.Key, DocumentParameter.Value);
	EndDo;
	
	// Posting - Structure containing data to be transferred on the server and post the document
	AdditionalProperties.Insert("Filling", New Structure);
	
	// Specify source data for filling the document
	AdditionalProperties.Filling.Insert("FillingData", TypedFillingData);
	
	// FillingTables - Structure containing document tables data for filling the document
	AdditionalProperties.Filling.Insert("FillingTables", New Structure);

	// TempTablesManager - Temporary tables manager, containing document data requested for creating document postings.
	AdditionalProperties.Filling.Insert("StructTempTablesManager", New Structure("TempTablesManager", New TempTablesManager));
	
EndProcedure

// Clear used additional document data passed as additional properties.
//
// Parameters:
// 	AdditionalProperties - Structure of additional object parameters (to be cleared)
//
Procedure ClearDataStructuresAfterFilling(AdditionalProperties) Export

	// Dispose used temporary tables managers
	AdditionalProperties.Filling.StructTempTablesManager.TempTablesManager.Close();

EndProcedure

//------------------------------------------------------------------------------
// Check document data consistency during filling an object

// Check documents attributes uniqueness on filling an object
//
// Parameters:
// 	AdditionalProperties - Structure of additional object parameters containing required attributes and tables
//  Cancel               - Boolean, flag of cancel document filling
//
Procedure CheckDataStructuresOnFilling(AdditionalProperties, Cancel) Export
	Var TableCheck, CheckAttributes;
	
	// Get table of grouped attributes
	AdditionalProperties.Filling.FillingTables.Property("Table_Check", TableCheck);
	AdditionalProperties.Filling.Property("CheckAttributes", CheckAttributes);
	
	// Check quantity of grouped strings (versions of a header)
	HeaderVersionsCount = TableCheck.Count();
	If HeaderVersionsCount = 0 Then
		MessageText = NStr("en = 'Failed to generate the %1, filling data is not suitable for filling.'");
		MessageText = StringFunctionsClientServer.SubstitureParametersInString(MessageText,
		                                                                       AdditionalProperties.Metadata.Presentation()); 
		CommonUseClientServer.MessageToUser(MessageText, AdditionalProperties.Ref,,, Cancel);
		
	ElsIf (HeaderVersionsCount > 0) And (CheckAttributes.Count() > 0) Then
		DisplayCodes  = GeneralFunctionsReusable.FunctionalOptionValue("DisplayCodes");
		CompaniesName = Lower(GeneralFunctionsReusable.GetCustomerName())+"s";
		For Each Attribute In CheckAttributes Do
			If Attribute.Value <> "Check" Then Continue; EndIf;
			
			// Check uniqueness by selected attributess
			Selection = TableCheck.Copy(, Attribute.Key);
			Selection.GroupBy(Attribute.Key);
			If Selection.Count() > 1 Then // Double found
				
				// Convert value to it's presentation
				DoublesText = "";
				For Each Row In Selection Do
					
					// Convert value to it's presentation
					Value = Row[Attribute.Key];
					If TypeOf(Value) = Type("CatalogRef.Companies") Then
						Presentation = ?(DisplayCodes, TrimAll(Value.Code) + " ", "") + TrimAll(Value.Description);
						
					ElsIf TypeOf(Value) = Type("CatalogRef.Products") Then
						Presentation = TrimAll(Value.Code) + " " + TrimAll(Value.Description);
						
					Else
						Presentation = TrimAll(Value);
					EndIf;
					
					// Generate doubled items text
					DoublesText = DoublesText + ?(IsBlankString(DoublesText), "", ", ") + " """ + Presentation + """";
				EndDo;
				
				MessageText  = NStr("en = 'Selected documents have different %1: %2'");
				MessageText  = StringFunctionsClientServer.SubstitureParametersInString(MessageText,
				               ?(Attribute.Key = "Company", CompaniesName, Lower(AdditionalProperties.Metadata.Attributes[Attribute.Key].Synonym) + " values"),
							   DoublesText); 
				CommonUseClientServer.MessageToUser(MessageText, AdditionalProperties.Ref,,, Cancel);
			EndIf;
		EndDo;
	EndIf;
		
EndProcedure
