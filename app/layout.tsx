import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "WeeklyFlow AI",
  description: "把流水账变成漂亮的周报",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="zh-CN">
      <body>{children}</body>
    </html>
  );
}
