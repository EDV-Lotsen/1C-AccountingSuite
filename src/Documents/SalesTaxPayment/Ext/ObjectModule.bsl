
Procedure Posting(Cancel, PostingMode)
	//Clear register records
	For Each RecordSet In RegisterRecords Do
		RecordSet.Read();
		If RecordSet.Count() > 0 Then
			RecordSet.Write = True;
			RecordSet.Clear();
			RecordSet.Write();
		EndIf;
	EndDo;

	////General Journal postings
	//RegisterRecords.GeneralJournal.Write = True;
	//
	//TaxPayableAccount = Constants.TaxPayableAccount.Get();
	//
	////Regular records
	//Record = RegisterRecords.GeneralJournal.AddDebit();
	//Record.Account = TaxPayableAccount;
	//Record.Period = Date;
	//Record.AmountRC = TotalPayment;
	//
	//--//GJ++
	//ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, Null, Null, Null);
	//--//GJ--
	//
	//Record = RegisterRecords.GeneralJournal.AddCredit();
	//Record.Account = BankAccount;
	//Record.Period = Date;
	//Record.AmountRC = TotalPayment;
	//
	//--//GJ++
	//ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, Null, Null, Null);
	//--//GJ--
	//
	////Adjustment records
	//	
	//If MadeAdjustment = True Then
	//	If AdjustmentAmount < 0 Then
	//		
	//		Record = RegisterRecords.GeneralJournal.AddDebit();
	//		Record.Account = TaxPayableAccount;
	//		Record.Period = Date;
	//		Record.AmountRC = -1 * AdjustmentAmount;
	//
	//		//--//GJ++
	//		ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, Null, Null, Null);
	//		//--//GJ--
	//
	//		Record = RegisterRecords.GeneralJournal.AddCredit();
	//		Record.Account = AdjustmentAccount;
	//		Record.Period = Date;
	//		Record.AmountRC = -1 * AdjustmentAmount;
	//
	//		//--//GJ++
	//		ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, Null, Null, Null);
	//		//--//GJ--
	//		
	//	ElsIf AdjustmentAmount > 0 Then
	//		
	//		Record = RegisterRecords.GeneralJournal.AddDebit();
	//		Record.Account = AdjustmentAccount;
	//		Record.Period = Date;
	//		Record.AmountRC = AdjustmentAmount;
	//
	//		//--//GJ++
	//		ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, Null, Null, Null);
	//		//--//GJ--
	//
	//		Record = RegisterRecords.GeneralJournal.AddCredit();
	//		Record.Account = TaxPayableAccount;
	//		Record.Period = Date;
	//		Record.AmountRC = AdjustmentAmount;
	//
	//		//--//GJ++
	//		ReconciledDocumentsServerCall.AddRecordForGeneralJournalAnalyticsDimensions(RegisterRecords, Record, Null, Null, Null);
	//		//--//GJ--
	//		
	//	EndIf;
	//EndIf;
	
	//Sales tax owed postings
	RegisterRecords.SalesTaxOwed.Write = True;
	
	//Lock SalesTaxOwed register
	// Create new managed data lock.
	DataLocks = New DataLock;
	
	// Set data lock parameters.
	SalesTaxOwedLock = DataLocks.Add("AccumulationRegister.SalesTaxOwed");
	SalesTaxOwedLock.Mode = DataLockMode.Exclusive;
	SalesTaxOwedLock.SetValue("Agency", SalesTaxAgency);
	DataLocks.Lock();
	
	//Select current balance of SalesTaxOwed register for the current Agency across tax rates
	Request = New Query("SELECT
	                    |	SalesTaxBalance.ChargeType,
	                    |	SalesTaxBalance.Agency,
	                    |	SalesTaxBalance.TaxRate,
	                    |	SalesTaxBalance.SalesTaxComponent,
	                    |	SUM(SalesTaxBalance.GrossSaleBalance) AS GrossSaleBalance,
	                    |	SUM(SalesTaxBalance.TaxableSaleBalance) AS TaxableSaleBalance,
	                    |	SUM(SalesTaxBalance.TaxPayableBalance) AS TaxPayableBalance,
	                    |	SUM(SalesTaxBalance.AdvancePaymentBalance) AS AdvancePaymentBalance
	                    |FROM
	                    |	(SELECT
	                    |		SalesTaxOwedBalance.ChargeType AS ChargeType,
	                    |		SalesTaxOwedBalance.Agency AS Agency,
	                    |		SalesTaxOwedBalance.TaxRate AS TaxRate,
	                    |		SalesTaxOwedBalance.SalesTaxComponent AS SalesTaxComponent,
	                    |		SalesTaxOwedBalance.GrossSaleBalance AS GrossSaleBalance,
	                    |		SalesTaxOwedBalance.TaxableSaleBalance AS TaxableSaleBalance,
	                    |		CASE
	                    |			WHEN SalesTaxOwedBalance.TaxPayableBalance > 0
	                    |				THEN SalesTaxOwedBalance.TaxPayableBalance
	                    |			ELSE 0
	                    |		END AS TaxPayableBalance,
	                    |		CASE
	                    |			WHEN SalesTaxOwedBalance.TaxPayableBalance < 0
	                    |				THEN -1 * SalesTaxOwedBalance.TaxPayableBalance
	                    |			ELSE 0
	                    |		END AS AdvancePaymentBalance
	                    |	FROM
	                    |		AccumulationRegister.SalesTaxOwed.Balance(&BoundaryInTime, Agency = &Agency) AS SalesTaxOwedBalance
	                    |	
	                    |	UNION ALL
	                    |	
	                    |	SELECT
	                    |		VALUE(Enum.AccountingMethod.Accrual),
	                    |		SalesTaxPayment.SalesTaxAgency,
	                    |		0,
	                    |		VALUE(Catalog.SalesTaxComponents.EmptyRef),
	                    |		0,
	                    |		0,
	                    |		0,
	                    |		0
	                    |	FROM
	                    |		Document.SalesTaxPayment AS SalesTaxPayment
	                    |	WHERE
	                    |		SalesTaxPayment.Ref = &Ref
	                    |	
	                    |	UNION ALL
	                    |	
	                    |	SELECT
	                    |		VALUE(Enum.AccountingMethod.Cash),
	                    |		SalesTaxPayment.SalesTaxAgency,
	                    |		0,
	                    |		VALUE(Catalog.SalesTaxComponents.EmptyRef),
	                    |		0,
	                    |		0,
	                    |		0,
	                    |		0
	                    |	FROM
	                    |		Document.SalesTaxPayment AS SalesTaxPayment
	                    |	WHERE
	                    |		SalesTaxPayment.Ref = &Ref) AS SalesTaxBalance
	                    |
	                    |GROUP BY
	                    |	SalesTaxBalance.ChargeType,
	                    |	SalesTaxBalance.Agency,
	                    |	SalesTaxBalance.TaxRate,
	                    |	SalesTaxBalance.SalesTaxComponent");
	Request.SetParameter("BoundaryInTime", New Boundary(EndOfDay(TaxPeriodEnding), BoundaryType.Including));
	Request.SetParameter("Agency", SalesTaxAgency); 
	Request.SetParameter("Ref", Ref);
	BalanceTable = Request.Execute().Unload();
	
	//Repay balances proportionally among tax rates for each charge type (both accrual and cash)
	ChargeTypes = BalanceTable.Copy(, "ChargeType");
	ChargeTypes.GroupBy("ChargeType");
	For Each ChargeTypeItem In ChargeTypes Do
		SalesTaxAcrossRatesRows = BalanceTable.FindRows(New Structure("ChargeType", ChargeTypeItem.ChargeType));
		SalesTaxAcrossRates = BalanceTable.Copy(SalesTaxAcrossRatesRows);
		
		TotalTaxPayableAmount = SalesTaxAcrossRates.Total("TaxPayableBalance");
		AdvancePaymentBalance = SalesTaxAcrossRates.Total("AdvancePaymentBalance");
		TotalAvailablePayment = Payment + AdvancePaymentBalance;
		
		TotalAdvancePayment = 0;
		If TotalAvailablePayment > TotalTaxPayableAmount Then
			TotalAdvancePayment = TotalAvailablePayment - TotalTaxPayableAmount;
			TotalAvailablePayment = TotalTaxPayableAmount;
		EndIf;
		AvailablePaymentLeft = TotalAvailablePayment;
		i = 0;
		For i = 0 To SalesTaxAcrossRates.Count()-1 Do
			TaxPayableToPay = 0;
			TaxableSaleToPay = 0;
			GrossSaleToPay = 0;
			SalesTaxPerRateBalance = SalesTaxAcrossRates[i];
			//Check if the current TaxPayableBalance = 0
			If SalesTaxPerRateBalance.TaxPayableBalance = 0 Then
				Continue;
			EndIf;
			If i < (SalesTaxAcrossRates.Count()-1) Then
				CurrentPaymentQuotient = SalesTaxPerRateBalance.TaxPayableBalance/TotalTaxPayableAmount;
				CurrentAmountToPay = Round(CurrentPaymentQuotient * TotalAvailablePayment, 2); 
				If CurrentAmountToPay > SalesTaxPerRateBalance.TaxPayableBalance Then
					CurrentAmountToPay = SalesTaxPerRateBalance.TaxPayableBalance;
				EndIf;
				AvailablePaymentLeft = AvailablePaymentLeft - CurrentAmountToPay;
			Else //Last balance 
				CurrentAmountToPay = AvailablePaymentLeft;
				If CurrentAmountToPay > SalesTaxPerRateBalance.TaxPayableBalance Then
					TotalAdvancePayment = CurrentAmountToPay - SalesTaxPerRateBalance.TaxPayableBalance;
					CurrentAmountToPay 	= SalesTaxPerRateBalance.TaxPayableBalance;
				EndIf;
			EndIf;
			If CurrentAmountToPay = SalesTaxPerRateBalance.TaxPayableBalance Then
				TaxPayableToPay = CurrentAmountToPay;
				TaxableSaleToPay = SalesTaxPerRateBalance.TaxableSaleBalance;
				GrossSaleToPay = SalesTaxPerRateBalance.GrossSaleBalance;
			Else
				CurrentRepaymentQuotient = CurrentAmountToPay/SalesTaxPerRateBalance.TaxPayableBalance;
				TaxPayableToPay = CurrentAmountToPay;
				TaxableSaleToPay = Round(SalesTaxPerRateBalance.TaxableSaleBalance * CurrentRepaymentQuotient, 2);
				GrossSaleToPay = Round(SalesTaxPerRateBalance.GrossSaleBalance * CurrentRepaymentQuotient, 2);
			EndIf;
			//Regular records
			Record 					= RegisterRecords.SalesTaxOwed.Add();
			Record.RecordType 		= AccumulationRecordType.Expense;
			Record.Period 			= TaxPeriodEnding;
			Record.ChargeType 		= ChargeTypeItem.ChargeType;
			Record.Agency 			= SalesTaxAgency;
			Record.TaxRate 			= SalesTaxAcrossRates[i].TaxRate;
			Record.SalesTaxComponent= SalesTaxAcrossRates[i].SalesTaxComponent;
			Record.GrossSale 		= GrossSaleToPay;
			Record.TaxableSale		= TaxableSaleToPay;
			Record.TaxPayable		= TaxPayableToPay;
			Record.Reason			= "Payment";
			
		EndDo;
		//Fine, penalty or interest due
		//Posting penalties with 0 tax rate
		If AdjustmentAmount <> 0 Then
			//Charging penalties
			Record 					= RegisterRecords.SalesTaxOwed.Add();
			Record.RecordType 		= AccumulationRecordType.Receipt;
			Record.Period 			= TaxPeriodEnding;
			Record.ChargeType 		= ChargeTypeItem.ChargeType;
			Record.Agency 			= SalesTaxAgency;
			Record.TaxRate 			= 0;	
			Record.SalesTaxComponent= Catalogs.SalesTaxComponents.EmptyRef();
			Record.GrossSale 		= 0;
			Record.TaxableSale		= 0;
			Record.TaxPayable		= AdjustmentAmount;
			If AdjustmentAmount > 0 Then
				Record.Reason		= "Fine, penalty or interest due";
			Else
				Record.Reason		= "Credit or discount";
			EndIf;
			//Repaying penalties
			Record 					= RegisterRecords.SalesTaxOwed.Add();
			Record.RecordType 		= AccumulationRecordType.Expense;
			Record.Period 			= TaxPeriodEnding;
			Record.ChargeType 		= ChargeTypeItem.ChargeType;
			Record.Agency 			= SalesTaxAgency;
			Record.TaxRate 			= 0;	
			Record.SalesTaxComponent= Catalogs.SalesTaxComponents.EmptyRef();
			Record.GrossSale 		= 0;
			Record.TaxableSale		= 0;
			Record.TaxPayable		= AdjustmentAmount;
			Record.Reason			= "Payment";
		EndIf;
		//Posting advance payment
		//Reversal of current advance payment balance
		If AdvancePaymentBalance > 0 Then
			Record 					= RegisterRecords.SalesTaxOwed.Add();
			Record.RecordType 		= AccumulationRecordType.Expense;
			Record.Period 			= TaxPeriodEnding;
			Record.ChargeType 		= ChargeTypeItem.ChargeType;
			Record.Agency 			= SalesTaxAgency;
			Record.TaxRate 			= 0;	
			Record.SalesTaxComponent= Catalogs.SalesTaxComponents.EmptyRef();
			Record.GrossSale 		= 0;
			Record.TaxableSale		= 0;
			Record.TaxPayable		= -1 * AdvancePaymentBalance;
			Record.Reason			= "Reversal of the current advance payment balance";
		EndIf;
		//Advance payment of sales tax is posted with 0 percent rate
		If TotalAdvancePayment > 0 Then
			Record 					= RegisterRecords.SalesTaxOwed.Add();
			Record.RecordType 		= AccumulationRecordType.Expense;
			Record.Period 			= TaxPeriodEnding;
			Record.ChargeType 		= ChargeTypeItem.ChargeType;
			Record.Agency 			= SalesTaxAgency;
			Record.TaxRate 			= 0;
			Record.SalesTaxComponent= Catalogs.SalesTaxComponents.EmptyRef();
			Record.GrossSale 		= 0;
			Record.TaxableSale		= 0;
			Record.TaxPayable		= TotalAdvancePayment;
			Record.Reason			= "Tax advance payment";
		EndIf;
	EndDo;
	
	//CASH BASIS--------------------------------------------------------------------------------------------------
	//------------------------------------------------------------------------------------------------------------
	RegisterRecords.CashFlowData.Write = True;
	
	For Each CurrentTrans In RegisterRecords.GeneralJournalAnalyticsDimensions Do
		
		Record = RegisterRecords.CashFlowData.Add();
		Record.RecordType    = CurrentTrans.RecordType;
		Record.Period        = CurrentTrans.Period;
		Record.Account       = CurrentTrans.Account;
		Record.Company       = CurrentTrans.Company;
		Record.Document      = Ref;
		Record.SalesPerson   = Null;
		Record.Class         = CurrentTrans.Class;
		Record.Project       = CurrentTrans.Project;
		Record.AmountRC      = CurrentTrans.AmountRC;
		Record.PaymentMethod = Null;;
		
	EndDo;
	//------------------------------------------------------------------------------------------------------------
	//CASH BASIS (end)--------------------------------------------------------------------------------------------

EndProcedure


Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	If Not MadeAdjustment Then
		AttrIndex = CheckedAttributes.Find("AdjustmentAccount");
		If AttrIndex <> Undefined Then
			CheckedAttributes.Delete(AttrIndex);
		EndIf;
	EndIf;
EndProcedure

