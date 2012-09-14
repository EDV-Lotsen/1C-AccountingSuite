
&AtClient
Procedure UnitsOfMeasureOnChange(Item)
	DoMessageBox("Restart the program for the setting to take effect");
	RefreshInterface();
EndProcedure

&AtClient
Procedure MultiLocationOnChange(Item)
	DoMessageBox("Restart the program for the setting to take effect");
	RefreshInterface();
EndProcedure

&AtClient
Procedure MultiCurrencyOnChange(Item)
	DoMessageBox("Restart the program for the setting to take effect");
	RefreshInterface();
EndProcedure

&AtClient
Procedure USFinLocalizationOnChange(Item)
	DoMessageBox("Restart the program for the setting to take effect");
	RefreshInterface();
EndProcedure

&AtClient
Procedure BrazilFinLocalizationOnChange(Item)
	DoMessageBox("Restart the program for the setting to take effect");
	RefreshInterface();
EndProcedure

&AtClient
Procedure ClearGeneralJournal(Command)
	
	ClearGJ();

EndProcedure

&AtServer
Procedure ClearGJ()
	
	SetPrivilegedMode(True);
	
	Query = New Query("SELECT
	                  |	GeneralJournal.Recorder AS Recorder
	                  |FROM
	                  |	AccountingRegister.GeneralJournal AS GeneralJournal
	                  |
	                  |GROUP BY
	                  |	GeneralJournal.Recorder");
				  
	QueryResult = Query.Execute();

	If QueryResult.IsEmpty() Then
	Else
		RecorderDataset = QueryResult.Choose();
		
		While RecorderDataset.Next() Do
			
			Reg = AccountingRegisters.GeneralJournal;
			Dataset = Reg.CreateRecordSet();
			Dataset.Filter.Recorder.Set(RecorderDataset.Recorder);
			Dataset.Read();
	        Test = Dataset.Unload();
			For Each T in Test Do
				Test.Delete(T);				
			EndDo;
			
			Dataset.Load(Test);
			Dataset.Write();	
				
		EndDo;
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

&AtClient
Procedure ClearInvInfRegister(Command)
	
	ClearIJ();
	
EndProcedure

&AtServer
Procedure ClearIJ()
	
	SetPrivilegedMode(True);
	
	Reg = InformationRegisters.InventoryJournal.CreateRecordSet();
	Reg.Write(True);	
	
	SetPrivilegedMode(False);
	
EndProcedure

&AtClient
Procedure ClearLocationBalances(Command)
	
	ClearLB();
	
EndProcedure

&AtServer
Procedure ClearLB()
	
	SetPrivilegedMode(True);
	
	Query = New Query("SELECT
	                  |	LocationBalances.Recorder AS Recorder
	                  |FROM
	                  |	AccumulationRegister.LocationBalances AS LocationBalances
	                  |
	                  |GROUP BY
	                  |	LocationBalances.Recorder");
				  
	QueryResult = Query.Execute();

	If QueryResult.IsEmpty() Then
	Else
		RecorderDataset = QueryResult.Choose();
		
		While RecorderDataset.Next() Do
			
			Reg = AccumulationRegisters.LocationBalances;
			Dataset = Reg.CreateRecordSet();
			Dataset.Filter.Recorder.Set(RecorderDataset.Recorder);
			Dataset.Read();
	        Test = Dataset.Unload();
			For Each T in Test Do
				Test.Delete(T);				
			EndDo;
			
			Dataset.Load(Test);
			Dataset.Write();	
				
		EndDo;
	EndIf;

	SetPrivilegedMode(False);
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
		
	Items.BankAccountLabel.Title =
		GeneralFunctions.GetAttributeValue(Constants.BankAccount.Get(), "Description");
	Items.IncomeAccountLabel.Title =
		GeneralFunctions.GetAttributeValue(Constants.IncomeAccount.Get(), "Description");
	Items.COGSAccountLabel.Title =
		GeneralFunctions.GetAttributeValue(Constants.COGSAccount.Get(), "Description");
	Items.ExpenseAccountLabel.Title =
		GeneralFunctions.GetAttributeValue(Constants.ExpenseAccount.Get(), "Description");
	Items.InventoryAccountLabel.Title =
		GeneralFunctions.GetAttributeValue(Constants.InventoryAccount.Get(), "Description");
	Items.ExchangeGainLabel.Title =
		GeneralFunctions.GetAttributeValue(Constants.ExchangeGain.Get(), "Description");
	Items.ExchangeLossLabel.Title =
		GeneralFunctions.GetAttributeValue(Constants.ExchangeLoss.Get(), "Description");
	Items.SalesTaxAccountLabel.Title =
		GeneralFunctions.GetAttributeValue(Constants.SalesTaxPayableAccount.Get(), "Description");
	Items.VATAccountLabel.Title = 
		GeneralFunctions.GetAttributeValue(Constants.VATAccount.Get(), "Description");
	Items.UndepositedFundsAccountLabel.Title =
		GeneralFunctions.GetAttributeValue(Constants.UndepositedFundsAccount.Get(), "Description");
	Items.BankInterestEarnedAccountLabel.Title =
		GeneralFunctions.GetAttributeValue(Constants.BankInterestEarnedAccount.Get(), "Description");
	Items.BankServiceChargeAccountLabel.Title =
		GeneralFunctions.GetAttributeValue(Constants.BankServiceChargeAccount.Get(), "Description");
	Items.AccumulatedOCIAccountLabel.Title =
		GeneralFunctions.GetAttributeValue(Constants.AccumulatedOCIAccount.Get(), "Description");
		
EndProcedure

&AtClient
Procedure BankAccountOnChange(Item)
	Items.BankAccountLabel.Title = GeneralFunctions.AccountName(Items.BankAccount.SelectedText);
EndProcedure

&AtClient
Procedure IncomeAccountOnChange(Item)
	Items.IncomeAccountLabel.Title = GeneralFunctions.AccountName(Items.IncomeAccount.SelectedText);
EndProcedure

&AtClient
Procedure COGSAccountOnChange(Item)
	Items.COGSAccountLabel.Title = GeneralFunctions.AccountName(Items.COGSAccount.SelectedText);
EndProcedure

&AtClient
Procedure ExpenseAccountOnChange(Item)
	Items.ExpenseAccountLabel.Title = GeneralFunctions.AccountName(Items.ExpenseAccount.SelectedText);
EndProcedure

&AtClient
Procedure InventoryAccountOnChange(Item)
	Items.InventoryAccountLabel.Title =
		GeneralFunctions.AccountName(Items.InventoryAccount.SelectedText);
EndProcedure

&AtClient
Procedure ExchangeGainOnChange(Item)
	Items.ExchangeGainLabel.Title = GeneralFunctions.AccountName(Items.ExchangeGain.SelectedText);
EndProcedure

&AtClient
Procedure ExchangeLossOnChange(Item)
	Items.ExchangeLossLabel.Title = GeneralFunctions.AccountName(Items.ExchangeLoss.SelectedText);
EndProcedure

&AtClient
Procedure SalesTaxPayableAccountOnChange(Item)
	Items.SalesTaxAccountLabel.Title =
		GeneralFunctions.AccountName(Items.SalesTaxPayableAccount.SelectedText);
EndProcedure

&AtClient
Procedure UndepositedFundsAccountOnChange(Item)
	Items.UndepositedFundsAccountLabel.Title =
		GeneralFunctions.AccountName(Items.UndepositedFundsAccount.SelectedText);
EndProcedure

&AtClient
Procedure BankInterestEarnedAccountOnChange(Item)
	Items.BankInterestEarnedAccountLabel.Title =
		GeneralFunctions.AccountName(Items.BankInterestEarnedAccount.SelectedText);
EndProcedure

&AtClient
Procedure BankServiceChargeAccountOnChange(Item)
	Items.BankServiceChargeAccountLabel.Title =
		GeneralFunctions.AccountName(Items.BankServiceChargeAccount.SelectedText);
EndProcedure

&AtClient
Procedure AdvancedPricingOnChange(Item)
	RefreshInterface();
EndProcedure

&AtClient
Procedure DefaultCurrencyOnChange(Item)
	DoMessageBox("Restart the program for the setting to take effect");
EndProcedure

&AtClient
Procedure VATAccountOnChange(Item)
	Items.VATAccountLabel.Title =
		GeneralFunctions.AccountName(Items.VATAccount.SelectedText);
EndProcedure

&AtClient
Procedure SAFinLocalizationOnChange(Item)
	
	GeneralFunctions.VATSetup();
	DoMessageBox("Restart the program for the setting to take effect");
	RefreshInterface();

EndProcedure

&AtClient
Procedure PaymentTermsDefaultOnChange(Item)
	
	DoMessageBox("Restart the program for the setting to take effect");
	RefreshInterface();
	
EndProcedure

&AtClient
Procedure VendorNameOnChange(Item)
	
	DoMessageBox("Restart the program for the setting to take effect");
	
EndProcedure

&AtClient
Procedure CustomerNameOnChange(Item)
	
	DoMessageBox("Restart the program for the setting to take effect");
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	If GeneralFunctionsReusable.FunctionalOptionValue("SAFinLocalization") Then
		
		If ConstantsSet.VATAccount.IsEmpty() Then
			
			Message = New UserMessage();
			Message.Text=NStr("en='Please select a VAT Account'");
			Message.Field = "ConstantsSet.VATAccount";
			Message.Message();
			Cancel = True;
			Return;

		EndIf;
		
	EndIf;
EndProcedure

&AtClient
Procedure EmailClientOnChange(Item)
	
	DoMessageBox("Restart the program for the setting to take effect");
	RefreshInterface();

EndProcedure

&AtClient
Procedure AccumulatedOCIAccountOnChange(Item)
	Items.AccumulatedOCIAccountLabel.Title =
		GeneralFunctions.AccountName(Items.AccumulatedOCIAccount.SelectedText);
EndProcedure
