import { Feather } from '@expo/vector-icons';
import * as Haptics from 'expo-haptics';
import { router } from 'expo-router';
import React, { useEffect, useRef, useState } from 'react';
import {
  Animated,
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
import { ProgressBar } from '@/components/ProgressBar';
import { Goals, formatCurrency, useApp } from '@/contexts/AppContext';
import { useColors } from '@/hooks/useColors';

function GoalCard({
  label,
  icon,
  goal,
  earned,
  color,
}: {
  label: string;
  icon: string;
  goal: number;
  earned: number;
  color: string;
}) {
  const colors = useColors();
  const progress = Math.min(earned / Math.max(goal, 1), 1);
  const achieved = earned >= goal;
  const scaleAnim = useRef(new Animated.Value(1)).current;

  useEffect(() => {
    if (achieved) {
      Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
      Animated.sequence([
        Animated.spring(scaleAnim, { toValue: 1.04, useNativeDriver: true, speed: 40 }),
        Animated.spring(scaleAnim, { toValue: 1, useNativeDriver: true, speed: 40 }),
      ]).start();
    }
  }, [achieved]);

  return (
    <Animated.View
      style={[
        styles.goalCard,
        {
          backgroundColor: colors.card,
          borderColor: achieved ? color : colors.border,
          borderWidth: achieved ? 1.5 : 1,
          transform: [{ scale: scaleAnim }],
        },
      ]}
    >
      <View style={styles.goalTop}>
        <View style={[styles.goalIcon, { backgroundColor: color + '22' }]}>
          <Feather name={icon as any} size={18} color={color} />
        </View>
        <View style={{ flex: 1 }}>
          <Text style={[styles.goalLabel, { color: colors.mutedForeground }]}>{label}</Text>
          <Text style={[styles.goalTarget, { color: colors.foreground }]}>{formatCurrency(goal)}</Text>
        </View>
        {achieved ? (
          <View style={[styles.achievedBadge, { backgroundColor: color }]}>
            <Feather name="check" size={12} color="#000" />
            <Text style={styles.achievedText}>Meta!</Text>
          </View>
        ) : (
          <Text style={[styles.pct, { color: color }]}>{Math.round(progress * 100)}%</Text>
        )}
      </View>

      <ProgressBar progress={progress} color={color} backgroundColor={colors.muted} height={8} />

      <View style={styles.goalBottom}>
        <Text style={[styles.earned, { color: color }]}>{formatCurrency(earned)}</Text>
        <Text style={[styles.remain, { color: colors.mutedForeground }]}>
          {achieved
            ? `+${formatCurrency(earned - goal)} acima da meta`
            : `Faltam ${formatCurrency(goal - earned)}`}
        </Text>
      </View>

      {achieved && (
        <View style={[styles.motivBanner, { backgroundColor: color + '22' }]}>
          <Feather name="star" size={12} color={color} />
          <Text style={[styles.motivText, { color: color }]}>
            Excelente! Continue assim!
          </Text>
        </View>
      )}
    </Animated.View>
  );
}

export default function MetasScreen() {
  const colors = useColors();
  const insets = useSafeAreaInsets();
  const { goals, updateGoals, todayEarnings, weekEarnings, monthEarnings } = useApp();
  const [editing, setEditing] = useState(false);
  const [draft, setDraft] = useState<Goals>(goals);
  const topPad = Platform.OS === 'web' ? 67 : insets.top;

  const handleSave = async () => {
    const parsed: Goals = {
      daily: parseFloat(draft.daily.toString().replace(',', '.')) || goals.daily,
      weekly: parseFloat(draft.weekly.toString().replace(',', '.')) || goals.weekly,
      monthly: parseFloat(draft.monthly.toString().replace(',', '.')) || goals.monthly,
    };
    await updateGoals(parsed);
    Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    setEditing(false);
  };

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
          <Text style={[styles.title, { color: colors.foreground }]}>Metas</Text>
          <TouchableOpacity
            onPress={() => { setDraft(goals); setEditing(true); }}
            style={[styles.editBtn, { backgroundColor: colors.card, borderColor: colors.border }]}
          >
            <Feather name="edit-2" size={16} color={colors.primary} />
            <Text style={[styles.editText, { color: colors.primary }]}>Editar</Text>
          </TouchableOpacity>
        </View>

        <GoalCard
          label="META DIARIA"
          icon="sun"
          goal={goals.daily}
          earned={todayEarnings}
          color="#22C55E"
        />
        <GoalCard
          label="META SEMANAL"
          icon="calendar"
          goal={goals.weekly}
          earned={weekEarnings}
          color="#3B82F6"
        />
        <GoalCard
          label="META MENSAL"
          icon="trending-up"
          goal={goals.monthly}
          earned={monthEarnings}
          color="#A855F7"
        />

        <TouchableOpacity
          style={[styles.calcCard, { backgroundColor: colors.card, borderColor: colors.border }]}
          onPress={() => router.push('/calculadora')}
        >
          <View style={[styles.calcIcon, { backgroundColor: colors.primary + '22' }]}>
            <Feather name="hash" size={22} color={colors.primary} />
          </View>
          <View style={{ flex: 1 }}>
            <Text style={[styles.calcTitle, { color: colors.foreground }]}>Calculadora de Objetivos</Text>
            <Text style={[styles.calcSub, { color: colors.mutedForeground }]}>
              Calcule quanto precisa ganhar para atingir um objetivo
            </Text>
          </View>
          <Feather name="chevron-right" size={18} color={colors.mutedForeground} />
        </TouchableOpacity>
      </ScrollView>

      <Modal visible={editing} animationType="slide" presentationStyle="pageSheet" onRequestClose={() => setEditing(false)}>
        <View style={[styles.modal, { backgroundColor: colors.background }]}>
          <View style={styles.modalHeader}>
            <Text style={[styles.modalTitle, { color: colors.foreground }]}>Editar Metas</Text>
            <TouchableOpacity onPress={() => setEditing(false)}>
              <Feather name="x" size={22} color={colors.mutedForeground} />
            </TouchableOpacity>
          </View>

          {[
            { key: 'daily' as keyof Goals, label: 'Meta Diaria', icon: 'sun', color: '#22C55E' },
            { key: 'weekly' as keyof Goals, label: 'Meta Semanal', icon: 'calendar', color: '#3B82F6' },
            { key: 'monthly' as keyof Goals, label: 'Meta Mensal', icon: 'trending-up', color: '#A855F7' },
          ].map(({ key, label, icon, color }) => (
            <View key={key} style={styles.fieldGroup}>
              <View style={styles.fieldLabel}>
                <Feather name={icon as any} size={14} color={color} />
                <Text style={[styles.fieldLabelText, { color: colors.foreground }]}>{label}</Text>
              </View>
              <View style={[styles.inputRow, { backgroundColor: colors.muted, borderColor: colors.border }]}>
                <Text style={[styles.currency, { color: colors.mutedForeground }]}>R$</Text>
                <TextInput
                  style={[styles.input, { color: colors.foreground }]}
                  value={String(draft[key])}
                  onChangeText={v => setDraft(d => ({ ...d, [key]: v }))}
                  keyboardType="decimal-pad"
                  placeholderTextColor={colors.mutedForeground}
                />
              </View>
            </View>
          ))}

          <TouchableOpacity
            style={[styles.saveBtn, { backgroundColor: colors.primary }]}
            onPress={handleSave}
          >
            <Text style={styles.saveBtnText}>Salvar Metas</Text>
          </TouchableOpacity>
        </View>
      </Modal>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  scroll: { paddingHorizontal: 16, gap: 12 },
  headerRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  title: { fontFamily: 'Inter_700Bold', fontSize: 26 },
  editBtn: {
    flexDirection: 'row', alignItems: 'center', gap: 6,
    paddingHorizontal: 12, paddingVertical: 8, borderRadius: 10, borderWidth: 1,
  },
  editText: { fontFamily: 'Inter_500Medium', fontSize: 13 },
  goalCard: { borderRadius: 16, padding: 16, gap: 12, borderWidth: 1 },
  goalTop: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  goalIcon: { width: 40, height: 40, borderRadius: 20, alignItems: 'center', justifyContent: 'center' },
  goalLabel: { fontFamily: 'Inter_500Medium', fontSize: 11, letterSpacing: 0.5 },
  goalTarget: { fontFamily: 'Inter_700Bold', fontSize: 20, marginTop: 2 },
  achievedBadge: {
    flexDirection: 'row', alignItems: 'center', gap: 4,
    paddingHorizontal: 8, paddingVertical: 4, borderRadius: 20,
  },
  achievedText: { fontFamily: 'Inter_700Bold', fontSize: 11, color: '#000' },
  pct: { fontFamily: 'Inter_700Bold', fontSize: 18 },
  goalBottom: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  earned: { fontFamily: 'Inter_700Bold', fontSize: 16 },
  remain: { fontFamily: 'Inter_400Regular', fontSize: 12 },
  motivBanner: {
    flexDirection: 'row', alignItems: 'center', gap: 6,
    padding: 8, borderRadius: 8,
  },
  motivText: { fontFamily: 'Inter_600SemiBold', fontSize: 12 },
  calcCard: {
    flexDirection: 'row', alignItems: 'center', gap: 12,
    padding: 16, borderRadius: 16, borderWidth: 1, marginTop: 4,
  },
  calcIcon: { width: 44, height: 44, borderRadius: 22, alignItems: 'center', justifyContent: 'center' },
  calcTitle: { fontFamily: 'Inter_600SemiBold', fontSize: 14 },
  calcSub: { fontFamily: 'Inter_400Regular', fontSize: 12, marginTop: 2 },
  modal: { flex: 1, padding: 20, gap: 16 },
  modalHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  modalTitle: { fontFamily: 'Inter_700Bold', fontSize: 20 },
  fieldGroup: { gap: 8 },
  fieldLabel: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  fieldLabelText: { fontFamily: 'Inter_600SemiBold', fontSize: 14 },
  inputRow: {
    flexDirection: 'row', alignItems: 'center', borderRadius: 12,
    borderWidth: 1, paddingHorizontal: 14, paddingVertical: 12, gap: 6,
  },
  currency: { fontFamily: 'Inter_600SemiBold', fontSize: 16 },
  input: { flex: 1, fontFamily: 'Inter_600SemiBold', fontSize: 18, padding: 0 },
  saveBtn: { borderRadius: 14, paddingVertical: 16, alignItems: 'center', marginTop: 8 },
  saveBtnText: { fontFamily: 'Inter_700Bold', fontSize: 16, color: '#000' },
});
