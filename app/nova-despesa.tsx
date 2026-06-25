import { Feather } from '@expo/vector-icons';
import * as Haptics from 'expo-haptics';
import { router, useLocalSearchParams } from 'expo-router';
import React, { useState } from 'react';
import {
  KeyboardAvoidingView,
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
import { MAINTENANCE_TYPES, getDateStr, useApp } from '@/contexts/AppContext';
import { useColors } from '@/hooks/useColors';

type Tipo = 'combustivel' | 'manutencao';

export default function NovaDespesaScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const { tipo: tipoParam } = useLocalSearchParams<{ tipo?: Tipo }>();
  const { addFuel, addMaintenance } = useApp();

  const [tipo, setTipo] = useState<Tipo>(tipoParam === 'manutencao' ? 'manutencao' : 'combustivel');
  const [amount, setAmount] = useState('');
  const [liters, setLiters] = useState('');
  const [km, setKm] = useState('');
  const [odometerKm, setOdometerKm] = useState('');
  const [maintType, setMaintType] = useState(MAINTENANCE_TYPES[0]);
  const [note, setNote] = useState('');
  const [error, setError] = useState('');

  const handleSave = async () => {
    const val = parseFloat(amount.replace(',', '.'));
    if (!val || val <= 0) { setError('Informe um valor valido'); return; }

    if (tipo === 'combustivel') {
      await addFuel({
        date: getDateStr(),
        amount: val,
        liters: liters ? parseFloat(liters.replace(',', '.')) : undefined,
        km: km ? parseFloat(km.replace(',', '.')) : undefined,
        odometerKm: odometerKm ? parseInt(odometerKm) : undefined,
        note: note.trim() || undefined,
      });
    } else {
      await addMaintenance({
        date: getDateStr(),
        type: maintType,
        amount: val,
        note: note.trim() || undefined,
      });
    }
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    router.back();
  };

  const accentColor = tipo === 'combustivel' ? colors.warning : colors.destructive;

  return (
    <KeyboardAvoidingView
      style={[styles.container, { backgroundColor: colors.background }]}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <View style={[styles.header, { paddingTop: insets.top + 16 }]}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backBtn}>
          <Feather name="x" size={22} color={colors.mutedForeground} />
        </TouchableOpacity>
        <Text style={[styles.headerTitle, { color: colors.foreground }]}>Nova Despesa</Text>
        <View style={{ width: 36 }} />
      </View>

      <ScrollView contentContainerStyle={styles.scroll} keyboardShouldPersistTaps="handled">
        <View style={[styles.segmented, { backgroundColor: colors.muted }]}>
          <Pressable onPress={() => setTipo('combustivel')} style={[styles.seg, tipo === 'combustivel' && { backgroundColor: colors.card }]}>
            <Feather name="droplet" size={14} color={tipo === 'combustivel' ? colors.warning : colors.mutedForeground} />
            <Text style={[styles.segText, { color: tipo === 'combustivel' ? colors.foreground : colors.mutedForeground }]}>Combustivel</Text>
          </Pressable>
          <Pressable onPress={() => setTipo('manutencao')} style={[styles.seg, tipo === 'manutencao' && { backgroundColor: colors.card }]}>
            <Feather name="tool" size={14} color={tipo === 'manutencao' ? colors.destructive : colors.mutedForeground} />
            <Text style={[styles.segText, { color: tipo === 'manutencao' ? colors.foreground : colors.mutedForeground }]}>Manutencao</Text>
          </Pressable>
        </View>

        <Text style={[styles.label, { color: colors.mutedForeground }]}>VALOR</Text>
        <View style={[styles.amountRow, { backgroundColor: colors.card, borderColor: error ? colors.destructive : accentColor + '66' }]}>
          <Text style={[styles.currencySign, { color: colors.mutedForeground }]}>R$</Text>
          <TextInput
            style={[styles.amountInput, { color: colors.foreground }]}
            value={amount}
            onChangeText={v => { setAmount(v); setError(''); }}
            placeholder="0,00"
            placeholderTextColor={colors.mutedForeground}
            keyboardType="decimal-pad"
            autoFocus
          />
        </View>
        {error ? <Text style={[styles.error, { color: colors.destructive }]}>{error}</Text> : null}

        {tipo === 'combustivel' ? (
          <>
            <Text style={[styles.label, { color: colors.mutedForeground }]}>LITROS (opcional)</Text>
            <View style={[styles.field, { backgroundColor: colors.card, borderColor: colors.border }]}>
              <Feather name="droplet" size={16} color={colors.warning} />
              <TextInput
                style={[styles.fieldInput, { color: colors.foreground }]}
                value={liters}
                onChangeText={setLiters}
                placeholder="Ex: 8,5"
                placeholderTextColor={colors.mutedForeground}
                keyboardType="decimal-pad"
              />
              <Text style={[styles.unit, { color: colors.mutedForeground }]}>L</Text>
            </View>

            <Text style={[styles.label, { color: colors.mutedForeground }]}>KM RODADOS DESDE ULTIMO ABASTECIMENTO (opcional)</Text>
            <View style={[styles.field, { backgroundColor: colors.card, borderColor: colors.border }]}>
              <Feather name="map" size={16} color={colors.mutedForeground} />
              <TextInput
                style={[styles.fieldInput, { color: colors.foreground }]}
                value={km}
                onChangeText={setKm}
                placeholder="Ex: 280"
                placeholderTextColor={colors.mutedForeground}
                keyboardType="decimal-pad"
              />
              <Text style={[styles.unit, { color: colors.mutedForeground }]}>km</Text>
            </View>

            <Text style={[styles.label, { color: colors.mutedForeground }]}>HODOMETRO ATUAL (opcional)</Text>
            <View style={[styles.field, { backgroundColor: colors.card, borderColor: colors.border }]}>
              <Feather name="activity" size={16} color={colors.primary} />
              <TextInput
                style={[styles.fieldInput, { color: colors.foreground }]}
                value={odometerKm}
                onChangeText={setOdometerKm}
                placeholder="Ex: 45280"
                placeholderTextColor={colors.mutedForeground}
                keyboardType="number-pad"
              />
              <Text style={[styles.unit, { color: colors.mutedForeground }]}>km</Text>
            </View>
          </>
        ) : (
          <>
            <Text style={[styles.label, { color: colors.mutedForeground }]}>TIPO DE MANUTENCAO</Text>
            <View style={styles.maintGrid}>
              {MAINTENANCE_TYPES.map(t => (
                <Pressable
                  key={t}
                  onPress={() => setMaintType(t)}
                  style={[
                    styles.maintChip,
                    {
                      backgroundColor: maintType === t ? colors.destructive + '22' : colors.card,
                      borderColor: maintType === t ? colors.destructive : colors.border,
                    },
                  ]}
                >
                  <Text style={[styles.maintChipText, { color: maintType === t ? colors.destructive : colors.mutedForeground }]}>
                    {t}
                  </Text>
                </Pressable>
              ))}
            </View>
          </>
        )}

        <Text style={[styles.label, { color: colors.mutedForeground }]}>OBSERVACAO (opcional)</Text>
        <TextInput
          style={[styles.noteInput, { backgroundColor: colors.card, borderColor: colors.border, color: colors.foreground }]}
          value={note}
          onChangeText={setNote}
          placeholder="Observacoes adicionais..."
          placeholderTextColor={colors.mutedForeground}
          multiline
        />
      </ScrollView>

      <View style={[styles.footer, { paddingBottom: insets.bottom + 16 }]}>
        <TouchableOpacity
          style={[styles.saveBtn, { backgroundColor: accentColor, opacity: !amount ? 0.6 : 1 }]}
          onPress={handleSave}
          disabled={!amount}
        >
          <Feather name="check" size={20} color="#FFF" />
          <Text style={[styles.saveBtnText, { color: '#FFF' }]}>
            Salvar {tipo === 'combustivel' ? 'Abastecimento' : 'Manutencao'}
          </Text>
        </TouchableOpacity>
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  header: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between',
    paddingHorizontal: 16, paddingBottom: 8,
  },
  backBtn: { width: 36, height: 36, alignItems: 'center', justifyContent: 'center' },
  headerTitle: { fontFamily: 'Inter_700Bold', fontSize: 18 },
  scroll: { padding: 16, gap: 8 },
  segmented: { flexDirection: 'row', borderRadius: 10, padding: 3 },
  seg: { flex: 1, flexDirection: 'row', alignItems: 'center', justifyContent: 'center', gap: 6, paddingVertical: 10, borderRadius: 8 },
  segText: { fontFamily: 'Inter_600SemiBold', fontSize: 13 },
  label: { fontFamily: 'Inter_500Medium', fontSize: 11, letterSpacing: 0.5, marginTop: 8 },
  amountRow: {
    flexDirection: 'row', alignItems: 'center', gap: 8,
    borderRadius: 14, borderWidth: 2, paddingHorizontal: 16, paddingVertical: 12,
  },
  currencySign: { fontFamily: 'Inter_700Bold', fontSize: 22 },
  amountInput: { flex: 1, fontFamily: 'Inter_700Bold', fontSize: 32, padding: 0 },
  error: { fontFamily: 'Inter_400Regular', fontSize: 12 },
  field: {
    flexDirection: 'row', alignItems: 'center', gap: 10,
    borderRadius: 12, borderWidth: 1, paddingHorizontal: 14, paddingVertical: 12,
  },
  fieldInput: { flex: 1, fontFamily: 'Inter_500Medium', fontSize: 16, padding: 0 },
  unit: { fontFamily: 'Inter_500Medium', fontSize: 14 },
  maintGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  maintChip: {
    paddingHorizontal: 12, paddingVertical: 7, borderRadius: 20, borderWidth: 1,
  },
  maintChipText: { fontFamily: 'Inter_500Medium', fontSize: 12 },
  noteInput: {
    borderRadius: 12, borderWidth: 1, paddingHorizontal: 14, paddingVertical: 12,
    fontFamily: 'Inter_400Regular', fontSize: 14, minHeight: 70, textAlignVertical: 'top',
  },
  footer: { paddingHorizontal: 16, paddingTop: 12 },
  saveBtn: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'center',
    gap: 8, borderRadius: 14, paddingVertical: 16,
  },
  saveBtnText: { fontFamily: 'Inter_700Bold', fontSize: 16 },
});
