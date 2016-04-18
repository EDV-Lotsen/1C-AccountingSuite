
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Items.AdjustmentGroup.Enabled = Object.MadeAdjustment;
	If Not ValueIsFilled(Object.AccountingBasis) Then
		Object.AccountingBasis = Enums.AccountingMethod.Accrual;
	EndIf;
	FillFrom = ?(Object.AccountingBasis = Enums.AccountingMethod.Accrual, "Accrual", "Cash");
	
	If ValueIsFilled(Object.Ref) Then
		//Auto fill current balances
		ReturnStructure = GetSalesTaxOwedAmount(Object.SalesTaxAgency, Object.TaxPeriodEnding);
		AccrualBalance 	= ReturnStructure.Accrual;
		CashBalance 	= ReturnStructure.Cash;
	EndIf;
EndProcedure

&AtClient
Procedure MadeAdjustmentOnChange(Item)
	Items.AdjustmentGroup.Enabled = Object.MadeAdjustment;
EndProcedure

&AtClient
Procedure PaymentOnChange(Item)
	RecalculateTotalPayment();
EndProcedure

&AtClient
Procedure RecalculateTotalPayment()
	Object.TotalPayment = Object.Payment + ?(Object.MadeAdjustment, Object.AdjustmentAmount, 0);
EndProcedure

&AtClient 
Procedure GetSalesTaxOwed()
	If Not ( ValueIsFilled(Object.SalesTaxAgency) And ValueIsFilled(Object.TaxPeriodEnding)) Then
		return;
	EndIf;
	If Object.Payment = 0 Then
		ReturnStructure = GetSalesTaxOwedAmount(Object.SalesTaxAgency, Object.TaxPeriodEnding);
		AccrualBalance 	= ReturnStructure.Accrual;
		CashBalance 	= ReturnStructure.Cash;
		Object.Payment = ?(Object.AccountingBasis = PredefinedValue("Enum.AccountingMethod.Accrual"), AccrualBalance, CashBalance);
		RecalculateTotalPayment();
	EndIf;
EndProcedure

&AtServerNoContext
Function GetSalesTaxOwedAmount(Agency, TaxPeriod)
	Request = New Query("SELECT ALLOWED
	                    |	SalesTaxOwedBalance.ChargeType,
	                    |	SalesTaxOwedBalance.TaxPayableBalance
	                    |FROM
	                    |	AccumulationRegister.SalesTaxOwed.Balance(&EndOfMonth, Agency = &Agency) AS SalesTaxOwedBalance");	
	Request.SetParameter("Agency", Agency);
	Request.SetParameter("EndOfMonth", EndOfMonth(TaxPeriod));
	Sel = Request.Execute().Select();
	ReturnStructure = New Structure("Accrual, Cash", 0,0);
	While Sel.Next() Do
		If Sel.ChargeType = Enums.AccountingMethod.Accrual Then
			ReturnStructure.Accrual = Sel.TaxPayableBalance;
		ElsIf Sel.ChargeType = Enums.AccountingMethod.Cash Then
			ReturnStructure.Cash = Sel.TaxPayableBalance;
		EndIf;
	EndDo;
	return ReturnStructure;
EndFunction

&AtClient
Procedure AdjustmentAmountOnChange(Item)
	RecalculateTotalPayment();
EndProcedure

&AtClient
Procedure SalesTaxAgencyOnChange(Item)
	GetSalesTaxOwed();
EndProcedure

&AtClient
Procedure TaxPeriodEndingOnChange(Item)
	GetSalesTaxOwed();
EndProcedure

&AtClient
Procedure AccountingBasisOnChange(Item)
	GetSalesTaxOwed();
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	//Closing period
	If PeriodClosingServerCall.DocumentPeriodIsClosed(Object.Ref, Object.Date) Then
		Cancel = Not PeriodClosingServerCall.DocumentWritePermitted(WriteParameters);
		If Cancel Then
			If WriteParameters.Property("PeriodClosingPassword") And WriteParameters.Property("Password") Then
				If WriteParameters.Password = TRUE Then //Writing the document requires a password
					ShowMessageBox(, "Invalid password!",, "Closed period notification");
				EndIf;
			Else
				Notify = New NotifyDescription("ProcessUserResponseOnDocumentPeriodClosed", ThisObject, WriteParameters);
				Password = "";
				OpenForm("CommonForm.ClosedPeriodNotification", New Structure, ThisForm,,,, Notify, FormWindowOpeningMode.LockOwnerWindow);
			EndIf;
			return;
		EndIf;
	EndIf;

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	//Period closing
	If PeriodClosingServerCall.DocumentPeriodIsClosed(CurrentObject.Ref, CurrentObject.Date) Then
		PermitWrite = PeriodClosingServerCall.DocumentWritePermitted(WriteParameters);
		CurrentObject.AdditionalProperties.Insert("PermitWrite", PermitWrite);	
	EndIf;

EndProcedure

//Closing period
&AtClient
Procedure ProcessUserResponseOnDocumentPeriodClosed(Result, Parameters) Export
	If (TypeOf(Result) = Type("String")) Then //Inserted password
		Parameters.Insert("PeriodClosingPassword", Result);
		Parameters.Insert("Password", TRUE);
		Write(Parameters);
	ElsIf (TypeOf(Result) = Type("DialogReturnCode")) Then //Yes, No or Cancel
		If Result = DialogReturnCode.Yes Then
			Parameters.Insert("PeriodClosingPassword", "Yes");
			Parameters.Insert("Password", FALSE);
			Write(Parameters);
		EndIf;
	EndIf;	
EndProcedure

&AtClient
Procedure FillFromOnChange(Item)
	Object.AccountingBasis 	= ?(FillFrom = "Accrual", PredefinedValue("Enum.AccountingMethod.Accrual"), PredefinedValue("Enum.AccountingMethod.Cash"));
	Object.Payment			= ?(FillFrom = "Accrual", AccrualBalance, CashBalance);
	RecalculateTotalPayment();
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	ReturnStructure = GetSalesTaxOwedAmount(Object.SalesTaxAgency, Object.TaxPeriodEnding);
	AccrualBalance 	= ReturnStructure.Accrual;
	CashBalance 	= ReturnStructure.Cash;
EndProcedure

&AtClient
Procedure AuditLogRecords(Command)
	
	FormParameters = New Structure();	
	FltrParameters = New Structure();
	FltrParameters.Insert("DocUUID", String(Object.Ref.UUID()));
	FormParameters.Insert("Filter", FltrParameters);
	OpenForm("CommonForm.AuditLogList",FormParameters, Object.Ref);

EndProcedure
