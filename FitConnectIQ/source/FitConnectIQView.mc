import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.ActivityMonitor;
import Toybox.Sensor;
import Toybox.Communications;
import Toybox.SensorHistory;
import Toybox.Position;
import Toybox.UserProfile;
import Toybox.Weather;

class FitConnectIQView extends WatchUi.View {

    hidden var mFormatter;

    hidden var mStatus = "Ready";
    hidden var mLastAction = "--";
    hidden var mLastResult = "--";
    hidden var mLastTimer = "--";
    hidden var mTransmitInProgress = false;

    function initialize() {
        View.initialize();
        mFormatter = new FitConnectDataFormatter();
    }

    function collectData() {
        if (mTransmitInProgress) {
            setWatchStatus("Busy", "Transmit", "Already in progress");
            return;
        }

        setWatchStatus("Collecting", "Payload", "Reading sensors");

        var mockPayload = {
            "KEY_MESSAGE_TYPE" => "ping",
            "KEY_MESSAGE_PAYLOAD" => {
                "timer" =>System.getTimer()
                }
        };

        setWatchStatus("Sending", "Payload", "Ping created");

        mTransmitInProgress = true;

        Communications.transmit(
            mockPayload,
            null,
            new FitConnectTransmitCallback(self)
        );

        setWatchStatus("Waiting", "Transmit", "Queued");
    }

    function setWatchStatus(status, action, result) {
        mStatus = status;
        mLastAction = action;
        mLastResult = result;
        mLastTimer = System.getTimer().toString();

        System.println(status + " | " + action + " | " + result);
        WatchUi.requestUpdate();
    }

    function onTransmitFinished(success) {
        mTransmitInProgress = false;

        if (success) {
            setWatchStatus("Ready", "Transmit", "Complete");
        } else {
            setWatchStatus("Ready", "Transmit", "Error");
        }
    }

    function onUpdate(dc) {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var w = dc.getWidth();
        var centerX = w / 2;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        dc.drawText(centerX, 30, Graphics.FONT_MEDIUM, "FitConnect", Graphics.TEXT_JUSTIFY_CENTER);

        dc.drawText(centerX, 75, Graphics.FONT_SMALL, "Status: " + mStatus, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX, 110, Graphics.FONT_SMALL, "Action: " + mLastAction, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX, 145, Graphics.FONT_SMALL, "Result: " + mLastResult, Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(centerX, 180, Graphics.FONT_XTINY, "Timer: " + mLastTimer, Graphics.TEXT_JUSTIFY_CENTER);

        if (mTransmitInProgress) {
            dc.drawText(centerX, 220, Graphics.FONT_XTINY, "Please wait...", Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.drawText(centerX, 220, Graphics.FONT_XTINY, "Press START to send", Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
}