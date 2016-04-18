
////////////////////////////////////////////////////////////////////////////////
#Region EVENTS_HANDLERS

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	RefillCreditListFlag = True;
	
	If Parameters.Property("Company") And Object.Ref.IsEmpty() Then
		Object.Company = Parameters.Company;
		OpenOrdersSelectionForm = True; 
		RefillCreditListFlag = False;
	EndIf;
	
	If Parameters.Property("Basis") And TypeOf(Parameters.Basis) = Type("DocumentRef.PurchaseInvoice") And Object.Ref.IsEmpty() Then 
		Object.Company = Parameters.Basis.Company;
		CompanyOnChangeAtServer();
		For Each Bill in Object.LineItems Do 
			If Bill.Document = Parameters.Basis Then 
				FillPaymentWithDiscountAtServer(Bill.Document, Bill.BalanceFCY, Bill.Payment, Bill.Discount);
				If Bill.Payment > 0 Then 
					Bill.Check = True;
				EndIf;	
				Continue;
			EndIf;	
		EndDo;	
		RefillCreditListFlag = False;
		Documents.InvoicePayment.AdditionalPaymentCall(Object);
	EndIf;	
	
	
	If Object.Ref.IsEmpty() Then
		ManualChangesAreMade = False;
	Else 	
		ManualChangesAreMade = True;
	EndIf;
	
	Items.Company.Title = GeneralFunctionsReusable.GetVendorName();
	
	If Object.BankAccount.IsEmpty() Then
		Object.BankAccount = Constants.BankAccount.Get();
	Else
	EndIf; 

	If GeneralFunctionsReusable.FunctionalOptionValue("MultiCurrency") Then	
		Items.LineItemsPayment.Title = "Payment FCY";	
	EndIf;
	
	//Disable voiding if document is not posted
	If Object.Ref.Posted = False Then
		Items.FormMarkAsVoid.Enabled = False;
	EndIf;
	
	CheckVoid();
	
	If RefillCreditListFlag Then 
		Documents.InvoicePayment.FillCreditList(Object,Object.Company);
	EndIf;	
	
	If Object.LineItems.Count() > 0 Then
		Items.PayAll.Visible = true;
	Else
		Items.PayAll.Visible = false;
	Endif;
	
	UpdateTabTitles();
	If Object.Credits.Count() > 0 Then 
		Items.Group1.CurrentPage = Items.VendorCredits;
	EndIf;	
	
	UpdateFormula();
	
	ProcessVisibilityOfDiscountFields();
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
//Period closing
	If PeriodClosingServerCall.DocumentPeriodIsClosed(CurrentObject.Ref, CurrentObject.Date) Then
		PermitWrite = PeriodClosingServerCall.DocumentWritePermitted(WriteParameters);
		CurrentObject.AdditionalProperties.Insert("PermitWrite", PermitWrite);	
	EndIf;
	
	If Object.PaymentMethod = Catalogs.PaymentMethods.Check Then
			
		If WriteParameters.AllowCheckNumber = True Then
	
			CurrentObject.PhysicalCheckNum = CurrentObject.Number;
			CurrentObject.AdditionalProperties.Insert("AllowCheckNumber", True);	
			
		Else
			Message("Check number already exists for this bank account");
			Cancel = True;
		EndIf;

	Endif;

	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	Documents.InvoicePayment.FillCreditList(Object,Object.Company);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Object.PaymentMethod.IsEmpty() Then
		Cancel = True;
		Message = New UserMessage();
		Message.Text=NStr("en='Select a payment method'");
		Message.Message();
	EndIf;	
	
	If Object.PaymentMethod = CheckPaymentMethod() Then
	
		Try
			If Number(Object.Number) < 0 OR Number(Object.Number) > 100000 Then
				Cancel = True;
				Message = New UserMessage();
				Message.Text=NStr("en='Enter a check number from 0 to 10000'");
				Message.Message();
			EndIf;
		Except
			
			Cancel = True;
			Message = New UserMessage();
			Message.Text=NStr("en='Enter a check number from 0 to 10000'");
			Message.Message();

		EndTry;
		
	Endif;


EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("AfterOpen", 0.1, True);
	
EndProcedure

&AtClient
// The procedure deletes all line items which are
// not paid by this invoice payment
//
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
	
	//Check number shouldn't be duplicated normally. 
	//Check its uniqueness and if not ask use to allow duplication (if applicable) 
	If Object.PaymentMethod = PredefinedValue("Catalog.PaymentMethods.Check") Then
		CheckNumberResult = CommonUseServerCall.CheckNumberAllowed(Object.Number, Object.Ref, Object.BankAccount);
		If CheckNumberResult.DuplicatesFound Then
			If Not CheckNumberResult.Allow Then
				Cancel = True;
				CommonUseClientServer.MessageToUser("Check number already exists for this bank account", Object, "Object.Number");
			Else
				If WriteParameters.Property("AllowCheckNumber") Then
					If Not WriteParameters.AllowCheckNumber Then
						Cancel = True;
					EndIf;
				Else
					Notify = New NotifyDescription("ProcessUserResponseOnCheckNumberDuplicated", ThisObject, WriteParameters);
					ShowQueryBox(Notify, "Check number already exists for this bank account. Continue?", QuestionDialogMode.YesNo);
					Cancel = True;
				EndIf;
			EndIf;
		Else
			WriteParameters.Insert("AllowCheckNumber", True);
		EndIf;
	EndIf;
	
	// preventing posting if already included in a bank rec
	If ReconciledDocumentsServerCall.DocumentRequiresExcludingFromBankReconciliation(Object, WriteParameters.WriteMode) Then
		Cancel = True;
		CommonUseClient.ShowCustomMessageBox(ThisForm, "Bank reconciliation", "The transaction you are editing has been reconciled. Saving your changes could put you out of balance the next time you try to reconcile. 
		|To modify it you should exclude it from the Bank rec. document.", PredefinedValue("Enum.MessageStatus.Warning"));
	EndIf;	
	
	If CommonUse.GetConstant("DiscountsReceived").IsEmpty() Then 
		If Object.DiscountAmount > 0 Then 
			Message("Discounts Received Account isn't set. Please select Discounts Received Account in Settings.");
			Cancel = True;
		EndIf;	
	EndIf;
	
	TotalPay = Object.LineItems.Total("Payment");

	NumberOfLines = Object.LineItems.Count() - 1;
	
	While NumberOfLines >=0 Do
		If Object.LineItems[NumberOfLines].Payment = 0 Then
			Object.LineItems.Delete(NumberOfLines);
		Else
		EndIf;
		NumberOfLines = NumberOfLines - 1;
	EndDo;
	
	ArrayOfCreditsToDel = New Array;
	For Each CreditRow In Object.Credits Do 
		If CreditRow.Payment = 0 Or CreditRow.Check = False Then 
			ArrayOfCreditsToDel.Add(CreditRow);
		EndIf;	
	EndDo;	
	For Each Row in ArrayOfCreditsToDel Do  
		Object.Credits.Delete(Row);
	EndDo;	
	
	
	UpdateTabTitles();
	
EndProcedure

&AtClient
// The procedure notifies all related dynamic lists that the changes in data have occured.
//
Procedure AfterWrite(WriteParameters)
	
	For Each DocumentLine in Object.LineItems Do
		
		RepresentDataChange(DocumentLine.Document, DataChangeType.Update);
		
	EndDo;
	
	Notify("UpdateBillInformation", Object.Company);
		
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region CONTROLS_EVENTS_HANDLERS

&AtClient
// CompanyOnChange UI event handler. The procedure repopulates line items upon a company change.
//
Procedure CompanyOnChange(Item)
	
	CompanyOnChangeAtServer();
	
	UpdateTabTitles();
	
	If Object.LineItems.Count() > 0 Then
		Items.PayAll.Visible = true;
	Else
		Items.PayAll.Visible = false;
	Endif;
	
	If Object.Credits.Count() > 0 Then 
		Items.Group1.CurrentPage = Items.VendorCredits;
	EndIf;	
	
EndProcedure

&AtServer
Procedure CompanyOnChangeAtServer()
	
	ManualChangesAreMade = False;
	
	Documents.InvoicePayment.FillDocumentList(Object,Object.Company);
	Documents.InvoicePayment.FillCreditList(Object,Object.Company);
	Documents.InvoicePayment.ClearTabularSections(Object, True, True);
	Documents.InvoicePayment.AdditionalPaymentCall(Object);
	
	Object.Currency = Object.Company.DefaultCurrency;
	
	UpdateRemitToAddress();
	
	UpdateFormula();
	
EndProcedure

&AtClient
Procedure PaymentMethodOnChange(Item)
	
	If Object.PaymentMethod = CheckPaymentMethod() Then
		
		If Object.Number = ""  AND Object.Ref.IsEmpty() = False Then
			Object.Number = StrReplace(Generalfunctions.LastCheckNumber(object.BankAccount),",","");
		Elsif Object.Number = "" And Object.Ref.IsEmpty() Then
			Object.Number = StrReplace(Generalfunctions.LastCheckNumber(object.BankAccount) + 1,",","");
		Else
		EndIf;

	Else
	EndIf;


EndProcedure

&AtClient
Procedure CreditsCheckOnChange(Item)
	
	If Items.Credits.CurrentData.Check Then
		Items.Credits.CurrentData.Payment = Items.Credits.CurrentData.BalanceFCY2;
	Else
		Items.Credits.CurrentData.Payment = 0;
	EndIf;
	
	CreditsCheckOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure CreditsCheckOnChangeAtServer()
	
	Documents.InvoicePayment.CashPaymentCalculation(Object);
	UpdateFormula();
	
EndProcedure

&AtClient
Procedure BankAccountOnChange(Item)
	
	If Object.PaymentMethod = CheckPaymentMethod() Then
		ChoiceProcessing = New NotifyDescription("UpdateBankCheck", ThisForm);
		ShowQueryBox(ChoiceProcessing, "Would you like to load the next check number for this bank account?", QuestionDialogMode.YesNo, 0);
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateBankCheck(Result, Parameters) Export
   	If Result = DialogReturnCode.Yes Then
		Object.Number = StrReplace(Generalfunctions.LastCheckNumber(object.BankAccount) + 1,",","");       
    EndIf;              
EndProcedure

&AtClient
Procedure UnappliedPaymentOnChange(Item)
	UnappliedPaymentOnChangeAtServer();
EndProcedure

&AtServer
Procedure UnappliedPaymentOnChangeAtServer()
	Documents.InvoicePayment.AdditionalPaymentCall(Object,false);
	UpdateFormula();
EndProcedure

&AtClient
Procedure CashPaymentOnChange(Item)
	UpdateFormula();
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region LINEITEMS_SECTION_EVENTS_HANDLERS

&AtClient
// LineItemsPaymentOnChange UI event handler.
// The procedure calculates a document total in the foreign currency (DocumentTotal) and in the
// reporting currency (DocumentTotalRC).
//
Procedure LineItemsPaymentOnChange(Item)
	
	
	If Items.LineItems.CurrentData <> Undefined Then
		TabularPartRow = Items.LineItems.CurrentData;
		
		TabularPartRow.Check = True;
		
		LimitPaymentWithDiscountAtServer(TabularPartRow.Document, TabularPartRow.BalanceFCY, TabularPartRow.Payment, TabularPartRow.Discount);
		
		If TabularPartRow.Payment = 0 Then
			TabularPartRow.Check = False;
		Endif;
		
	Endif;
	
	LineItemsPaymentOnChangeServer();
	
EndProcedure

// LineItemsPaymentOnChange UI event handler.
// The procedure calculates a document total in the foreign currency (DocumentTotal) and in the
// reporting currency (DocumentTotalRC).
//
Procedure LineItemsPaymentOnChangeServer()
	
	ManualChangesAreMade = True;
	Documents.InvoicePayment.AdditionalPaymentCall(Object);
	UpdateFormula();
EndProcedure

&AtClient
Procedure LineItemsDiscountOnChange(Item)
	
	If Items.LineItems.CurrentData <> Undefined Then
		FormCurrentRow = Items.LineItems.CurrentData;
		If FormCurrentRow.Payment + FormCurrentRow.Discount > FormCurrentRow.BalanceFCY Then 
			FormCurrentRow.Discount = FormCurrentRow.BalanceFCY - FormCurrentRow.Payment;
		EndIf;	
		
		If FormCurrentRow.Payment + FormCurrentRow.Discount > 0 Then
			FormCurrentRow.Check = True;
		Else
			FormCurrentRow.Check = False;
		Endif;
	Endif;
	
	LineItemsDiscountOnChangeAtServer();
	
EndProcedure

&AtServer
Procedure LineItemsDiscountOnChangeAtServer()
	Documents.InvoicePayment.AdditionalPaymentCall(Object);
	UpdateFormula();
EndProcedure

&AtClient
Procedure LineItemsDocumentStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure LineItemsDocumentClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure LineItemsCheckOnChange(Item)
	
	If Items.LineItems.CurrentData.Check Then
		CurrentRow = Items.LineItems.CurrentData;
		FillPaymentWithDiscountAtServer(CurrentRow.Document, CurrentRow.BalanceFCY, CurrentRow.Payment, CurrentRow.Discount);
		RecalcPayment = True;
	Else                           
		Items.LineItems.CurrentData.Discount = 0;
		Items.LineItems.CurrentData.Payment = 0;
		RecalcPayment = False;
	Endif;
	LineItemsCheckOnChangeServer(RecalcPayment);
EndProcedure

&AtServer
Procedure LineItemsCheckOnChangeServer(RecalcPayment)
	Documents.InvoicePayment.AdditionalPaymentCall(Object);
	UpdateFormula();
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region CREDITS_SECTION_EVENTS_HANDLERS

&AtClient 
Procedure CreditsPaymentOnChange(Item)
	
	If Items.Credits.CurrentData.Payment > Items.Credits.CurrentData.BalanceFCY2 Then
		Items.Credits.CurrentData.Payment = Items.Credits.CurrentData.BalanceFCY2;
	Endif;
	
	If Items.Credits.CurrentData.Payment = 0 Then
		Items.Credits.CurrentData.Check = False;
	Else 	
		Items.Credits.CurrentData.Check = True;
	Endif;   
	
	CreditsPaymentOnChangeAtServer();
EndProcedure

&AtServer
Procedure CreditsPaymentOnChangeAtServer()
	
	Documents.InvoicePayment.CashPaymentCalculation(Object);
	UpdateFormula();
	
EndProcedure

&AtClient
Procedure CreditsDocumentStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
EndProcedure

&AtClient
Procedure CreditsDocumentClearing(Item, StandardProcessing)
	StandardProcessing = False;
EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region COMMANDS_HANDLERS

&AtClient
Procedure PayAll(Command)
	
	For Each LineItem In Object.LineItems Do
		LineItem.Check = True;
		FillPaymentWithDiscountAtServer(LineItem.Document, LineItem.BalanceFCY, LineItem.Payment, LineItem.Discount);
	EndDo;
	
	PayAllAtServer();
	
EndProcedure

&AtServer
Procedure PayAllAtServer()
	Documents.InvoicePayment.AdditionalPaymentCall(Object);
	UpdateFormula();
EndProcedure

&AtClient
Procedure MarkAsVoid(Command)
	Notify = New NotifyDescription("OpenJournalEntry", ThisObject);
	OpenForm("CommonForm.VoidDateForm",,,,,,Notify,FormWindowOpeningMode.LockOwnerWindow);
EndProcedure

&AtClient
Procedure OpenJournalEntry(Parameter1,Parameter2) Export
	
	Str = New Structure;
	Str.Insert("InvoicePayRef", Object.Ref);
	Str.Insert("VoidDate", Parameter1);
	If Parameter1 <> Undefined Then
		OpenForm("Document.GeneralJournalEntry.ObjectForm",Str);	
	EndIf;
EndProcedure

&AtClient
Procedure AuditLogRecord(Command)
	
	FormParameters = New Structure();	
	FltrParameters = New Structure();
	FltrParameters.Insert("DocUUID", String(Object.Ref.UUID()));
	FormParameters.Insert("Filter", FltrParameters);
	OpenForm("CommonForm.AuditLogList",FormParameters, Object.Ref);
	

EndProcedure

#EndRegion

////////////////////////////////////////////////////////////////////////////////
#Region PRIVATE_IMPLEMENTATION

&AtServer
Procedure UpdateFormula()
	
	TotalFormula = 
	"Total Bills ("+Object.LineItems.Total("Payment")+") - " + 
	"Credits ("+Object.Credits.Total("Payment")+") + "+
	"Unapplied Payments ("+Object.UnappliedPayment+") = "+
	"Total Cash Payment ("+Object.CashPayment+")  ";
	
EndProcedure

&AtServer
Procedure ProcessVisibilityOfDiscountFields()
	Visible = Constants.UseExtendedDiscountsInPayments.Get();
	Items.DiscountAmount.Visible = Visible;
	Items.LineItemsDiscountDate.Visible = Visible;
	Items.LineItemsDiscount.Visible = Visible;
	
EndProcedure	

&AtServer
Procedure UpdateTabTitles()
	InvoiceCount = Object.LineItems.Count();
	CreditCount = Object.Credits.Count();
	Items.PaidInvoices.Title = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Bills [%1]'"),    InvoiceCount);
	Items.VendorCredits.Title  = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = 'Credits [%1]'"), CreditCount);	
EndProcedure	

&AtServer
Procedure CheckVoid()
	
	//Check if there is a voiding entry for this document
	Query = New Query;
	Query.Text = "SELECT
	             |	GeneralJournalEntry.Ref
	             |FROM
	             |	Document.GeneralJournalEntry AS GeneralJournalEntry
	             |WHERE
	             |	GeneralJournalEntry.VoidingEntry = &Ref";
				 
	Query.SetParameter("Ref", Object.Ref);
	QueryResult = Query.Execute().Unload();
	If QueryResult.Count() <> 0 Then
		Items.VoidMessage.Title = "This bill payment has been voided by";
		VoidingGJ = QueryResult[0].Ref;
		Items.VoidInfo.Visible = True;
		Items.FormMarkAsVoid.Enabled = False;
	Else
		Items.VoidInfo.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterOpen()
	
	ThisForm.Activate();
	
	If ThisForm.IsInputAvailable() Then
		///////////////////////////////////////////////
		DetachIdleHandler("AfterOpen");
		
		If OpenOrdersSelectionForm Then
			CompanyOnChange(Items.Company);	
		EndIf;	
		///////////////////////////////////////////////
	Else 
		AttachIdleHandler("AfterOpen", 0.1, True);
	EndIf;		
	
EndProcedure

&AtServer
Function CheckPaymentMethod()
	
	Return Catalogs.PaymentMethods.Check;
	
EndFunction

&AtServer
Function GetRippleAddress(Company)
	
	Return Company.RippleAddress;	
	
EndFunction

&AtServer
Procedure UpdateRemitToAddress()
	
	Query = New Query;
	Query.Text = "
		|SELECT
		|	Addresses.Ref AS Address
		|FROM
		|	Catalog.Addresses AS Addresses
		|WHERE
		|	Addresses.Owner = &Company
		|	AND Addresses.DefaultRemitTo";
	Query.SetParameter("Company", Object.Company);
	
	QuerySelection = Query.Execute().Select();
	If QuerySelection.Next() Then
		Object.RemitTo = QuerySelection.Address;	
	EndIf;
	
EndProcedure

&AtServer
Function GetCurrentDocumentBalance(CurrentDocumentLine)
	
	PayTotal = 0;
	
	DefaultCurrency = GeneralFunctionsReusable.DefaultCurrency();
	
	For Each LineItem In Object.LineItems Do
		If LineItem.Document <> CurrentDocumentLine And LineItem.Check Then 
			PayTotal = PayTotal + LineItem.Payment;
		EndIf;	
	EndDo;
	
	
	For Each CreditItem In Object.Credits Do
		If CreditItem.Document <> CurrentDocumentLine And CreditItem.Check Then 
			PayTotal = PayTotal - CreditItem.Payment;
		EndIf;	
	EndDo;
	
	Return ?(PayTotal > 0, PayTotal, 0);
		
EndFunction

&AtServer
Procedure FillPaymentWithDiscountAtServer(CurrentDocument, CurrentBalance, CurrentPayment, CurrentDiscount)
	Documents.InvoicePayment.FillPaymentWithDiscount(Object, CurrentDocument, CurrentBalance, CurrentPayment, CurrentDiscount);
EndProcedure

&AtServer
Procedure LimitPaymentWithDiscountAtServer(CurrentDocument, CurrentBalance, CurrentPayment, CurrentDiscount)
	CashReceiptMethods.LimitPaymentWithDiscount(Object, CurrentDocument, CurrentBalance, CurrentPayment, CurrentDiscount);
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
Procedure ProcessUserResponseOnCheckNumberDuplicated(Result, Parameters) Export
	
	If Result = DialogReturnCode.Yes Then
		Parameters.Insert("AllowCheckNumber", True);
		Write(Parameters);
	Else
		Parameters.Insert("AllowCheckNumber", False);
		Write(Parameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "UpdateVoid" And Parameter = Object.Ref Then
		
		CheckVoid();
		
	EndIf;
	
EndProcedure

#EndRegion
