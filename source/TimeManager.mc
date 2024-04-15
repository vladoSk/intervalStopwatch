using Log4MonkeyC as Log;
using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.Timer as Timer;
using Toybox.Attention as Attn;
import Toybox.Lang;

class Racer {
  var startPos as Number = 0;
  var finishPos as Number = 0;
  var finishTime as Number = 0;
}

//! Class responsible for creating and starting/stopping [EggTimer]s
class TimeManager {
	static const MAX_MANAGED_RACERS_COUNT = 12;
	static const TIMER_INCREMENT = 10;

	hidden var timerCount = 0;
	hidden var racer as Array <Racer> = new Array<Racer> [ MAX_MANAGED_RACERS_COUNT ];
//var typedArray as Array<Number> = new Array<Number>[10];
	hidden var currentRacersCount = 0;
	hidden var racersOnTrack = 0;
	hidden var selectedTime;
	hidden var racersStarted = 0;
	hidden var racersInFinish = 0;
	hidden var startGap;
	hidden var state3Sec = 1;
	hidden var clockTimer;
	hidden var clockTimerIsRunning;
	hidden var timerCountdown;
	hidden var startSysTimer = 0;
	hidden var waitText= "Ready?";

	//! Creates a TimerManager instance
	//!
	//! @param [Method] timerStartedCallback Method to call when a timer starts
	//! @param [Method] timerStoppedCallback Method to call when a timer stops
	//! @param [Method] timerFinishedCallback Method to call when a timer finishes
	function initialize(clockTimer, currentRacersCount, startGap) {
		self.currentRacersCount = currentRacersCount;
		self.startGap = startGap;
		self.clockTimer = clockTimer;
		self.clockTimerIsRunning = false;
		self.timerCountdown = new Timer.Timer();
		for (var i=0;i<MAX_MANAGED_RACERS_COUNT;i++) {
			racer[i] = new Racer();
		}
	}

	//! @return [Boolean] True if a timer can be added
	function maxManagedRacersCount() {
		return MAX_MANAGED_RACERS_COUNT;
	}

	//! Add a timer, selecting it in the process. This timer begins in a stopped state
	//!
	//! @param [Number] duration, in ms
	//! @param [Number] elapsedTime, in ms
	function setStartGap(newStartGap) {
		self.startGap = newStartGap;
	}

	function getStartGap() {
		return startGap;
	}

	function setCurrentRacersCount(newRacersCount) {
		self.currentRacersCount = newRacersCount;
	}
	function getCurrentRacersCount() {
		return self.currentRacersCount;
	}

	function getState3Sec() {
		return self.state3Sec;
	}
	function setState3Sec(newState3Sec) {
		self.state3Sec = newState3Sec;
	}
	//! Add a timer, selecting it in the process
	//!
	//! @param [Number] duration, in ms
	//! @param [Number] elapsedTime, in ms
	//! @param [Boolean] startAutomatically if true, else begin in a stopped state
	function setFinishTime() as Number {
		racer[racersInFinish].finishTime = getMainStopwatchTime();
		racer[racersInFinish].finishPos = racersInFinish;
		Sys.println("setFinishTime: "+racersInFinish.toString()+". "+racer[racersInFinish].finishTime.toString());
		++racersInFinish;
		if (racersInFinish == currentRacersCount) {
			clockTimerIsRunning = false;
		}
		return racersInFinish;
	}

	//! @return [Number] The number of timers
	function getFinishTime(racerNumber) {
		return racer[racerNumber].finishTime;
	}

	//! Clear the  times
	function resetFinishTimes() {
		waitText = "Ready?";
		timerCountdown.stop();
		clockTimerIsRunning = false;
		startSysTimer = 0;
		for (var i=0; i<MAX_MANAGED_RACERS_COUNT; i++) {
			racer[i].startPos = 0;
			racer[i].finishPos = 0;
			racer[i].finishTime = 0;
		}
	}

	function shortBeep1() {	
		timerCountdown.start(method(:shortBeep2), 1000, false);
		waitText = "Set 2";
		if (Attn has :playTone && Sys.getDeviceSettings().tonesOn) {
			Attn.playTone(Attn.TONE_START);
		}
	}
	function shortBeep2() {	
		timerCountdown.start(method(:startCountdownCallback), 1000, false);
		waitText = "Set 1";
		if (Attn has :playTone && Sys.getDeviceSettings().tonesOn) {
			Attn.playTone(Attn.TONE_START);
		}
	}
	function startCountdownCallback() {
		if (startGap == 0) {
			racersOnTrack = currentRacersCount;
			racersStarted = currentRacersCount;
		} else {
			racersOnTrack++;
			racersStarted++;
		}
		if (racersStarted < currentRacersCount) {
			var nextStart = startGap*1000*racersStarted - (Sys.getTimer() - startSysTimer);
			Sys.print("NextStart = ");
			Sys.println(nextStart);
			if (nextStart - 2000 > 0) { 
				timerCountdown.start(method(:shortBeep1), nextStart - 2000, false);
			} else {
				if (nextStart - 1000 > 0) { 
					timerCountdown.start(method(:shortBeep2), nextStart - 1000, false);
				} else {
					timerCountdown.start(method(:startCountdownCallback), nextStart, false);
				}
			}
		} else {
			waitText = "Finished";
		}
		if (!clockTimerIsRunning) {
			clockTimerIsRunning = true;
		}
		if (Attn has :playTone && Sys.getDeviceSettings().tonesOn) {
			Attn.playTone(Attn.TONE_LOUD_BEEP);
		}
	}

	function startStopwatchIn3sec() {
		if (waitText == "Finished") {
			waitText = "Ready?";
			return;
		}
		racersStarted = 0;
		racersInFinish = 0;
		timerCountdown.start(method(:shortBeep1), 1000, false);
	// 	timerS2.start(method(:shortBeep2), 2000, false);
	//	timerCountdown.start(method(:startCountdownCallback), 3000, false);
		startSysTimer = Sys.getTimer() + 3000;
	}

	function getMainStopwatchTime() {
		if (clockTimerIsRunning) {
			// return timeElapsed - (racersInFinish * startGap*1000);
			return Sys.getTimer() - (startSysTimer + (racersInFinish * startGap*1000));
		}
		return 0;
	}

	function getStopwatchTimeNo(number as Number) {
		if (number < racersInFinish) {
			return racer[number].finishTime;
		} else {
			return 0;
		}
	}

	function isStopwatchRunning() {
		return clockTimerIsRunning; 
	}

	function getRacersInFinish() {
		return racersInFinish;
	}

	function getWaitText() {
		return waitText;
	}
}