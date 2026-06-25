import { Feather } from '@expo/vector-icons';
import * as Haptics from 'expo-haptics';
import { router } from 'expo-router';
import React, { useMemo, useState } from 'react';
import {
  Alert,
  FlatList,
  Platform,
  Pressable,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { EmptyState } from '@/components/EmptyState';
import { formatCurrency, formatDate, useApp } from '@/contexts/AppContext';
import { useColors } from '@/hooks/useColors';

const PLATFORM_COLORS: Record<string, string> = {
  Uber: '#FFFFFF',
  '99': '#F9B027',
  iFood: '#EA1D2C',
  Lalamove: '#FF6600',
  InDrive: '#2ECC40',
  Particular: '#6366F1',
  Outro: '#888888',
};

type RideGroupItem =
  | { type: 'header'; date: string; total: number }
  | { type: 'ride'; id: string; platform: string; amount: number; time: string; note?: string; date: string };

export default function CorridasScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const { rides, deleteRide } = useApp();
  const [filter, setFilter] = useState<string>('Todas');

  const platforms = useMemo(() => {
    const set = new Set(rides.map(r => r.platform));
    return ['Todas', ...Array.from(set)];
  }, [rides]);

  const filtered = useMemo(() => {
    return filter === 'Todas' ? rides : rides.filter(r => r.platform === filter);
  }, [rides, filter]);

  const grouped = useMemo((): RideGroupItem[] => {
    const byDate: Record<string, typeof filtered> = {};
    for (const r of filtered) {
      if (!byDate[r.date]) byDate[r.date] = [];
      byDate[r.date].push(r);
    }
    const dates = Object.keys(byDate).sort((a, b) => b.localeCompare(a));
    const items: RideGroupItem[] = [];
    for (const d of dates) {
      const group = byDate[d];
      const total = group.reduce((s, r) => s + r.amount, 0);
      items.push({ type: 'header', date: d, total });
      for (const r of group) {
        items.push({ type: 'ride', ...r });
      }
    }
    return items;
  }, [filtered]);

  const handleDelete = (id: string) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    Alert.alert('Excluir corrida', 'Tem certeza que deseja excluir esta corrida?', [
      { text: 'Cancelar', style: 'cancel' },
      { text: 'Excluir', style: 'destructive', onPress: () => deleteRide(id) },
    ]);
  };

  const topPad = Platform.OS === 'web' ? 67 : insets.top;

  return (
    <View style={[styles.container, { backgroundColor: colors.background }]}>
      <View style={[styles.header, { paddingTop: topPad + 16, backgroundColor: colors.background }]}>
        <Text style={[styles.title, { color: colors.foreground }]}>Corridas</Text>
        <Text style={[styles.sub, { color: colors.mutedForeground }]}>
          {rides.length} registro{rides.length !== 1 ? 's' : ''}
        </Text>
      </View>

      {rides.length > 1 && (
        <FlatList
          data={platforms}
          keyExtractor={p => p}
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={styles.filterRow}
          renderItem={({ item }) => (
            <Pressable
              onPress={() => setFilter(item)}
              style={[
                styles.filterChip,
                {
                  backgroundColor: filter === item ? colors.primary : colors.card,
                  borderColor: filter === item ? colors.primary : colors.border,
                },
              ]}
            >
              <Text
                style={[
                  styles.filterChipText,
                  { color: filter === item ? '#000' : colors.mutedForeground },
                ]}
              >
                {item}
              </Text>
            </Pressable>
          )}
        />
      )}

      {grouped.length === 0 ? (
        <EmptyState
          icon="navigation"
          title="Nenhuma corrida registrada"
          subtitle="Toque no botao + para comecar"
        />
      ) : (
        <FlatList
          data={grouped}
          keyExtractor={(item, i) =>
            item.type === 'header' ? `h-${item.date}` : `r-${item.id}`
          }
          contentContainerStyle={{ paddingBottom: 100 + (Platform.OS === 'web' ? 34 : 0), paddingHorizontal: 16 }}
          renderItem={({ item }) => {
            if (item.type === 'header') {
              return (
                <View style={styles.dateHeader}>
                  <Text style={[styles.dateText, { color: colors.mutedForeground }]}>
                    {formatDate(item.date)}
                  </Text>
                  <Text style={[styles.dateTotalText, { color: colors.primary }]}>
                    {formatCurrency(item.total)}
                  </Text>
                </View>
              );
            }
            const pc = PLATFORM_COLORS[item.platform] ?? '#888';
            return (
              <View style={[styles.rideCard, { backgroundColor: colors.card, borderColor: colors.border }]}>
                <View style={[styles.platformBar, { backgroundColor: pc }]} />
                <View style={{ flex: 1 }}>
                  <Text style={[styles.platform, { color: colors.foreground }]}>{item.platform}</Text>
                  {item.note ? (
                    <Text style={[styles.note, { color: colors.mutedForeground }]}>{item.note}</Text>
                  ) : null}
                </View>
                <View style={{ alignItems: 'flex-end', gap: 2 }}>
                  <Text style={[styles.amount, { color: colors.primary }]}>
                    {formatCurrency(item.amount)}
                  </Text>
                  <Text style={[styles.time, { color: colors.mutedForeground }]}>{item.time}</Text>
                </View>
                <TouchableOpacity
                  onPress={() => handleDelete(item.id)}
                  style={styles.del}
                  hitSlop={8}
                >
                  <Feather name="trash-2" size={14} color={colors.destructive} />
                </TouchableOpacity>
              </View>
            );
          }}
          ItemSeparatorComponent={() => <View style={{ height: 8 }} />}
        />
      )}

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
  header: { paddingHorizontal: 16, paddingBottom: 8 },
  title: { fontFamily: 'Inter_700Bold', fontSize: 26 },
  sub: { fontFamily: 'Inter_400Regular', fontSize: 13 },
  filterRow: { paddingHorizontal: 16, paddingBottom: 8, gap: 8 },
  filterChip: {
    paddingHorizontal: 14, paddingVertical: 6, borderRadius: 20, borderWidth: 1,
  },
  filterChipText: { fontFamily: 'Inter_500Medium', fontSize: 13 },
  dateHeader: {
    flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center',
    paddingTop: 16, paddingBottom: 8,
  },
  dateText: { fontFamily: 'Inter_500Medium', fontSize: 13 },
  dateTotalText: { fontFamily: 'Inter_700Bold', fontSize: 14 },
  rideCard: {
    flexDirection: 'row', alignItems: 'center', gap: 10,
    borderRadius: 12, borderWidth: 1, overflow: 'hidden', padding: 12,
  },
  platformBar: { width: 4, height: 40, borderRadius: 2 },
  platform: { fontFamily: 'Inter_600SemiBold', fontSize: 14 },
  note: { fontFamily: 'Inter_400Regular', fontSize: 12 },
  amount: { fontFamily: 'Inter_700Bold', fontSize: 16 },
  time: { fontFamily: 'Inter_400Regular', fontSize: 12 },
  del: { padding: 4 },
  fab: {
    position: 'absolute', right: 20, bottom: 80,
    width: 56, height: 56, borderRadius: 28,
    alignItems: 'center', justifyContent: 'center',
    shadowColor: '#22C55E', shadowOpacity: 0.4, shadowRadius: 12, elevation: 8,
  },
});
