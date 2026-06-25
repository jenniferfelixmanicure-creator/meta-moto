import AsyncStorage from '@react-native-async-storage/async-storage';
import React, { createContext, useContext, useEffect, useState } from 'react';

export interface Ride {
  id: string;
  date: string;
  platform: string;
  amount: number;
  time: string;
  duration?: number;
  kmRidden?: number;
  note?: string;
  createdAt: string;
}

export interface FuelEntry {
  id: string;
  date: string;
  amount: number;
  liters?: number;
  km?: number;
  odometerKm?: number;
  note?: string;
  createdAt: string;
}

export interface MaintenanceEntry {
  id: string;
  date: string;
  type: string;
  amount: number;
  note?: string;
  createdAt: string;
}

export interface MaintenanceSchedule {
  id: string;
  type: string;
  intervalKm: number;
  lastServiceKm: number;
  lastServiceDate: string;
}

export interface Goals {
  daily: number;
  weekly: number;
  monthly: number;
}

export interface PlatformStat {
  platform: string;
  rides: number;
  earnings: number;
  minutes: number;
  earningsPerHour: number;
  avgPerRide: number;
}

interface MaintenanceAlert {
  schedule: MaintenanceSchedule;
  kmRemaining: number;
  urgent: boolean;
}

interface AppContextType {
  rides: Ride[];
  fuel: FuelEntry[];
  maintenance: MaintenanceEntry[];
  maintenanceSchedules: MaintenanceSchedule[];
  goals: Goals;
  shiftStart: Date | null;
  addRide: (ride: Omit<Ride, 'id' | 'createdAt'>) => Promise<void>;
  deleteRide: (id: string) => Promise<void>;
  addFuel: (entry: Omit<FuelEntry, 'id' | 'createdAt'>) => Promise<void>;
  deleteFuel: (id: string) => Promise<void>;
  addMaintenance: (entry: Omit<MaintenanceEntry, 'id' | 'createdAt'>) => Promise<void>;
  deleteMaintenance: (id: string) => Promise<void>;
  updateGoals: (goals: Goals) => Promise<void>;
  startShift: () => void;
  endShift: () => void;
  addMaintenanceSchedule: (s: Omit<MaintenanceSchedule, 'id'>) => Promise<void>;
  updateMaintenanceSchedule: (id: string, lastServiceKm: number, lastServiceDate: string) => Promise<void>;
  deleteMaintenanceSchedule: (id: string) => Promise<void>;
  todayEarnings: number;
  todayRides: Ride[];
  weekEarnings: number;
  prevWeekEarnings: number;
  monthEarnings: number;
  shiftEarnings: number;
  todayFuelCost: number;
  todayMaintenanceCost: number;
  monthFuelCost: number;
  monthMaintenanceCost: number;
  weekFuelCost: number;
  weekMaintenanceCost: number;
  netProfit: { daily: number; weekly: number; monthly: number };
  platformStats: PlatformStat[];
  avgKmPerLiter: number;
  currentOdometer: number;
  maintenanceAlerts: MaintenanceAlert[];
}

const AppContext = createContext<AppContextType | undefined>(undefined);

function genId(): string {
  return Date.now().toString() + Math.random().toString(36).substring(2, 9);
}

function toDateStr(d: Date): string {
  return d.toISOString().split('T')[0];
}

function todayStr(): string {
  return toDateStr(new Date());
}

function weekStartStr(): string {
  const d = new Date();
  const day = d.getDay();
  const diff = d.getDate() - day + (day === 0 ? -6 : 1);
  const monday = new Date(d);
  monday.setDate(diff);
  return toDateStr(monday);
}

function prevWeekStartStr(): string {
  const d = new Date();
  const day = d.getDay();
  const diff = d.getDate() - day + (day === 0 ? -6 : 1) - 7;
  const monday = new Date(d);
  monday.setDate(diff);
  return toDateStr(monday);
}

function monthStartStr(): string {
  const d = new Date();
  return toDateStr(new Date(d.getFullYear(), d.getMonth(), 1));
}

const KEYS = {
  RIDES: '@mm:rides',
  FUEL: '@mm:fuel',
  MAINTENANCE: '@mm:maintenance',
  GOALS: '@mm:goals',
  MAINT_SCHEDULES: '@mm:maint_schedules',
};

const DEFAULT_GOALS: Goals = { daily: 250, weekly: 1500, monthly: 6000 };

export function AppProvider({ children }: { children: React.ReactNode }) {
  const [rides, setRides] = useState<Ride[]>([]);
  const [fuel, setFuel] = useState<FuelEntry[]>([]);
  const [maintenance, setMaintenance] = useState<MaintenanceEntry[]>([]);
  const [maintenanceSchedules, setMaintenanceSchedules] = useState<MaintenanceSchedule[]>([]);
  const [goals, setGoals] = useState<Goals>(DEFAULT_GOALS);
  const [shiftStart, setShiftStart] = useState<Date | null>(null);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    (async () => {
      try {
        const [r, f, m, g, ms] = await Promise.all([
          AsyncStorage.getItem(KEYS.RIDES),
          AsyncStorage.getItem(KEYS.FUEL),
          AsyncStorage.getItem(KEYS.MAINTENANCE),
          AsyncStorage.getItem(KEYS.GOALS),
          AsyncStorage.getItem(KEYS.MAINT_SCHEDULES),
        ]);
        if (r) setRides(JSON.parse(r));
        if (f) setFuel(JSON.parse(f));
        if (m) setMaintenance(JSON.parse(m));
        if (g) setGoals(JSON.parse(g));
        if (ms) setMaintenanceSchedules(JSON.parse(ms));
      } catch (_) {}
      setReady(true);
    })();
  }, []);

  const addRide = async (ride: Omit<Ride, 'id' | 'createdAt'>) => {
    const item: Ride = { ...ride, id: genId(), createdAt: new Date().toISOString() };
    const updated = [item, ...rides];
    setRides(updated);
    await AsyncStorage.setItem(KEYS.RIDES, JSON.stringify(updated));
  };

  const deleteRide = async (id: string) => {
    const updated = rides.filter(r => r.id !== id);
    setRides(updated);
    await AsyncStorage.setItem(KEYS.RIDES, JSON.stringify(updated));
  };

  const addFuel = async (entry: Omit<FuelEntry, 'id' | 'createdAt'>) => {
    const item: FuelEntry = { ...entry, id: genId(), createdAt: new Date().toISOString() };
    const updated = [item, ...fuel];
    setFuel(updated);
    await AsyncStorage.setItem(KEYS.FUEL, JSON.stringify(updated));
  };

  const deleteFuel = async (id: string) => {
    const updated = fuel.filter(f => f.id !== id);
    setFuel(updated);
    await AsyncStorage.setItem(KEYS.FUEL, JSON.stringify(updated));
  };

  const addMaintenance = async (entry: Omit<MaintenanceEntry, 'id' | 'createdAt'>) => {
    const item: MaintenanceEntry = { ...entry, id: genId(), createdAt: new Date().toISOString() };
    const updated = [item, ...maintenance];
    setMaintenance(updated);
    await AsyncStorage.setItem(KEYS.MAINTENANCE, JSON.stringify(updated));
  };

  const deleteMaintenance = async (id: string) => {
    const updated = maintenance.filter(m => m.id !== id);
    setMaintenance(updated);
    await AsyncStorage.setItem(KEYS.MAINTENANCE, JSON.stringify(updated));
  };

  const updateGoals = async (g: Goals) => {
    setGoals(g);
    await AsyncStorage.setItem(KEYS.GOALS, JSON.stringify(g));
  };

  const startShift = () => setShiftStart(new Date());
  const endShift = () => setShiftStart(null);

  const addMaintenanceSchedule = async (s: Omit<MaintenanceSchedule, 'id'>) => {
    const item: MaintenanceSchedule = { ...s, id: genId() };
    const updated = [...maintenanceSchedules, item];
    setMaintenanceSchedules(updated);
    await AsyncStorage.setItem(KEYS.MAINT_SCHEDULES, JSON.stringify(updated));
  };

  const updateMaintenanceSchedule = async (id: string, lastServiceKm: number, lastServiceDate: string) => {
    const updated = maintenanceSchedules.map(s =>
      s.id === id ? { ...s, lastServiceKm, lastServiceDate } : s
    );
    setMaintenanceSchedules(updated);
    await AsyncStorage.setItem(KEYS.MAINT_SCHEDULES, JSON.stringify(updated));
  };

  const deleteMaintenanceSchedule = async (id: string) => {
    const updated = maintenanceSchedules.filter(s => s.id !== id);
    setMaintenanceSchedules(updated);
    await AsyncStorage.setItem(KEYS.MAINT_SCHEDULES, JSON.stringify(updated));
  };

  const today = todayStr();
  const weekStart = weekStartStr();
  const prevWeekStart = prevWeekStartStr();
  const monthStart = monthStartStr();

  const todayRides = rides.filter(r => r.date === today);
  const todayEarnings = todayRides.reduce((s, r) => s + r.amount, 0);
  const weekEarnings = rides.filter(r => r.date >= weekStart).reduce((s, r) => s + r.amount, 0);
  const prevWeekEarnings = rides
    .filter(r => r.date >= prevWeekStart && r.date < weekStart)
    .reduce((s, r) => s + r.amount, 0);
  const monthEarnings = rides.filter(r => r.date >= monthStart).reduce((s, r) => s + r.amount, 0);

  const shiftEarnings = shiftStart
    ? rides
        .filter(r => new Date(r.createdAt) >= shiftStart)
        .reduce((s, r) => s + r.amount, 0)
    : 0;

  const todayFuelCost = fuel.filter(f => f.date === today).reduce((s, f) => s + f.amount, 0);
  const todayMaintenanceCost = maintenance.filter(m => m.date === today).reduce((s, m) => s + m.amount, 0);
  const weekFuelCost = fuel.filter(f => f.date >= weekStart).reduce((s, f) => s + f.amount, 0);
  const weekMaintenanceCost = maintenance.filter(m => m.date >= weekStart).reduce((s, m) => s + m.amount, 0);
  const monthFuelCost = fuel.filter(f => f.date >= monthStart).reduce((s, f) => s + f.amount, 0);
  const monthMaintenanceCost = maintenance.filter(m => m.date >= monthStart).reduce((s, m) => s + m.amount, 0);

  const netProfit = {
    daily: todayEarnings - todayFuelCost - todayMaintenanceCost,
    weekly: weekEarnings - weekFuelCost - weekMaintenanceCost,
    monthly: monthEarnings - monthFuelCost - monthMaintenanceCost,
  };

  const platformStats: PlatformStat[] = (() => {
    const map: Record<string, { earnings: number; rides: number; minutes: number }> = {};
    rides.filter(r => r.date >= monthStart).forEach(r => {
      if (!map[r.platform]) map[r.platform] = { earnings: 0, rides: 0, minutes: 0 };
      map[r.platform].earnings += r.amount;
      map[r.platform].rides += 1;
      map[r.platform].minutes += r.duration ?? 0;
    });
    return Object.entries(map).map(([platform, s]) => ({
      platform,
      rides: s.rides,
      earnings: s.earnings,
      minutes: s.minutes,
      earningsPerHour: s.minutes > 0 ? (s.earnings / s.minutes) * 60 : 0,
      avgPerRide: s.rides > 0 ? s.earnings / s.rides : 0,
    })).sort((a, b) => b.earnings - a.earnings);
  })();

  const fuelWithKm = fuel.filter(f => f.liters && f.km && f.liters > 0 && f.km > 0);
  const avgKmPerLiter = fuelWithKm.length > 0
    ? fuelWithKm.reduce((s, f) => s + (f.km! / f.liters!), 0) / fuelWithKm.length
    : 0;

  const currentOdometer = fuel
    .filter(f => f.odometerKm && f.odometerKm > 0)
    .reduce((max, f) => Math.max(max, f.odometerKm!), 0);

  const maintenanceAlerts: MaintenanceAlert[] = currentOdometer > 0
    ? maintenanceSchedules.map(s => {
        const kmDone = currentOdometer - s.lastServiceKm;
        const kmRemaining = s.intervalKm - kmDone;
        const pct = kmDone / s.intervalKm;
        return { schedule: s, kmRemaining, urgent: pct >= 0.9 };
      }).filter(a => a.kmRemaining <= a.schedule.intervalKm * 0.2 || a.urgent)
    : [];

  if (!ready) return null;

  return (
    <AppContext.Provider value={{
      rides, fuel, maintenance, maintenanceSchedules, goals, shiftStart,
      addRide, deleteRide, addFuel, deleteFuel, addMaintenance, deleteMaintenance,
      updateGoals, startShift, endShift,
      addMaintenanceSchedule, updateMaintenanceSchedule, deleteMaintenanceSchedule,
      todayEarnings, todayRides, weekEarnings, prevWeekEarnings, monthEarnings, shiftEarnings,
      todayFuelCost, todayMaintenanceCost,
      weekFuelCost, weekMaintenanceCost,
      monthFuelCost, monthMaintenanceCost,
      netProfit, platformStats, avgKmPerLiter, currentOdometer, maintenanceAlerts,
    }}>
      {children}
    </AppContext.Provider>
  );
}

export function useApp() {
  const ctx = useContext(AppContext);
  if (!ctx) throw new Error('useApp must be used inside AppProvider');
  return ctx;
}

export function formatCurrency(value: number): string {
  return value.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
}

export function formatDate(dateStr: string): string {
  const [y, m, d] = dateStr.split('-').map(Number);
  return `${String(d).padStart(2, '0')}/${String(m).padStart(2, '0')}/${y}`;
}

export const PLATFORMS = ['Uber', '99', 'iFood', 'Lalamove', 'InDrive', 'Particular', 'Outro'];

export const MAINTENANCE_TYPES = [
  'Troca de Oleo', 'Pneu Dianteiro', 'Pneu Traseiro', 'Relacao',
  'Freios', 'Revisao', 'Filtro de Ar', 'Vela', 'Outro',
];

export const SCHEDULE_INTERVALS: Record<string, number> = {
  'Troca de Oleo': 3000,
  'Pneu Dianteiro': 15000,
  'Pneu Traseiro': 10000,
  'Relacao': 8000,
  'Freios': 12000,
  'Revisao': 5000,
  'Filtro de Ar': 6000,
  'Vela': 8000,
};

export function getDateStr(date?: Date): string {
  return toDateStr(date ?? new Date());
}
