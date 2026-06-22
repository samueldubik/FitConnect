import { useCallback, useEffect, useState } from "react";
import { Button, NativeModules, ScrollView, StyleSheet, Text, View } from "react-native";

const { GarminModule } = NativeModules;

type ConnectionSnapshot = {
  status: string;
  message: string;
  receivedCount: number;
  lastReceivedAt: number;
  physicalDeviceMode: boolean;
};

export default function App() {
  const [snapshot, setSnapshot] = useState<ConnectionSnapshot>({
    status: "Loading Garmin connection...",
    message: "No message received yet",
    receivedCount: 0,
    lastReceivedAt: 0,
    physicalDeviceMode: true,
  });
  const [uiError, setUiError] = useState("");

  const refreshSnapshot = useCallback(async () => {
    try {
      setSnapshot(await GarminModule.getConnectionSnapshot());
      setUiError("");
    } catch (error) {
      setUiError(error instanceof Error ? error.message : String(error));
    }
  }, []);

  useEffect(() => {
    refreshSnapshot();
    const interval = setInterval(refreshSnapshot, 1000);

    return () => clearInterval(interval);
  }, [refreshSnapshot]);

  const lastReceived = snapshot.lastReceivedAt
    ? new Date(snapshot.lastReceivedAt).toLocaleTimeString()
    : "Never";

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <Text style={styles.title}>FitConnect</Text>
      <Text style={styles.mode}>
        Mode: {snapshot.physicalDeviceMode ? "Physical Garmin device" : "Simulator"}
      </Text>

      <View style={styles.card}>
        <Text style={styles.label}>Connection status</Text>
        <Text selectable>{snapshot.status}</Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.label}>Messages received: {snapshot.receivedCount}</Text>
        <Text>Last received: {lastReceived}</Text>
        <Text selectable style={styles.payload}>{snapshot.message}</Text>
      </View>

      {uiError ? <Text style={styles.error}>UI/native error: {uiError}</Text> : null}

      <View style={styles.button}>
        <Button
          title="Refresh Garmin connection"
          onPress={async () => {
            await GarminModule.refreshConnection();
            await refreshSnapshot();
          }}
        />
      </View>
      <Button
        title="Send Ping to Watch"
        onPress={async () => {
          await GarminModule.sendPingToWatch();
          await refreshSnapshot();
        }}
      />
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flexGrow: 1,
    justifyContent: "center",
    padding: 32,
    gap: 16,
  },
  title: {
    fontSize: 28,
    fontWeight: "700",
  },
  mode: {
    color: "#555",
  },
  card: {
    borderColor: "#bbb",
    borderRadius: 8,
    borderWidth: 1,
    padding: 16,
    gap: 8,
  },
  label: {
    fontSize: 16,
    fontWeight: "600",
  },
  payload: {
    backgroundColor: "#f2f2f2",
    borderRadius: 6,
    marginTop: 4,
    padding: 12,
  },
  error: {
    color: "#b00020",
  },
  button: {
    marginTop: 8,
  },
});
