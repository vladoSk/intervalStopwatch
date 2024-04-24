using Toybox.Application as App;
using Toybox.Time as Time;
using Toybox.System as Sys;

//! Retrieves and stores application properties
class PropertyHandler {
	hidden const START_GAP = "START_GAP";
	hidden const CURRENT_RACERS_COUNT = "CURRENT_RACERS_COUNT";
	hidden const STATE_3SEC_COUNTDOWN = "STATE_3SEC_COUNTDOWN";
	
	hidden var logger;

	//! Create a PropertyHandler
	function initialize() {
		
	}
	function storeProperties(manager) {
		App.getApp().setProperty(START_GAP, manager.getStartGap());
		App.getApp().setProperty(CURRENT_RACERS_COUNT, manager.getCurrentRacersCount());
		App.getApp().setProperty(STATE_3SEC_COUNTDOWN, manager.getState3Sec());
		Sys.println("_storeProperties_");
	}

	function loadPreviousProperties(manager) {
		var startGap = App.getApp().getProperty(START_GAP);
		if (startGap != null) { manager.setStartGap(startGap); }
		var currentRacersCount = App.getApp().getProperty(CURRENT_RACERS_COUNT);
		if (currentRacersCount != null) { manager.setCurrentRacersCount(currentRacersCount); }
		var state3Sec = App.getApp().getProperty(STATE_3SEC_COUNTDOWN);
		if (state3Sec != null) { manager.setState3Sec(state3Sec); }
		Sys.println("_loadPreviousProperties_");
	}
}