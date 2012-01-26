// Indicates that in the current session a repeated installation isn't offered
Var AskToInstallFileExtensionModule Export;


// Launches the function that checks if this is the first start of the system,
// and if yes prefills the database with default values and settings.
//
Procedure OnStart()
	
	GeneralFunctions.FirstStart();
	GeneralFunctions.VATSetup();
	
EndProcedure


