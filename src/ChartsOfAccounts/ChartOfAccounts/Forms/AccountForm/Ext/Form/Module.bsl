
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Object.Ref.IsEmpty() Then
		Object.CashFlowSection = Enums.CashFlowSections.Operating;	
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
		
	If Object.AccountType = Enums.AccountTypes.AccountsPayable OR Object.AccountType = Enums.AccountTypes.AccountsReceivable Then
			
		Account = Object.Ref;
		AccountObject = Account.GetObject();
		
		Dimension = AccountObject.ExtDimensionTypes.Find(ChartsOfCharacteristicTypes.Dimensions.Company, "ExtDimensionType");
		If Dimension = Undefined Then	
			NewType = AccountObject.ExtDimensionTypes.Insert(0);
			NewType.ExtDimensionType = ChartsOfCharacteristicTypes.Dimensions.Company;
		EndIf;	
		
		Dimension = AccountObject.ExtDimensionTypes.Find(ChartsOfCharacteristicTypes.Dimensions.Document, "ExtDimensionType");
		If Dimension = Undefined Then
			NewType = AccountObject.ExtDimensionTypes.Insert(1);
			NewType.ExtDimensionType = ChartsOfCharacteristicTypes.Dimensions.Document;
		EndIf;	
			
		AccountObject.Write();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AccountTypeOnChange(Item)
	
	If Object.Ref.IsEmpty() Then
		BankType = GeneralFunctionsReusable.BankAccountType(); 
		ARType = GeneralFunctionsReusable.ARAccountType(); 
		APType = GeneralFunctionsReusable.APAccountType();  
	
		If NOT Object.AccountType = BankType AND NOT Object.AccountType = ARType AND NOT Object.AccountType = APType Then
			Items.Currency.ReadOnly = True;                                                                        
			Object.Currency = GeneralFunctionsReusable.CurrencyEmptyRef();
		Else
			Items.Currency.ReadOnly = False;
			Object.Currency = GeneralFunctionsReusable.DefaultCurrency();
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	BankType = GeneralFunctionsReusable.BankAccountType(); 
	ARType = GeneralFunctionsReusable.ARAccountType(); 
	APType = GeneralFunctionsReusable.APAccountType();  
	
	OneOfThreeTypes = False;
	If Object.AccountType = BankType OR Object.AccountType = ARType OR Object.AccountType = APType Then
		OneOfThreeTypes = True;
	EndIf;
	
	If OneOfThreeTypes AND Object.Currency.IsEmpty() Then
		Cancel = True;
		Message = New UserMessage();
		Message.Text=NStr("en='Select a currency';de='Währung auswählen'");
		Message.Field = "Object.Currency";
		Message.Message();
		Return;
	EndIf;

EndProcedure

&AtClient
Procedure CodeOnChange(Item)
	
	Object.Order = Object.Code;
	
EndProcedure
