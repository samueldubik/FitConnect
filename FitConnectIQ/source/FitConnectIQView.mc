import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Communications;
import Toybox.Timer;

class FitConnectIQView extends WatchUi.View {

    hidden var mFormatter;

    hidden var mStatus = "Ready";
    hidden var mLastAction = "Waiting";
    hidden var mLastResult = "Press START to send";
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
            setWatchStatus("Blocked", "Restart the app to retry");
            return;
        }

        if (mTransmitInProgress) {
            setWatchStatus("Sending", "Message already in progress");
            return;
        }

        mTransmitInProgress = true;
        setWatchStatus("Preparing", "Creating message");

        // Keep this deliberately small until phone ↔ watch messaging works.
        var payload = {
            :type => "ping",
            :source => "watch",
            :message => "hello from Fenix 8",
            :timestamp => System.getTimer()
        };

        setWatchStatus("Sending", "Sending to iPhone");

        Communications.transmit(
            payload,
            {},
            new FitConnectTransmitCallback(self)
        );

        mTransmitTimer.start(method(:onTransmitTimeout), 6000, false);
        WatchUi.requestUpdate();
    }

    function onTransmitTimeout() as Void {
        if (!mTransmitInProgress) {
            return;
        }

        mTransmitInProgress = false;
        mTransportBlocked = true;

        setWatchStatus("Timeout", "No response after 6 seconds");
    }

    function onTransmitFinished(success) {
        mTransmitTimer.stop();
        mTransmitInProgress = false;
        mTransportBlocked = false;

        if (success) {
            setWatchStatus("Sent", "Message delivered");
        } else {
            setWatchStatus("Failed", "Phone connection unavailable");
        }
    }

    function onReceivePhoneMessage(message) {
        setWatchStatus("Received", message.toString());
    }

    function setWatchStatus(status, result) {
        mStatus = status;
        mLastResult = result;

        System.println(status + " | " + result);
        WatchUi.requestUpdate();
    }

    function onUpdate(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var centerX = width / 2;

        // AMOLED-friendly black background.
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Header
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            centerX,
            28,
            Graphics.FONT_MEDIUM,
            "FITCONNECT",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            centerX,
            58,
            Graphics.FONT_XTINY,
            "FENIX ↔ IPHONE BRIDGE",
            Graphics.TEXT_JUSTIFY_CENTER
        );

        // Status card
        var cardX = 24;
        var cardY = 94;
        var cardWidth = width - 48;
        var cardHeight = 126;

        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(cardX, cardY, cardWidth, cardHeight, 12);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cardX + 18,
            cardY + 18,
            Graphics.FONT_XTINY,
            "CONNECTION",
            Graphics.TEXT_JUSTIFY_LEFT
        );

        dc.setColor(statusColor(), Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cardX + 18,
            cardY + 48,
            Graphics.FONT_MEDIUM,
            mStatus,
            Graphics.TEXT_JUSTIFY_LEFT
        );

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            cardX + 18,
            cardY + 84,
            Graphics.FONT_XTINY,
            shorten(mLastResult, 27),
            Graphics.TEXT_JUSTIFY_LEFT
        );

        // Action area
        var actionY = height - 98;

        if (mTransmitInProgress) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                centerX,
                actionY,
                Graphics.FONT_SMALL,
                "SENDING...",
                Graphics.TEXT_JUSTIFY_CENTER
            );
        } else {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                centerX,
                actionY,
                Graphics.FONT_SMALL,
                "PRESS START",
                Graphics.TEXT_JUSTIFY_CENTER
            );

            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                centerX,
                actionY + 28,
                Graphics.FONT_XTINY,
                "Send test message to iPhone",
                Graphics.TEXT_JUSTIFY_CENTER
            );
        }
    }

    hidden function statusColor() {
        if (mStatus == "Ready" || mStatus == "Sent" || mStatus == "Received") {
            return Graphics.COLOR_GREEN;
        }

        if (mStatus == "Failed" || mStatus == "Timeout" || mStatus == "Blocked") {
            return Graphics.COLOR_RED;
        }

        return Graphics.COLOR_LT_GRAY;
    }

    hidden function shorten(value, limit) {
        if (value.length() <= limit) {
            return value;
        }

        return value.substring(0, limit - 3) + "...";
    }
}