
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
		
		//++MisA 11/14/2014	
		AcceptableListTypes = GeneralFunctionsReusable.GetAcceptableAccountTypesForChange(Object.Ref.AccountType);
		Items.AccountType.ListChoiceMode = True;
		Items.AccountType.ChoiceList.LoadValues(AcceptableListTypes);
		//- MisA 11/14/2014
		
		AcctType = Object.AccountType;
		If AcctType = ARType OR AcctType = APType OR AcctType = BankType Then
				Items.Currency.Visible = True;
			Else
				Items.Currency.Visible = False;
		EndIf;
	EndIf;

	If Object.Ref.IsEmpty() Then
		
		//Clear code from autofilling
		Object.Code = "";
		Object.Parent = ChartsOfAccounts.ChartOfAccounts.EmptyRef();
		
		Items.CashFlowSection.Visible = False;
		Items.Currency.Visible = False;
		
		AcctType = Object.AccountType;
		If AcctType = Enums.AccountTypes.Bank OR AcctType = Enums.AccountTypes.OtherCurrentLiability 
			OR AcctType = Enums.AccountTypes.Income OR AcctType = Enums.AccountTypes.CostOfSales
			OR AcctType = Enums.AccountTypes.Expense Then
			Items.Code.InputHint = "<Auto>";
			Items.Code.AutoMarkIncomplete = False;
		Else
			Items.Code.InputHint = "";
			Items.Code.AutoMarkIncomplete = True;
		EndIf;
		
	EndIf;
	
	SetVisibility();
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	ARType = GeneralFunctionsReusable.ARAccountType();
	APType = GeneralFunctionsReusable.APAccountType();
	
	If NOT Object.Ref.IsEmpty() Then
		Items.AccountType.ReadOnly = True;
		Items.Currency.ReadOnly = True;
		SetVisibility();
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
	
	AccountTypeOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure AccountTypeOnChangeAtServer()
	
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
		
		AcctType = Object.AccountType;
		
		If AcctType = BankType OR AcctType = ARType OR AcctType = APType Then
			Items.Currency.Visible = True;
			Object.Currency = GeneralFunctionsReusable.DefaultCurrency();
		Else
			Items.Currency.Visible = False;
		EndIf;
			
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
		
		If AcctType = Enums.AccountTypes.Bank OR AcctType = Enums.AccountTypes.OtherCurrentLiability 
			OR AcctType = Enums.AccountTypes.Income OR AcctType = Enums.AccountTypes.CostOfSales
			OR AcctType = Enums.AccountTypes.Expense
			OR AcctType = Enums.AccountTypes.Inventory
			OR AcctType = Enums.AccountTypes.AccountsReceivable
			OR AcctType = Enums.AccountTypes.OtherCurrentAsset
			OR AcctType = Enums.AccountTypes.FixedAsset
			OR AcctType = Enums.AccountTypes.AccumulatedDepreciation
			OR AcctType = Enums.AccountTypes.OtherNonCurrentAsset
			OR AcctType = Enums.AccountTypes.AccountsPayable
			OR AcctType = Enums.AccountTypes.LongTermLiability
			OR AcctType = Enums.AccountTypes.Equity 
			OR AcctType = Enums.AccountTypes.OtherIncome 
			OR AcctType = Enums.AccountTypes.OtherExpense 
			OR AcctType = Enums.AccountTypes.IncomeTaxExpense Then
			Items.Code.InputHint = "<Auto>";
			Items.Code.AutoMarkIncomplete = False;
		Else
			Items.Code.InputHint = "";
			Items.Code.AutoMarkIncomplete = True;
		EndIf;
		
	//++MisA 11/14/2014	
	Else 
		AcctType = Object.AccountType;
		If GeneralFunctionsReusable.CurrencyUsedAccountType(AcctType) And Object.Currency.IsEmpty() Then
			Object.Currency = GeneralFunctionsReusable.DefaultCurrency();
		ElsIf AcctType = Enums.AccountTypes.OtherCurrentAsset AND Object.Ref.AccountType = Enums.AccountTypes.Bank Then 
			Object.Currency = Catalogs.Currencies.EmptyRef();
			If Object.CashFlowSection.IsEmpty() Then 
				Object.CashFlowSection = GeneralFunctionsReusable.CashFlowOperatingSection();
			EndIf;	
		EndIf;
	//- MisA 11/14/2014
	
	// KZ 08/25/15
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
	
	SetVisibility();
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	BankType      = GeneralFunctionsReusable.BankAccountType(); 
	InventoryType = GeneralFunctionsReusable.InventoryAccountType();
	ARType        = GeneralFunctionsReusable.ARAccountType();
	OCAType       = GeneralFunctionsReusable.OtherCurrentAssetAccountType();
	FAType        = GeneralFunctionsReusable.FixedAssetAccountType();
	ADType        = GeneralFunctionsReusable.AccumulatedDepreciationAccountType();
	ONCAType      = GeneralFunctionsReusable.OtherNonCurrentAssetAccountType();
	APType        = GeneralFunctionsReusable.APAccountType();
	OCLType       = GeneralFunctionsReusable.OtherCurrentLiabilityAccountType();
	LTLType       = GeneralFunctionsReusable.LongTermLiabilityAccountType();
	EquityType    = GeneralFunctionsReusable.EquityAccountType(); 
	
	AcctType = Object.AccountType;
	
	//Implement fill check programmatically
	ObjectAttribute = CheckedAttributes.Find("Object");
	If ObjectAttribute <> Undefined Then
		CheckedAttributes.Delete(ObjectAttribute);
	EndIf;
	
	If Items.Code.InputHint <> "<Auto>" Then
		If Not ValueIsFilled(Object.Code) Then
			Cancel = True;
			Message = New UserMessage();
			Message.Text = "Field """ + "Code" + """ is empty";
			Message.SetData(Object);
			Message.Field = "Object.Code";
			Message.Message();
		EndIf;
	EndIf;
	
	If Not ValueIsFilled(Object.Description) Then
		Cancel = True;
		Message = New UserMessage();
		Message.Text = "Field """ + "Name" + """ is empty";
		Message.SetData(Object);
		Message.Field = "Object.Description";
		Message.Message();
	EndIf;
	
	If Not ValueIsFilled(Object.AccountType) Then
		Cancel = True;
		Message = New UserMessage();
		Message.Text = "Field """ + "AccountType" + """ is empty";
		Message.SetData(Object);
		Message.Field = "Object.AccountType";
		Message.Message();
	EndIf;
	
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
	EndIf;
	
	If Object.AccountType = Enums.AccountTypes.Equity And Object.RetainedEarnings Then
		
		RetainedEarningsAccount = ChartsOfAccounts.ChartOfAccounts.FindByAttribute("RetainedEarnings", True);
		
		If ValueIsFilled(RetainedEarningsAccount) And RetainedEarningsAccount <> Object.Ref Then
			
			Cancel = True;
			
			Message = New UserMessage();
			Message.Text  = NStr("en = 'Retained earnings account already exists!'");
			Message.Field = "Object.RetainedEarnings";
			Message.Message();
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure CodeOnChange(Item)
	
	Object.Order = Object.Code;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If CurrentObject.Ref.IsEmpty() AND (NOT ValueIsFilled(CurrentObject.Code)) Then
		AcctType = CurrentObject.AccountType;
		If AcctType = Enums.AccountTypes.Bank Then
			StartCode = "1000";
			EndCode = "2000";
		ElsIf AcctType = Enums.AccountTypes.Inventory Then
			StartCode = "1000";
			EndCode = "2000";	
		ElsIf AcctType = Enums.AccountTypes.AccountsReceivable Then
			StartCode = "1000";
			EndCode = "2000";	
		ElsIf AcctType = Enums.AccountTypes.OtherCurrentAsset Then
			StartCode = "1000";
			EndCode = "2000";	
		ElsIf AcctType = Enums.AccountTypes.FixedAsset Then
			StartCode = "1000";
			EndCode = "2000";		
		ElsIf AcctType = Enums.AccountTypes.AccumulatedDepreciation Then
			StartCode = "1000";
			EndCode = "2000";		
		ElsIf AcctType = Enums.AccountTypes.OtherNonCurrentAsset Then
			StartCode = "1000";
			EndCode = "2000";		
		ElsIf AcctType = Enums.AccountTypes.OtherCurrentLiability Then
			StartCode = "2100";
			EndCode = "3000";
		ElsIf AcctType = Enums.AccountTypes.AccountsPayable Then
			StartCode = "2000";
			EndCode = "3000";
		ElsIf AcctType = Enums.AccountTypes.LongTermLiability Then
			StartCode = "2000";
			EndCode = "3000";
		ElsIf AcctType = Enums.AccountTypes.Equity Then
			StartCode = "3000";
			EndCode = "4000";	
		ElsIf AcctType = Enums.AccountTypes.Income Then
			StartCode = "4000";
			EndCode = "5000";
		ElsIf AcctType = Enums.AccountTypes.CostOfSales Then
			StartCode = "5000";
			EndCode = "6000";
		ElsIf AcctType = Enums.AccountTypes.Expense Then
			// Apply two intervals depending on parent account
			ParentCode = CurrentObject.Parent.Code;
			Try
				NumericalCode = 0;
				If Format(Number(TrimAll(ParentCode)), "NFD=; NG=0") = TrimAll(ParentCode) Then //Found digital code
					NumericalCode = Number(TrimAll(ParentCode));
				EndIf;
				If NumericalCode >= 7000 Then
					StartCode = "7000";
					EndCode = "8000";
				Else
					StartCode = "6000";
					EndCode = "7000";	
				EndIf;
			Except
				StartCode = "6000";
				EndCode = "7000";
			EndTry
		ElsIf AcctType = Enums.AccountTypes.OtherIncome Then
			StartCode = "8000";
			EndCode = "9000";	
		ElsIf AcctType = Enums.AccountTypes.OtherExpense Then
			StartCode = "9000";
			EndCode = "9999"; // if set 10000 then gitting new code will break.  Start/end codes must have the same digits count
		ElsIf AcctType = Enums.AccountTypes.IncomeTaxExpense Then
			StartCode = "9000";
			EndCode = "9999"; // if set 10000 then gitting new code will break.  Start/end codes must have the same digits count
		Else
			return;
		EndIf;
	
		CurrentObject.AdditionalProperties.Insert("IsNew", True);
		CurrentObject.AdditionalProperties.Insert("StartCode", StartCode);
		CurrentObject.AdditionalProperties.Insert("EndCode", EndCode);
		CurrentObject.AdditionalProperties.Insert("AccountType", AcctType);
	EndIf;
EndProcedure

&AtServer
Procedure VisibilityRetainedEarnings()
	
	If Object.AccountType = PredefinedValue("Enum.AccountTypes.Equity") Then
		Items.RetainedEarnings.Visible = True;
	Else
		Items.RetainedEarnings.Visible = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure VisibilityCategory1099()
	
	Items.Category1099.Visible = False;
	
	If Object.AccountType = Enums.AccountTypes.Income
		OR Object.AccountType = Enums.AccountTypes.OtherIncome 
		OR Object.AccountType = Enums.AccountTypes.CostOfSales 
		OR Object.AccountType = Enums.AccountTypes.Expense 
		OR Object.AccountType = Enums.AccountTypes.OtherExpense 
		OR Object.AccountType = Enums.AccountTypes.IncomeTaxExpense
		Then
		
		Items.Category1099.Visible = True;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibility()
	
	If Object.AccountType = Enums.AccountTypes.OtherCurrentLiability Then
		Items.CreditCard.Visible = True;
	Else
		Items.CreditCard.Visible = False;
	EndIf;
	
	VisibilityRetainedEarnings();
	VisibilityCategory1099();
	
EndProcedure

&AtClient
Procedure CreditCardOnChange(Item)
	
	SetVisibility();
	
EndProcedure
