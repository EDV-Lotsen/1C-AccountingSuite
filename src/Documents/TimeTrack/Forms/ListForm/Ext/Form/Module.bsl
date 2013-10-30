
&AtClient
Procedure GenInvoice(Command)
	SelectedItem = Items.List.CurrentData;
	GenInvoiceAtServer(SelectedItem);
EndProcedure

&AtServer
Procedure GenInvoiceAtServer(SelectedItem)
	
	RefObject = SelectedItem.Ref.GetObject();
	If RefObject.Billable = false Then
		Message("Either one or more of the selected documents are considered non-billable");
	Else
		
		TabularPartRow = SelectedItem;
		
		rowcount = items.List.SelectedRows.Count();
		rownum = 0;
		companymatch = true;
		While rownum < rowcount Do
			 CheckRow = Items.List.SelectedRows.Get(rownum);
			 If CheckRow.Company <> TabularPartRow.Company Then
			 	companymatch = false;			
			Endif;
			
		rownum = rownum + 1;	
		EndDo;
		
		
		If companymatch = true Then

		NewInvoice = Documents.SalesInvoice.CreateDocument();
		//NewInvoice.Number = DataLine.SIHeaderNumber;
		NewInvoice.Date = TabularPartRow.Date;
		NewInvoice.Company = TabularPartRow.Company;
		NewInvoice.CompanyCode = TabularPartRow.Company.Code;
		NewInvoice.DocumentTotal = TabularPartRow.Price * TabularPartRow.TimeComplete;
		NewInvoice.Currency = Constants.DefaultCurrency.Get();
		NewInvoice.ExchangeRate = 1;
		NewInvoice.DocumentTotalRC = TabularPartRow.Price * TabularPartRow.TimeComplete;
		NewInvoice.Location = Catalogs.Locations.MainWarehouse;
		NewInvoice.Project = TabularPartRow.Project;
		
		// query - find default shipping address of the company
		Query = New Query("SELECT
		                  |	Addresses.Ref
		                  |FROM
		                  |	Catalog.Addresses AS Addresses
		                  |WHERE
		                  |	Addresses.Owner = &Company
		                  |	AND Addresses.DefaultShipping = TRUE");
		Query.SetParameter("Company", TabularPartRow.Company.Ref);
		
		QueryResult = Query.Execute();
					
		Dataset = QueryResult.Unload();
			
		If Dataset.Count() = 0 Then
			NewInvoice.ShipTo = Catalogs.Addresses.EmptyRef();
		Else
			ShipToAddr = Dataset[0][0];
		Endif;

		NewInvoice.ShipTo = ShipToAddr;
		
		NewInvoice.Terms = TabularPartRow.Company.Terms;
		
		If TabularPartRow.Company = Catalogs.Companies.EmptyRef() Then
			NewInvoice.DueDate = TabularPartRow.Date + CommonUse.GetAttributeValue(Catalogs.PaymentTerms.Net30, "Days") * 60 * 60 * 24;
		Else
			NewInvoice.DueDate = TabularPartRow.Date + CommonUse.GetAttributeValue(TabularPartRow.Company.Terms, "Days") * 60 * 60 * 24;
		Endif;

		If TabularPartRow.Company.ARAccount = ChartsOfAccounts.ChartOfAccounts.EmptyRef() Then
			NewInvoice.ARAccount = NewInvoice.Currency.DefaultARAccount;
		Else	
			NewInvoice.ARAccount = TabularPartRow.Company.ARAccount;
		EndIf;
		
		//NewInvoice.RefNum = DataLine.SIHeaderPO;
		NewInvoice.Write();
		rownum = 0;
			
			While rownum < rowcount Do
				TabularPartRow = Items.List.SelectedRows.Get(rownum);
				SelectedObject = TabularPartRow.GetObject();
				//SelectedObject.Billed = true;
				If SelectedObject.LogType = "Week" Then
					DayHours = 0;
					DayVal = 0;
					If SelectedObject.Mon > 0 Then
						  DayHours = TabularPartRow.Mon;
						  WeekLineItems(NewInvoice,DayHours,TabularPartRow,DayVal);
					Endif;
					  
					If SelectedObject.Tue > 0 Then
						  DayHours = TabularPartRow.Tue;
						  DayVal = 1;
						  WeekLineItems(NewInvoice,DayHours,TabularPartRow,DayVal);
					Endif;
					  
					If SelectedObject.Wed > 0 Then
						  DayHours = TabularPartRow.Wed;
						  DayVal = 2;
						  WeekLineItems(NewInvoice,DayHours,TabularPartRow,DayVal);
					Endif;
					  
					If SelectedObject.Thur > 0 Then
						  DayHours = TabularPartRow.Thur;
						  DayVal = 3;
						  WeekLineItems(NewInvoice,DayHours,TabularPartRow,DayVal);
					Endif;

					If SelectedObject.Fri > 0 Then
						  DayHours = TabularPartRow.Fri;
						  DayVal = 4;
						  WeekLineItems(NewInvoice,DayHours,TabularPartRow,DayVal);
					Endif;
					  
					If SelectedObject.Sat > 0 Then
						  DayHours = TabularPartRow.Sat;
						  DayVal = 5;
						  WeekLineItems(NewInvoice,DayHours,TabularPartRow,DayVal);
					Endif;
					  
					If SelectedObject.Sun > 0 Then
						  DayHours = TabularPartRow.Sun;
						  DayVal = 6;
						  WeekLineItems(NewInvoice,DayHours,TabularPartRow,DayVal);
					Endif;


					  
					  
				Else			
				//
				
				NewLine = NewInvoice.LineItems.Add();
				NewLine.Product = TabularPartRow.Task;
				NewLine.ProductDescription = TabularPartRow.Memo;
				NewLine.Price = TabularPartRow.Price;
				NewLine.Quantity = TabularPartRow.TimeComplete;
				NewLine.LineTotal = TabularPartRow.Price * TabularPartRow.TimeComplete; 
				NewLine.Project = TabularPartRow.Project;
				//NewLine.SalesTaxType = US_FL.GetSalesTaxType(TabularPartRow.Task);
				NewLine.SalesTaxType = US_FL.GetSalesTaxType(TabularPartRow.Task);

				NewLine.TaxableAmount = 0;
				NewLine.VATCode = CommonUse.GetAttributeValue(TabularPartRow.Task, "SalesVATCode");
				NewLine.VAT = 0;
						
				NewInvoice.Write();
				Endif;
			
				rownum = rownum + 1;
			EndDo;
		
		Message("Your invoice has been created.");
		
		Else
			Message("Selected item companies do not all match");
		Endif;
		
	Endif;

	                         	
EndProcedure

&AtClient
Procedure RefreshItems(Command)
	Items.List.Refresh();
EndProcedure

&AtServer
Procedure WeekLineItems(NewInvoice,DayHours,TabularPartRow,DayVal)
	
			NewLine = NewInvoice.LineItems.Add();
			NewLine.Product = TabularPartRow.Task;
			//DatedMemo = String(TabularPartRow.DateFrom + DayVal*60*60*24) + " " + TabularPartRow.Memo; 
			DatedMemo = String(Format(TabularPartRow.DateFrom + DayVal*60*60*24,"DLF=D")) + " " + TabularPartRow.Memo;

			NewLine.ProductDescription = DatedMemo;
			NewLine.Price = TabularPartRow.Price;
			NewLine.Quantity = DayHours;
			NewLine.LineTotal = TabularPartRow.Price * DayHours; 
			NewLine.Project = TabularPartRow.Project;
			//NewLine.SalesTaxType = US_FL.GetSalesTaxType(TabularPartRow.Task);
			NewLine.SalesTaxType = US_FL.GetSalesTaxType(TabularPartRow.Task);

			NewLine.TaxableAmount = 0;
			NewLine.VATCode = CommonUse.GetAttributeValue(TabularPartRow.Task, "SalesVATCode");
			NewLine.VAT = 0;
							
			NewInvoice.Write();
EndProcedure