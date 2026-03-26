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
