#!/bin/bash
set -e

echo "🚀 正在创建 WeeklyFlow AI 项目..."

# ── 基础目录 ──────────────────────────────────────────────
mkdir -p app/api/generate lib

# ════════════════════════════════════════════════════════════
# package.json
# ════════════════════════════════════════════════════════════
cat > package.json << 'EOF'
{
  "name": "weeklyflow-ai",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "next": "15.3.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "clsx": "^2.1.1",
    "tailwind-merge": "^2.5.4"
  },
  "devDependencies": {
    "@types/node": "^20",
    "@types/react": "^19",
    "@types/react-dom": "^19",
    "tailwindcss": "^3.4.1",
    "postcss": "^8",
    "autoprefixer": "^10",
    "typescript": "^5"
  }
}
EOF

# ════════════════════════════════════════════════════════════
# tsconfig.json
# ════════════════════════════════════════════════════════════
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2017",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": { "@/*": ["./*"] }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
EOF

# ════════════════════════════════════════════════════════════
# next.config.ts
# ════════════════════════════════════════════════════════════
cat > next.config.ts << 'EOF'
import type { NextConfig } from "next";
const nextConfig: NextConfig = {};
export default nextConfig;
EOF

# ════════════════════════════════════════════════════════════
# tailwind.config.ts
# ════════════════════════════════════════════════════════════
cat > tailwind.config.ts << 'EOF'
import type { Config } from "tailwindcss";
const config: Config = {
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        background: "hsl(var(--background))",
        foreground: "hsl(var(--foreground))",
        border: "hsl(var(--border))",
        muted: {
          DEFAULT: "hsl(var(--muted))",
          foreground: "hsl(var(--muted-foreground))",
        },
        destructive: {
          DEFAULT: "hsl(var(--destructive))",
        },
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
      },
    },
  },
  plugins: [],
};
export default config;
EOF

# ════════════════════════════════════════════════════════════
# postcss.config.mjs
# ════════════════════════════════════════════════════════════
cat > postcss.config.mjs << 'EOF'
const config = {
  plugins: { tailwindcss: {}, autoprefixer: {} },
};
export default config;
EOF

# ════════════════════════════════════════════════════════════
# app/globals.css
# ════════════════════════════════════════════════════════════
cat > app/globals.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 240 10% 3.9%;
    --muted: 240 4.8% 95.9%;
    --muted-foreground: 240 3.8% 46.1%;
    --border: 240 5.9% 90%;
    --destructive: 0 84.2% 60.2%;
    --radius: 0.625rem;
  }
  .dark {
    --background: 240 10% 3.9%;
    --foreground: 0 0% 98%;
    --muted: 240 3.7% 15.9%;
    --muted-foreground: 240 5% 64.9%;
    --border: 240 3.7% 15.9%;
    --destructive: 0 62.8% 30.6%;
  }
}

* { border-color: hsl(var(--border)); }
body {
  background: hsl(var(--background));
  color: hsl(var(--foreground));
}
EOF

# ════════════════════════════════════════════════════════════
# app/layout.tsx
# ════════════════════════════════════════════════════════════
cat > app/layout.tsx << 'EOF'
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
EOF

# ════════════════════════════════════════════════════════════
# lib/utils.ts
# ════════════════════════════════════════════════════════════
cat > lib/utils.ts << 'EOF'
import { type ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
EOF

# ════════════════════════════════════════════════════════════
# app/api/generate/route.ts
# ════════════════════════════════════════════════════════════
cat > app/api/generate/route.ts << 'EOF'
import { NextRequest, NextResponse } from "next/server";

const STYLE_PROMPTS: Record<string, string> = {
  internet: `你是一名拥有10年经验的互联网大厂技术 leader，擅长写字节/阿里风格的周报。
风格要求：
- 善用"对齐"、"闭环"、"推进"、"落地"、"赋能"等术语
- 结构清晰，用 ▌ 或【】做区块标题
- 每项工作要体现"价值"和"影响"
- 语气自信、数据化、有颗粒度`,

  formal: `你是一名拥有10年经验的500强企业职业经理人，擅长写严谨专业的工作总结。
风格要求：
- 用"一、二、三"或"（一）（二）"分条陈述
- 措辞正式、客观、准确
- 每项工作说明完成情况和结果
- 避免口语化表达`,

  minimal: `你是一名拥有10年经验的极简主义技术专家，用最少的文字表达最多的内容。
风格要求：
- 每条不超过15字
- 只用 - 列表，无多余修饰
- 删去所有形容词和连接词
- 数字和结果直接呈现`,
};

export async function POST(req: NextRequest) {
  try {
    const { rawText, style } = await req.json();

    if (!rawText?.trim()) {
      return NextResponse.json({ error: "内容不能为空" }, { status: 400 });
    }

    const stylePrompt = STYLE_PROMPTS[style] ?? STYLE_PROMPTS.internet;

    const res = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${process.env.GROQ_API_KEY}`,
      },
      body: JSON.stringify({
        model: "llama-3.3-70b-versatile",
        max_tokens: 1024,
        messages: [
          {
            role: "system",
            content: `${stylePrompt}

你的任务：将用户输入的工作流水账，整理成一份结构清晰的周报。
- 自动归纳分类，补充合理细节
- 保留所有关键数字和事实，不要捏造
- 直接输出周报正文，不要加任何前缀或说明`,
          },
          {
            role: "user",
            content: `以下是我本周的工作记录，请帮我整理成周报：\n\n${rawText}`,
          },
        ],
      }),
    });

    if (!res.ok) {
      const errBody = await res.json().catch(() => ({}));
      throw new Error(errBody?.error?.message ?? `Groq API 请求失败 (${res.status})`);
    }

    const data = await res.json();
    const text: string = data.choices?.[0]?.message?.content ?? "";
    return NextResponse.json({ result: text });
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : "生成失败，请稍后重试";
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}
EOF

# ════════════════════════════════════════════════════════════
# app/page.tsx
# ════════════════════════════════════════════════════════════
cat > app/page.tsx << 'EOF'
"use client";

import { useState, useCallback } from "react";
import { cn } from "@/lib/utils";

type Style = "internet" | "formal" | "minimal";

const STYLES: { id: Style; label: string; desc: string }[] = [
  { id: "internet", label: "互联网大厂风", desc: "对齐闭环，数据驱动" },
  { id: "formal",   label: "严谨专业风",   desc: "条分缕析，正式规范" },
  { id: "minimal",  label: "极简风",       desc: "少即是多，一击即中" },
];

export default function WeeklyFlowPage() {
  const [rawText, setRawText] = useState("");
  const [style, setStyle]     = useState<Style>("internet");
  const [result, setResult]   = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError]     = useState("");
  const [copied, setCopied]   = useState(false);

  const generate = useCallback(async () => {
    if (!rawText.trim() || loading) return;
    setLoading(true);
    setError("");
    setResult("");

    try {
      const res = await fetch("/api/generate", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ rawText, style }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error ?? "未知错误");
      setResult(data.result);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "生成失败");
    } finally {
      setLoading(false);
    }
  }, [rawText, style, loading]);

  const copyResult = () => {
    navigator.clipboard.writeText(result).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 1800);
    });
  };

  return (
    <div className="min-h-screen bg-background text-foreground">
      <header className="border-b px-6 py-4 flex items-center gap-3">
        <h1 className="text-base font-medium tracking-tight">WeeklyFlow AI</h1>
        <span className="text-sm text-muted-foreground">把流水账变成漂亮的周报</span>
      </header>

      <main className="flex h-[calc(100vh-57px)]">
        {/* 左：输入 */}
        <section className="flex-1 flex flex-col gap-4 p-6 min-w-0">
          <div className="flex items-center justify-between">
            <span className="text-[11px] font-medium tracking-widest uppercase text-muted-foreground">本周记录</span>
            <span className="text-[11px] text-muted-foreground">{rawText.length} 字</span>
          </div>
          <textarea
            className={cn(
              "flex-1 resize-none rounded-lg border bg-muted/40",
              "p-3.5 text-sm leading-relaxed placeholder:text-muted-foreground/50",
              "focus:outline-none focus:ring-1 focus:ring-violet-400 font-mono"
            )}
            placeholder={"随意写下这周做了什么……\n\n例如：\n周一开了三个需求评审，下午修了个登录 bug\n周二写了用户模块的单测，覆盖率从 40% 升到 76%\n周三和设计师对了新版首页的方案"}
            value={rawText}
            onChange={(e) => setRawText(e.target.value)}
          />
        </section>

        <div className="w-px bg-border self-stretch" />

        {/* 中：控制 */}
        <section className="w-52 flex flex-col gap-6 p-6 bg-muted/20">
          <div>
            <p className="text-[11px] font-medium tracking-widest uppercase text-muted-foreground mb-3">文案风格</p>
            <div className="flex flex-col gap-2">
              {STYLES.map((s) => (
                <button
                  key={s.id}
                  onClick={() => setStyle(s.id)}
                  className={cn(
                    "flex flex-col items-start gap-0.5 px-3 py-2.5 rounded-lg border text-left transition-all text-sm",
                    style === s.id
                      ? "border-violet-400 bg-background text-foreground font-medium"
                      : "border-border/60 text-muted-foreground hover:border-border hover:text-foreground"
                  )}
                >
                  <span>{s.label}</span>
                  <span className="text-[11px] text-muted-foreground font-normal">{s.desc}</span>
                </button>
              ))}
            </div>
          </div>

          <div className="mt-auto">
            <button
              onClick={generate}
              disabled={!rawText.trim() || loading}
              className={cn(
                "w-full py-2.5 rounded-lg text-sm font-medium transition-all",
                "bg-violet-500 text-white hover:bg-violet-600 active:scale-[0.98]",
                "disabled:opacity-40 disabled:cursor-not-allowed"
              )}
            >
              {loading ? (
                <span className="flex items-center justify-center gap-2">
                  <span className="flex gap-0.5">
                    {[0, 160, 320].map((d) => (
                      <span key={d} className="w-1 h-1 rounded-full bg-white/70 animate-bounce" style={{ animationDelay: `${d}ms` }} />
                    ))}
                  </span>
                  生成中
                </span>
              ) : "生成周报"}
            </button>
          </div>
        </section>

        <div className="w-px bg-border self-stretch" />

        {/* 右：结果 */}
        <section className="flex-1 flex flex-col gap-4 p-6 min-w-0">
          <div className="flex items-center justify-between">
            <span className="text-[11px] font-medium tracking-widest uppercase text-muted-foreground">生成结果</span>
            {result && (
              <button
                onClick={copyResult}
                className="text-[11px] text-muted-foreground hover:text-foreground border border-border/60 hover:border-border rounded-md px-2.5 py-1 transition-all"
              >
                {copied ? "已复制 ✓" : "复制"}
              </button>
            )}
          </div>

          {error && (
            <div className="text-sm text-red-600 bg-red-50 border border-red-200 rounded-lg px-3.5 py-2.5">
              {error}
            </div>
          )}

          <div className={cn(
            "flex-1 rounded-lg border bg-muted/40 p-3.5 overflow-y-auto",
            "text-sm leading-relaxed whitespace-pre-wrap",
            !result && "flex items-center justify-center"
          )}>
            {result || (
              <span className="text-muted-foreground/40 text-sm text-center">
                在左侧输入本周工作内容<br />选择风格后点击生成
              </span>
            )}
          </div>
        </section>
      </main>
    </div>
  );
}
EOF

# ════════════════════════════════════════════════════════════
# .env.local
# ════════════════════════════════════════════════════════════
if [ ! -f .env.local ]; then
  cat > .env.local << 'EOF'
GROQ_API_KEY=请把你的Key粘贴在这里
EOF
  echo "  ✅ 已创建 .env.local（记得填入你的 GROQ_API_KEY）"
else
  echo "  ⚠️  .env.local 已存在，跳过（请手动确认 GROQ_API_KEY 已填写）"
fi

# ════════════════════════════════════════════════════════════
# .gitignore
# ════════════════════════════════════════════════════════════
cat > .gitignore << 'EOF'
.env.local
.env*.local
node_modules/
.next/
EOF

# ── 安装依赖 ──────────────────────────────────────────────
echo ""
echo "📦 正在安装依赖（npm install）..."
npm install

echo ""
echo "✅ 项目初始化完成！"
echo ""
echo "下一步："
echo "  1. 编辑 .env.local，填入你的 GROQ_API_KEY"
echo "  2. 运行 npm run dev"
echo "  3. 打开 http://localhost:3000"
echo ""
