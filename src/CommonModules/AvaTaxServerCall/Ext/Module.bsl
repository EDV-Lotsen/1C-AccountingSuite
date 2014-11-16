////////////////////////////////////////////////////////////////////////////////
//  Methods, implementing tax calculation at Avalara
//  
////////////////////////////////////////////////////////////////////////////////

Function GetLastAvataxDocCode(ObjectRef) Export
	
	LastAvataxDocCode 			= AvaTaxServer.GetLastAvataxDocCode(ObjectRef);
	DocumentIsPresentAtAvatax 	= AvaTaxServer.IsDocumentPresentAtAvatax(ObjectRef);
	DocumentStatus				= AvaTAxServer.GetLastAvataxDocumentStatus(ObjectRef);
	return New Structure("LastAvataxDocCode, DocumentIsPresentAtAvatax, LastAvataxDocumentStatus", LastAvataxDocCode, DocumentIsPresentAtAvatax, DocumentStatus);
	
EndFunction
