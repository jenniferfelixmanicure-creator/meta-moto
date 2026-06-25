import { NativeEventEmitter, NativeModules, Platform } from 'react-native';

const { RideNotificationListener } = NativeModules;

export interface DetectedRide {
  platform: string;
  amount: number;
  rawText: string;
  timestamp: number;
}

let emitter: NativeEventEmitter | null = null;
if (Platform.OS === 'android' && RideNotificationListener) {
  emitter = new NativeEventEmitter(RideNotificationListener);
}

export function subscribeToRides(callback: (ride: DetectedRide) => void) {
  if (!emitter) return { remove: () => {} };
  return emitter.addListener('onRideDetected', callback);
}

export async function isPermissionGranted(): Promise<boolean> {
  if (Platform.OS !== 'android' || !RideNotificationListener) return false;
  try {
    return await RideNotificationListener.isPermissionGranted();
  } catch {
    return false;
  }
}

export async function openPermissionSettings(): Promise<void> {
  if (Platform.OS !== 'android' || !RideNotificationListener) return;
  try {
    await RideNotificationListener.openPermissionSettings();
  } catch {}
}

export const isSupported = Platform.OS === 'android' && !!RideNotificationListener;
