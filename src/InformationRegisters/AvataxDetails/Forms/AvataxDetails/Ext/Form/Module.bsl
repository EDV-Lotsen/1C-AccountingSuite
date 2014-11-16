
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ObjectRef = Parameters.ObjectRef;
	If Not ValueIsFilled(ObjectRef) Then
		Cancel = True;
		return;
	EndIf;
	Request = New Query("SELECT
	                    |	TaxDetailsTable.TimeStamp,
	                    |	TaxDetailsTable.TaxDetails,
	                    |	TaxDetailsTable.Status,
	                    |	AvalaraTransactions.RequestParameters
	                    |FROM
	                    |	(SELECT
	                    |		AvataxDetails.TimeStamp AS TimeStamp,
	                    |		AvataxDetails.TaxDetails AS TaxDetails,
	                    |		AvataxDetails.Status AS Status,
	                    |		AvataxDetails.TransactionID AS TransactionID
	                    |	FROM
	                    |		InformationRegister.AvataxDetails AS AvataxDetails
	                    |	WHERE
	                    |		AvataxDetails.ObjectRef = &ObjectRef) AS TaxDetailsTable
	                    |		LEFT JOIN InformationRegister.AvalaraTransactions AS AvalaraTransactions
	                    |		ON TaxDetailsTable.TransactionID = AvalaraTransactions.TransactionID
	                    |			AND (AvalaraTransactions.RequestType = VALUE(Enum.AvalaraRequestTypes.TaxCalculation))");
	Request.SetParameter("ObjectRef", Parameters.ObjectRef);
	Res = Request.Execute();
	If Res.IsEmpty() Then
		Cancel = True;
		return;
	EndIf;
	Sel = Res.Select();
	Sel.Next();
	TimeStamp = Sel.TimeStamp;
	Status = Sel.Status;
	LastTaxDetails = Sel.TaxDetails.Get();
	LastTaxLines = LastTaxDetails.TaxLines;
	RequestParameters = Sel.RequestParameters;
	LastLineParameters = Undefined;
	If ValueIsFilled(RequestParameters) Then
		RPValue = RequestParameters.Get();
		If RPValue.Property("RequestParameters") Then
			LastLineParameters = RPValue.RequestParameters.Lines;
		EndIf;
	EndIf;
	For Each LastTaxLine In LastTaxLines Do
		NewTaxLine = TaxLines.Add();
		FillPropertyValues(NewTaxLine, LastTaxLine);
		If Find(LastTaxLine.LineNo, "Shipping") Then
			NewTaxLine.ProductDescription = "Shipping";
			NewTaxLine.DocumentLineNo = LastTaxLines.Count();
		Else
			NewTaxLine.DocumentLineNo = LastTaxLine.LineNo;
		EndIf;
		NewTaxLine.Rate = NewTaxLine.Rate * 100;
		For Each LastTaxDetail In LastTaxLine.TaxDetails Do
			NewTaxDetail = TaxDetails.Add();
			FillPropertyValues(NewTaxDetail, LastTaxDetail);
			NewTaxDetail.LineNo = LastTaxLine.LineNo;
			NewTaxDetail.Rate 	= NewTaxDetail.Rate * 100;
		EndDo;
		//Filling Product and ProductDescription
		//These fields are in the request parameters (sent to AvaTax)
		If LastLineParameters <> Undefined Then
			LineParametersFound = Undefined;
			For Each LineParam In LastLineParameters Do
				If LineParam.LineNo = LastTaxLine.LineNo  Then
					LineParametersFound = LineParam;
					Break;
				EndIf;
			EndDo;
			If LineParametersFound <> Undefined Then
				NewTaxLine.Product = LineParametersFound.ItemCode;
				NewTaxLine.ProductDescription = LineParametersFound.Description;
				If Find(NewTaxLine.Product, "Shipping") Then
					NewTaxLine.Product = "Shipping";
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	TaxLines.Sort("DocumentLineNo");
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	ThisForm.Title = "Tax detail for the " + String(ObjectRef) + ". Calculated on " + Format(ToLocalTime(TimeStamp), "DLF=");
EndProcedure

&AtClient
Procedure TaxLinesOnActivateRow(Item)
	If Items.TaxLines.CurrentData <> Undefined Then
		Items.TaxDetails.RowFilter = New FixedStructure("LineNo", Items.TaxLines.CurrentData.LineNo);
	EndIf;
EndProcedure

