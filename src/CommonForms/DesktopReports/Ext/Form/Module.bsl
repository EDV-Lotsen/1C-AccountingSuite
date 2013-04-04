
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Reports = "Select...";
	
EndProcedure

&AtClient
Procedure ReportsOnChange(Item)
	
	If Reports = "A/R Aging" Then
		OpenForm("Report.ARAging.Form.ReportForm"); 
	ElsIf Reports = "A/P Aging" Then
		OpenForm("Report.APAging.Form.ReportForm");
	ElsIf Reports = "General Ledger" Then
		OpenForm("Report.GeneralLedger.Form.ReportForm");
	ElsIf Reports = "Trial Balance" Then
		OpenForm("Report.TrialBalance.Form.ReportForm");
	ElsIf Reports = "Income Statement" Then
		OpenForm("Report.IncomeStatement.Form.ReportForm");
	ElsIf Reports = "Balance Sheet" Then
		OpenForm("Report.BalanceSheet.Form.ReportForm");
	ElsIf Reports = "Cash Flow (direct)" Then
		OpenForm("Report.CashFlowDirect.Form.ReportForm");
	ElsIf Reports = "Inventory Balances" Then
		OpenForm("Report.InventoryBalances.Form.ReportForm");
	ElsIf Reports = "Sales Transaction Detail" Then
		OpenForm("Report.SalesTransactionDetail.Form.ReportForm");
	ElsIf Reports = "Purchasing Transaction Detail" Then
		OpenForm("Report.PurchasingTransactionDetail.Form.ReportForm");
	EndIf;

EndProcedure
