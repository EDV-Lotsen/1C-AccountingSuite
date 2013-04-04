
// The interface which determines common commands in the configuration
// that generate workspaces for calling additional data processors.
//
// Parameters:
//	No.
//
// Returns:
//  ValueTable - with names of common commands for calling additional data processors,
// 		it sould contain the fields defined in 
//		AdditionalReportsAndDataProcessors.CreateCommandsTable
//
Function GetAdditionalDataProcessorCommonCommands() Export
	
	CommandsTable = AdditionalReportsAndDataProcessors.CreateCommandsTable();
	
	AdditionalReportsAndDataProcessors.AddCommand(CommandsTable,
					"AdditionalDataProcessorsAccounting",
					NStr("en = 'default list'"));
	
	Return CommandsTable;
	
EndFunction

// The interface which determines common commands in the configuration
// that generate workspaces for calling additional reports.
//
// Parameters:
//	No.
//
// Returns:
//  ValueTable - with names of common commands for calling additional reports,
// 		it sould contain the fields defined in 
//		AdditionalReportsAndDataProcessors.CreateCommandsTable
//
Function GetAdditionalReportCommonCommands() Export
	
	CommandsTable = AdditionalReportsAndDataProcessors.CreateCommandsTable();
	
	AdditionalReportsAndDataProcessors.AddCommand(CommandsTable,
					"AdditionalReportsAccounting",
					NStr("en = 'default list'"));
	
	Return CommandsTable;
	
EndFunction
