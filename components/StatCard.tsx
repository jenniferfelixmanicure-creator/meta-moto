import { Feather } from '@expo/vector-icons';
import React from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { useColors } from '@/hooks/useColors';

interface Props {
  icon: string;
  value: string;
  label: string;
  iconColor?: string;
  small?: boolean;
}

export function StatCard({ icon, value, label, iconColor, small }: Props) {
  const colors = useColors();
  const ic = iconColor ?? colors.primary;

  return (
    <View style={[styles.card, { backgroundColor: colors.card, borderColor: colors.border }]}>
      <View style={[styles.iconWrap, { backgroundColor: ic + '22' }]}>
        <Feather name={icon as any} size={small ? 14 : 18} color={ic} />
      </View>
      <Text style={[styles.value, { color: colors.foreground, fontSize: small ? 14 : 18 }]}>
        {value}
      </Text>
      <Text style={[styles.label, { color: colors.mutedForeground, fontSize: small ? 10 : 11 }]}>
        {label}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    flex: 1,
    alignItems: 'center',
    padding: 12,
    borderRadius: 12,
    borderWidth: 1,
    gap: 4,
  },
  iconWrap: {
    width: 32,
    height: 32,
    borderRadius: 16,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 2,
  },
  value: { fontFamily: 'Inter_700Bold', textAlign: 'center' },
  label: { fontFamily: 'Inter_400Regular', textAlign: 'center' },
});
