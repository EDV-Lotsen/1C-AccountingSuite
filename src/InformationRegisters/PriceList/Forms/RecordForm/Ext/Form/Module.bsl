﻿

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Record.PriceType = "" Then
		Record.PriceType = "Item";
		Items.Product.MarkIncomplete = True;
	EndIf;
	
	If Record.PriceType = "Item" Then
		Items.ProductCategory.Visible = False;
		Items.PriceLevel.Visible = False;
	ElsIf Record.PriceType = "ItemPriceLevel" Then
		Items.ProductCategory.Visible = False;
	ElsIf Record.PriceType = "CategoryPriceLevel" Then
		Items.Product.Visible = False;
	ElsIf Record.PriceType = "Category" Then
		Items.Product.Visible = False;
		Items.PriceLevel.Visible = False;
	EndIf;
	
	Product = Record.Product;
	
	// Update prices presentation.
	PriceFormat = GeneralFunctionsReusable.DefaultPriceFormat();
	Items.Price.EditFormat = PriceFormat;
	Items.Price.Format     = PriceFormat;
	Items.Cost.EditFormat  = PriceFormat;
	Items.Cost.Format      = PriceFormat;
	
EndProcedure

&AtClient
Procedure PriceTypeOnChange(Item)
	
	If Record.PriceType = "Item" Then
		
		Items.Product.Visible = True;
		Items.Product.MarkIncomplete = ?(Product = ProductEmptyRef(), True, False);		
		Items.ProductCategory.Visible = False;
		Items.PriceLevel.Visible = False;
		
		Record.Product = Product;
		Record.ProductCategory = ProductCategoryEmptyRef();
		Record.PriceLevel = PriceLevelEmptyRef();
		
	ElsIf Record.PriceType = "ItemPriceLevel" Then
		
		Items.Product.Visible = True;
		Items.Product.MarkIncomplete = ?(Product = ProductEmptyRef(), True, False);
		Items.ProductCategory.Visible = False;
		Items.PriceLevel.Visible = True;
		Items.PriceLevel.MarkIncomplete = True;
		
		Record.Product = Product;
		Record.ProductCategory = ProductCategoryEmptyRef();
		Record.PriceLevel = PriceLevelEmptyRef();

	ElsIf Record.PriceType = "CategoryPriceLevel" Then
		
		Items.Product.Visible = False;		
		Items.ProductCategory.Visible = True;
		Items.ProductCategory.MarkIncomplete = True;
		Items.PriceLevel.Visible = True;
		Items.PriceLevel.MarkIncomplete = True;
		
		Record.Product = ProductEmptyRef();
		Record.ProductCategory = ProductCategoryEmptyRef();
		Record.PriceLevel = PriceLevelEmptyRef();
		
	ElsIf Record.PriceType = "Category" Then
		
		Items.Product.Visible = False;		
		Items.ProductCategory.Visible = True;
		Items.ProductCategory.MarkIncomplete = True;
		Items.PriceLevel.Visible = False;
		
		Record.Product = ProductEmptyRef();
		Record.ProductCategory = ProductCategoryEmptyRef();
		Record.PriceLevel = PriceLevelEmptyRef();
		
	EndIf;
	
	UpdatePrices();

EndProcedure

&AtServerNoContext
Function ProductEmptyRef()
	
	Return Catalogs.Products.EmptyRef();
	
EndFunction

&AtServerNoContext 
Function ProductCategoryEmptyRef()
	
	Return Catalogs.ProductCategories.EmptyRef();
	
EndFunction

&AtServerNoContext 
Function PriceLevelEmptyRef()
	
	Return Catalogs.PriceLevels.EmptyRef();
	
EndFunction

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Record.PriceType = "Item" Then
		
		If Record.Product = Catalogs.Products.EmptyRef() Then
			Message = New UserMessage();
			Message.Text = NStr("en = 'Please select an Item'");
			Message.Message();
			Cancel = True;
		EndIf;
		
	ElsIf Record.PriceType = "ItemPriceLevel" Then
		
		If Record.Product = Catalogs.Products.EmptyRef() Then
			Message = New UserMessage();
			Message.Text = NStr("en = 'Please select an Item'");
			Message.Message();
			Cancel = True;
		EndIf;

		If Record.PriceLevel = Catalogs.PriceLevels.EmptyRef() Then
			Message = New UserMessage();
			Message.Text = NStr("en = 'Please select a Price level'");
			Message.Message();
			Cancel = True;
		EndIf;
		
	ElsIf Record.PriceType = "CategoryPriceLevel" Then
		
		If Record.PriceLevel = Catalogs.PriceLevels.EmptyRef() Then
			Message = New UserMessage();
			Message.Text = NStr("en = 'Please select a Price level'");
			Message.Message();
			Cancel = True;
		EndIf;
		
		If Record.ProductCategory = Catalogs.ProductCategories.EmptyRef() Then
			Message = New UserMessage();
			Message.Text = NStr("en = 'Please select an Item category'");
			Message.Message();
			Cancel = True;
		EndIf;
		
	ElsIf Record.PriceType = "Category" Then
		
		If Record.ProductCategory = Catalogs.ProductCategories.EmptyRef() Then
			Message = New UserMessage();
			Message.Text = NStr("en = 'Please select an Item category'");
			Message.Message();
			Cancel = True;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProductOnChange(Item)
	
	If Record.Product = ProductEmptyRef() Then
		Items.Product.MarkIncomplete = True;
	Else
		Items.Product.MarkIncomplete = False;
	EndIf;
	
	Product = Record.Product; 
	
	UpdatePrices();

EndProcedure

&AtClient
Procedure ProductCategoryOnChange(Item)
	
	If Record.ProductCategory = ProductCategoryEmptyRef() Then
		Items.ProductCategory.MarkIncomplete = True;
	Else
		Items.ProductCategory.MarkIncomplete = False;
	EndIf;

EndProcedure

&AtClient
Procedure PriceLevelOnChange(Item)
	
	If Record.PriceLevel = PriceLevelEmptyRef() Then
		Items.PriceLevel.MarkIncomplete = True;
	Else
		Items.PriceLevel.MarkIncomplete = False;
	EndIf;

EndProcedure


&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	companies_webhook = Constants.items_webhook.Get();
	
	If NOT companies_webhook = "" Then
		
		//double_slash = Find(companies_webhook, "//");
		
		//companies_webhook = Right(companies_webhook,StrLen(companies_webhook) - double_slash - 1);
		
		//first_slash = Find(companies_webhook, "/");
		//webhook_address = Left(companies_webhook,first_slash - 1);
		//webhook_resource = Right(companies_webhook,StrLen(companies_webhook) - first_slash + 1); 		
		
		WebhookMap = GeneralFunctions.ReturnProductObjectMap(Record.Product);
		WebhookMap.Insert("resource","price level");
		If (Record.PriceLevel <> Catalogs.PriceLevels.EmptyRef()) Then
			WebhookMap.Insert("modified_price_level",Record.PriceLevel.Description);
		EndIf;

		If NewRecord = True Then
			WebhookMap.Insert("action","create");
		Else
			WebhookMap.Insert("action","update");
		EndIf;
		WebhookMap.Insert("apisecretkey",Constants.APISecretKey.Get());
		WebhookParams = New Array();
		WebhookParams.Add(Constants.items_webhook.Get());
		WebhookParams.Add(WebhookMap);
		LongActions.ExecuteInBackground("GeneralFunctions.SendWebhook", WebhookParams);
		
	
	EndIf;
	
	If Constants.zoho_auth_token.Get() <> "" AND Record.PriceType = "ItemPriceLevel" Then
		zoho_Functions.zoho_UpdatePricebook(Record.PriceLevel.Ref,Record.Product.Ref, Record.Price);
	EndIf;

EndProcedure

&AtClient
Procedure PriceOnChange(Item)
	
	If ValueIsFilled(Record.Product) Then
		Record.Price = Round(Record.Price, GeneralFunctionsReusable.PricePrecisionForOneItem(Record.Product));
	EndIf;
	
EndProcedure

&AtClient
Procedure CostOnChange(Item)
	
	If ValueIsFilled(Record.Product) Then
		Record.Cost = Round(Record.Cost, GeneralFunctionsReusable.PricePrecisionForOneItem(Record.Product));
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdatePrices()
	
	If ValueIsFilled(Record.Product) Then
		Record.Price = Round(Record.Price, GeneralFunctionsReusable.PricePrecisionForOneItem(Record.Product));
		Record.Cost = Round(Record.Cost, GeneralFunctionsReusable.PricePrecisionForOneItem(Record.Product));
	EndIf;
	
EndProcedure