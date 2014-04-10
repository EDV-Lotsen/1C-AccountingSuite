
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
	If Not (ValueIsFilled(Object.AccountingBasis) And ValueIsFilled(Object.SalesTaxAgency) And ValueIsFilled(Object.TaxPeriodEnding)) Then
		return;
	EndIf;
	If Object.Payment = 0 Then
		Object.Payment = GetSalesTaxOwedAmount(Object.SalesTaxAgency, Object.TaxPeriodEnding, Object.AccountingBasis);
	EndIf;
EndProcedure

&AtServerNoContext
Function GetSalesTaxOwedAmount(Agency, TaxPeriod, ChargeType)
	Request = New Query("SELECT ALLOWED
	                    |	SalesTaxRates.Ref
	                    |INTO TaxRates
	                    |FROM
	                    |	Catalog.SalesTaxRates AS SalesTaxRates
	                    |WHERE
	                    |	SalesTaxRates.Agency = &Agency
	                    |;
	                    |
	                    |////////////////////////////////////////////////////////////////////////////////
	                    |SELECT ALLOWED
	                    |	SalesTaxOwedBalance.TaxPayableBalance
	                    |FROM
	                    |	AccumulationRegister.SalesTaxOwed.Balance(
	                    |			,
	                    |			Agency IN
	                    |					(SELECT
	                    |						TaxRates.Ref
	                    |					FROM
	                    |						TaxRates)
	                    |				AND TaxPeriod <= &TaxPeriod
	                    |				AND ChargeType = &ChargeType) AS SalesTaxOwedBalance");	
	Request.SetParameter("Agency", Agency);
	Request.SetParameter("TaxPeriod", TaxPeriod);
	Request.SetParameter("ChargeType", ChargeType);
	Sel = Request.Execute().Select();
	SalesTaxAmountOwed = 0;
	If Sel.Next() Then
		SalesTaxAmountOwed = Sel.TaxPayableBalance;
	EndIf;
	return SalesTaxAmountOwed;
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
