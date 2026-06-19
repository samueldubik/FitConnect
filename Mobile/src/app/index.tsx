import { useEffect, useState } from "react";
import { NativeModules, Text, View } from "react-native";

const { GarminModule } = NativeModules;

export default function App() {
  const [status, setStatus] = useState("Loading...");
  const [message, setMessage] = useState("No message");

  useEffect(() => {
    const interval = setInterval(async () => {
      setStatus(await GarminModule.getStatus());
      setMessage(await GarminModule.getLastMessage());
    }, 1000);

    return () => clearInterval(interval);
  }, []);

  return (
    <View style={{ flex: 1, padding: 40, justifyContent: "center" }}>
      <Text style={{ fontSize: 24, fontWeight: "bold" }}>FitConnect</Text>
      <Text>Status: {status}</Text>
      <Text>Message: {message}</Text>
    </View>
  );
}
