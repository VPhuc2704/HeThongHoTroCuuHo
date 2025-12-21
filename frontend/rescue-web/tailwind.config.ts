import type { Config } from 'tailwindcss'

export default <Config>{
  // Chỉ định các file cần quét class CSS
  content: [
    "./components/**/*.{js,vue,ts}",
    "./layouts/**/*.vue",
    "./pages/**/*.vue",
    "./plugins/**/*.{js,ts}",
    "./app.vue",
    "./error.vue",
  ],
  theme: {
    extend: {
      // ĐỊNH NGHĨA MÀU CHỦ ĐẠO (ĐỎ)
      colors: {
        primary: {
          DEFAULT: '#DC2626', // Đỏ đậm (Main)
          hover: '#B91C1C',   // Đỏ tối hơn (khi di chuột)
          light: '#FEE2E2',   // Đỏ nhạt (nền phụ)
        }
      }
    },
  },
  // Tắt reset mặc định để không xung đột với Element Plus (như đã bàn trước đó)
  corePlugins: {
    preflight: false,
  },
  plugins: [],
}