

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	AddressRef	= Parameters.AddressRef;
	
	If Parameters.Property("OriginalAddress") Then
		OriginalAddress = Parameters.OriginalAddress;
		AddressLine1 	= OriginalAddress.AddressLine1;
		AddressLine2 	= OriginalAddress.AddressLine2;
		AddressLine3 	= OriginalAddress.AddressLine3;
		City			= OriginalAddress.City;
		Region			= OriginalAddress.State.Code;
		Country			= OriginalAddress.Country.Code;
		PostalCode		= OriginalAddress.ZIP;
		AvataxValidateAddressAtServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure AvataxValidateAddressAtServer()
	
	// Set request parameters.
	RequestParameters = New Structure;
	RequestParameters.Insert("Line1", AddressLine1);
	RequestParameters.Insert("Line2", AddressLine2);
	RequestParameters.Insert("Line3", AddressLine3);
	RequestParameters.Insert("City", City);
	RequestParameters.Insert("Region", Region);
	RequestParameters.Insert("Country", Country);
	RequestParameters.Insert("PostalCode", PostalCode);
	
	DecodedBody = AvaTaxServer.SendRequestToAvalara(Enums.AvalaraRequestTypes.AddressValidation, RequestParameters, AddressRef);
	
	If DecodedBody.Successful Then
		
		AddressDetails = New Structure("Line1, Line2, Line3, City, Region, Country, AddressType, PostalCode, County, FIPSCode, PostNet, TaxRegionID");
		AvaTaxServer.ReadStructureValuesSafely(DecodedBody.Address, AddressDetails);
	
		ValidatedAddressLine1 	= AddressDetails.Line1;
		ValidatedAddressLine2 	= AddressDetails.Line2;
		ValidatedAddressLine3 	= AddressDetails.Line3;
		ValidatedCity			= AddressDetails.City;
		ValidatedRegion			= AddressDetails.Region;
		ValidatedCountry		= AddressDetails.Country;
		ValidatedCounty			= AddressDetails.County;
		ValidatedAddressType	= AddressDetails.AddressType;
		If ValidatedAddressType = "B" Then
			Items.AddressTypeDescription.Title = " - PO Box";
		ElsIf ValidatedAddressType = "C" Then
			Items.AddressTypeDescription.Title = " - City delivery";
		ElsIf ValidatedAddressType = "G" Then
			Items.AddressTypeDescription.Title = " - General delivery";
		ElsIf ValidatedAddressType = "H" Then
			Items.AddressTypeDescription.Title = " - Highway contract";
		ElsIf ValidatedAddressType = "R" Then
			Items.AddressTypeDescription.Title = " - Rural route";			
		EndIf;
		ValidatedPostalCode		= AddressDetails.PostalCode;
		ValidatedFIPSCode		= AddressDetails.FIPSCode;
		ValidatedPostNet		= AddressDetails.PostNet;
		ValidatedTaxRegionID	= AddressDetails.TaxRegionID; 
		
	Else
		
		ErrorOccured = True;
		ErrorMessage = DecodedBody.ErrorMessage;
		
	EndIf;

EndProcedure

&AtClient
Procedure Accept(Command)
	ValidatedAddress = New Structure();
	ValidatedAddress.Insert("AddressLine1", ValidatedAddressLine1);
	ValidatedAddress.Insert("AddressLine2", ValidatedAddressLine2);
	ValidatedAddress.Insert("AddressLine3", ValidatedAddressLine3);
	ValidatedAddress.Insert("City", ValidatedCity);
	ValidatedAddress.Insert("RegionCode", ValidatedRegion);
	ValidatedAddress.Insert("CountryCode", ValidatedCountry);
	ValidatedAddress.Insert("ZIP", ValidatedPostalCode);
	CloseParameters = New Structure("ValidatedAddress", ValidatedAddress);
	Close(CloseParameters);
EndProcedure


&AtClient
Procedure OnOpen(Cancel)
	If ErrorOccured Then
		CommonUseClient.ShowCustomMessageBox(ThisForm, "Address validation", ErrorMessage, PredefinedValue("Enum.MessageStatus.Warning"));
		ErrorOccured = False;
		ErrorMessage = "";
	EndIf;
EndProcedure


&AtClient
Procedure ValidateAddress(Command)
	AvataxValidateAddressAtServer();
	If ErrorOccured Then
		CommonUseClient.ShowCustomMessageBox(ThisForm, "Address validation", ErrorMessage, PredefinedValue("Enum.MessageStatus.Warning"));
		ErrorOccured = False;
		ErrorMessage = "";
	EndIf;
EndProcedure


