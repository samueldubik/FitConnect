

class FitConnectDataFormatter {
    function initialize() {

    }

function formatData(data) {
    return {
        :type => "fitconnect_dump",
        :timer => data[:timer],

        :system => formatSystem(
            data[:clockTime],
            data[:deviceSettings],
            data[:displayMode],
            data[:systemStats]
        ),

        :activity => {
            :info => formatActivityInfo(data[:activityInfo]),
            :history => formatActivityHistory(data[:activityHistory])
        },

        :sensor => {
            :live => formatSensorInfo(data[:sensorInfo]),
            :history => {
                :heartRate => formatSensorHistoryIterator(data[:sensorHeartRateHistory], 20),
                :stress => formatSensorHistoryIterator(data[:sensorStressHistory], 20),
                :bodyBattery => formatSensorHistoryIterator(data[:sensorBodyBatteryHistory], 20),
                :oxygen => formatSensorHistoryIterator(data[:sensorOxygenHistory], 20),
                :temperature => formatSensorHistoryIterator(data[:sensorTemperatureHistory], 20),
                :pressure => formatSensorHistoryIterator(data[:sensorPressureHistory], 20),
                :elevation => formatSensorHistoryIterator(data[:sensorElevationHistory], 20)
            }
        },

        :position => formatPositionInfo(data[:positionInfo]),
        :userProfile => formatUserProfile(data[:userProfile])
    };
}

function formatSystem(clockTime, deviceSettings, displayMode, systemStats) {
    return {
        :clockTime => clockTime == null ? null : {
            :hour => clockTime.hour,
            :min => clockTime.min,
            :sec => clockTime.sec
        },

        :displayMode => displayMode,

        :deviceSettings => deviceSettings == null ? null : {
            :phoneConnected => deviceSettings.phoneConnected,
            :notificationCount => deviceSettings.notificationCount,
            :alarmCount => deviceSettings.alarmCount,
            :is24Hour => deviceSettings.is24Hour,
            :screenWidth => deviceSettings.screenWidth,
            :screenHeight => deviceSettings.screenHeight
        },

        :systemStats => systemStats == null ? null : {
            :battery => systemStats.battery,
            :freeMemory => systemStats.freeMemory,
            :usedMemory => systemStats.usedMemory
        }
    };
}

function formatActivityInfo(info) {
    if (info == null) {
        return null;
    }

    return {
        :steps => info.steps,
        :stepGoal => info.stepGoal,
        :calories => info.calories,
        :distance => info.distance,
        :floorsClimbed => info.floorsClimbed,
        :floorsClimbedGoal => info.floorsClimbedGoal,
        :floorsDescended => info.floorsDescended,
    };
}

function formatActivityHistory(history) {
    var result = [];

    if (history == null) {
        return result;
    }

    for (var i = 0; i < history.size(); i++) {
        var item = history[i];

        result.add({
            :steps => item.steps,
            :stepGoal => item.stepGoal,
            :calories => item.calories,
            :distance => item.distance,
            :floorsClimbed => item.floorsClimbed,
            :floorsClimbedGoal => item.floorsClimbedGoal,
            :floorsDescended => item.floorsDescended,
            :activeMinutes => formatActiveMinutes(item.activeMinutes),
            :startOfDay => formatMoment(item.startOfDay)
        });
    }

    return result;
}

function formatActiveMinutes(activeMinutes) {
    if (activeMinutes == null) {
        return null;
    }

    return {
        :moderate => activeMinutes.moderate,
        :vigorous => activeMinutes.vigorous,
        :total => activeMinutes.total
    };
}

function formatSensorInfo(info) {
    if (info == null) {
        return null;
    }

    return {
        :heartRate => info.heartRate,
        :speed => info.speed,
        :cadence => info.cadence,
        :temperature => info.temperature,
        :altitude => info.altitude,
        :pressure => info.pressure,
        :heading => info.heading,
    };
}

function formatSensorHistoryIterator(iterator, limit) {
    var result = [];

    if (iterator == null) {
        return result;
    }

    for (var i = 0; i < limit; i++) {
        var sample = iterator.next();

        if (sample == null) {
            break;
        }

        result.add(formatSensorHistorySample(sample));
    }

    return result;
}

function formatSensorHistorySample(sample) {
    if (sample == null) {
        return null;
    }

    return {
        :data => sample.data,
        :when => formatMoment(sample.when)
    };
}

function formatPositionInfo(info) {
    if (info == null) {
        return null;
    }

    return {
        :position => formatPosition(info.position),
        :accuracy => info.accuracy,
        :altitude => info.altitude,
        :speed => info.speed,
        :heading => info.heading,
        :when => formatMoment(info.when)
    };
}

function formatPosition(position) {
    if (position == null) {
        return null;
    }

    var degrees = position.toDegrees();

    return {
        :lat => degrees[0],
        :lon => degrees[1]
    };
}

function formatUserProfile(profile) {
    if (profile == null) {
        return null;
    }

    return {
        :gender => profile.gender,
        :height => profile.height,
        :weight => profile.weight,
        :birthYear => profile.birthYear,
        :restingHeartRate => profile.restingHeartRate,
        :walkingStepLength => profile.walkingStepLength,
        :runningStepLength => profile.runningStepLength
    };
}

function formatMoment(moment) {
    if (moment == null) {
        return null;
    }

    return moment.value();
}

}