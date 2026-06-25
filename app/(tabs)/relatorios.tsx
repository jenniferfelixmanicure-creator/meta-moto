import { Feather } from '@expo/vector-icons';
import React, { useMemo, useState } from 'react';
import { Platform, Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { formatCurrency, useApp } from '@/contexts/AppContext';
import { useColors } from '@/hooks/useColors';

const DAYS_PT = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab'];

function toDateStr(d: Date) {
  return d.toISOString().split('T')[0];
}

function MiniBar({ value, maxValue, label, color, sublabel }: {
  value: number; maxValue: number; label: string; color: string; sublabel?: string;
}) {
  const colors = useColors();
  const pct = maxValue > 0 ? Math.min(value / maxValue, 1) : 0;
  return (
    <View style={{ alignItems: 'center', gap: 4, flex: 1 }}>
      <Text style={{ fontFamily: 'Inter_500Medium', fontSize: 9, color: colors.mutedForeground }}>
        {value > 0 ? formatCurrency(value).replace('R$\u00a0', '') : '-'}
      </Text>
      <View style={{ width: 20, height: 80, justifyContent: 'flex-end', backgroundColor: colors.muted, borderRadius: 4 }}>
        <View style={{ width: 20, height: Math.max(pct * 80, value > 0 ? 4 : 0), backgroundColor: color, borderRadius: 4 }} />
      </View>
      <Text style={{ fontFamily: 'Inter_400Regular', fontSize: 9, color: colors.mutedForeground }}>{label}</Text>
      {sublabel ? <Text style={{ fontFamily: 'Inter_400Regular', fontSize: 8, color: colors.mutedForeground }}>{sublabel}</Text> : null}
    </View>
  );
}

type Period = 'semana' | 'mes';

export default function RelatoriosScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const {
    rides, fuel, maintenance, netProfit,
    weekEarnings, monthEarnings,
    weekFuelCost, weekMaintenanceCost,
    monthFuelCost, monthMaintenanceCost,
    prevWeekEarnings, platformStats,
    avgKmPerLiter,
  } = useApp();
  const [period, setPeriod] = useState<Period>('semana');
  const topPad = Platform.OS === 'web' ? 67 : insets.top;

  const weekData = useMemo(() => {
    const days = Array.from({ length: 7 }, (_, i) => {
      const d = new Date();
      d.setDate(d.getDate() - (6 - i));
      return toDateStr(d);
    });
    return days.map(d => {
      const dayObj = new Date(d + 'T00:00:00');
      return {
        label: DAYS_PT[dayObj.getDay()],
        earnings: rides.filter(r => r.date === d).reduce((s, r) => s + r.amount, 0),
      };
    });
  }, [rides]);

  const monthData = useMemo(() => {
    const now = new Date();
    const weeks: { label: string; earnings: number }[] = [];
    for (let w = 0; w < 4; w++) {
      const start = new Date(now.getFullYear(), now.getMonth(), 1 + w * 7);
      const end = new Date(now.getFullYear(), now.getMonth(), Math.min(7 + w * 7, new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate()));
      const startStr = toDateStr(start);
      const endStr = toDateStr(end);
      weeks.push({
        label: `S${w + 1}`,
        earnings: rides.filter(r => r.date >= startStr && r.date <= endStr).reduce((s, r) => s + r.amount, 0),
      });
    }
    return weeks;
  }, [rides]);

  const data = period === 'semana' ? weekData : monthData;
  const maxEarnings = Math.max(...data.map(d => d.earnings), 1);

  const totalEarnings = period === 'semana' ? weekEarnings : monthEarnings;
  const totalFuel = period === 'semana' ? weekFuelCost : monthFuelCost;
  const totalMaint = period === 'semana' ? weekMaintenanceCost : monthMaintenanceCost;
  const totalProfit = period === 'semana' ? netProfit.weekly : netProfit.monthly;

  const weekDiff = prevWeekEarnings > 0
    ? ((weekEarnings - prevWeekEarnings) / prevWeekEarnings) * 100
    : null;

  const maxPlatformEarnings = Math.max(...platformStats.map(p => p.earnings), 1);

  return (
    <View style={[styles.container, { backgroundColor: colors.background }]}>
      <ScrollView
        contentContainerStyle={{ paddingTop: topPad + 16, paddingBottom: 100 + (Platform.OS === 'web' ? 34 : 0) }}
        showsVerticalScrollIndicator={false}
      >
        <View style={{ paddingHorizontal: 16, marginBottom: 16 }}>
          <Text style={[styles.title, { color: colors.foreground }]}>Relatorios</Text>

          <View style={[styles.segmented, { backgroundColor: colors.muted }]}>
            <Pressable onPress={() => setPeriod('semana')} style={[styles.seg, period === 'semana' && { backgroundColor: colors.card }]}>
              <Text style={[styles.segText, { color: period === 'semana' ? colors.foreground : colors.mutedForeground }]}>Semana</Text>
            </Pressable>
            <Pressable onPress={() => setPeriod('mes')} style={[styles.seg, period === 'mes' && { backgroundColor: colors.card }]}>
              <Text style={[styles.segText, { color: period === 'mes' ? colors.foreground : colors.mutedForeground }]}>Mes</Text>
            </Pressable>
          </View>
        </View>

        {/* Weekly comparison */}
        {period === 'semana' && (
          <View style={[styles.compCard, { backgroundColor: colors.card, borderColor: colors.border, marginHorizontal: 16, marginBottom: 14 }]}>
            <Text style={[styles.chartTitle, { color: colors.foreground }]}>Esta semana vs semana passada</Text>
            <View style={styles.compRow}>
              <View style={styles.compItem}>
                <Text style={[styles.compLabel, { color: colors.mutedForeground }]}>Esta semana</Text>
                <Text style={[styles.compValue, { color: colors.primary }]}>{formatCurrency(weekEarnings)}</Text>
              </View>
              <View style={[styles.compDivider, { backgroundColor: colors.border }]} />
              <View style={styles.compItem}>
                <Text style={[styles.compLabel, { color: colors.mutedForeground }]}>Semana passada</Text>
                <Text style={[styles.compValue, { color: colors.foreground }]}>{formatCurrency(prevWeekEarnings)}</Text>
              </View>
              {weekDiff !== null && (
                <>
                  <View style={[styles.compDivider, { backgroundColor: colors.border }]} />
                  <View style={styles.compItem}>
                    <Text style={[styles.compLabel, { color: colors.mutedForeground }]}>Variacao</Text>
                    <View style={{ flexDirection: 'row', alignItems: 'center', gap: 4 }}>
                      <Feather
                        name={weekDiff >= 0 ? 'trending-up' : 'trending-down'}
                        size={14}
                        color={weekDiff >= 0 ? colors.primary : colors.destructive}
                      />
                      <Text style={[styles.compValue, { color: weekDiff >= 0 ? colors.primary : colors.destructive }]}>
                        {weekDiff >= 0 ? '+' : ''}{weekDiff.toFixed(1)}%
                      </Text>
                    </View>
                  </View>
                </>
              )}
            </View>
          </View>
        )}

        {/* Earnings chart */}
        <View style={[styles.chartCard, { backgroundColor: colors.card, borderColor: colors.border }]}>
          <Text style={[styles.chartTitle, { color: colors.foreground }]}>
            {period === 'semana' ? 'Ganhos por dia (7 dias)' : 'Ganhos por semana (mes atual)'}
          </Text>
          <View style={styles.barsRow}>
            {data.map((d, i) => (
              <MiniBar key={i} value={d.earnings} maxValue={maxEarnings} label={d.label} color={colors.primary} />
            ))}
          </View>
        </View>

        {/* Summary grid */}
        <View style={[styles.summaryGrid, { paddingHorizontal: 16, gap: 10 }]}>
          {[
            { label: 'Receita', value: totalEarnings, color: colors.primary, icon: 'trending-up', bg: colors.primary },
            { label: 'Combustivel', value: totalFuel, color: colors.warning, icon: 'droplet', bg: colors.warning },
            { label: 'Manutencao', value: totalMaint, color: colors.destructive, icon: 'tool', bg: colors.destructive },
            { label: 'Lucro Liquido', value: totalProfit, color: totalProfit >= 0 ? colors.primary : colors.destructive, icon: 'dollar-sign', bg: colors.primary },
          ].map((item, i) => (
            <View key={i} style={[styles.summaryCard, { backgroundColor: colors.card, borderColor: i === 3 ? colors.primary + '44' : colors.border }]}>
              <View style={[styles.summaryIcon, { backgroundColor: item.bg + '22' }]}>
                <Feather name={item.icon as any} size={16} color={item.color} />
              </View>
              <Text style={[styles.summaryLabel, { color: colors.mutedForeground }]}>{item.label}</Text>
              <Text style={[styles.summaryValue, { color: item.color }]}>{formatCurrency(item.value)}</Text>
            </View>
          ))}
        </View>

        {/* Platform analysis */}
        {platformStats.length > 0 && (
          <View style={{ paddingHorizontal: 16, marginTop: 14 }}>
            <Text style={[styles.chartTitle, { color: colors.foreground, marginBottom: 10 }]}>
              Plataformas este mes
            </Text>
            <View style={[styles.platformCard, { backgroundColor: colors.card, borderColor: colors.border }]}>
              {platformStats.map((p, i) => (
                <View key={p.platform} style={[
                  styles.platformRow,
                  i < platformStats.length - 1 && { borderBottomWidth: 1, borderBottomColor: colors.border },
                ]}>
                  <View style={{ flex: 1 }}>
                    <Text style={[styles.platformName, { color: colors.foreground }]}>{p.platform}</Text>
                    <Text style={[styles.platformSub, { color: colors.mutedForeground }]}>
                      {p.rides} corridas
                      {p.minutes > 0 ? ` • ${p.earningsPerHour > 0 ? formatCurrency(p.earningsPerHour) + '/h' : ''}` : ''}
                    </Text>
                  </View>
                  <View style={{ alignItems: 'flex-end', gap: 4 }}>
                    <Text style={[styles.platformEarnings, { color: colors.primary }]}>{formatCurrency(p.earnings)}</Text>
                    <View style={[styles.platformBar, { backgroundColor: colors.muted }]}>
                      <View style={[styles.platformBarFill, {
                        width: `${(p.earnings / maxPlatformEarnings) * 100}%` as any,
                        backgroundColor: colors.primary,
                      }]} />
                    </View>
                  </View>
                </View>
              ))}
            </View>
          </View>
        )}

        {/* KM / Fuel efficiency */}
        {avgKmPerLiter > 0 && (
          <View style={{ paddingHorizontal: 16, marginTop: 14 }}>
            <View style={[styles.effCard, { backgroundColor: colors.card, borderColor: colors.border }]}>
              <Feather name="droplet" size={16} color={colors.warning} />
              <View style={{ flex: 1 }}>
                <Text style={[styles.effLabel, { color: colors.mutedForeground }]}>Media de consumo</Text>
                <Text style={[styles.effValue, { color: colors.foreground }]}>
                  {avgKmPerLiter.toFixed(1)} km/L
                </Text>
              </View>
            </View>
          </View>
        )}

        {/* Profit detail */}
        <View style={{ paddingHorizontal: 16, marginTop: 14 }}>
          <Text style={[styles.chartTitle, { color: colors.foreground, marginBottom: 10 }]}>Detalhe de gastos</Text>
          <View style={[styles.detailCard, { backgroundColor: colors.card, borderColor: colors.border }]}>
            {[
              { label: 'Receita total', value: totalEarnings, color: colors.primary, icon: 'arrow-up-circle' },
              { label: 'Combustivel', value: -totalFuel, color: colors.warning, icon: 'droplet' },
              { label: 'Manutencao', value: -totalMaint, color: colors.destructive, icon: 'tool' },
            ].map((row, i) => (
              <View key={i} style={[styles.detailRow, i < 2 && { borderBottomWidth: 1, borderBottomColor: colors.border }]}>
                <Feather name={row.icon as any} size={14} color={row.color} />
                <Text style={[styles.detailLabel, { color: colors.mutedForeground }]}>{row.label}</Text>
                <Text style={[styles.detailValue, { color: row.color }]}>{formatCurrency(Math.abs(row.value))}</Text>
              </View>
            ))}
            <View style={[styles.detailRow, { borderTopWidth: 2, borderTopColor: colors.primary + '44' }]}>
              <Feather name="check-circle" size={14} color={colors.primary} />
              <Text style={[styles.detailLabel, { color: colors.foreground, fontFamily: 'Inter_700Bold' }]}>Lucro liquido</Text>
              <Text style={[styles.detailValue, { color: totalProfit >= 0 ? colors.primary : colors.destructive, fontFamily: 'Inter_700Bold', fontSize: 16 }]}>
                {formatCurrency(totalProfit)}
              </Text>
            </View>
          </View>
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  title: { fontFamily: 'Inter_700Bold', fontSize: 26, marginBottom: 12 },
  segmented: { flexDirection: 'row', borderRadius: 10, padding: 3 },
  seg: { flex: 1, alignItems: 'center', paddingVertical: 8, borderRadius: 8 },
  segText: { fontFamily: 'Inter_600SemiBold', fontSize: 13 },
  compCard: { borderRadius: 16, padding: 16, borderWidth: 1 },
  compRow: { flexDirection: 'row', alignItems: 'center', marginTop: 12 },
  compItem: { flex: 1, alignItems: 'center' },
  compLabel: { fontFamily: 'Inter_400Regular', fontSize: 11, marginBottom: 4 },
  compValue: { fontFamily: 'Inter_700Bold', fontSize: 15 },
  compDivider: { width: 1, height: 36, marginHorizontal: 8 },
  chartCard: { marginHorizontal: 16, borderRadius: 16, padding: 16, borderWidth: 1, marginBottom: 14 },
  chartTitle: { fontFamily: 'Inter_600SemiBold', fontSize: 14, marginBottom: 16 },
  barsRow: { flexDirection: 'row', alignItems: 'flex-end', gap: 6 },
  summaryGrid: { flexDirection: 'row', flexWrap: 'wrap' },
  summaryCard: { width: '47%', padding: 14, borderRadius: 12, borderWidth: 1, gap: 8 },
  summaryIcon: { width: 32, height: 32, borderRadius: 16, alignItems: 'center', justifyContent: 'center' },
  summaryLabel: { fontFamily: 'Inter_400Regular', fontSize: 11 },
  summaryValue: { fontFamily: 'Inter_700Bold', fontSize: 16 },
  platformCard: { borderRadius: 16, borderWidth: 1, overflow: 'hidden' },
  platformRow: { flexDirection: 'row', alignItems: 'center', paddingVertical: 12, paddingHorizontal: 14, gap: 12 },
  platformName: { fontFamily: 'Inter_600SemiBold', fontSize: 14 },
  platformSub: { fontFamily: 'Inter_400Regular', fontSize: 12, marginTop: 2 },
  platformEarnings: { fontFamily: 'Inter_700Bold', fontSize: 14 },
  platformBar: { width: 80, height: 4, borderRadius: 2, overflow: 'hidden' },
  platformBarFill: { height: 4, borderRadius: 2 },
  effCard: { flexDirection: 'row', alignItems: 'center', gap: 12, padding: 14, borderRadius: 12, borderWidth: 1 },
  effLabel: { fontFamily: 'Inter_400Regular', fontSize: 12 },
  effValue: { fontFamily: 'Inter_700Bold', fontSize: 18, marginTop: 2 },
  detailCard: { borderRadius: 16, borderWidth: 1, overflow: 'hidden' },
  detailRow: { flexDirection: 'row', alignItems: 'center', gap: 10, paddingVertical: 12, paddingHorizontal: 14 },
  detailLabel: { flex: 1, fontFamily: 'Inter_500Medium', fontSize: 13 },
  detailValue: { fontFamily: 'Inter_600SemiBold', fontSize: 14 },
});
