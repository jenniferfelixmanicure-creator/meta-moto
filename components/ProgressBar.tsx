import React, { useEffect, useRef } from 'react';
import { Animated, StyleSheet, View } from 'react-native';

interface Props {
  progress: number;
  color?: string;
  backgroundColor?: string;
  height?: number;
  animated?: boolean;
}

export function ProgressBar({
  progress,
  color = '#22C55E',
  backgroundColor = '#2A2A2A',
  height = 12,
  animated = true,
}: Props) {
  const clamp = Math.min(Math.max(progress, 0), 1);
  const widthAnim = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    if (animated) {
      Animated.timing(widthAnim, {
        toValue: clamp,
        duration: 800,
        useNativeDriver: false,
      }).start();
    } else {
      widthAnim.setValue(clamp);
    }
  }, [clamp, animated]);

  const barColor = clamp >= 1 ? '#22C55E' : color;

  return (
    <View style={[styles.track, { backgroundColor, height, borderRadius: height / 2 }]}>
      <Animated.View
        style={[
          styles.bar,
          {
            height,
            borderRadius: height / 2,
            backgroundColor: barColor,
            width: widthAnim.interpolate({
              inputRange: [0, 1],
              outputRange: ['0%', '100%'],
            }),
          },
        ]}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  track: { width: '100%', overflow: 'hidden' },
  bar: { position: 'absolute', left: 0, top: 0 },
});
