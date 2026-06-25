import AsyncStorage from '@react-native-async-storage/async-storage';
import { useEffect, useRef, useState } from 'react';
import { AppState, Platform } from 'react-native';
import {
  DetectedRide,
  isPermissionGranted,
  isSupported,
  subscribeToRides,
} from '@/modules/notification-listener';
import { useApp } from '@/contexts/AppContext';

const LAST_SEEN_KEY = '@mm:last_notification_ts';

export interface PendingRide extends DetectedRide {
  id: string;
}

export function useRideNotifications() {
  const { addRide } = useApp();
  const [hasPermission, setHasPermission] = useState(false);
  const [pendingRides, setPendingRides] = useState<PendingRide[]>([]);
  const seenTimestamps = useRef<Set<number>>(new Set());

  // Check permission on mount and when app comes back to foreground
  useEffect(() => {
    if (!isSupported) return;

    const check = async () => {
      const granted = await isPermissionGranted();
      setHasPermission(granted);
    };

    check();

    const sub = AppState.addEventListener('change', (state) => {
      if (state === 'active') check();
    });

    return () => sub.remove();
  }, []);

  // Subscribe to ride events
  useEffect(() => {
    if (!isSupported || !hasPermission) return;

    const sub = subscribeToRides((ride) => {
      // Deduplicate: same amount within 30 seconds
      if (seenTimestamps.current.has(ride.timestamp)) return;
      seenTimestamps.current.add(ride.timestamp);

      const pending: PendingRide = {
        ...ride,
        id: `${ride.timestamp}-${ride.amount}`,
      };

      setPendingRides((prev) => {
        // Don't add if already in list
        if (prev.some((p) => p.id === pending.id)) return prev;
        return [pending, ...prev];
      });
    });

    return () => sub.remove();
  }, [hasPermission]);

  const acceptRide = async (pending: PendingRide) => {
    const date = new Date(pending.timestamp);
    const timeStr = `${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`;
    await addRide({
      date: date.toISOString().split('T')[0],
      platform: pending.platform,
      amount: pending.amount,
      time: timeStr,
      note: undefined,
    });
    setPendingRides((prev) => prev.filter((p) => p.id !== pending.id));
  };

  const dismissRide = (id: string) => {
    setPendingRides((prev) => prev.filter((p) => p.id !== id));
  };

  const dismissAll = () => setPendingRides([]);

  return {
    isSupported,
    hasPermission,
    pendingRides,
    acceptRide,
    dismissRide,
    dismissAll,
  };
}
