

// Function generating print form using external source.
// DataSource       	- Arbitrary - data source
// SourceParameters 	- Arbitrary - print source parameters
//
// parameters, being filled in function:
// PrintFormsCollection - ValueTable - table of print forms,
//					      			   structure matches the one, that is generated on printing
// 						               in normal way
// PrintObjects 		- ValueList - list of objects for printing
// OutputParameters 	- Structure - keys and values matches those,
//									  that are generated on printing in normal way
//
Function PrintFromExternalDataSource(DataSource,
							   SourceParameters,
							   PrintFormsCollection,
							   PrintObjects,
							   OutputParameters) Export
	
	// AdditionalReportsAndDataProcessors
	If TypeOf(DataSource) = Type("CatalogRef.AdditionalReportsAndDataProcessors") Then
		AdditionalReportsAndDataProcessors.PrintFromExternalDataSource(
			DataSource, SourceParameters, PrintFormsCollection, PrintObjects, OutputParameters);
		Return True;
	EndIf;
	// End AdditionalReportsAndDataProcessors
	
	Return False;
	
EndFunction
