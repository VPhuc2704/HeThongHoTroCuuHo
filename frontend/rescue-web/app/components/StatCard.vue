<script setup lang="ts">
import { CaretTop, CaretBottom } from '@element-plus/icons-vue';
import type { Component } from 'vue';

interface Props {
  title: string;
  value: number;
  unit: string;
  icon: Component;
  color: 'red' | 'green' | 'blue';
  change: string;
  percent: number;
}
defineProps<Props>();

const colorMap = {
  red: { text: 'text-red-400', bg: 'bg-red-900', bar: 'bg-red-500' },
  green: { text: 'text-green-400', bg: 'bg-green-900', bar: 'bg-green-500' },
  blue: { text: 'text-blue-400', bg: 'bg-blue-900', bar: 'bg-blue-500' },
};
</script>

<template>
  <div class="bg-slate-800 p-4 rounded-xl border border-slate-700 shadow-lg flex flex-col justify-between hover:shadow-xl hover:shadow-slate-800/50 transition-all">
    <div>
      <div class="flex items-start justify-between mb-2">
        <p class="text-xs font-semibold text-slate-400 uppercase tracking-wide flex items-center gap-1">
          <el-icon :class="colorMap[color].text" class="text-base"><component :is="icon" /></el-icon>
          {{ title }}
        </p>
        <div class="w-8 h-8 rounded-full flex items-center justify-center relative" :class="colorMap[color].bg">
          <el-icon :class="colorMap[color].text" class="relative z-10 text-sm"><component :is="icon" /></el-icon>
        </div>
      </div>
      <div class="flex items-baseline gap-1">
        <span class="text-4xl font-extrabold text-white">{{ value }}</span>
        <span class="text-base font-medium text-slate-400">{{ unit }}</span>
      </div>
    </div>
    
    <div class="mt-4 pt-3 border-t border-slate-700/50">
      <div class="flex justify-between items-center text-xs mb-1">
        <span :class="change.startsWith('+') ? 'text-green-400' : 'text-red-400'" class="flex items-center font-medium">
          <el-icon class="mr-1"><component :is="change.startsWith('+') ? CaretTop : CaretBottom" /></el-icon>
          {{ change }}
        </span>
      </div>
      <div class="w-full bg-slate-700 h-1.5 rounded-full overflow-hidden">
        <div class="h-full rounded-full" :class="colorMap[color].bar" :style="{ width: percent + '%' }"></div>
      </div>
    </div>
  </div>
</template>