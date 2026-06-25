import { Feather } from '@expo/vector-icons';
import * as Haptics from 'expo-haptics';
import { router } from 'expo-router';
import React, { useEffect, useRef, useState } from 'react';
import {
  Animated,
  FlatList,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { EmptyState } from '@/components/EmptyState';
import { ProgressBar } from '@/components/ProgressBar';
import { formatCurrency, useApp } from '@/contexts/AppContext';
import { useColors } from '@/hooks/useColors';

const PLATFORM_COLORS: Record<string, string> = {
  Uber: '#000000',
  '99': '#F9B027',
  iFood: '#EA1D2C',
  Lalamove: '#FF6600',
  InDrive: '#2ECC40',
  Particular: '#6366F1',
  Outro: '#888888',
};

function formatElapsed(ms: number): string {
  const totalSec = Math.floor(ms / 1000);
  const h = Math.floor(totalSec / 3600);
  const m = Math.floor((totalSec % 3600) / 60);
  const s = totalSec % 60;
  if (h > 0) return `${h}h ${String(m).padStart(2, '0')}m`;
  return `${String(m).padStart(2, '0')}m ${String(s).padStart(2, '0')}s`;
}

function ShiftWidget() {
  const colors = useColors();
  const { shiftStart, shiftEarnings, startShift, endShift } = useApp();
  const [elapsed, setElapsed] = useState(0);

  useEffect(() => {
    if (!shiftStart) { setElapsed(0); return; }
    const tick = () => setElapsed(Date.now() - shiftStart.getTime());
    tick();
    const id = setInterval(tick, 1000);
    return () => clearInterval(id);
  }, [shiftStart]);

  if (!shiftStart) {
    return (
      <TouchableOpacity
        style={[styles.shiftBtn, { backgroundColor: colors.card, borderColor: colors.border }]}
        onPress={() => {
          Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
          startShift();
        }}
      >
        <Feather name="play-circle" size={18} color={colors.primary} />
        <Text style={[styles.shiftBtnText, { color: colors.primary }]}>Iniciar Turno</Text>
      </TouchableOpacity>
    );
  }

  return (
    <View style={[styles.shiftActive, { backgroundColor: colors.primary + '18', borderColor: colors.primary + '44' }]}>
      <View style={styles.shiftRow}>
        <View style={[styles.shiftDot, { backgroundColor: colors.primary }]} />
        <Text style={[styles.shiftLabel, { color: colors.primary }]}>TURNO ATIVO</Text>
        <Text style={[styles.shiftTimer, { color: colors.foreground }]}>{formatElapsed(elapsed)}</Text>
      </View>
      <View style={styles.shiftStats}>
        <View>
          <Text style={[styles.shiftStatLabel, { color: colors.mutedForeground }]}>Ganhos no turno</Text>
          <Text style={[styles.shiftStatValue, { color: colors.primary }]}>{formatCurrency(shiftEarnings)}</Text>
        </View>
        {elapsed > 0 && shiftEarnings > 0 && (
          <View>
            <Text style={[styles.shiftStatLabel, { color: colors.mutedForeground }]}>R$/hora</Text>
            <Text style={[styles.shiftStatValue, { color: colors.foreground }]}>
              {formatCurrency((shiftEarnings / elapsed) * 3600000)}
            </Text>
          </View>
        )}
        <TouchableOpacity
          style={[styles.shiftStop, { backgroundColor: colors.destructive + '22', borderColor: colors.destructive + '44' }]}
          onPress={() => {
            Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Heavy);
            endShift();
          }}
        >
          <Feather name="square" size={14} color={colors.destructive} />
          <Text style={[styles.shiftStopText, { color: colors.destructive }]}>Encerrar</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

function GoalBanner() {
  const colors = useColors();
  const { todayEarnings, goals, todayRides } = useApp();
  const progress = Math.min(todayEarnings / Math.max(goals.daily, 1), 1);
  const faltam = Math.max(goals.daily - todayEarnings, 0);
  const achieved = todayEarnings >= goals.daily;

  const glowAnim = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    if (achieved) {
      Animated.loop(
        Animated.sequence([
          Animated.timing(glowAnim, { toValue: 1, duration: 900, useNativeDriver: true }),
          Animated.timing(glowAnim, { toValue: 0, duration: 900, useNativeDriver: true }),
        ])
      ).start();
    }
  }, [achieved]);

  return (
    <Animated.View
      style={[
        styles.goalCard,
        {
          backgroundColor: colors.card,
          borderColor: achieved ? colors.primary : colors.border,
          borderWidth: achieved ? 1.5 : 1,
          opacity: achieved ? glowAnim.interpolate({ inputRange: [0, 1], outputRange: [0.9, 1] }) : 1,
        },
      ]}
    >
      <View style={styles.goalHeader}>
        <View>
          <Text style={[styles.goalLabel, { color: colors.mutedForeground }]}>META DIARIA</Text>
          <Text style={[styles.goalAmount, { color: colors.foreground }]}>
            {formatCurrency(goals.daily)}
          </Text>
        </View>
        {achieved ? (
          <View style={[styles.badge, { backgroundColor: colors.primary }]}>
            <Feather name="check" size={12} color="#000" />
            <Text style={styles.badgeText}>Batida!</Text>
          </View>
        ) : (
          <View style={[styles.badge, { backgroundColor: colors.muted }]}>
            <Text style={[styles.badgePct, { color: colors.primary }]}>
              {Math.round(progress * 100)}%
            </Text>
          </View>
        )}
      </View>

      <ProgressBar progress={progress} color={colors.primary} backgroundColor={colors.muted} height={10} />

      <View style={styles.goalStats}>
        <View>
          <Text style={[styles.statLabel, { color: colors.mutedForeground }]}>Faturado</Text>
          <Text style={[styles.statValue, { color: colors.primary }]}>{formatCurrency(todayEarnings)}</Text>
        </View>
        <View style={[styles.divider, { backgroundColor: colors.border }]} />
        <View>
          <Text style={[styles.statLabel, { color: colors.mutedForeground }]}>
            {achieved ? 'Superado' : 'Faltam'}
          </Text>
          <Text style={[styles.statValue, { color: achieved ? colors.primary : colors.warning }]}>
            {achieved ? '+' + formatCurrency(todayEarnings - goals.daily) : formatCurrency(faltam)}
          </Text>
        </View>
        <View style={[styles.divider, { backgroundColor: colors.border }]} />
        <View>
          <Text style={[styles.statLabel, { color: colors.mutedForeground }]}>Corridas</Text>
          <Text style={[styles.statValue, { color: colors.foreground }]}>{todayRides.length}</Text>
        </View>
      </View>

      {achieved && (
        <Text style={[styles.motivational, { color: colors.primary }]}>
          Parabens! Meta atingida hoje!
        </Text>
      )}
    </Animated.View>
  );
}

function MaintenanceAlertBanner() {
  const colors = useColors();
  const { maintenanceAlerts } = useApp();
  if (maintenanceAlerts.length === 0) return null;

  return (
    <View style={[styles.alertCard, { backgroundColor: colors.warning + '18', borderColor: colors.warning + '55' }]}>
      <Feather name="alert-triangle" size={16} color={colors.warning} />
      <View style={{ flex: 1 }}>
        <Text style={[styles.alertTitle, { color: colors.warning }]}>Manutencao Proxima</Text>
        {maintenanceAlerts.map(a => (
          <Text key={a.schedule.id} style={[styles.alertText, { color: colors.mutedForeground }]}>
            {a.schedule.type}: {a.kmRemaining <= 0 ? 'Vencida!' : `${a.kmRemaining} km restantes`}
          </Text>
        ))}
      </View>
      <TouchableOpacity onPress={() => router.push('/(tabs)/despesas')}>
        <Feather name="chevron-right" size={18} color={colors.warning} />
      </TouchableOpacity>
    </View>
  );
}

function RideRow({ ride, onDelete }: { ride: any; onDelete: () => void }) {
  const colors = useColors();
  const pc = PLATFORM_COLORS[ride.platform] ?? '#888';
  return (
    <View style={[styles.rideRow, { backgroundColor: colors.card, borderColor: colors.border }]}>
      <View style={[styles.platformDot, { backgroundColor: pc }]} />
      <View style={{ flex: 1 }}>
        <Text style={[styles.ridePlatform, { color: colors.foreground }]}>{ride.platform}</Text>
        <Text style={[styles.rideTime, { color: colors.mutedForeground }]}>
          {ride.time}{ride.duration ? ` • ${ride.duration}min` : ''}{ride.kmRidden ? ` • ${ride.kmRidden}km` : ''}
        </Text>
      </View>
      <Text style={[styles.rideAmount, { color: colors.primary }]}>{formatCurrency(ride.amount)}</Text>
      <TouchableOpacity onPress={onDelete} style={styles.deleteBtn} hitSlop={8}>
        <Feather name="trash-2" size={14} color={colors.destructive} />
      </TouchableOpacity>
    </View>
  );
}

export default function Dashboard() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const { todayRides, deleteRide, netProfit, todayFuelCost, todayMaintenanceCost } = useApp();

  const topPad = Platform.OS === 'web' ? 67 : insets.top;

  const handleDelete = (id: string) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    deleteRide(id);
  };

  const now = new Date();
  const hour = now.getHours();
  const greeting = hour < 12 ? 'Bom dia' : hour < 18 ? 'Boa tarde' : 'Boa noite';

  return (
    <View style={[styles.container, { backgroundColor: colors.background }]}>
      <ScrollView
        contentContainerStyle={[
          styles.scroll,
          { paddingTop: topPad + 16, paddingBottom: 100 + (Platform.OS === 'web' ? 34 : 0) },
        ]}
        showsVerticalScrollIndicator={false}
      >
        <View style={styles.headerRow}>
          <View>
            <Text style={[styles.greeting, { color: colors.mutedForeground }]}>{greeting}</Text>
            <Text style={[styles.headline, { color: colors.foreground }]}>Meta Moto</Text>
          </View>
          <Pressable
            onPress={() => router.push('/calculadora')}
            style={[styles.calcBtn, { backgroundColor: colors.card, borderColor: colors.border }]}
          >
            <Feather name="hash" size={18} color={colors.primary} />
          </Pressable>
        </View>

        <ShiftWidget />

        <MaintenanceAlertBanner />

        <GoalBanner />

        <View style={styles.costRow}>
          <View style={[styles.costCard, { backgroundColor: colors.card, borderColor: colors.border }]}>
            <Feather name="droplet" size={14} color={colors.warning} />
            <Text style={[styles.costLabel, { color: colors.mutedForeground }]}>Combustivel</Text>
            <Text style={[styles.costVal, { color: colors.warning }]}>{formatCurrency(todayFuelCost)}</Text>
          </View>
          <View style={[styles.costCard, { backgroundColor: colors.card, borderColor: colors.border }]}>
            <Feather name="tool" size={14} color={colors.destructive} />
            <Text style={[styles.costLabel, { color: colors.mutedForeground }]}>Manutencao</Text>
            <Text style={[styles.costVal, { color: colors.destructive }]}>{formatCurrency(todayMaintenanceCost)}</Text>
          </View>
          <View style={[styles.costCard, { backgroundColor: colors.card, borderColor: colors.border }]}>
            <Feather name="trending-up" size={14} color={colors.primary} />
            <Text style={[styles.costLabel, { color: colors.mutedForeground }]}>Lucro</Text>
            <Text style={[styles.costVal, { color: netProfit.daily >= 0 ? colors.primary : colors.destructive }]}>
              {formatCurrency(netProfit.daily)}
            </Text>
          </View>
        </View>

        <View style={styles.sectionHeader}>
          <Text style={[styles.sectionTitle, { color: colors.foreground }]}>Corridas de Hoje</Text>
        </View>

        {todayRides.length === 0 ? (
          <EmptyState
            icon="navigation"
            title="Nenhuma corrida hoje"
            subtitle="Toque no botao + para registrar sua primeira corrida"
          />
        ) : (
          <FlatList
            data={todayRides}
            keyExtractor={i => i.id}
            scrollEnabled={false}
            renderItem={({ item }) => (
              <RideRow ride={item} onDelete={() => handleDelete(item.id)} />
            )}
            ItemSeparatorComponent={() => <View style={{ height: 8 }} />}
          />
        )}
      </ScrollView>

      <TouchableOpacity
        style={[styles.fab, { backgroundColor: colors.primary }]}
        onPress={() => {
          Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
          router.push('/nova-corrida');
        }}
      >
        <Feather name="plus" size={26} color="#000" />
      </TouchableOpacity>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  scroll: { paddingHorizontal: 16, gap: 12 },
  headerRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-start' },
  greeting: { fontFamily: 'Inter_400Regular', fontSize: 13 },
  headline: { fontFamily: 'Inter_700Bold', fontSize: 26 },
  calcBtn: { padding: 10, borderRadius: 12, borderWidth: 1 },
  shiftBtn: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'center',
    gap: 8, padding: 12, borderRadius: 12, borderWidth: 1,
  },
  shiftBtnText: { fontFamily: 'Inter_600SemiBold', fontSize: 14 },
  shiftActive: { borderRadius: 14, padding: 14, borderWidth: 1, gap: 10 },
  shiftRow: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  shiftDot: { width: 8, height: 8, borderRadius: 4 },
  shiftLabel: { fontFamily: 'Inter_700Bold', fontSize: 11, letterSpacing: 0.5, flex: 1 },
  shiftTimer: { fontFamily: 'Inter_700Bold', fontSize: 18 },
  shiftStats: { flexDirection: 'row', alignItems: 'center', gap: 16 },
  shiftStatLabel: { fontFamily: 'Inter_400Regular', fontSize: 11 },
  shiftStatValue: { fontFamily: 'Inter_700Bold', fontSize: 16, marginTop: 2 },
  shiftStop: {
    flexDirection: 'row', alignItems: 'center', gap: 6,
    paddingHorizontal: 12, paddingVertical: 8, borderRadius: 20, borderWidth: 1, marginLeft: 'auto',
  },
  shiftStopText: { fontFamily: 'Inter_600SemiBold', fontSize: 12 },
  alertCard: { flexDirection: 'row', alignItems: 'center', gap: 10, padding: 12, borderRadius: 12, borderWidth: 1 },
  alertTitle: { fontFamily: 'Inter_700Bold', fontSize: 13 },
  alertText: { fontFamily: 'Inter_400Regular', fontSize: 12, marginTop: 2 },
  goalCard: { borderRadius: 16, padding: 16, gap: 12, borderWidth: 1 },
  goalHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-start' },
  goalLabel: { fontFamily: 'Inter_500Medium', fontSize: 11, letterSpacing: 0.5 },
  goalAmount: { fontFamily: 'Inter_700Bold', fontSize: 24, marginTop: 2 },
  badge: {
    flexDirection: 'row', alignItems: 'center', gap: 4,
    paddingHorizontal: 10, paddingVertical: 4, borderRadius: 20,
  },
  badgeText: { fontFamily: 'Inter_700Bold', fontSize: 12, color: '#000' },
  badgePct: { fontFamily: 'Inter_700Bold', fontSize: 14 },
  goalStats: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  statLabel: { fontFamily: 'Inter_400Regular', fontSize: 11 },
  statValue: { fontFamily: 'Inter_700Bold', fontSize: 16, marginTop: 2 },
  divider: { width: 1, height: 32 },
  motivational: { fontFamily: 'Inter_600SemiBold', fontSize: 13, textAlign: 'center' },
  costRow: { flexDirection: 'row', gap: 8 },
  costCard: {
    flex: 1, padding: 10, borderRadius: 12, borderWidth: 1,
    alignItems: 'center', gap: 4,
  },
  costLabel: { fontFamily: 'Inter_400Regular', fontSize: 10, textAlign: 'center' },
  costVal: { fontFamily: 'Inter_700Bold', fontSize: 13 },
  sectionHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginTop: 4 },
  sectionTitle: { fontFamily: 'Inter_600SemiBold', fontSize: 15 },
  rideRow: {
    flexDirection: 'row', alignItems: 'center', gap: 10,
    padding: 12, borderRadius: 12, borderWidth: 1,
  },
  platformDot: { width: 10, height: 10, borderRadius: 5 },
  ridePlatform: { fontFamily: 'Inter_600SemiBold', fontSize: 14 },
  rideTime: { fontFamily: 'Inter_400Regular', fontSize: 12 },
  rideAmount: { fontFamily: 'Inter_700Bold', fontSize: 16 },
  deleteBtn: { padding: 4 },
  fab: {
    position: 'absolute', right: 20, bottom: 80,
    width: 56, height: 56, borderRadius: 28,
    alignItems: 'center', justifyContent: 'center',
    shadowColor: '#22C55E', shadowOpacity: 0.4, shadowRadius: 12, elevation: 8,
  },
});
