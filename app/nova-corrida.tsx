import { Feather } from '@expo/vector-icons';
import * as Haptics from 'expo-haptics';
import { router } from 'expo-router';
import React, { useEffect, useState } from 'react';
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
import { PLATFORMS, getDateStr, useApp } from '@/contexts/AppContext';
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

function nowTime(): string {
  const d = new Date();
  return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
}

export default function NovaCorridaScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const { addRide, shiftStart } = useApp();

  const [amount, setAmount] = useState('');
  const [platform, setPlatform] = useState('Uber');
  const [time, setTime] = useState(nowTime());
  const [duration, setDuration] = useState('');
  const [kmRidden, setKmRidden] = useState('');
  const [note, setNote] = useState('');
  const [error, setError] = useState('');
  const [autoDetected, setAutoDetected] = useState(false);

  useEffect(() => {
    if (shiftStart) {
      const elapsed = Math.round((Date.now() - shiftStart.getTime()) / 60000);
      if (elapsed > 0 && !duration) setDuration(String(elapsed));
    }
  }, []);

  const handleSave = async () => {
    const val = parseFloat(amount.replace(',', '.'));
    if (!val || val <= 0) {
      setError('Informe um valor valido');
      return;
    }
    await addRide({
      date: getDateStr(),
      platform,
      amount: val,
      time,
      duration: duration ? parseInt(duration) : undefined,
      kmRidden: kmRidden ? parseFloat(kmRidden.replace(',', '.')) : undefined,
      note: note.trim() || undefined,
    });
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    router.back();
  };

  return (
    <KeyboardAvoidingView
      style={[styles.container, { backgroundColor: colors.background }]}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <View style={[styles.header, { paddingTop: insets.top + 16, backgroundColor: colors.background }]}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backBtn}>
          <Feather name="x" size={22} color={colors.mutedForeground} />
        </TouchableOpacity>
        <Text style={[styles.headerTitle, { color: colors.foreground }]}>Nova Corrida</Text>
        <View style={{ width: 36 }} />
      </View>

      <ScrollView contentContainerStyle={styles.scroll} keyboardShouldPersistTaps="handled">
        {autoDetected && (
          <View style={[styles.detectedBanner, { backgroundColor: colors.primary + '22', borderColor: colors.primary + '44' }]}>
            <Feather name="bell" size={14} color={colors.primary} />
            <Text style={[styles.detectedText, { color: colors.primary }]}>Valor detectado automaticamente!</Text>
          </View>
        )}

        <Text style={[styles.label, { color: colors.mutedForeground }]}>VALOR DA CORRIDA</Text>
        <View style={[styles.amountRow, { backgroundColor: colors.card, borderColor: error ? colors.destructive : colors.border }]}>
          <Text style={[styles.currencySign, { color: colors.mutedForeground }]}>R$</Text>
          <TextInput
            style={[styles.amountInput, { color: colors.foreground }]}
            value={amount}
            onChangeText={v => { setAmount(v); setError(''); setAutoDetected(false); }}
            placeholder="0,00"
            placeholderTextColor={colors.mutedForeground}
            keyboardType="decimal-pad"
            autoFocus
          />
        </View>
        {error ? <Text style={[styles.error, { color: colors.destructive }]}>{error}</Text> : null}

        <Text style={[styles.label, { color: colors.mutedForeground }]}>PLATAFORMA</Text>
        <View style={styles.platformGrid}>
          {PLATFORMS.map(p => {
            const pc = PLATFORM_COLORS[p] ?? '#888';
            const selected = platform === p;
            return (
              <Pressable
                key={p}
                onPress={() => setPlatform(p)}
                style={[
                  styles.platformChip,
                  {
                    backgroundColor: selected ? pc + '33' : colors.card,
                    borderColor: selected ? pc : colors.border,
                    borderWidth: selected ? 1.5 : 1,
                  },
                ]}
              >
                <View style={[styles.platformDot, { backgroundColor: pc }]} />
                <Text style={[styles.platformChipText, { color: selected ? colors.foreground : colors.mutedForeground }]}>
                  {p}
                </Text>
              </Pressable>
            );
          })}
        </View>

        <Text style={[styles.label, { color: colors.mutedForeground }]}>HORARIO</Text>
        <View style={[styles.field, { backgroundColor: colors.card, borderColor: colors.border }]}>
          <Feather name="clock" size={16} color={colors.mutedForeground} />
          <TextInput
            style={[styles.fieldInput, { color: colors.foreground }]}
            value={time}
            onChangeText={setTime}
            placeholder="00:00"
            placeholderTextColor={colors.mutedForeground}
          />
        </View>

        <View style={styles.row}>
          <View style={{ flex: 1 }}>
            <Text style={[styles.label, { color: colors.mutedForeground }]}>DURACAO (min)</Text>
            <View style={[styles.field, { backgroundColor: colors.card, borderColor: colors.border }]}>
              <Feather name="activity" size={16} color={colors.mutedForeground} />
              <TextInput
                style={[styles.fieldInput, { color: colors.foreground }]}
                value={duration}
                onChangeText={setDuration}
                placeholder="Ex: 25"
                placeholderTextColor={colors.mutedForeground}
                keyboardType="number-pad"
              />
              <Text style={[styles.unit, { color: colors.mutedForeground }]}>min</Text>
            </View>
          </View>
          <View style={{ width: 10 }} />
          <View style={{ flex: 1 }}>
            <Text style={[styles.label, { color: colors.mutedForeground }]}>KM RODADOS</Text>
            <View style={[styles.field, { backgroundColor: colors.card, borderColor: colors.border }]}>
              <Feather name="map-pin" size={16} color={colors.mutedForeground} />
              <TextInput
                style={[styles.fieldInput, { color: colors.foreground }]}
                value={kmRidden}
                onChangeText={setKmRidden}
                placeholder="Ex: 5,2"
                placeholderTextColor={colors.mutedForeground}
                keyboardType="decimal-pad"
              />
              <Text style={[styles.unit, { color: colors.mutedForeground }]}>km</Text>
            </View>
          </View>
        </View>

        <Text style={[styles.label, { color: colors.mutedForeground }]}>OBSERVACAO (opcional)</Text>
        <TextInput
          style={[styles.noteInput, { backgroundColor: colors.card, borderColor: colors.border, color: colors.foreground }]}
          value={note}
          onChangeText={setNote}
          placeholder="Ex: corrida longa, gorjeta..."
          placeholderTextColor={colors.mutedForeground}
          multiline
        />
      </ScrollView>

      <View style={[styles.footer, { paddingBottom: insets.bottom + 16, backgroundColor: colors.background }]}>
        <TouchableOpacity
          style={[styles.saveBtn, { backgroundColor: colors.primary, opacity: !amount ? 0.6 : 1 }]}
          onPress={handleSave}
          disabled={!amount}
        >
          <Feather name="check" size={20} color="#000" />
          <Text style={styles.saveBtnText}>Salvar Corrida</Text>
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
  detectedBanner: {
    flexDirection: 'row', alignItems: 'center', gap: 8,
    padding: 10, borderRadius: 10, borderWidth: 1,
  },
  detectedText: { fontFamily: 'Inter_600SemiBold', fontSize: 13 },
  label: { fontFamily: 'Inter_500Medium', fontSize: 11, letterSpacing: 0.5, marginTop: 8 },
  amountRow: {
    flexDirection: 'row', alignItems: 'center', gap: 8,
    borderRadius: 14, borderWidth: 1, paddingHorizontal: 16, paddingVertical: 14,
  },
  currencySign: { fontFamily: 'Inter_700Bold', fontSize: 22 },
  amountInput: { flex: 1, fontFamily: 'Inter_700Bold', fontSize: 32, padding: 0 },
  error: { fontFamily: 'Inter_400Regular', fontSize: 12 },
  platformGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  platformChip: {
    flexDirection: 'row', alignItems: 'center', gap: 6,
    paddingHorizontal: 12, paddingVertical: 8, borderRadius: 20,
  },
  platformDot: { width: 8, height: 8, borderRadius: 4 },
  platformChipText: { fontFamily: 'Inter_500Medium', fontSize: 13 },
  row: { flexDirection: 'row', alignItems: 'flex-end' },
  field: {
    flexDirection: 'row', alignItems: 'center', gap: 10,
    borderRadius: 12, borderWidth: 1, paddingHorizontal: 14, paddingVertical: 12,
  },
  fieldInput: { flex: 1, fontFamily: 'Inter_500Medium', fontSize: 16, padding: 0 },
  unit: { fontFamily: 'Inter_500Medium', fontSize: 13 },
  noteInput: {
    borderRadius: 12, borderWidth: 1, paddingHorizontal: 14, paddingVertical: 12,
    fontFamily: 'Inter_400Regular', fontSize: 14, minHeight: 70, textAlignVertical: 'top',
  },
  footer: { paddingHorizontal: 16, paddingTop: 12 },
  saveBtn: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'center',
    gap: 8, borderRadius: 14, paddingVertical: 16,
  },
  saveBtnText: { fontFamily: 'Inter_700Bold', fontSize: 16, color: '#000' },
});
