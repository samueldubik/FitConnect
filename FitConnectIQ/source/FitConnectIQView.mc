import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.ActivityMonitor;
import Toybox.Sensor;
import Toybox.Communications;



class FitConnectIQView extends WatchUi.View {

    hidden var mHeartRate = "--";
    hidden var mSteps = "--";
    hidden var mBattery = "--";
    hidden var mStatus = "Press START";
    hidden var mFormatter;

       
       
    function initialize() {
        View.initialize();
        mFormatter = new FitConnectDataFormatter();
    }


    function collectData() {

    // ====================
    // System
    // ====================

    var clockTime = System.getClockTime();
    var deviceSettings = System.getDeviceSettings();
    var displayMode = System.getDisplayMode();
    var systemStats = System.getSystemStats();
    var timer = System.getTimer();

    // ====================
    // Activity Monitor
    // ====================

    var activityInfo = ActivityMonitor.getInfo();
    var heartRateHistory = ActivityMonitor.getHeartRateHistory(null, false);
    var activityHistory = ActivityMonitor.getHistory();

    // ====================
    // Live Sensors
    // ====================

    var sensorInfo = Sensor.getInfo();

    // ====================
    // Sensor History
    // ====================

    var sensorHeartRateHistory = SensorHistory.getHeartRateHistory({});
    var sensorStressHistory = SensorHistory.getStressHistory({});
    var sensorBodyBatteryHistory = SensorHistory.getBodyBatteryHistory({});
    var sensorOxygenHistory = SensorHistory.getOxygenSaturationHistory({});
    var sensorTemperatureHistory = SensorHistory.getTemperatureHistory({});
    var sensorPressureHistory = SensorHistory.getPressureHistory({});
    var sensorElevationHistory = SensorHistory.getElevationHistory({});

    // ====================
    // Position
    // ====================

    var positionInfo = Position.getInfo();

    // ====================
    // User Profile
    // ====================

    var userProfile = UserProfile.getProfile();

    // ====================
    // Weather
    // ====================

    var weatherCurrentConditions = Weather.getCurrentConditions();
    var weatherDailyForecast = Weather.getDailyForecast();
    var weatherHourlyForecast = Weather.getHourlyForecast();

    
    var payload = mFormatter.formatData({
    :clockTime => clockTime,
    :deviceSettings => deviceSettings,
    :displayMode => displayMode,
    :systemStats => systemStats,
    :timer => timer,

    :activityInfo => activityInfo,
    :heartRateHistory => heartRateHistory,
    :activityHistory => activityHistory,

    :sensorInfo => sensorInfo,

    :sensorHeartRateHistory => sensorHeartRateHistory,
    :sensorStressHistory => sensorStressHistory,
    :sensorBodyBatteryHistory => sensorBodyBatteryHistory,
    :sensorOxygenHistory => sensorOxygenHistory,
    :sensorTemperatureHistory => sensorTemperatureHistory,
    :sensorPressureHistory => sensorPressureHistory,
    :sensorElevationHistory => sensorElevationHistory,

    :positionInfo => positionInfo,

    :userProfile => userProfile,

    :weatherCurrentConditions => weatherCurrentConditions,
    :weatherDailyForecast => weatherDailyForecast,
    :weatherHourlyForecast => weatherHourlyForecast
});

    // Put breakpoint here and inspect payload
    System.println("Payload created");

    var options = null;

    // Communications.transmit(
    //     payload,
    //     options,
    //     new FitConnectTransmitCallback()
    // );
}
        function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var w = dc.getWidth();
        var centerX = w / 2;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        dc.drawText(centerX, 35, Graphics.FONT_MEDIUM, "FitConnect", Graphics.TEXT_JUSTIFY_CENTER);

        dc.drawText(centerX, 90, Graphics.FONT_SMALL, "HR: " + mHeartRate, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX, 125, Graphics.FONT_SMALL, "Steps: " + mSteps, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX, 160, Graphics.FONT_SMALL, "Battery: " + mBattery, Graphics.TEXT_JUSTIFY_CENTER);

        dc.drawText(centerX, 215, Graphics.FONT_XTINY, mStatus, Graphics.TEXT_JUSTIFY_CENTER);
    }


}
