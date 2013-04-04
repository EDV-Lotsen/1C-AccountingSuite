
////////////////////////////////////////////////////////////////////////////////
// EXPORT PROCEDURES AND FUNCTIONS

// Opens the form with available commands and passes assignement objects and data
// processor type to it.
// It is designed to be a handler of additional reports and data processors commands.
//
// Parameters:        	
//  CommandParameter 		 - Array - infobase objects, for which this command is called
//  CommandExecuteParameters - FormDataStructure - command execution parameters received
//							   	by the form command handler
//  Type 					 - String presentation of data processor type
//  SectionName 			 - String - section name for data processors filtration,
//						 		specified only for global data processors
//
// Returns:
//  No.
//
Function OpenAdditionalReportsAndDataProcessorsCommandListForm(CommandParameter,
												CommandExecuteParameters,
												Type,
												SectionName = "") Export
												
	CommandParameterList = New ValueList;
	
	If TypeOf(CommandParameter) = Type("Array") Then // assigned data processor
		CommandParameterList.LoadValues(CommandParameter);
	EndIf;
	
	Parameters = New Structure("DestinationObjects,Type,SectionName",
							   CommandParameterList,
							   Type,
							   SectionName);
	
	If TypeOf(CommandParameter) = Type("Array") Then // assigned data processor
		Parameters.Insert("FormName", CommandExecuteParameters.Source.FormName);
	EndIf;
	
	OpenFormModal("CommonForm.AdditionalReportsAndDataProcessors",
				  Parameters,
				  CommandExecuteParameters.Source);
	
EndFunction

// Used to manage calls of external reports and data processors.
// Depending on the data processor start variant it either opens the data 
// processor form, or calls form's client method or passes execution to the 
// server for the following call of data processor at server. It also handles
// displaying of notifications and notifications about modified objects.
//
// Parameters:
//  AdditionalDataProcessor - CatalogRef.AdditionalReportsAndDataProcessors
//  DataProcessorType  	 	- String - string presentation of data processor type
//  CommandID 				- String - id of the command
//  SafeMode 				- Boolean - if data processor should be used in safe mode
//  UsageVariant 			- EnumRef.AdditionalDataProcessorsUsageVariants - 
//								data processor usage variant
//  ShowAlert 				- Boolean - if data processor operation start and 
//								end notifications should be displayed. Is not used 
//								if UsageVariant specified as FormOpening
//  Modifier 				- String - modifier of command, used for print forms 
//								based on the spreadsheet document templates: if this
//								parameter is "PrintMXL" the DocumentsPrinting common 
//								form is used for printing
//  DestinationObjectsArray - Array - refs to the infobase objects
//
// Returns:
//  No.
//
Procedure RunDataProcessor(AdditionalDataProcessor,
						   DataProcessorType,
						   CommandID,
						   SafeMode,
						   UsageVariant,
						   ShowAlert,
						   Modifier,
						   DestinationObjectsArray) Export
	
	If UsageVariant = UsageVariantFormOpeninig() Then
		
		RunOpenOfDataProcessorForm(AdditionalDataProcessor,
								   DataProcessorType,
								   CommandID,
								   SafeMode,
								   DestinationObjectsArray);
		
	ElsIf UsageVariant = UsageVariantClientMethodCall() Then
		
		RunClientMethodOfDataProcessor(AdditionalDataProcessor,
									   DataProcessorType,
									   CommandID,
									   SafeMode,
									   ShowAlert,
									   DestinationObjectsArray);
		
	ElsIf UsageVariant = UsageVariantServerMethodCall() Then
		
		RunServerMethodOfDataProcessor(AdditionalDataProcessor,
									   DataProcessorType,
									   CommandID,
									   SafeMode,
									   ShowAlert,
									   Modifier,
									   DestinationObjectsArray);
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// AUXILIARY PROCEDURES AND FUNCTIONS

Function IsGlobalDataProcessorType(TypeString)
	
	Return (TypeString = AdditionalReportsAndDataProcessorsClientServer.DataProcessorTypeAdditionalDataProcessor())
		Or (TypeString = AdditionalReportsAndDataProcessorsClientServer.DataProcessorTypeAdditionalReport());
	
EndFunction

Procedure RunOpenOfDataProcessorForm(
							AdditionalDataProcessor,
							DataProcessorType,
							CommandID,
							SafeMode,
							DestinationObjectsArray)
	
		DataProcessorName = AdditionalReportsAndDataProcessors.AttachAdditionalDataProcessor(AdditionalDataProcessor, SafeMode);
		
		ProcessingParameters = New Structure("CommandID");
		ProcessingParameters.CommandID = CommandID;
		
		If NOT IsGlobalDataProcessorType(DataProcessorType) Then
			ProcessingParameters.Insert("DestinationObjects", DestinationObjectsArray);
		EndIf;
		
		If DataProcessorType = AdditionalReportsAndDataProcessorsClientServer.DataProcessorTypeReport()
			OR DataProcessorType = AdditionalReportsAndDataProcessorsClientServer.DataProcessorTypeAdditionalReport() Then
			OpenForm("ExternalReport."+ DataProcessorName +".Form", ProcessingParameters);
		Else
			OpenForm("ExternalDataProcessor."+ DataProcessorName +".Form", ProcessingParameters);
		EndIf;
	
EndProcedure

Procedure RunClientMethodOfDataProcessor(
							AdditionalDataProcessor,
							DataProcessorType,
							CommandID,
							SafeMode,
							ShowAlert,
							DestinationObjectsArray)
	
		If ShowAlert Then
			ShowUserNotification(NStr("en = 'Executing data processor...'"));
		EndIf;
		
		DataProcessorName = AdditionalReportsAndDataProcessors.AttachAdditionalDataProcessor(AdditionalDataProcessor, SafeMode);
		
		ProcessingParameters = New Structure("CommandID");
		ProcessingParameters.CommandID = CommandID;
		
		If NOT IsGlobalDataProcessorType(DataProcessorType) Then
			ProcessingParameters.Insert("DestinationObjects", DestinationObjectsArray);
		EndIf;
		
		If DataProcessorType = AdditionalReportsAndDataProcessorsClientServer.DataProcessorTypeReport()
			OR DataProcessorType = AdditionalReportsAndDataProcessorsClientServer.DataProcessorTypeAdditionalReport() Then
			DataProcessorForm 	 = GetForm("ExternalReport."+ DataProcessorName +".Form", ProcessingParameters);
		Else
			DataProcessorForm = GetForm("ExternalDataProcessor."+ DataProcessorName +".Form", ProcessingParameters);
		EndIf;
		
		If DataProcessorType = AdditionalReportsAndDataProcessorsClientServer.DataProcessorTypeAdditionalDataProcessor()
		OR DataProcessorType = AdditionalReportsAndDataProcessorsClientServer.DataProcessorTypeAdditionalReport() Then
			
			DataProcessorForm.RunCommand(CommandID);
			
		ElsIf DataProcessorType = AdditionalReportsAndDataProcessorsClientServer.DataProcessorTypeCreatingRelatedObjects() Then
			
			CreatedObjects = New Array;
			
			DataProcessorForm.RunCommand(CommandID, DestinationObjectsArray, CreatedObjects);
			
			TypesOfCreatedObjects = New Array;
			
			For Each ObjectCreated In CreatedObjects Do
				Type = TypeOf(ObjectCreated);
				If TypesOfCreatedObjects.Find(Type) = Undefined Then
					TypesOfCreatedObjects.Add(Type);
				EndIf;
			EndDo;
			
			For Each Type In TypesOfCreatedObjects Do
				NotifyChanged(Type);
			EndDo;
			
		ElsIf DataProcessorType = AdditionalReportsAndDataProcessorsClientServer.DataProcessorTypePrintForm() Then
			
			DataProcessorForm.Print(CommandID, DestinationObjectsArray);
			
		ElsIf DataProcessorType = AdditionalReportsAndDataProcessorsClientServer.DataProcessorTypeObjectFilling() Then
			
			DataProcessorForm.RunCommand(CommandID, DestinationObjectsArray);
			
			TypesOfModifiedObjects = New Array;
			
			For Each ModifiedObject In DestinationObjectsArray Do
				Type = TypeOf(ModifiedObject);
				If TypesOfModifiedObjects.Find(Type) = Undefined Then
					TypesOfModifiedObjects.Add(Type);
				EndIf;
			EndDo;
		
			For Each Type In TypesOfModifiedObjects Do
				NotifyChanged(Type);
			EndDo;
			
		ElsIf DataProcessorType = AdditionalReportsAndDataProcessorsClientServer.DataProcessorTypeReport() Then
			
			DataProcessorForm.RunCommand(CommandID, DestinationObjectsArray);
			
		EndIf;
		
		If ShowAlert Then
			ShowUserNotification(NStr("en = 'Data processor completed...'"));
		EndIf;
	
EndProcedure

Procedure RunServerMethodOfDataProcessor(
							AdditionalDataProcessor,
							DataProcessorType,
							CommandID,
							SafeMode,
							ShowAlert,
							Modifier,
							DestinationObjectsArray)
	
		If ShowAlert Then
			ShowUserNotification(NStr("en = 'Executing data processor...'"));
		EndIf;
		
		If DataProcessorType = AdditionalReportsAndDataProcessorsClientServer.DataProcessorTypeAdditionalDataProcessor()
		   Or DataProcessorType = AdditionalReportsAndDataProcessorsClientServer.DataProcessorTypeAdditionalReport() Then
			
			AdditionalReportsAndDataProcessors.RunDataProcessorDirectly(AdditionalDataProcessor, CommandID, SafeMode);
			
		ElsIf DataProcessorType = AdditionalReportsAndDataProcessorsClientServer.DataProcessorTypeCreatingRelatedObjects() Then
			
			TypesOfCreatedObjects = New Array;
			
			AdditionalReportsAndDataProcessors.RunDataProcessorDirectly(AdditionalDataProcessor, CommandID, SafeMode, DestinationObjectsArray, TypesOfCreatedObjects);
			
			For Each Type In TypesOfCreatedObjects Do
				NotifyChanged(Type);
			EndDo;
			
		ElsIf DataProcessorType = AdditionalReportsAndDataProcessorsClientServer.DataProcessorTypePrintForm()
			  And Modifier = "PrintMXL" Then
			
			SourceParameters = New Structure;
			SourceParameters.Insert("CommandID", 		  CommandID);
			SourceParameters.Insert("DestinationObjects", DestinationObjectsArray);
			SourceParameters.Insert("SafeMode", 		  SafeMode);
			
			OpenParameters = New Structure("DataSource,SourceParameters");
			OpenParameters.DataSource = AdditionalDataProcessor;
			OpenParameters.SourceParameters = SourceParameters;
			
			OpenForm("CommonForm.DocumentsPrinting", OpenParameters);
			
		ElsIf DataProcessorType = AdditionalReportsAndDataProcessorsClientServer.DataProcessorTypeObjectFilling() Then
			
			ModifiedObjects = New Array;
			
			AdditionalReportsAndDataProcessors.RunDataProcessorDirectly(AdditionalDataProcessor, CommandID, SafeMode, DestinationObjectsArray, ModifiedObjects);
			
			For Each Type In ModifiedObjects Do
				NotifyChanged(Type);
			EndDo;
			
		ElsIf DataProcessorType = AdditionalReportsAndDataProcessorsClientServer.DataProcessorTypePrintForm()
		 OR DataProcessorType = AdditionalReportsAndDataProcessorsClientServer.DataProcessorTypeReport() Then
			
			AdditionalReportsAndDataProcessors.RunDataProcessorDirectly(AdditionalDataProcessor, CommandID, SafeMode, DestinationObjectsArray);
			
		EndIf;
		
		If ShowAlert Then
			ShowUserNotification(NStr("en = 'Data processor completed...'"));
		EndIf;
	
EndProcedure

Function UsageVariantClientMethodCall()
	
	Return "CallClientMethod";
	
EndFunction

Function UsageVariantServerMethodCall()
	
	Return "CallServerMethod";
	
EndFunction

Function UsageVariantFormOpeninig()
	
	Return "FormOpening";
	
EndFunction
