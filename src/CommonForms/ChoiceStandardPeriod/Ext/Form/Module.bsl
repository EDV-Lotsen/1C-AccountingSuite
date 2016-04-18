
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillPropertyValues(ThisObject, Parameters, "BeginOfPeriod, EndOfPeriod");
	BeginDateYear = ?(ValueIsFilled(EndOfPeriod), BegOfYear(EndOfPeriod), BegOfYear(CurrentSessionDate()));
	If Parameters.SelectMonths Then
		Items.SelectQuarter1.Visible 	= False;
		Items.SelectQuarter2.Visible 	= False;
		Items.SelectQuarter3.Visible	= False;
		Items.SelectQuarter4.Visible 	= False;
		Items.Quarter.Visible			= False;
		Items.SelectHalfYear1.Visible	= False;
		Items.Select9Months.Visible 	= False;
		Items.SelectYear.Visible		= False;
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SetActivePeriod();
	
EndProcedure



&AtClient
Procedure GoToYearBack(Command)
	
	BeginDateYear = BegOfYear(BeginDateYear - 1);
	
	SetActivePeriod();
	
EndProcedure

&AtClient
Procedure NavigateToForwardOfYear(Command)
	
	BeginDateYear = EndOfYear(BeginDateYear) + 1;
	
	SetActivePeriod();
	
EndProcedure

&AtClient
Procedure SelectMonth1(Command)
	
	SelectMonth(1);
	
EndProcedure

&AtClient
Procedure SelectMonth2(Command)
	
	SelectMonth(2);
	
EndProcedure

&AtClient
Procedure SelectMonth3(Command)
	
	SelectMonth(3);
	
EndProcedure

&AtClient
Procedure SelectMonth4(Command)
	
	SelectMonth(4);
	
EndProcedure

&AtClient
Procedure SelectMonth5(Command)
	
	SelectMonth(5);
	
EndProcedure

&AtClient
Procedure SelectMonth6(Command)
	
	SelectMonth(6);
	
EndProcedure

&AtClient
Procedure SelectMonth7(Command)
	
	SelectMonth(7);
	
EndProcedure

&AtClient
Procedure SelectMonth8(Command)
	
	SelectMonth(8);
	
EndProcedure

&AtClient
Procedure SelectMonth9(Command)
	
	SelectMonth(9);
	
EndProcedure

&AtClient
Procedure SelectMonth10(Command)
	
	SelectMonth(10);
	
EndProcedure

&AtClient
Procedure SelectMonth11(Command)
	
	SelectMonth(11);
	
EndProcedure

&AtClient
Procedure SelectMonth12(Command)
	
	SelectMonth(12);
	
EndProcedure

&AtClient
Procedure SelectQuarter1(Command)
	
	SelectQuarter(1);
	
EndProcedure

&AtClient
Procedure SelectQuarter2(Command)
	
	SelectQuarter(2);
	
EndProcedure

&AtClient
Procedure SelectQuarter3(Command)
	
	SelectQuarter(3);
	
EndProcedure

&AtClient
Procedure SelectQuarter4(Command)
	
	SelectQuarter(4);
	
EndProcedure

&AtClient
Procedure SelectHalfYear1(Command)
	
	SelectHalfYear(1);
	
EndProcedure

&AtClient
Procedure SelectHalfYear2(Command)
	
	SelectHalfYear(2);
	
EndProcedure

&AtClient
Procedure Select9Months(Command)

	BeginOfPeriod = BeginDateYear;
	EndOfPeriod   = Date(Year(BeginDateYear), 9 , 30);
	ProceedPeriodSelection();
	
EndProcedure

&AtClient
Procedure SelectYear(Command)

	BeginOfPeriod = BeginDateYear;
	EndOfPeriod   = EndOfYear(BeginDateYear);
	ProceedPeriodSelection();
	
EndProcedure

&AtClient
Procedure SetActivePeriod()
	
	If BegOfMonth(BeginOfPeriod) = BegOfMonth(EndOfPeriod) Then
		MonthNumber = Month(BeginOfPeriod);
		CurrentItem = Items["SelectMonth" + MonthNumber];
		
	ElsIf BegOfQuarter(BeginOfPeriod) = BegOfQuarter(EndOfPeriod) Then
		MonthNumber = Month(BeginOfPeriod);
		QuartNumber = Int((MonthNumber + 3) / 3);
		CurrentItem = Items["SelectQuarter" + QuartNumber];
		
	ElsIf BegOfYear(BeginOfPeriod) = BegOfYear(EndOfPeriod) Then
		BegMonthNumber = Month(BeginOfPeriod);
		EndMonthNumber = Month(EndOfPeriod);
		If BegMonthNumber <= 3 And EndMonthNumber <= 6 Then
			CurrentItem = Items["SelectHalfYear1"];
		ElsIf BegMonthNumber <= 3 And EndMonthNumber <= 9 Then
			CurrentItem = Items["Select9Months"];
		Else
			CurrentItem = Items["SelectYear"];
		EndIf;
	Else
		CurrentItem = Items["SelectYear"];
	EndIf;
	
	CurrentItem.BackColor = ColorCurrentPeriod;
	
EndProcedure

&AtClient
Procedure ProceedPeriodSelection()
	
	SelectionResult = New Structure("BeginOfPeriod, EndOfPeriod", BeginOfPeriod, EndOfDay(EndOfPeriod));
	NotifyChoice(SelectionResult);
	
EndProcedure 

&AtClient
Procedure SelectMonth(MonthNumber)
	
	BeginOfPeriod = Date(Year(BeginDateYear), MonthNumber, 1);
	EndOfPeriod   = EndOfMonth(BeginOfPeriod);
	
	ProceedPeriodSelection();
	
EndProcedure

&AtClient
Procedure SelectQuarter(QuartNumber)
	
	BeginOfPeriod = Date(Year(BeginDateYear), 1 + (QuartNumber - 1) * 3, 1);
	EndOfPeriod   = EndOfQuarter(BeginOfPeriod);
	
	ProceedPeriodSelection();
	
EndProcedure

&AtClient
Procedure SelectHalfYear(HalfYearNumber)
	
	BeginOfPeriod = Date(Year(BeginDateYear), 1 + (HalfYearNumber - 1) * 6, 1);
	EndOfPeriod   = EndOfMonth(AddMonth(BeginOfPeriod, 5));
	
	ProceedPeriodSelection();
	
EndProcedure

