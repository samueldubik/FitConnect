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
import Toybox.Timer;

class FitConnectIQView extends WatchUi.View {

    hidden var mFormatter;

    hidden var mStatus = "Ready";
    hidden var mLastAction = "--";
    hidden var mLastResult = "--";
    hidden var mLastTimer = "--";
    hidden var mTransmitInProgress = false;
    hidden var mTransportBlocked = false;
    hidden var mTransmitTimer;

    function initialize() {
        View.initialize();
        mFormatter = new FitConnectDataFormatter();
        mTransmitTimer = new Timer.Timer();
    }

    function collectData() {
        if (mTransportBlocked) {
            setWatchStatus("Blocked", "Transmit", "Restart app to retry");
            return;
        }

        if (mTransmitInProgress) {
            setWatchStatus("Busy", "Transmit", "Already in progress");
            return;
        }

        setWatchStatus("Collecting", "Payload", "Reading sensors");

        var mockPayload = "ping from watch";

        setWatchStatus("Sending", "Payload", mockPayload);

        mTransmitInProgress = true;

        Communications.transmit(
            mockPayload,
            {},
            new FitConnectTransmitCallback(self)
        );

        mTransmitTimer.start(method(:onTransmitTimeout), 6000, false);

        setWatchStatus("Waiting", "Transmit", "Queued");
    }

    function onTransmitTimeout() as Void {
        if (!mTransmitInProgress) {
            return;
        }

        mTransmitInProgress = false;
        mTransportBlocked = true;
        setWatchStatus("Timeout", "Transmit", "Blocked after 6s");
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
        mTransmitTimer.stop();
        mTransmitInProgress = false;
        mTransportBlocked = false;

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

    function onReceivePhoneMessage(message) {
        setWatchStatus("Received", "Android -> Watch", message.toString());
    }
}
