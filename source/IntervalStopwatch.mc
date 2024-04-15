using Toybox.Application as App;
using Toybox.Attention as Attn;
using Toybox.Time as Time;
using Toybox.Timer as Timer;
using Toybox.System as Sys;
using Toybox.WatchUi as Ui;
using Toybox.Sensor;


//! Main application. Creates the initial view and provides some high-level callback methods related to user attention
class IntervalStopwatchApp extends App.AppBase {
		hidden const VIBRATE_DUTY_CYCLE = 100; // Max vibration frequency/strength
		hidden var racersCount = 6;
		hidden var startGap = 10;
		// Using global clock timer to get around Connect IQ issue where "too many timers" exception may be raised incorrectly
		hidden var clockTimer;

		hidden var manager;
		hidden var view;
		hidden var propertyHandler;

	  //! Init the app
	  function initialize() {
		  App.AppBase.initialize();
	  }

    //! onStart() is called on application start up
    function onStart(state) {
    	// SET APPROPRIATELY BEFORE DEPLOYMENT/RELEASE
		  clockTimer = null;  // new Timer.Timer();
		  manager = new TimeManager(clockTimer, racersCount, startGap);
    	view = new IntervalStopwatchView(manager, clockTimer);
    	propertyHandler = new PropertyHandler();
    	propertyHandler.loadPreviousProperties(manager);
    }

    //! onStop() is called when your application is exiting
    function onStop(state) {
    	propertyHandler.storeProperties(manager);
    //	manager.dereference();
    }

    //! Return the initial view of your application here
    function getInitialView() {
        return [ view, new IntervalStopwatchDelegate(manager, view, null, clockTimer) ];
    }

    //! Handle when a timer is started in the application
	//!
	//! @param [EggTimer] timer that started
    function timerStarted(timer) {
   		if (Sys.getDeviceSettings().vibrateOn) {
				Attn.vibrate([ new Attn.VibeProfile(VIBRATE_DUTY_CYCLE, 250) ]);
			}

			// Not actually applicable on Vivoactive, just adding in case of additional device support
			if (Attn has :playTone && Sys.getDeviceSettings().tonesOn) {
				Attn.playTone(Attn.TONE_START);
			}
    }

    //! Handle when a timer is stopped in the application
	//!
	//! @param [EggTimer] timer that stopped
    function timerStopped(timer) {
    	if (Sys.getDeviceSettings().vibrateOn) {
			  Attn.vibrate([ new Attn.VibeProfile(VIBRATE_DUTY_CYCLE, 500) ]);
		  }

		  // Not actually applicable on Vivoactive, just adding in case of additional device support
		  if (Attn has :playTone && Sys.getDeviceSettings().tonesOn) {
			  Attn.playTone(Attn.TONE_STOP);
		  }
    }

		function startNextRacer(startState) {
			
		}
}


//! Handles user interaction with the timers
class IntervalStopwatchDelegate extends Ui.BehaviorDelegate {
	hidden var manager;
	hidden var view;
	hidden var propertyHandler;
	hidden var clockTimer;
	hidden var logger;

	//! Creates a delegate instance
	//!
	//! @param [TimerManager] manager
	//! @param [PropertyHandler] propertyHandler
	//! @param [Timer] masterClockTimer
	function initialize(manager, view, propertyHandler, clockTimer) {
		Ui.BehaviorDelegate.initialize();
		self.view = view;
		self.manager = manager;
		self.propertyHandler = propertyHandler;
		self.clockTimer = clockTimer;
	}

    //! Handle general hardware key presses
	//!
	//! @param evt
	function onKey(evt) {
		// Sys.println("Key press: " + evt.getKey());
		if (view.isMenuShown()) {
			if (Ui.KEY_ENTER == evt.getKey()) {
				if (view.getMenuPage()==1) {
					manager.setCurrentRacersCount(view.getNewSetupValue());
					view.showNextMenuPage();
				} else {
					if (view.getMenuPage()==2) {
						manager.setStartGap(view.getNewSetupValue());
						view.showNextMenuPage();
					}	else {
						if (view.getMenuPage()==3) {
							manager.setState3Sec(view.getNewSetupValue());
							view.hideMenu();
						} else {
							view.hideMenu();
						}
					}
				}
			} else if (Ui.KEY_ESC == evt.getKey()) {
				view.hideMenu();
				Sys.println("ESC");
				return false;
			} else if (Ui.KEY_UP == evt.getKey()) {
				Sys.println("UpkeyM");
				view.updateSetupValue(1);
			} else if (Ui.KEY_DOWN == evt.getKey()) {
				Sys.println("DownkeyM");
				view.updateSetupValue(-1);
			}
			view.updateOnTimer();
			return true;
		} 
		if (Ui.KEY_ENTER == evt.getKey()) {
			if (manager.isStopwatchRunning()) {
				var racersInFinish = manager.setFinishTime();
				view.setOffset(racersInFinish);
			} else {
				Sys.println("Start in 3s");
				manager.startStopwatchIn3sec();
			}
		} else if (Ui.KEY_ESC == evt.getKey()) {
			if (manager.isStopwatchRunning()) {
				manager.resetFinishTimes();
				view.hideMenu();
				Sys.println("Race canceled");
			} else {
				// Exit application
				Ui.popView(Ui.SLIDE_IMMEDIATE);
			}
		} else if (Ui.KEY_UP == evt.getKey()) {
			Sys.println("Upkey");
			view.changeOffset(1);
		} else if (Ui.KEY_DOWN == evt.getKey()) {
			Sys.println("Downkey");
			view.changeOffset(-1);
		}
		view.updateOnTimer();
		return true;
	}

	//! Specifically handles the menu key press
    function onMenu() {
			Sys.println("OnMenu");
    	return menuPress();
	}

	function onBack() {
		// Exit application
		Sys.println("onBack");
		if (view.isMenuShown()) {
			view.hideMenu();
		} else {
			if (manager.isStopwatchRunning()) {
				manager.resetFinishTimes();
				view.hideMenu();
				Sys.println("Race canceled");
			} else {
				Ui.popView(Ui.SLIDE_IMMEDIATE);
			}
		}
		return true;
	}

	hidden function menuPress() {
		manager.resetFinishTimes();
		view.showNextMenuPage();
    return true;
	}
}
