import { Feather } from '@expo/vector-icons';
import { router } from 'expo-router';
import React, { useState } from 'react';
import {
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
  View,
} from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { formatCurrency } from '@/contexts/AppContext';
import { useColors } from '@/hooks/useColors';

interface Result {
  daysNeeded: number;
  dailyNeeded: number;
  endDate: string;
  monthlyNeeded: number;
  weeklyNeeded: number;
}

function addDays(days: number): string {
  const d = new Date();
  d.setDate(d.getDate() + days);
  return d.toLocaleDateString('pt-BR');
}

export default function CalculadoraScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();

  const [objective, setObjective] = useState('');
  const [saved, setSaved] = useState('');
  const [dailyEarning, setDailyEarning] = useState('');
  const [result, setResult] = useState<Result | null>(null);

  const calculate = () => {
    const obj = parseFloat(objective.replace(',', '.'));
    const sv = parseFloat(saved.replace(',', '.')) || 0;
    const daily = parseFloat(dailyEarning.replace(',', '.'));

    if (!obj || obj <= 0 || !daily || daily <= 0) return;

    const needed = Math.max(obj - sv, 0);
    const days = Math.ceil(needed / daily);
    setResult({
      daysNeeded: days,
      dailyNeeded: daily,
      endDate: addDays(days),
      monthlyNeeded: daily * 26,
      weeklyNeeded: daily * 6,
    });
  };

  return (
    <KeyboardAvoidingView
      style={[styles.container, { backgroundColor: colors.background }]}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <View style={[styles.header, { paddingTop: insets.top + 16 }]}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backBtn}>
          <Feather name="arrow-left" size={22} color={colors.mutedForeground} />
        </TouchableOpacity>
        <Text style={[styles.headerTitle, { color: colors.foreground }]}>Calculadora</Text>
        <View style={{ width: 36 }} />
      </View>

      <ScrollView contentContainerStyle={styles.scroll} keyboardShouldPersistTaps="handled">
        <View style={[styles.infoCard, { backgroundColor: colors.secondary, borderColor: colors.border }]}>
          <Feather name="info" size={14} color={colors.primary} />
          <Text style={[styles.infoText, { color: colors.mutedForeground }]}>
            Informe seu objetivo financeiro e quanto ganha por dia para calcular quando atingira a meta.
          </Text>
        </View>

        <Text style={[styles.label, { color: colors.mutedForeground }]}>OBJETIVO (valor total)</Text>
        <View style={[styles.field, { backgroundColor: colors.card, borderColor: colors.border }]}>
          <Text style={[styles.prefix, { color: colors.mutedForeground }]}>R$</Text>
          <TextInput
            style={[styles.input, { color: colors.foreground }]}
            value={objective}
            onChangeText={setObjective}
            placeholder="Ex: 20.000"
            placeholderTextColor={colors.mutedForeground}
            keyboardType="decimal-pad"
          />
        </View>

        <Text style={[styles.label, { color: colors.mutedForeground }]}>JA TENHO GUARDADO</Text>
        <View style={[styles.field, { backgroundColor: colors.card, borderColor: colors.border }]}>
          <Text style={[styles.prefix, { color: colors.mutedForeground }]}>R$</Text>
          <TextInput
            style={[styles.input, { color: colors.foreground }]}
            value={saved}
            onChangeText={setSaved}
            placeholder="0,00"
            placeholderTextColor={colors.mutedForeground}
            keyboardType="decimal-pad"
          />
        </View>

        <Text style={[styles.label, { color: colors.mutedForeground }]}>GANHO MEDIO POR DIA</Text>
        <View style={[styles.field, { backgroundColor: colors.card, borderColor: colors.border }]}>
          <Text style={[styles.prefix, { color: colors.mutedForeground }]}>R$</Text>
          <TextInput
            style={[styles.input, { color: colors.foreground }]}
            value={dailyEarning}
            onChangeText={setDailyEarning}
            placeholder="Ex: 250"
            placeholderTextColor={colors.mutedForeground}
            keyboardType="decimal-pad"
          />
        </View>

        <TouchableOpacity
          style={[styles.calcBtn, { backgroundColor: colors.primary, opacity: !objective || !dailyEarning ? 0.6 : 1 }]}
          onPress={calculate}
          disabled={!objective || !dailyEarning}
        >
          <Feather name="hash" size={18} color="#000" />
          <Text style={styles.calcBtnText}>Calcular</Text>
        </TouchableOpacity>

        {result && (
          <View style={[styles.resultCard, { backgroundColor: colors.card, borderColor: colors.primary + '44' }]}>
            <View style={styles.resultHeader}>
              <Feather name="target" size={20} color={colors.primary} />
              <Text style={[styles.resultTitle, { color: colors.foreground }]}>Resultado</Text>
            </View>

            <View style={[styles.resultHighlight, { backgroundColor: colors.primary + '22' }]}>
              <Text style={[styles.resultDays, { color: colors.primary }]}>{result.daysNeeded}</Text>
              <Text style={[styles.resultDaysLabel, { color: colors.mutedForeground }]}>dias de trabalho</Text>
            </View>

            {[
              { icon: 'calendar', label: 'Previsao de conclusao', value: result.endDate, color: colors.foreground },
              { icon: 'sun', label: 'Meta diaria necessaria', value: formatCurrency(result.dailyNeeded), color: colors.primary },
              { icon: 'briefcase', label: 'Meta semanal (6 dias)', value: formatCurrency(result.weeklyNeeded), color: colors.info },
              { icon: 'trending-up', label: 'Meta mensal (26 dias)', value: formatCurrency(result.monthlyNeeded), color: colors.warning },
            ].map((row, i) => (
              <View key={i} style={[styles.resultRow, i < 3 && { borderBottomWidth: 1, borderBottomColor: colors.border }]}>
                <View style={[styles.resultIcon, { backgroundColor: row.color + '22' }]}>
                  <Feather name={row.icon as any} size={14} color={row.color} />
                </View>
                <Text style={[styles.resultLabel, { color: colors.mutedForeground }]}>{row.label}</Text>
                <Text style={[styles.resultValue, { color: row.color }]}>{row.value}</Text>
              </View>
            ))}
          </View>
        )}
      </ScrollView>
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
  scroll: { padding: 16, gap: 10, paddingBottom: 60 },
  infoCard: { flexDirection: 'row', gap: 8, padding: 12, borderRadius: 12, borderWidth: 1, alignItems: 'flex-start' },
  infoText: { flex: 1, fontFamily: 'Inter_400Regular', fontSize: 13, lineHeight: 18 },
  label: { fontFamily: 'Inter_500Medium', fontSize: 11, letterSpacing: 0.5, marginTop: 4 },
  field: {
    flexDirection: 'row', alignItems: 'center', gap: 8,
    borderRadius: 12, borderWidth: 1, paddingHorizontal: 14, paddingVertical: 12,
  },
  prefix: { fontFamily: 'Inter_700Bold', fontSize: 18 },
  input: { flex: 1, fontFamily: 'Inter_600SemiBold', fontSize: 20, padding: 0 },
  calcBtn: {
    flexDirection: 'row', alignItems: 'center', justifyContent: 'center',
    gap: 8, borderRadius: 14, paddingVertical: 15, marginTop: 6,
  },
  calcBtnText: { fontFamily: 'Inter_700Bold', fontSize: 16, color: '#000' },
  resultCard: { borderRadius: 16, borderWidth: 1.5, overflow: 'hidden', marginTop: 4 },
  resultHeader: { flexDirection: 'row', alignItems: 'center', gap: 8, padding: 16, paddingBottom: 12 },
  resultTitle: { fontFamily: 'Inter_700Bold', fontSize: 17 },
  resultHighlight: { alignItems: 'center', paddingVertical: 20, marginHorizontal: 16, borderRadius: 12, marginBottom: 8 },
  resultDays: { fontFamily: 'Inter_700Bold', fontSize: 52 },
  resultDaysLabel: { fontFamily: 'Inter_500Medium', fontSize: 14 },
  resultRow: { flexDirection: 'row', alignItems: 'center', gap: 10, paddingVertical: 12, paddingHorizontal: 16 },
  resultIcon: { width: 28, height: 28, borderRadius: 14, alignItems: 'center', justifyContent: 'center' },
  resultLabel: { flex: 1, fontFamily: 'Inter_500Medium', fontSize: 13 },
  resultValue: { fontFamily: 'Inter_700Bold', fontSize: 14 },
});
