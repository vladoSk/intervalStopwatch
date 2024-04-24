using Toybox.Graphics as Gfx;
using Toybox.WatchUi as Ui;
using Toybox.System as Sys;
using Toybox.Time.Gregorian as Cal;
import Toybox.Lang;

const VERSION = "1.03";

const tfSSSUU = 1;		// M - min, S - sec, U - microsec  134.12
const tfMMSSU = 2;		// 11:23.3
const tfHHMMSS = 3; 	// 12:34:56
class MenuDefinition {
  var minValue as Number = 0;
  var maxValue as Number = 0;
  var step as Number = 0;
	var text as String = "";

	function initialize(minValue,maxValue,step,text){
		self.minValue = minValue;
		self.maxValue = maxValue;
		self.step = step;
		self.text = text;
	}

}
//! Main timer UI view
class IntervalStopwatchView extends Ui.View {
	hidden const MASTER_TIMER_INCREMENT = 200;	// ms

	hidden var manager;
	hidden var refreshTimer;
	hidden var refreshTimerStarted = false;
	hidden var separatorLabel;
	hidden var logger;
	hidden var timesOffset = 1;
	hidden var newSetupValue = 0;
	hidden var menuPage = 0;
	hidden var timeFormat = tfSSSUU;
  hidden var menu as Array <MenuDefinition> = new Array<MenuDefinition> [ 3 ];

	//! Creates an EggTimerView
	//!
	//! @param [TimerManager] manager
	//! @param [Timer] masterClockTimer
	/*
			menuText = menu[menuPage].text;
		menuMinValue = menu[menuPage].minValue;
		menuMaxValue = menu[menuPage].maxValue;
		menuStep = menu[menuPage].step;
*/
	function initialize(manager, clockTimer) {
		Ui.View.initialize();
		self.manager = manager;
		self.refreshTimer = new Timer.Timer();
		separatorLabel = new Rez.Drawables.clockSeparator();
		menu[0] = new MenuDefinition(1,100,1,"Racers count");
		menu[1] = new MenuDefinition(0,900,5,"Start gap");
		menu[2] = new MenuDefinition(0,1,1, "3sec countdown");
	}

    //! Load resources
	//!
	//! @param [Graphics.dc] dc
	function onLayout(dc) {
			setLayout(Rez.Layouts.MainLayout(dc));
			separatorLabel.draw(dc);
	}

	//! Called when this View is brought to the foreground. Restore
	//! the state of this View and prepare it to be shown. This includes
	//! loading resources into memory.
	function onShow() {
		hideMenu();
		updateClockTimeUi();
		if (!refreshTimerStarted) {
			refreshTimer.start(method(:updateOnTimer), MASTER_TIMER_INCREMENT, true);
			refreshTimerStarted = true;
		}
	}

	//! Update the view
//!
//! @param [Graphics.dc] dc
	function onUpdate(dc) {
		//System.println("On update event");
			// Call the parent onUpdate function to redraw the layout
			View.onUpdate(dc);
			updateTimersUi();
			separatorLabel.draw(dc);
			
	}

	//! Called when this View is removed from the screen. Save the
	//! state of this View here. This includes freeing resources from
	//! memory.
	function onHide() {
		refreshTimer.stop();
	}

	//! Callback function for view timer
//!
//! This function would ideally be hidden but that would prevent it from being used as a timer callback in Monkey C
	function updateOnTimer() {
		if (menuPage > 0) {
			drawMenuPage();
		} else {
			updateTimersUi();
		}
		Ui.requestUpdate();
	}

	function showNextMenuPage() {
		menuPage++;
		if (menuPage==1) { newSetupValue = manager.getCurrentRacersCount(); }
		if (menuPage==2) { newSetupValue = manager.getStartGap(); }
		if (menuPage==3) { newSetupValue = manager.getState3Sec(); }
	}

	function getMenuPage() {
		return menuPage;
	}
	
	function hideMenu() {
		var timerDrawable;
		menuPage = 0;
		for (var i=2;i<5; i++) {
			timerDrawable = (i+timesOffset).toString()+". "+getTimeFormatted(manager.getStopwatchTimeNo(i+timesOffset-1));
			timerDrawable = (findDrawableById("timer"+i.toString()) as Toybox.WatchUi.Text);
			if (timerDrawable != null) {
				timerDrawable.setText("");	// (i+1).toString()
			}
		}
		timerDrawable = (findDrawableById("timer0") as Toybox.WatchUi.Text);
		if (timerDrawable != null) {
			timerDrawable.setText("Racers:"+manager.getCurrentRacersCount().toString());
		}
		timerDrawable = (findDrawableById("timer1") as Toybox.WatchUi.Text);
		if (timerDrawable != null) {
			timerDrawable.setText("Start gap:"+manager.getStartGap().toString());
		}
		timerDrawable = (findDrawableById("timer2") as Toybox.WatchUi.Text);
		if (timerDrawable != null) {
			if (manager.getState3Sec()) {
				timerDrawable.setText("3sec countdown");
			} else {
				timerDrawable.setText("No countdown");
			}
		}
		timerDrawable = (findDrawableById("timer3") as Toybox.WatchUi.Text);
		if (timerDrawable != null) {
			timerDrawable.setText("");
		}
		timerDrawable = (findDrawableById("timer4") as Toybox.WatchUi.Text);
		if (timerDrawable != null) {
			timerDrawable.setText("");
		}
		timesOffset = 1;
	}

	hidden function drawMenuPage(){
		var timerDrawable;
		Sys.println("menuPage "+menuPage.toString());
		timerDrawable = (findDrawableById("mainTime") as Toybox.WatchUi.Text);
		if (timerDrawable != null) {
			timerDrawable.setText("SETUP");
		}
		timerDrawable = (findDrawableById("timer0") as Toybox.WatchUi.Text);
		if (timerDrawable != null) {
			Sys.println(menu[menuPage-1].text);
			timerDrawable.setText(menu[menuPage-1].text);
		}
		timerDrawable = (findDrawableById("timer1") as Toybox.WatchUi.Text);
		if (timerDrawable != null) {
			timerDrawable.setText("");
		}
		timerDrawable = (findDrawableById("timer2") as Toybox.WatchUi.Text);
		if (timerDrawable != null) {
			Sys.println(newSetupValue);
			timerDrawable.setText(newSetupValue.toString());
		}
		timerDrawable = (findDrawableById("timer3") as Toybox.WatchUi.Text);
		if (timerDrawable != null) {
			timerDrawable.setText("");
		}
		timerDrawable = (findDrawableById("timer4") as Toybox.WatchUi.Text);
		if (timerDrawable != null) {
			timerDrawable.setText("ver.: "+VERSION);
		}
	}

	hidden function updateTimersUi() {
		var timerDrawable;
		var mainTime = manager.getMainStopwatchTime();
		var timeRemainingText;
		if ( mainTime != 0) {
			timeRemainingText = getTimeFormatted(mainTime);
			timerDrawable = (findDrawableById("mainTime") as Toybox.WatchUi.Text);
			if (timerDrawable != null) {
				timerDrawable.setText(timeRemainingText);
			}
			if (!manager.showMessage().equals("")) {
				timerDrawable = (findDrawableById("timer0") as Toybox.WatchUi.Text);
				timerDrawable.setText("");
				timerDrawable = (findDrawableById("timer1") as Toybox.WatchUi.Text);
				timerDrawable.setText(manager.showMessage());
				timerDrawable = (findDrawableById("timer2") as Toybox.WatchUi.Text);
				timerDrawable.setText("");
				timerDrawable = (findDrawableById("timer3") as Toybox.WatchUi.Text);
				timerDrawable.setText("<- Yes     ");
				timerDrawable = (findDrawableById("timer4") as Toybox.WatchUi.Text);
				timerDrawable.setText("");
				return;
			} 
			for (var i=0;i<manager.getDisplayTimesCount(); i++) {
				timeRemainingText = (i+timesOffset).toString()+". "+getTimeFormatted(manager.getStopwatchTimeNo(i+timesOffset-1));
				timerDrawable = (findDrawableById("timer"+i.toString()) as Toybox.WatchUi.Text);
				if (timerDrawable != null) {
					timerDrawable.setText(timeRemainingText);
				}
			}
		}
		else {
			timerDrawable = (findDrawableById("mainTime") as Toybox.WatchUi.Text);
			if (timerDrawable != null) {
				var waitText = manager.getWaitText();
				timerDrawable.setText(waitText);
			}
			if (manager.getRacersInFinish() > 0) {
				for (var i=0;i<manager.getDisplayTimesCount(); i++) {
					timeRemainingText = (i+timesOffset).toString()+". "+getTimeFormatted(manager.getStopwatchTimeNo(i+timesOffset-1));
					timerDrawable = (findDrawableById("timer"+i.toString()) as Toybox.WatchUi.Text);
					if (timerDrawable != null) {
						timerDrawable.setText(timeRemainingText);
					}
				}
			}
		}
	}

	hidden function updateClockTimeUi() {
		
		var currentTimeLabel = (findDrawableById("mainTime") as Toybox.WatchUi.Text);
		var clockTime = manager.getMainStopwatchTime();
		var min = ((clockTime / 1000) / 60).toNumber();
		var sec = ((clockTime / 1000).toNumber()) % 60;
		Sys.print("Update: ");
		Sys.println(clockTime.toString());
		var timeText = min.format("%02d") + ":" + sec.format("%02d");
		if (currentTimeLabel != null) {
			currentTimeLabel.setText(timeText);
		}
	}

	hidden function getTimeFormatted(timeRemainingSeconds) {
		var timeRemainingText = 0;
		if (timeFormat == tfMMSSU) {
			var minutes = ((timeRemainingSeconds).toNumber()/1000 / Cal.SECONDS_PER_MINUTE).toNumber();
			var seconds = ((timeRemainingSeconds).toNumber() / 1000).toNumber() % Cal.SECONDS_PER_MINUTE;
			var millisec = ((timeRemainingSeconds).toNumber()/10).toNumber() % 10;  // 1/10sec.
			timeRemainingText = minutes.format("%01d") + ":" + seconds.format("%02d")+"."+millisec.format("%01d");

		} else if (timeFormat == tfSSSUU) {
			var seconds = ((timeRemainingSeconds).toNumber() / 1000).toNumber();
			var millisec = ((timeRemainingSeconds).toNumber()/10).toNumber() % 100;  // 1/100sec.
			timeRemainingText = seconds.format("%01d") + "." + millisec.format("%02d");
		} else if (timeFormat == tfHHMMSS) {
			var hours = ((timeRemainingSeconds).toNumber()/1000 / Cal.SECONDS_PER_HOUR).toNumber();;
			var minutes = ((timeRemainingSeconds).toNumber()/1000 / Cal.SECONDS_PER_MINUTE).toNumber();
			var seconds = ((timeRemainingSeconds).toNumber() / 1000).toNumber() % Cal.SECONDS_PER_MINUTE;
			timeRemainingText = hours.format("%01d") + ":" + minutes.format("%01d") + ":" + seconds.format("%02d");

		}
		return timeRemainingText;
	}

	function changeOffset(offsetChange) {
		Sys.println(manager.getCurrentRacersCount());
		if (offsetChange > 0 && timesOffset+5<= manager.getCurrentRacersCount() ) { 
			Sys.println("U");
			timesOffset++; }
		if (offsetChange < 0 && timesOffset > 1 ) { 
			Sys.println("D");
			timesOffset--; }
		Sys.print("timesOffset=");
		Sys.println(timesOffset);
	}

	function setOffset(newOffset) {
		if (timesOffset > newOffset) { timesOffset = newOffset; }
		if (timesOffset + 4 < newOffset) { timesOffset = newOffset - 4; }
	}

	function updateSetupValue(direction) {
		var number = direction * menu[menuPage-1].step;
		if (newSetupValue+number < menu[menuPage-1].minValue) { return; } 
		if (newSetupValue+number > menu[menuPage-1].maxValue) { return; }
		newSetupValue += number; 
	}

	function getNewSetupValue() {
		return newSetupValue; 
	}

	function isMenuShown() {
		return menuPage > 0;
	}
}
