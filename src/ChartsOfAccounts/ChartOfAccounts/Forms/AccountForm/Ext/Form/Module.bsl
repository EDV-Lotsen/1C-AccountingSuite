
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	CurUser = InfoBaseUsers.FindByName(SessionParameters.ACSUser);
	
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
		
		If CurUser.Roles.Contains(Metadata.Roles.FullAccess) = True Then
		Else
			Items.AccountType.ReadOnly = True;
		EndIf;
		Items.Currency.ReadOnly = True;
	EndIf;
	
	If Object.Ref.IsEmpty() Then
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
			OR AcctType = Enums.AccountTypes.Expense Then
			Items.Code.InputHint = "<Auto>";
			Items.Code.AutoMarkIncomplete = False;
		Else
			Items.Code.InputHint = "";
			Items.Code.AutoMarkIncomplete = True;
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
	EndIf


EndProcedure

&AtClient
Procedure CodeOnChange(Item)
	
	Object.Order = Object.Code;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	If CurrentObject.Ref.IsEmpty() AND ((Items.Code.InputHint = "<Auto>") OR (NOT ValueIsFilled(CurrentObject.Code))) Then
		AcctType = CurrentObject.AccountType;
		If AcctType = Enums.AccountTypes.Bank Then
			StartCode = "1000";
			EndCode = "2000";
		ElsIf AcctType = Enums.AccountTypes.OtherCurrentLiability Then
			StartCode = "2100";
			EndCode = "3000";
		ElsIf AcctType = Enums.AccountTypes.Income Then
			StartCode = "4000";
			EndCode = "5000";
		ElsIf AcctType = Enums.AccountTypes.CostOfSales Then
			StartCode = "5000";
			EndCode = "6000";
		ElsIf AcctType = Enums.AccountTypes.Expense Then
			StartCode = "6000";
			EndCode = "7000";
		Else
			return;
		EndIf;	
		CurrentObject.AdditionalProperties.Insert("IsNew", True);
		CurrentObject.AdditionalProperties.Insert("StartCode", StartCode);
		CurrentObject.AdditionalProperties.Insert("EndCode", EndCode);
		CurrentObject.AdditionalProperties.Insert("AccountType", AcctType);
	EndIf;
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	If Not Object.Ref.IsEmpty() Then
		Items.Code.TextColor = New Color();
	EndIf;
EndProcedure
