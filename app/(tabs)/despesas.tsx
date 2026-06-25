import { Feather } from '@expo/vector-icons';
import * as Haptics from 'expo-haptics';
import { router } from 'expo-router';
import React, { useState } from 'react';
import {
  Alert,
  FlatList,
  Modal,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { EmptyState } from '@/components/EmptyState';
import { MAINTENANCE_TYPES, SCHEDULE_INTERVALS, formatCurrency, formatDate, useApp } from '@/contexts/AppContext';
import { useColors } from '@/hooks/useColors';

type Tab = 'combustivel' | 'manutencao' | 'agenda';

function ScheduleBar({ done, total, color }: { done: number; total: number; color: string }) {
  const colors = useColors();
  const pct = Math.min(done / Math.max(total, 1), 1);
  return (
    <View style={{ height: 6, backgroundColor: colors.muted, borderRadius: 3, marginTop: 6, overflow: 'hidden' }}>
      <View style={{ width: `${pct * 100}%`, height: 6, backgroundColor: color, borderRadius: 3 }} />
    </View>
  );
}

function AddScheduleModal({ visible, onClose, onSave }: {
  visible: boolean;
  onClose: () => void;
  onSave: (type: string, intervalKm: number, lastServiceKm: number) => void;
}) {
  const colors = useColors();
  const [type, setType] = useState(MAINTENANCE_TYPES[0]);
  const [intervalKm, setIntervalKm] = useState('');
  const [lastKm, setLastKm] = useState('');

  const handleSave = () => {
    const interval = parseInt(intervalKm) || SCHEDULE_INTERVALS[type] || 3000;
    const last = parseInt(lastKm) || 0;
    onSave(type, interval, last);
    setIntervalKm('');
    setLastKm('');
    setType(MAINTENANCE_TYPES[0]);
    onClose();
  };

  return (
    <Modal visible={visible} animationType="slide" transparent presentationStyle="overFullScreen">
      <View style={styles.modalOverlay}>
        <View style={[styles.modalSheet, { backgroundColor: colors.background }]}>
          <View style={styles.modalHeader}>
            <Text style={[styles.modalTitle, { color: colors.foreground }]}>Agenda de Manutencao</Text>
            <TouchableOpacity onPress={onClose}>
              <Feather name="x" size={22} color={colors.mutedForeground} />
            </TouchableOpacity>
          </View>

          <ScrollView contentContainerStyle={{ gap: 10 }} keyboardShouldPersistTaps="handled">
            <Text style={[styles.modalLabel, { color: colors.mutedForeground }]}>TIPO</Text>
            <View style={styles.chipGrid}>
              {MAINTENANCE_TYPES.map(t => (
                <Pressable
                  key={t}
                  onPress={() => {
                    setType(t);
                    if (SCHEDULE_INTERVALS[t] && !intervalKm) {
                      setIntervalKm(String(SCHEDULE_INTERVALS[t]));
                    }
                  }}
                  style={[
                    styles.chip,
                    {
                      backgroundColor: type === t ? colors.primary + '22' : colors.card,
                      borderColor: type === t ? colors.primary : colors.border,
                    },
                  ]}
                >
                  <Text style={[styles.chipText, { color: type === t ? colors.primary : colors.mutedForeground }]}>{t}</Text>
                </Pressable>
              ))}
            </View>

            <Text style={[styles.modalLabel, { color: colors.mutedForeground }]}>INTERVALO (km)</Text>
            <View style={[styles.modalField, { backgroundColor: colors.card, borderColor: colors.border }]}>
              <Feather name="repeat" size={16} color={colors.mutedForeground} />
              <TextInput
                style={[styles.modalInput, { color: colors.foreground }]}
                value={intervalKm}
                onChangeText={setIntervalKm}
                placeholder={String(SCHEDULE_INTERVALS[type] ?? 3000)}
                placeholderTextColor={colors.mutedForeground}
                keyboardType="number-pad"
              />
              <Text style={[styles.unit, { color: colors.mutedForeground }]}>km</Text>
            </View>

            <Text style={[styles.modalLabel, { color: colors.mutedForeground }]}>KM NO ULTIMO SERVICO</Text>
            <View style={[styles.modalField, { backgroundColor: colors.card, borderColor: colors.border }]}>
              <Feather name="map-pin" size={16} color={colors.mutedForeground} />
              <TextInput
                style={[styles.modalInput, { color: colors.foreground }]}
                value={lastKm}
                onChangeText={setLastKm}
                placeholder="Ex: 45000"
                placeholderTextColor={colors.mutedForeground}
                keyboardType="number-pad"
              />
              <Text style={[styles.unit, { color: colors.mutedForeground }]}>km</Text>
            </View>

            <TouchableOpacity
              style={[styles.saveBtn, { backgroundColor: colors.primary, marginTop: 8 }]}
              onPress={handleSave}
            >
              <Feather name="check" size={18} color="#000" />
              <Text style={styles.saveBtnText}>Adicionar</Text>
            </TouchableOpacity>
          </ScrollView>
        </View>
      </View>
    </Modal>
  );
}

export default function DespesasScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const {
    fuel, maintenance, maintenanceSchedules, currentOdometer,
    deleteFuel, deleteMaintenance, monthFuelCost, monthMaintenanceCost,
    addMaintenanceSchedule, updateMaintenanceSchedule, deleteMaintenanceSchedule,
  } = useApp();
  const [tab, setTab] = useState<Tab>('combustivel');
  const [showAddSchedule, setShowAddSchedule] = useState(false);
  const topPad = Platform.OS === 'web' ? 67 : insets.top;

  const handleDelFuel = (id: string) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    Alert.alert('Excluir abastecimento', 'Tem certeza?', [
      { text: 'Cancelar', style: 'cancel' },
      { text: 'Excluir', style: 'destructive', onPress: () => deleteFuel(id) },
    ]);
  };

  const handleDelMaint = (id: string) => {
    Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
    Alert.alert('Excluir manutencao', 'Tem certeza?', [
      { text: 'Cancelar', style: 'cancel' },
      { text: 'Excluir', style: 'destructive', onPress: () => deleteMaintenance(id) },
    ]);
  };

  const handleDelSchedule = (id: string) => {
    Alert.alert('Remover agenda', 'Tem certeza?', [
      { text: 'Cancelar', style: 'cancel' },
      { text: 'Remover', style: 'destructive', onPress: () => deleteMaintenanceSchedule(id) },
    ]);
  };

  const handleMarkServiced = (id: string) => {
    if (currentOdometer > 0) {
      updateMaintenanceSchedule(id, currentOdometer, new Date().toISOString().split('T')[0]);
    } else {
      Alert.prompt(
        'Hodometro atual',
        'Informe a quilometragem atual da moto:',
        [
          { text: 'Cancelar', style: 'cancel' },
          {
            text: 'Salvar',
            onPress: (km) => {
              const val = parseInt(km ?? '0');
              if (val > 0) updateMaintenanceSchedule(id, val, new Date().toISOString().split('T')[0]);
            },
          },
        ],
        'plain-text',
        '',
        'number-pad'
      );
    }
  };

  return (
    <View style={[styles.container, { backgroundColor: colors.background }]}>
      <View style={[styles.header, { paddingTop: topPad + 16, backgroundColor: colors.background }]}>
        <Text style={[styles.title, { color: colors.foreground }]}>Despesas</Text>

        <View style={styles.totalRow}>
          <View style={[styles.totalCard, { backgroundColor: colors.card, borderColor: colors.border }]}>
            <Feather name="droplet" size={14} color={colors.warning} />
            <Text style={[styles.totalLabel, { color: colors.mutedForeground }]}>Combustivel/mes</Text>
            <Text style={[styles.totalValue, { color: colors.warning }]}>{formatCurrency(monthFuelCost)}</Text>
          </View>
          <View style={[styles.totalCard, { backgroundColor: colors.card, borderColor: colors.border }]}>
            <Feather name="tool" size={14} color={colors.destructive} />
            <Text style={[styles.totalLabel, { color: colors.mutedForeground }]}>Manutencao/mes</Text>
            <Text style={[styles.totalValue, { color: colors.destructive }]}>{formatCurrency(monthMaintenanceCost)}</Text>
          </View>
        </View>

        <View style={[styles.segmented, { backgroundColor: colors.muted }]}>
          {(['combustivel', 'manutencao', 'agenda'] as Tab[]).map((t) => {
            const icons = { combustivel: 'droplet', manutencao: 'tool', agenda: 'calendar' } as const;
            const labels = { combustivel: 'Combustivel', manutencao: 'Manutencao', agenda: 'Agenda' };
            const activeColors = { combustivel: colors.warning, manutencao: colors.destructive, agenda: colors.primary };
            return (
              <Pressable key={t} onPress={() => setTab(t)} style={[styles.seg, tab === t && { backgroundColor: colors.card }]}>
                <Feather name={icons[t]} size={13} color={tab === t ? activeColors[t] : colors.mutedForeground} />
                <Text style={[styles.segText, { color: tab === t ? colors.foreground : colors.mutedForeground }]}>
                  {labels[t]}
                </Text>
              </Pressable>
            );
          })}
        </View>
      </View>

      {tab === 'combustivel' && (
        fuel.length === 0 ? (
          <EmptyState icon="droplet" title="Nenhum abastecimento" subtitle="Registre seus gastos com combustivel" />
        ) : (
          <FlatList
            data={fuel}
            keyExtractor={i => i.id}
            contentContainerStyle={{ padding: 16, paddingBottom: 100 }}
            ItemSeparatorComponent={() => <View style={{ height: 8 }} />}
            renderItem={({ item }) => (
              <View style={[styles.card, { backgroundColor: colors.card, borderColor: colors.border }]}>
                <View style={[styles.iconCircle, { backgroundColor: colors.warning + '22' }]}>
                  <Feather name="droplet" size={18} color={colors.warning} />
                </View>
                <View style={{ flex: 1 }}>
                  <Text style={[styles.cardTitle, { color: colors.foreground }]}>Abastecimento</Text>
                  <Text style={[styles.cardSub, { color: colors.mutedForeground }]}>
                    {formatDate(item.date)}
                    {item.liters ? ` • ${item.liters}L` : ''}
                    {item.km ? ` • ${item.km}km rodados` : ''}
                    {item.odometerKm ? ` • Hod: ${item.odometerKm}km` : ''}
                  </Text>
                </View>
                <Text style={[styles.cardAmount, { color: colors.warning }]}>{formatCurrency(item.amount)}</Text>
                <TouchableOpacity onPress={() => handleDelFuel(item.id)} hitSlop={8}>
                  <Feather name="trash-2" size={14} color={colors.destructive} />
                </TouchableOpacity>
              </View>
            )}
          />
        )
      )}

      {tab === 'manutencao' && (
        maintenance.length === 0 ? (
          <EmptyState icon="tool" title="Nenhuma manutencao" subtitle="Registre suas despesas com manutencao" />
        ) : (
          <FlatList
            data={maintenance}
            keyExtractor={i => i.id}
            contentContainerStyle={{ padding: 16, paddingBottom: 100 }}
            ItemSeparatorComponent={() => <View style={{ height: 8 }} />}
            renderItem={({ item }) => (
              <View style={[styles.card, { backgroundColor: colors.card, borderColor: colors.border }]}>
                <View style={[styles.iconCircle, { backgroundColor: colors.destructive + '22' }]}>
                  <Feather name="tool" size={18} color={colors.destructive} />
                </View>
                <View style={{ flex: 1 }}>
                  <Text style={[styles.cardTitle, { color: colors.foreground }]}>{item.type}</Text>
                  <Text style={[styles.cardSub, { color: colors.mutedForeground }]}>{formatDate(item.date)}</Text>
                </View>
                <Text style={[styles.cardAmount, { color: colors.destructive }]}>{formatCurrency(item.amount)}</Text>
                <TouchableOpacity onPress={() => handleDelMaint(item.id)} hitSlop={8}>
                  <Feather name="trash-2" size={14} color={colors.destructive} />
                </TouchableOpacity>
              </View>
            )}
          />
        )
      )}

      {tab === 'agenda' && (
        <ScrollView contentContainerStyle={{ padding: 16, paddingBottom: 100, gap: 12 }}>
          {currentOdometer > 0 && (
            <View style={[styles.odomCard, { backgroundColor: colors.card, borderColor: colors.border }]}>
              <Feather name="activity" size={14} color={colors.primary} />
              <Text style={[styles.odomText, { color: colors.mutedForeground }]}>
                Hodometro atual: <Text style={{ color: colors.foreground, fontFamily: 'Inter_700Bold' }}>{currentOdometer.toLocaleString()} km</Text>
              </Text>
            </View>
          )}

          {maintenanceSchedules.length === 0 ? (
            <EmptyState icon="calendar" title="Nenhuma agenda" subtitle="Adicione lembretes de manutencao por quilometragem" />
          ) : (
            maintenanceSchedules.map(s => {
              const kmDone = currentOdometer > 0 ? currentOdometer - s.lastServiceKm : 0;
              const pct = Math.min(kmDone / s.intervalKm, 1);
              const kmRemaining = s.intervalKm - kmDone;
              const urgent = pct >= 0.9;
              const overdue = kmRemaining <= 0;
              const color = overdue ? colors.destructive : urgent ? colors.warning : colors.primary;

              return (
                <View key={s.id} style={[styles.scheduleCard, { backgroundColor: colors.card, borderColor: overdue ? colors.destructive + '66' : colors.border }]}>
                  <View style={styles.scheduleHeader}>
                    <View style={[styles.scheduleIcon, { backgroundColor: color + '22' }]}>
                      <Feather name="tool" size={16} color={color} />
                    </View>
                    <View style={{ flex: 1 }}>
                      <Text style={[styles.scheduleType, { color: colors.foreground }]}>{s.type}</Text>
                      <Text style={[styles.scheduleSub, { color: colors.mutedForeground }]}>
                        A cada {s.intervalKm.toLocaleString()} km • Ultimo: {s.lastServiceKm.toLocaleString()} km
                      </Text>
                    </View>
                    <TouchableOpacity onPress={() => handleDelSchedule(s.id)} hitSlop={8}>
                      <Feather name="trash-2" size={14} color={colors.mutedForeground} />
                    </TouchableOpacity>
                  </View>

                  {currentOdometer > 0 && (
                    <>
                      <ScheduleBar done={kmDone} total={s.intervalKm} color={color} />
                      <View style={styles.scheduleFooter}>
                        <Text style={[styles.scheduleStatus, { color }]}>
                          {overdue
                            ? `Vencida! ${Math.abs(kmRemaining).toLocaleString()} km atrasada`
                            : urgent
                            ? `Urgente: ${kmRemaining.toLocaleString()} km restantes`
                            : `${kmRemaining.toLocaleString()} km restantes`}
                        </Text>
                        <TouchableOpacity
                          style={[styles.servicedBtn, { backgroundColor: colors.primary + '22', borderColor: colors.primary + '44' }]}
                          onPress={() => handleMarkServiced(s.id)}
                        >
                          <Feather name="check" size={12} color={colors.primary} />
                          <Text style={[styles.servicedText, { color: colors.primary }]}>Feito</Text>
                        </TouchableOpacity>
                      </View>
                    </>
                  )}
                </View>
              );
            })
          )}

          <TouchableOpacity
            style={[styles.addScheduleBtn, { backgroundColor: colors.card, borderColor: colors.primary + '44', borderStyle: 'dashed' }]}
            onPress={() => setShowAddSchedule(true)}
          >
            <Feather name="plus" size={18} color={colors.primary} />
            <Text style={[styles.addScheduleText, { color: colors.primary }]}>Adicionar Lembrete</Text>
          </TouchableOpacity>
        </ScrollView>
      )}

      {(tab === 'combustivel' || tab === 'manutencao') && (
        <TouchableOpacity
          style={[styles.fab, { backgroundColor: tab === 'combustivel' ? colors.warning : colors.destructive }]}
          onPress={() => {
            Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
            router.push({ pathname: '/nova-despesa', params: { tipo: tab } });
          }}
        >
          <Feather name="plus" size={26} color="#FFF" />
        </TouchableOpacity>
      )}

      <AddScheduleModal
        visible={showAddSchedule}
        onClose={() => setShowAddSchedule(false)}
        onSave={(type, intervalKm, lastServiceKm) => {
          addMaintenanceSchedule({
            type,
            intervalKm,
            lastServiceKm,
            lastServiceDate: new Date().toISOString().split('T')[0],
          });
        }}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  header: { paddingHorizontal: 16, paddingBottom: 8, gap: 12 },
  title: { fontFamily: 'Inter_700Bold', fontSize: 26 },
  totalRow: { flexDirection: 'row', gap: 8 },
  totalCard: { flex: 1, padding: 10, borderRadius: 12, borderWidth: 1, alignItems: 'center', gap: 4 },
  totalLabel: { fontFamily: 'Inter_400Regular', fontSize: 10, textAlign: 'center' },
  totalValue: { fontFamily: 'Inter_700Bold', fontSize: 14 },
  segmented: { flexDirection: 'row', borderRadius: 10, padding: 3, gap: 2 },
  seg: { flex: 1, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 4, paddingVertical: 8, borderRadius: 8 },
  segText: { fontFamily: 'Inter_600SemiBold', fontSize: 11 },
  card: { flexDirection: 'row', alignItems: 'center', gap: 10, padding: 12, borderRadius: 12, borderWidth: 1 },
  iconCircle: { width: 38, height: 38, borderRadius: 19, alignItems: 'center', justifyContent: 'center' },
  cardTitle: { fontFamily: 'Inter_600SemiBold', fontSize: 14 },
  cardSub: { fontFamily: 'Inter_400Regular', fontSize: 12 },
  cardAmount: { fontFamily: 'Inter_700Bold', fontSize: 15 },
  odomCard: { flexDirection: 'row', alignItems: 'center', gap: 8, padding: 10, borderRadius: 10, borderWidth: 1 },
  odomText: { fontFamily: 'Inter_400Regular', fontSize: 13 },
  scheduleCard: { borderRadius: 14, padding: 14, borderWidth: 1, gap: 4 },
  scheduleHeader: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  scheduleIcon: { width: 34, height: 34, borderRadius: 17, alignItems: 'center', justifyContent: 'center' },
  scheduleType: { fontFamily: 'Inter_600SemiBold', fontSize: 14 },
  scheduleSub: { fontFamily: 'Inter_400Regular', fontSize: 11, marginTop: 2 },
  scheduleFooter: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginTop: 6 },
  scheduleStatus: { fontFamily: 'Inter_600SemiBold', fontSize: 12 },
  servicedBtn: { flexDirection: 'row', alignItems: 'center', gap: 4, paddingHorizontal: 10, paddingVertical: 5, borderRadius: 16, borderWidth: 1 },
  servicedText: { fontFamily: 'Inter_600SemiBold', fontSize: 11 },
  addScheduleBtn: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 8, padding: 14, borderRadius: 14, borderWidth: 1 },
  addScheduleText: { fontFamily: 'Inter_600SemiBold', fontSize: 14 },
  fab: { position: 'absolute', right: 20, bottom: 80, width: 56, height: 56, borderRadius: 28, alignItems: 'center', justifyContent: 'center', elevation: 8 },
  modalOverlay: { flex: 1, backgroundColor: '#00000088', justifyContent: 'flex-end' },
  modalSheet: { borderTopLeftRadius: 24, borderTopRightRadius: 24, padding: 20, gap: 12, maxHeight: '85%' },
  modalHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 },
  modalTitle: { fontFamily: 'Inter_700Bold', fontSize: 18 },
  modalLabel: { fontFamily: 'Inter_500Medium', fontSize: 11, letterSpacing: 0.5 },
  chipGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  chip: { paddingHorizontal: 12, paddingVertical: 7, borderRadius: 20, borderWidth: 1 },
  chipText: { fontFamily: 'Inter_500Medium', fontSize: 12 },
  modalField: { flexDirection: 'row', alignItems: 'center', gap: 10, borderRadius: 12, borderWidth: 1, paddingHorizontal: 14, paddingVertical: 12 },
  modalInput: { flex: 1, fontFamily: 'Inter_500Medium', fontSize: 16, padding: 0 },
  unit: { fontFamily: 'Inter_500Medium', fontSize: 13 },
  saveBtn: { flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 8, borderRadius: 14, paddingVertical: 14 },
  saveBtnText: { fontFamily: 'Inter_700Bold', fontSize: 15, color: '#000' },
});
