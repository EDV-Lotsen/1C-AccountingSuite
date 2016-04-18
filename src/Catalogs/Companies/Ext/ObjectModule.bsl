
Procedure BeforeWrite(Cancel)
	
	If NewObject = True Then
		NewObject = False
	Else
		If Ref = Catalogs.Companies.EmptyRef() Then
			NewObject = True;
		EndIf;
	EndIf;
	
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If ThisObject.IsNew() And Not ValueIsFilled(ThisObject.Code) Then ThisObject.SetNewCode(); EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	If ThisObject.IsNew() Then ThisObject.SetNewCode(); EndIf;
	
EndProcedure

Procedure OnSetNewCode(StandardProcessing, Prefix)
	
	StandardProcessing = False;
	
	Numerator = Catalogs.DocumentNumbering.Companies;
	NextNumber = GeneralFunctions.Increment(Numerator.Number);
	
	While Catalogs.Companies.FindByCode(NextNumber) <> Catalogs.Companies.EmptyRef() And NextNumber <> "" Do
		ObjectNumerator = Numerator.GetObject();
		ObjectNumerator.Number = NextNumber;
		ObjectNumerator.Write();
		
		NextNumber = GeneralFunctions.Increment(NextNumber);
	EndDo;
	
	ThisObject.Code = NextNumber; 
	
EndProcedure