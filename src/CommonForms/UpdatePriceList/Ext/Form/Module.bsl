
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Product = Parameters.SelectedProduct;
	Vendor = Parameters.Vendor;
	VendorCurrency = GeneralFunctions.GetAttributeValue(Vendor, "DefaultCurrency");
	Customer = Parameters.Customer;
	CustomerCurrency = GeneralFunctions.GetAttributeValue(Customer, "DefaultCurrency"); 
	Date = Parameters.Date;
	ExchangeRate = GeneralFunctions.GetExchangeRate(Date, VendorCurrency, CustomerCurrency);
	ProductCost = Parameters.ProductCost;
	Cost = ProductCost / ExchangeRate;
	NewPrice = Cost;
	
	Items.ExchangeRate.Title = String(VendorCurrency.Symbol) + "/" + String(CustomerCurrency.Symbol);
	
EndProcedure

&AtClient
Procedure MarkUpOnChange(Item)
	
	NewPrice = Cost * (1 + MarkUp/100);
	
EndProcedure

&AtClient
Procedure Update(Command)
	
	Close(UpdatePriceList(Product, NewPrice, Date, CustomerCurrency));
	
EndProcedure

&AtServer
Function UpdatePriceList(Product, NewPrice, Date, Currency)
	
	Reg = InformationRegisters.PriceList.CreateRecordManager();
	Reg.Product = Product;
	Reg.Period = Date;
	Reg.Price = NewPrice;
	If GetFunctionalOption("AdvancedPricing") Then
		Reg.Company = Customer;
		Reg.Currency = Currency;
	Else
	EndIf;
	Reg.Write(True);
	
EndFunction

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure


