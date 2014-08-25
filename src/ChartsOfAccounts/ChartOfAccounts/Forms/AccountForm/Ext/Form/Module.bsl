
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	BankType = GeneralFunctionsReusable.BankAccountType(); 
	InventoryType = GeneralFunctionsReusable.InventoryAccountType();
	ARType = GeneralFunctionsReusable.ARAccountType();
	OCAType = GeneralFunctionsReusable.OtherCurrentAssetAccountType();
	FAType = GeneralFunctionsReusable.FixedAssetAccountType();
	ADType = GeneralFunctionsReusable.AccumulatedDepreciationAccountType();
	ONCAType = GeneralFunctionsReusable.OtherNonCurrentAssetAccountType();
	APType = GeneralFunctionsReusable.APAccountType();
	OCLType = GeneralFunctionsReusable.OtherCurrentLiabilityAccountType();
	LTLType = GeneralFunctionsReusable.LongTermLiabilityAccountType();
	EquityType = GeneralFunctionsReusable.EquityAccountType();

	If NOT Object.Ref.IsEmpty() Then
	
		AcctType = Object.AccountType;
		If AcctType = InventoryType OR AcctType = ARType OR AcctType = OCAType OR AcctType = FAType OR AcctType = ADType
			OR AcctType = ONCAType OR AcctType = APType OR AcctType = OCLType OR AcctType = LTLType OR AcctType = EquityType Then			
				Items.CashFlowSection.Visible = True;			
			Else								
				Items.CashFlowSection.Visible = False;
		EndIf;
			
	EndIf;
	
	If NOT Object.Ref.IsEmpty() Then
	
		AcctType = Object.AccountType;
		If AcctType = ARType OR AcctType = APType OR AcctType = BankType Then			
				Items.Currency.Visible = True;			
			Else								
				Items.Currency.Visible = False;
		EndIf;
			
	EndIf;

	If NOT Object.Ref.IsEmpty() Then
		Items.AccountType.ReadOnly = True;
		Items.Currency.ReadOnly = True;
	EndIf;
	
	If Object.Ref.IsEmpty() Then
		Items.CashFlowSection.Visible = False;
		Items.Currency.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	ARType = GeneralFunctionsReusable.ARAccountType();
	APType = GeneralFunctionsReusable.APAccountType();
	
	If NOT Object.Ref.IsEmpty() Then
		Items.AccountType.ReadOnly = True;
		Items.Currency.ReadOnly = True;
	EndIf;
		
	If Object.AccountType = APType OR Object.AccountType = ARType Then
			
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
	
	BankType = GeneralFunctionsReusable.BankAccountType(); 
	InventoryType = GeneralFunctionsReusable.InventoryAccountType();
	ARType = GeneralFunctionsReusable.ARAccountType();
	OCAType = GeneralFunctionsReusable.OtherCurrentAssetAccountType();
	FAType = GeneralFunctionsReusable.FixedAssetAccountType();
	ADType = GeneralFunctionsReusable.AccumulatedDepreciationAccountType();
	ONCAType = GeneralFunctionsReusable.OtherNonCurrentAssetAccountType();
	APType = GeneralFunctionsReusable.APAccountType();
	OCLType = GeneralFunctionsReusable.OtherCurrentLiabilityAccountType();
	LTLType = GeneralFunctionsReusable.LongTermLiabilityAccountType();
	EquityType = GeneralFunctionsReusable.EquityAccountType();
	
	If Object.Ref.IsEmpty() Then 
	
		If Object.AccountType = BankType OR Object.AccountType = ARType OR Object.AccountType = APType Then
			Items.Currency.Visible = True;                                                                        
			Object.Currency = GeneralFunctionsReusable.DefaultCurrency();
		Else
			Items.Currency.Visible = False;			
		EndIf;
		
	EndIf;
	
	If Object.Ref.IsEmpty() Then
		
		AcctType = Object.AccountType;
		If AcctType = InventoryType OR AcctType = ARType OR AcctType = OCAType OR AcctType = FAType OR AcctType = ADType
			OR AcctType = ONCAType OR AcctType = APType OR AcctType = OCLType OR AcctType = LTLType OR AcctType = EquityType Then			
				Items.CashFlowSection.Visible = True;			
			Else								
				Items.CashFlowSection.Visible = False;
		EndIf;
			
		If AcctType = InventoryType OR AcctType = ARType OR AcctType = OCAType OR AcctType = ADType
			OR AcctType = ONCAType OR AcctType = APType OR AcctType = OCLType Then			
				Object.CashFlowSection = GeneralFunctionsReusable.CashFlowOperatingSection();
		Else
		EndIf;
		
		If AcctType = FAType Then			
				Object.CashFlowSection = GeneralFunctionsReusable.CashFlowInvestingSection();
		Else
		EndIf;
		
		If AcctType = LTLType OR AcctType = EquityType Then			
				Object.CashFlowSection = GeneralFunctionsReusable.CashFlowFinancingSection();
		Else
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	BankType = GeneralFunctionsReusable.BankAccountType(); 
	InventoryType = GeneralFunctionsReusable.InventoryAccountType();
	ARType = GeneralFunctionsReusable.ARAccountType();
	OCAType = GeneralFunctionsReusable.OtherCurrentAssetAccountType();
	FAType = GeneralFunctionsReusable.FixedAssetAccountType();
	ADType = GeneralFunctionsReusable.AccumulatedDepreciationAccountType();
	ONCAType = GeneralFunctionsReusable.OtherNonCurrentAssetAccountType();
	APType = GeneralFunctionsReusable.APAccountType();
	OCLType = GeneralFunctionsReusable.OtherCurrentLiabilityAccountType();
	LTLType = GeneralFunctionsReusable.LongTermLiabilityAccountType();
	EquityType = GeneralFunctionsReusable.EquityAccountType(); 
	
	AcctType = Object.AccountType;
		
	If (AcctType = BankType OR AcctType = ARType OR AcctType = APType) AND Object.Currency.IsEmpty() Then
		Cancel = True;
		Message = New UserMessage();
		Message.Text=NStr("en='Select a currency'");
		//Message.Field = "Object.Currency";
		Message.Message();
		Return;
	EndIf;	
	
	If AcctType = InventoryType OR AcctType = ARType OR AcctType = OCAType OR AcctType = FAType OR AcctType = ADType
		OR AcctType = ONCAType OR AcctType = APType OR AcctType = OCLType OR AcctType = LTLType OR AcctType = EquityType Then			
			If Object.CashFlowSection.IsEmpty() Then
				Cancel = True;
				Message = New UserMessage();
				Message.Text=NStr("en='Select a cash flow section'");
				Message.Message();
				Return;	
			EndIf;
		Else								
	EndIf


EndProcedure

&AtClient
Procedure CodeOnChange(Item)
	
	Object.Order = Object.Code;
	
EndProcedure
