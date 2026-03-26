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
