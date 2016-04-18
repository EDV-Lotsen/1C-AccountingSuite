
&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	//If Object.NewObject = True Then
	//	
	//	DefaultCurrency = Constants.DefaultCurrency.Get();
	//	DefaultARCode = DefaultCurrency.DefaultARAccount.Code;
	//	DefaultAPCode = DefaultCurrency.DefaultAPAccount.Code;
	//	
	//	// Creating A/R account
	//	
	//	NewAccount = ChartsOfAccounts.ChartOfAccounts.CreateAccount();
	//	NewAccount.Code = DefaultARCode + Object.Description;
	//	NewAccount.Order = NewAccount.Code;
	//	NewAccount.Description = "A/R " + Object.Description;
	//	NewAccount.Currency = Object.Ref;
	//	
	//	NewAccount.AccountType = Enums.AccountTypes.AccountsReceivable;
	//	NewAccount.CashFlowSection = Enums.CashFlowSections.Operating;
	//	NewAccount.Write();	
	//	
	//	Account = NewAccount.Ref;
	//	AccountObject = Account.GetObject();
	//	
	//	Dimension = AccountObject.ExtDimensionTypes.Find(ChartsOfCharacteristicTypes.Dimensions.Company, "ExtDimensionType");
	//	If Dimension = Undefined Then	
	//		NewType = AccountObject.ExtDimensionTypes.Insert(0);
	//		NewType.ExtDimensionType = ChartsOfCharacteristicTypes.Dimensions.Company;
	//	EndIf;	
	//	
	//	Dimension = AccountObject.ExtDimensionTypes.Find(ChartsOfCharacteristicTypes.Dimensions.Document, "ExtDimensionType");
	//	If Dimension = Undefined Then
	//		NewType = AccountObject.ExtDimensionTypes.Insert(1);
	//		NewType.ExtDimensionType = ChartsOfCharacteristicTypes.Dimensions.Document;
	//	EndIf;	
	//		
	//	AccountObject.Write();

	//	AddedCurrency = Object.Ref.GetObject();
	//	AddedCurrency.DefaultARAccount = NewAccount.Ref;
	//	AddedCurrency.Write();
	//	
	//	// Creating A/P account
	//	
	//	NewAccount = ChartsOfAccounts.ChartOfAccounts.CreateAccount();
	//	NewAccount.Code = DefaultAPCode + Object.Description;
	//	NewAccount.Order = NewAccount.Code;
	//	NewAccount.Description = "A/P " + Object.Description;
	//	NewAccount.Currency = Object.Ref;
	//	
	//	NewAccount.AccountType = Enums.AccountTypes.AccountsPayable;
	//	NewAccount.CashFlowSection = Enums.CashFlowSections.Operating;
	//	NewAccount.Write();	
	//	
	//	Account = NewAccount.Ref;
	//	AccountObject = Account.GetObject();
	//	
	//	Dimension = AccountObject.ExtDimensionTypes.Find(ChartsOfCharacteristicTypes.Dimensions.Company, "ExtDimensionType");
	//	If Dimension = Undefined Then	
	//		NewType = AccountObject.ExtDimensionTypes.Insert(0);
	//		NewType.ExtDimensionType = ChartsOfCharacteristicTypes.Dimensions.Company;
	//	EndIf;	
	//	
	//	Dimension = AccountObject.ExtDimensionTypes.Find(ChartsOfCharacteristicTypes.Dimensions.Document, "ExtDimensionType");
	//	If Dimension = Undefined Then
	//		NewType = AccountObject.ExtDimensionTypes.Insert(1);
	//		NewType.ExtDimensionType = ChartsOfCharacteristicTypes.Dimensions.Document;
	//	EndIf;	
	//		
	//	AccountObject.Write();

	//	AddedCurrency = Object.Ref.GetObject();
	//	AddedCurrency.DefaultAPAccount = NewAccount.Ref;
	//	AddedCurrency.Write();
	//	
	//EndIf;
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	//Query = New Query("SELECT
	//                  |	Currencies.Description
	//                  |FROM
	//                  |	Catalog.Currencies AS Currencies");
	//QueryResult = Query.Execute();
	//If QueryResult.IsEmpty() Then		
	//Else
	//	Selection = QueryResult.Select();
	//	While Selection.Next() Do
	//		
	//		If Object.Description = Selection.Description Then
	//			
	//			Message = New UserMessage();
	//			Message.Text=NStr("en='Currency name is not unique'");
	//			//Message.Field = "Object.Description";
	//			Message.Message();
	//			Cancel = True;
	//			Return;
	//
	//		EndIf;
	//		
	//	EndDo;						
	//EndIf;
	
	If Constants.UseSOPrepayment.Get() And (Not ValueIsFilled(Object.DefaultPrepaymentAR)) Then
		
		Message = New UserMessage();
		Message.Text  = NStr("en = 'Cannot save with no ""Prepayment A/R account""'");
		Message.Field = "Object.DefaultPrepaymentAR";
		Message.Message();
		Cancel = True;
		
		Return;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Object.Ref.IsEmpty() Then 
		Object.AutoUpdateRates = True;
	EndIf;	
EndProcedure


