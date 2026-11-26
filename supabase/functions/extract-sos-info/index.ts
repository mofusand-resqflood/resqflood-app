import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const VALID_HELP_TYPES = [
  "Evacuation",
  "Walking Support",
  "Water Inside House",
] as const;

type HelpType = (typeof VALID_HELP_TYPES)[number];

interface ExtractedSosInfo {
  people_count: number;
  help_type: HelpType;
  summary: string;
}

const MODELS = ["gemini-3.8-flash", "gemini-3.5-flash-lite"];

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { message } = await req.json();

    if (!message || typeof message !== "string" || !message.trim()) {
      return new Response(
        JSON.stringify({ error: "Message text is required." }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const geminiApiKey = Deno.env.get("GEMINI_API_KEY");
    if (!geminiApiKey) {
      return new Response(
        JSON.stringify({ error: "GEMINI_API_KEY secret is not configured." }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const prompt = `You are an emergency flood triage assistant for ResQFlood in Malaysia.
Analyze the resident's emergency message (which may be in Bahasa Melayu, English, or Manglish) and extract structured SOS details.

Return ONLY a valid JSON object with this exact schema:
{
  "people_count": <integer >= 1>,
  "help_type": "<one of: Evacuation | Walking Support | Water Inside House>",
  "summary": "<concise 1-sentence rescue summary in the same language as the input>"
}

Classification rules for "help_type":
- "Evacuation": People are trapped, stranded on roof/upper floor, rising fast water, boat/rescue transport needed, or urgent evacuation requested ("tolong selamatkan", "terperangkap", "pindah", "bot", "stuck", "trapped", "evacuate").
- "Walking Support": Elderly, disabled (OKU), pregnant, injured, sick, or young children who need physical assistance walking/moving out ("warga emas", "OKU", "tak boleh jalan", "sakit", "wheelchair", "elderly", "injured", "cannot walk").
- "Water Inside House": Floodwater has entered the house/ground floor, property flooding, or rising water indoors without immediate entrapment ("air masuk rumah", "banjir dalam rumah", "paras lutut", "water inside house", "flooded house").
- If unclear, default to "Evacuation".

Rules for "people_count":
- Count total people mentioned (e.g., "saya dan 3 anak" = 4; "family of 5" = 5; "2 dewasa 1 warga emas" = 3).
- If no number is mentioned, default to 1.

Resident message:
"""${message.trim()}"""`;

    let response: Response | null = null;
    let lastErrorText = "";

    for (const model of MODELS) {
      response = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${geminiApiKey}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            contents: [{ parts: [{ text: prompt }] }],
            generationConfig: {
              temperature: 0.1,
              responseMimeType: "application/json",
            },
          }),
        },
      );

      if (response.ok) break;
      lastErrorText = await response.text();
    }

    if (!response || !response.ok) {
      return new Response(
        JSON.stringify({
          error: "Gemini API request failed",
          details: lastErrorText,
        }),
        {
          status: 502,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const data = await response.json();
    const rawText =
      data?.candidates?.[0]?.content?.parts?.[0]?.text?.trim() ?? "";

    const cleanedJson = rawText
      .replace(/^```json\s*/i, "")
      .replace(/^```\s*/i, "")
      .replace(/\s*```$/i, "")
      .trim();

    const parsed = JSON.parse(cleanedJson);

    const peopleCount =
      typeof parsed.people_count === "number" && parsed.people_count >= 1
        ? Math.round(parsed.people_count)
        : 1;

    const helpType: HelpType = VALID_HELP_TYPES.includes(parsed.help_type)
      ? parsed.help_type
      : "Evacuation";

    const summary =
      typeof parsed.summary === "string" && parsed.summary.trim().length > 0
        ? parsed.summary.trim()
        : message.trim();

    const result: ExtractedSosInfo = {
      people_count: peopleCount,
      help_type: helpType,
      summary,
    };

    return new Response(JSON.stringify(result), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(
      JSON.stringify({
        error: "Failed to extract SOS information",
        details: err instanceof Error ? err.message : String(err),
      }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});