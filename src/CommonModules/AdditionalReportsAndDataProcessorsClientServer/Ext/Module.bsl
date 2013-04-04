// Identifiers of additional data processor types

// The print form data processor identifier
//
Function DataProcessorTypePrintForm() Export
	
	Return "PrintForm"; // not localized
	
EndFunction

// The object filling data processor identifier
//
Function DataProcessorTypeObjectFilling() Export
	
	Return "ObjectFilling"; // not localized
	
EndFunction

// The related objects creating data processor identifier
//
Function DataProcessorTypeCreatingRelatedObjects() Export
	
	Return "CreateLinkedObjects"; // not localized
	
EndFunction

// The report identifier
//
Function DataProcessorTypeReport() Export
	
	Return "Report"; // not localized
	
EndFunction

// The global data processor identifier
//
Function DataProcessorTypeAdditionalDataProcessor() Export
	
	Return "AdditionalDataProcessor"; // not localized
	
EndFunction

// The global report identifier
//
Function DataProcessorTypeAdditionalReport() Export
	
	Return "AdditionalReport"; // not localized
	
EndFunction
