# Which GDPR-compliant, EU-sovereign providers can serve the software factory's model calls?

## Answer

None of the EU services checked here serves Jev itself: TypeSafe hosts it only in the US, and OpenRouter's EU routing does not cover it, but Berget AI in Sweden serves the same `/v1/systemone` API with open decision models (Laya, Clef-flash, Qwen3.5-2B) at €0.042 per million input tokens. For the code reviewer, Scaleway in Paris serves strong open coding models (Qwen3.5-397B, GLM-5.3, DeepSeek V4.1 Flash) as a built-in OpenCode provider, with zero data retention by default. Anthropic has no EU inference option, so Claude stays in the EU only through Amazon Bedrock's `eu.` inference profiles or Vertex AI's EU multi-region; US cloud companies run both, and both bill per token instead of through the Team plan.

## Findings

Live APIs and price lists were checked on 2026-10-28. Prices are per million tokens, written as "input / output", in the currency the source uses. Every table cell comes from a bullet below it.

### 1. Jev, or a model that does the same job

Jev answers typed questions (yes/no, choice, score) and gives a probability for each answer. There are two kinds of EU replacement. The first kind speaks the same API as Jev (`/v1/systemone`). The second kind is a normal language model whose API returns token log-probabilities (`logprobs`, `top_logprobs`), so a one-token answer such as "yes" or "B" comes with a probability. For the second kind, the model must not write reasoning text before the answer token.

| Option | Headquarters | Data centers | Probabilities | Price per million tokens |
| --- | --- | --- | --- | --- |
| TypeSafe Jev (today's plan) | TypeSafe AI, Inc., San Francisco, USA | USA | Built in, Jev API | $0.042 input, output free |
| Berget AI `/v1/systemone` | Berget AI AB, Sweden | Sweden (EEA) | Built in, same API as Jev; Laya, Clef-flash, Qwen3.5-2B, all "preview" | €0.042 input, output free |
| Cortecs `/v1/systemone` (beta router) | Cortecs GmbH, Vienna, Austria | The chosen provider's; Berget when `eu_native` is on | Built in, same request format as Jev | €0.042 via Berget, plus 5% fee on top-ups |
| Laya or Clef on your own servers | Your team | Your servers | Built in, `/v1/systemone` | Hardware only |
| IONOS AI Model Hub | IONOS Cloud GmbH, Germany | Germany | `logprobs` and `top_logprobs` (0–20); JSON schema | Qwen3.5-9B €0.10 / €0.15 |
| Mistral, EU host | Mistral AI, Paris, France | EU and EFTA countries | `logprobs` and `top_logprobs`; JSON schema | Ministral 3 3B $0.10 / $0.10, plus 10% on the EU host |
| Scaleway | Scaleway SAS, Paris, France | Paris | `logprobs` only, no `top_logprobs`; structured output | gpt-oss-120b €0.15 / €0.60 |
| OVHcloud AI Endpoints | OVH SAS, Roubaix, France | Gravelines, France | Not documented; JSON schema | qwen-3-5-9b 0.10 / 0.15 (currency not given) |
| STACKIT AI Model Serving | Schwarz Digits Cloud GmbH & Co. KG, Bad Friedrichshall, Germany | Germany (EU01) | Not documented | gpt-oss-20b €0.15 / €0.25 |
| vLLM or Ollama on your own servers | Your team | Your servers | vLLM: yes, in its OpenAI API; Ollama: only in its own API | Hardware only |

#### Jev and TypeSafe

- TypeSafe AI, Inc. gives its address as 255 California St, Suite 1300, San Francisco, and its terms use Delaware law and Delaware courts (terms last updated Sep 19, 2026). The terms do not name the state of incorporation. Source: https://typesafe.ai/legal/terms
- TypeSafe's privacy policy says "The Services are hosted in the United States", and that users in the EEA and UK transfer their data to the US (last updated Nov 19, 2025). Source: https://typesafe.ai/legal/privacy-policy
- The same privacy policy says TypeSafe will not train or fine-tune any model on prompts or other input. Source: https://typesafe.ai/legal/privacy-policy
- TypeSafe has a DPA (dated Apr 24, 2026). TypeSafe is the processor, EU transfers use the Standard Contractual Clauses (Module 2, and Module 3 when the customer is itself a processor), and UK transfers use the UK Addendum. Data is kept "as long as necessary", and no processing location is named. Source: https://typesafe.ai/legal/data-processing
- TypeSafe offers zero data retention (ZDR) only to enterprise customers, through a support request. Source: https://docs.typesafe.ai/legal.md
- The Jev API has one base URL, `https://api.typesafe.ai`, and no regional (EU) base URL. Its question types are `noul` (yes/no as a probability), `choice` (1–255 options) and `score` (1–10 levels). Source: https://docs.typesafe.ai/api/system-one.md
- `jev-1.14.0` is available from Oct 14, 2026, and costs $0.042 per million input tokens, with free output. Source: https://docs.typesafe.ai/models.md
- TypeSafe's list of sub-processors, which would name its cloud and region, needs JavaScript, and I could not read it. Not verified. Source: https://trust.typesafe.ai/subprocessors

#### The innFactory page

- The innFactory page is an information and consulting page by innFactory AI Consulting GmbH in Rosenheim. It does not host or resell Jev. It says Jev is "available exclusively as a hosted API" and "No EU region is documented" (page updated Oct 9, 2026). Source: https://innfactory.ai/en/ai-models/typesafe-jev/
- The page shows a "GDPR Hosting Available" badge, but nothing on the page backs it: the same page says that using Jev means a transfer of data to the US. Source: https://innfactory.ai/en/ai-models/typesafe-jev/

#### OpenRouter

- OpenRouter has one provider for `typesafe/jev-1.14` and `typesafe/jev-1.13`: TypeSafe itself, at $0.042 per million input tokens and $0 output. Source: https://openrouter.ai/api/v1/models/typesafe/jev-1.14/endpoints
- OpenRouter's provider list gives no headquarters and no data centers for TypeSafe. Source: https://openrouter.ai/api/v1/providers
- OpenRouter lists both Jev endpoints as zero data retention endpoints. Source: https://openrouter.ai/api/v1/endpoints/zdr
- OpenRouter's EU in-region routing (`eu.openrouter.ai`) needs the Business or Enterprise plan. It sends requests only to provider endpoints in Europe (EU/EEA, UK and Switzerland), and it returns an error when no such endpoint exists. Source: https://openrouter.ai/docs/guides/features/in-region-routing.md
- Even with EU routing, OpenRouter may store or process account, billing and other operational records in the US. Source: https://openrouter.ai/docs/guides/features/sovereign-ai.md
- EU routing does not cover Jev. The EU model list has 69 models and no TypeSafe model, and `typesafe/jev-1.14` has no endpoint on the EU host. Source: https://eu.openrouter.ai/api/v1/models

#### EU services that speak the Jev API

- Berget AI documents `POST https://api.berget.ai/v1/systemone/` as "Compatible with the TypeSafe Jev `/v1/systemone` API". The TypeSafe SDK works after you change the base URL and set a model. Berget does not serve `jev-latest`, which returns 404. Source: https://api.berget.ai/openapi.json
- Berget's endpoint has the same limits as Jev: 1–64 questions per request, 2–255 choice options and 2–10 score levels. Source: https://api.berget.ai/openapi.json
- Berget's model list has three "system-one" models: `Qwen/Qwen3.5-2B`, `convaiinnovations/laya` and `Cloudflare/clef-flash` (9B). Each costs €0.042 per million input tokens with free output, and all three are marked "preview". Source: https://api.berget.ai/v1/models
- Berget's home page says its data centres are in Sweden and that it works under Swedish law. Source: https://berget.ai
- Berget AI AB is a Swedish company. Its DPA (updated 2026-10-22) says all its data centres are in the EEA, it keeps no prompts or outputs after a call, it does not train on serverless inference data, and it does not move personal data out of the EEA without written instruction. Source: https://berget.ai/en/dpa
- Berget's DPA lists four sub-processors: AI Iron AB (GPU servers), Acebit AB (network and servers), Obenet AB (colocation) and Stripe Payments Europe (card payments). Source: https://berget.ai/en/dpa
- The planned `hyper-jev` client accepts `provider: "typesafe"` with its own `apiKey` and a full `baseUrl`, so it can call Berget's endpoint without code changes. I did not test this. Source: https://github.com/disler/ten-levels-of-jev/blob/HEAD/.claude/skills/hyper-jev/templates/starter/src/core/client.ts
- Cortecs GmbH in Vienna runs an EU model router. It charges a flat 5% fee on top-ups, bills tokens at the providers' own prices, and links a DPA. Source: https://cortecs.ai
- Cortecs has a beta Decisions API with `POST https://api.cortecs.ai/v1/systemone` in the same request format as Jev: up to 128 questions, up to 255 choice options and up to 10 score levels. Source: https://docs.cortecs.ai/api/decisions.md
- Cortecs serves three Decision models: `clef-flash` and `laya` through Berget at €0.042 per million input tokens, and `clef` (27B) through a provider called "sference" at €0.22. With `eu_native=true`, only the two Berget models remain. Source: https://api.cortecs.ai/v1/models?tag=Decision
- Cortecs's `eu_native: true` setting uses only providers that are based and regulated in the EU. It is off by default; when it is off, companies outside the EU, such as Microsoft, Google or AWS, may process the data. Source: https://docs.cortecs.ai/security-and-compliance/sovereign-cloud.md

#### Open decision models you can run yourself

- Clef is Cloudflare's 27B decision model under the Apache-2.0 license, built on Qwen3.8-27B with a small decision head. Its model card says the API is "fully compatible with Jev and SystemOne". Source: https://huggingface.co/Cloudflare/clef
- Clef runs with `vllm serve "Cloudflare/clef"` (OpenAI chat API) or with SGLang, which serves `/v1/systemone`. The card names only one test setup, a single H200 GPU. Source: https://huggingface.co/Cloudflare/clef
- In Cloudflare's own test, Clef's median latency was 209 ms and Jev's was 524 ms. Jev scored higher on several tests, for example GPQA Diamond (78.3 against 48.0) and MMLU-Pro (82.7 against 65.9). These are vendor numbers. Source: https://huggingface.co/Cloudflare/clef
- Laya by Convai Innovations is a small decision model under Apache-2.0 (about 421M parameters in English, 322M in the multilingual version). `laya-serve` serves `POST /v1/systemone` and runs on CPU (193–464 ms per request) or GPU (33–40 ms per question on a T4). Source: https://huggingface.co/convaiinnovations/laya
- Laya's authors say the base checkpoints answer typed decisions near chance without fine-tuning (0.362 for English) and are over-confident, so they advise tuning the calibration on your own data. Source: https://huggingface.co/convaiinnovations/laya

#### EU providers with token log-probabilities

- IONOS's chat API documents `logprobs` (true or false) and `top_logprobs` (0–20), and `response_format` with `json_object` and `json_schema`. Which formats work depends on the model. Source: https://docs.ionos.com/cloud/api-reference/ai/ai-model-hub/chat-completions/create-chat-completion.md
- IONOS runs all AI Model Hub inference in its data centers in Germany. Prompts and outputs are never logged, never written to storage, never used for training, and never shared with the model developers. Source: https://docs.ionos.com/cloud/ai/ai-model-hub/governance-and-compliance/data-handling.md
- IONOS uses no third-party sub-processors for AI Model Hub, and only IONOS staff in the EU can access its operational data. Source: https://docs.ionos.com/cloud/ai/ai-model-hub/governance-and-compliance/data-handling.md
- The IONOS DPA ("Datenschutzpaket") is part of the contract with IONOS Cloud GmbH (Germany) and needs no separate signature. Its data centers have ISO 27001, and AI Model Hub is in the scope of BSI C5. Source: https://docs.ionos.com/cloud/ai/ai-model-hub/governance-and-compliance/data-handling.md
- IONOS prices (price list v2026-10-22): Qwen3.5-9B €0.10 / €0.15, Mistral Small 24B €0.10 / €0.30, gpt-oss-120b €0.15 / €0.65, Llama 3.3 70B €0.65 / €0.65, Qwen3.8-27B €0.40 / €2.70. Source: https://docs.ionos.com/cloud/support/general-information/price-list/ionos-cloud-eur-en.md
- Mistral's chat API lists `logprobs`, `top_logprobs`, `prompt_logprobs` and `response_format` with a JSON schema mode. Source: https://docs.mistral.ai/api/
- Mistral's default host `api.mistral.ai` makes no promise about where inference runs. The EU host `api.eu.mistral.ai` keeps inference in "multiple data centers in EU and EFTA countries" for 1.1 times the list price. Account and billing data may still be handled outside the EU, and the models on offer differ by region. Source: https://docs.mistral.ai/inference/regional-inference.md
- Mistral AI is a French company at 15 rue des Halles, Paris. Its DPA (effective July 27, 2026) lets Mistral train on customer data "unless Customer is or has opted-out of training". Source: https://legal.mistral.ai/terms/data-processing-addendum
- Mistral's help center says pay-as-you-go customers can opt out of training at any time in the admin panel (Privacy, "Anonymous improvement data"). It does not say whether training is on by default for paid API use (article dated September 3, 2026). Source: https://help.mistral.ai/en/articles/455207-can-i-opt-out-of-my-input-or-output-data-being-used-for-training
- Mistral offers ZDR on paid plans, on request, for stateless endpoints such as `/v1/chat/completions`. It does not cover Agents, Batch, Files or Labs models. Source: https://docs.mistral.ai/admin/monitor-comply/zero-data-retention.md
- Mistral's small models cost (USD): Ministral 3 3B $0.10 / $0.10, Ministral 3 8B $0.15 / $0.15, Ministral 3 14B $0.20 / $0.20, Mistral Small 4 $0.15 / $0.60. Source: https://docs.mistral.ai/inference/pricing.md
- Scaleway documents `logprobs` as supported and `top_logprobs` as not supported (page checked by Scaleway on 2026-04-24). So a reply shows the chosen token's probability, but not the other options. Source: https://github.com/scaleway/docs-content/blob/main/pages/generative-apis/reference-content/openai-compatibility.mdx
- Scaleway marks its current Qwen models as supporting structured output, and Qwen3.6-35B-A3B accepts the reasoning effort `none`, so it can answer without reasoning text first (page checked 2026-08-14). Source: https://github.com/scaleway/docs-content/blob/main/pages/generative-apis/reference-content/supported-models.mdx
- Scaleway's registered office is at 8 rue de la Ville l'Evêque, 75008 Paris. Source: https://github.com/scaleway/docs-content/blob/main/pages/generative-apis/reference-content/data-privacy.mdx
- All Scaleway serverless models run in one data center in Paris, run by OPCORE. Source: https://github.com/scaleway/docs-content/blob/main/pages/generative-apis/faq.mdx
- Scaleway applies zero data retention by default. It keeps full requests only after rare errors such as HTTP 500, for up to two weeks. Inputs and outputs are not used for training and are not shared with the model makers (page checked 2025-10-03). Source: https://github.com/scaleway/docs-content/blob/main/pages/generative-apis/reference-content/data-privacy.mdx
- Scaleway states that, as a European company, its AI services are "not subject to extraterritorial laws such as the American Cloud Act". Source: https://github.com/scaleway/docs-content/blob/main/pages/generative-apis/reference-content/data-privacy.mdx
- Scaleway's AI terms (version of 7 April 2026) say Scaleway "does not retain any requests or generated Content after processing". Source: https://www-uploads.scaleway.com/Specific_Conditions_AI_Services_275907180f.pdf
- Scaleway offers a Data Processing Agreement among its standard contracts. Source: https://github.com/scaleway/docs-content/blob/main/pages/account/support/download-scaleway-contracts.mdx
- Scaleway prices (fr-par): gpt-oss-120b €0.15 / €0.60, Mistral Small 3.2 24B €0.15 / €0.35, Gemma 4 26B €0.25 / €0.50 (preview), Qwen3.6-35B-A3B €0.25 / €1.50. Source: https://api.scaleway.com/product-catalog/v2alpha1/public-catalog/products?page_size=1000&product_types=generative_apis
- OVHcloud's model catalog lists only `temperature`, `stop`, `top_p` and `seed` as sampling parameters, so logprobs are not documented. Its response formats include `json_schema`. Source: https://catalog.endpoints.ai.ovh.net/rest/v1/models_v2
- OVHcloud's catalog lists only `low`, `medium` and `high` reasoning efforts for gpt-oss-120b, with no `none`. Source: https://catalog.endpoints.ai.ovh.net/rest/v1/models_v2
- OVHcloud catalog prices (the API does not give a currency): qwen-3-5-9b 0.10 / 0.15, gpt-oss-20b 0.04 / 0.15, gpt-oss-120b 0.08 / 0.40. Source: https://catalog.endpoints.ai.ovh.net/rest/v1/models_v2
- OVHcloud runs AI Endpoints in Gravelines, France, and says "Data is not stored or shared during or after model use" (page updated 2026-02-03). It makes no clear statement about training. Source: https://docs.ovhcloud.com/en/guides/public-cloud/ai-machine-learning/ai-endpoints-capabilities.md
- OVH SAS has its registered office at 2 rue Kellermann, 59100 Roubaix, France. Source: https://www.ovhcloud.com/en-gb/terms-and-conditions/
- OVHcloud's Public Cloud terms (version of 26 August 2026) have an AI Endpoints appendix (Appendix 10) and refer to a "Data Processing Agreement" annex. Source: https://contract.eu.ovhapis.com/1.0/pdf/Conditions_particulieres_OVH_Stack-gb.pdf
- STACKIT's docs list no `logprobs` parameter. Its "use the models" page shows only `model`, `messages`, `max_completion_tokens` and `temperature` (updated Mar 11, 2026). Source: https://docs.stackit.cloud/products/data-and-ai/ai-model-serving/how-tos/use-the-models/
- STACKIT says "Your data and queries are neither stored nor used to train models", and all its shared models run in region EU01. Source: https://stackit.com/en/products/data-ai/stackit-ai-model-serving
- STACKIT prices (EU01): gpt-oss-20b €0.15 / €0.25, gpt-oss-120b €0.45 / €0.65, Qwen3.8 27B €0.45 / €0.65, Gemma 4 31B €0.45 / €0.65. The page footer names Schwarz Digits Cloud GmbH & Co. KG, Am Campus 1, 74177 Bad Friedrichshall. Source: https://stackit.com/en/products/data-ai/stackit-ai-model-serving
- STACKIT hosts all regions only in Germany (eu01) and Austria (eu02) (updated Feb 27, 2026). Source: https://docs.stackit.cloud/platform/regions/
- STACKIT's FAQ says "We do not store any customer data from the requests" and "We do not train any models using your data" (updated Nov 24, 2025). Source: https://docs.stackit.cloud/products/data-and-ai/ai-model-serving/faq/
- Berget's chat API also accepts `logprobs`. Source: https://api.berget.ai/openapi.json

#### Running a model yourself

- vLLM's chat API supports `logprobs` and `top_logprobs`. It also has an extra `logprob_token_ids` field that returns log-probabilities for a fixed list of label tokens and "Requires `logprobs=True`". Source: https://docs.vllm.ai/en/latest/serving/online_serving/openai_compatible_server/
- vLLM can force the answer to be one item from a list with `structured_outputs: {"choice": [...]}`. The older `guided_choice` field was removed in v0.12.0. Source: https://docs.vllm.ai/en/latest/features/structured_outputs.html
- By default, vLLM returns raw log-probabilities, taken "before applying any logit processors", and at most 20 per position (`--max-logprobs`). Source: https://docs.vllm.ai/en/latest/configuration/engine_args/
- Ollama's own chat API (`/api/chat`) has `logprobs` and `top_logprobs` fields. Source: https://docs.ollama.com/api/chat.md
- Ollama's OpenAI-compatible API marks logprobs as not supported. Source: https://docs.ollama.com/api/openai-compatibility.md

### 2. A non-Claude code reviewer

| Provider | Headquarters | Data centers | Coding fit | Price per million tokens | OpenCode |
| --- | --- | --- | --- | --- | --- |
| Scaleway | Paris, France | Paris | Qwen3.5-397B (GA), GLM-5.3, DeepSeek V4.1 Flash and Mistral Medium 3.5 (preview); small: gpt-oss-120b, Qwen3.6-35B-A3B (GA) | Qwen3.5-397B €0.60 / €3.60; GLM-5.3 €1.80 / €5.50; DeepSeek V4.1 Flash €0.60 / €1.80; gpt-oss-120b €0.15 / €0.60 | Built in |
| Mistral, EU host | Paris, France | EU and EFTA countries | Mistral Medium 3.5 (replaces Devstral 2), GLM 5.3, Mistral Large 4 (preview) | Medium 3.5 $1.50 / $7.50; GLM 5.3 $1.40 / $4.40; plus 10% on the EU host | In OpenCode's model list; the EU host needs a `baseURL` change (not tested) |
| OVHcloud | Roubaix, France | Gravelines, France | Qwen3.5-397B, gpt-oss-120b, Qwen3.6 27B, Qwen3.8 27B | 0.60 / 3.60; 0.08 / 0.40; 0.40 / 2.70 (currency not given) | Built in |
| IONOS | Germany | Germany | Qwen3-Coder-Next 80B, Qwen3.5-397B, gpt-oss-120b | €0.15 / €0.80; €0.60 / €3.60; €0.15 / €0.65 | Not built in; add as an OpenAI-compatible provider |
| STACKIT | Bad Friedrichshall, Germany | Germany (EU01) | gpt-oss-120b, Qwen3.8 27B, Qwen3-VL 235B; no coding model | €0.45 / €0.65; €0.45 / €0.65; €1.50 / €1.75 | Built in |
| Berget AI | Sweden | Sweden (EEA) | Kimi-K3, GLM-5.3-Flash, Qwen3.8-27B | €3 / €15; €0.25 / €0.50; €0.40 / €3 | In OpenCode's model list |
| Cortecs (router) | Vienna, Austria | The chosen provider's | GLM-5.3, DeepSeek V4.1 Flash, Qwen3.5-397B, Kimi K3 and more | GLM-5.3 from €0.459 / €1.836, plus 5% fee | Built in |

- OpenCode supports providers through the AI SDK and Models.dev. Any OpenAI-compatible API can be added with the `@ai-sdk/openai-compatible` package and a `baseURL` (page updated Oct 27, 2026). Source: https://opencode.ai/docs/providers/
- OpenCode's provider docs list Scaleway, OVHcloud AI Endpoints, STACKIT, Cortecs and Nebius Token Factory as providers with setup steps. They do not list IONOS or Mistral. Source: https://opencode.ai/docs/providers/
- Models.dev, the model list OpenCode uses, includes `mistral` (with the `@ai-sdk/mistral` package), `scaleway`, `ovhcloud`, `stackit`, `berget` and `cortecs`. It has no IONOS entry. Source: https://models.dev/api.json
- Scaleway has its own OpenCode guide: pick the "Scaleway" provider, or set `baseURL` to `https://api.scaleway.ai/{SCW_PROJECT_ID}/v1` (guide checked 2026-10-14). Source: https://github.com/scaleway/docs-content/blob/main/pages/generative-apis/reference-content/integrate-with-opencode.mdx
- IONOS's OpenAI-compatible base URL is `https://openai.inference.de-txl.ionos.com/v1`. Source: https://docs.ionos.com/cloud/ai/ai-model-hub/how-tos/text-generation.md
- Scaleway prices (fr-par): Qwen3.5-397B €0.60 / €3.60 (generally available), GLM-5.3 €1.80 / €5.50 (preview), DeepSeek V4.1 Flash €0.60 / €1.80 (preview), Mistral Medium 3.5 €1.50 / €7.50 (preview), gpt-oss-120b €0.15 / €0.60 (generally available). Source: https://api.scaleway.com/product-catalog/v2alpha1/public-catalog/products?page_size=1000&product_types=generative_apis
- Scaleway replaces coding models fast: Devstral 2 reached end of life on Aug 1, 2026, Qwen3-Coder-30B on Oct 1, 2026, and GLM-5.2 ends on Nov 16, 2026, with its requests sent to GLM-5.3. Source: https://github.com/scaleway/docs-content/blob/main/pages/generative-apis/reference-content/supported-models.mdx
- Mistral says Mistral Medium 3.5 "supersedes all our previous coding models, namely Devstral" and scores 77.6% on SWE-bench Verified. This is a vendor number. Source: https://huggingface.co/mistralai/Mistral-Medium-3.5-128B
- Mistral retired Devstral 2 on 2026-07-31 and names Mistral Medium 3.5 as its replacement. Mistral Large 4 is in public preview. Source: https://docs.mistral.ai/models.md
- Mistral API prices (USD): Mistral Medium 3.5 $1.50 / $7.50, GLM 5.3 $1.40 / $4.40, Mistral Large 4 $1.36 / $4.18, Codestral $0.30 / $0.90. Codestral is a code completion model. Source: https://docs.mistral.ai/inference/pricing.md
- Qwen reports 76.4 on SWE-bench Verified for Qwen3.5-397B-A17B; the same table gives Claude 4.5 Opus 80.9. These are vendor numbers. Source: https://huggingface.co/Qwen/Qwen3.5-397B-A17B
- Z.ai calls GLM-5.3 "the most capable open-weights model for coding" and reports 66.9 on DeepSWE v1.1. This is a vendor number. Source: https://huggingface.co/zai-org/GLM-5.3
- DeepSeek reports 74.2 on DeepSWE v1.1 for DeepSeek-V4.1-Flash at maximum reasoning effort. This is a vendor number. Source: https://huggingface.co/deepseek-ai/DeepSeek-V4.1-Flash
- IONOS sells Qwen3-Coder-Next 80B as its coding model at €0.15 / €0.80, and Qwen3.5-397B-A17B at €0.60 / €3.60 (price list v2026-10-22). Source: https://docs.ionos.com/cloud/support/general-information/price-list/ionos-cloud-eur-en.md
- OVHcloud's catalog has Qwen3.5-397B at 0.60 / 3.60, gpt-oss-120b at 0.08 / 0.40, and Qwen3.6 27B and Qwen3.8 27B at 0.40 / 2.70. It has no Qwen3-Coder, GLM or DeepSeek model. Source: https://catalog.endpoints.ai.ovh.net/rest/v1/models_v2
- STACKIT's shared models are Qwen3-VL 235B, Qwen3.8 27B, Llama 3.3 70B, gpt-oss-120b, Gemma 4 31B and gpt-oss-20b (updated Oct 15, 2026). None is a coding-only model. Source: https://docs.stackit.cloud/products/data-and-ai/ai-model-serving/basics/available-shared-models/
- Berget serves Kimi-K3 at €3 / €15, GLM-5.3-Flash at €0.25 / €0.50 and Qwen3.8-27B-FP8 at €0.40 / €3. Source: https://api.berget.ai/v1/models
- With `eu_native=true`, Cortecs offers GLM-5.3 from seven providers, including Scaleway and Mistral, at €0.459 / €1.836, and DeepSeek V4.1 Flash at €0.18 / €0.539. Some of these providers (Tensorix, Inceptron, AKI, Arkane, Entrim) were not checked for this report. Source: https://api.cortecs.ai/v1/models?eu_native=true
- Cortecs lists 0 days of retention for Scaleway, OVH, Nebius, Ionos, Mistral, Berget and others, and 30 days for Microsoft. The request field `allow_zero_data_retention: true` limits routing to zero-retention endpoints. Source: https://docs.cortecs.ai/security-and-compliance/zero-data-retention-zdr.md

### 3. Claude with EU data residency

| Option | Headquarters | Data centers | Claude Code fit | Price |
| --- | --- | --- | --- | --- |
| Anthropic API or Team plan (today) | Anthropic, PBC; EEA customers sign with Anthropic Ireland, Limited | Inference "global" or "us" only | Today's setup | Team seats; API list price Opus 5.5 $4 / $20, Sonnet 5.5 $2 / $10 |
| Amazon Bedrock, `eu.` profiles | Amazon Web Services, Inc., Seattle; EU customers sign with AWS EMEA SARL, Luxembourg | From Frankfurt: Frankfurt, Stockholm, Milan, Spain, Ireland, Paris | `CLAUDE_CODE_USE_BEDROCK=1`, `eu.` model IDs | Per token through AWS; regional endpoints cost 10% more than global |
| Vertex AI, `eu` multi-region | Google LLC; EMEA customers sign with Google Cloud EMEA Limited | "Europe multi-region" | `CLAUDE_CODE_USE_VERTEX=1`, `CLOUD_ML_REGION=eu` | Per token through Google Cloud; multi-region costs 10% more than global |

- Anthropic's own API offers the `inference_geo` values "global" and "us" only, and the workspace geo "us" only. There is no EU option. Source: https://platform.claude.com/docs/en/manage-claude/data-residency
- For Claude in Microsoft Foundry, the same page names only a US Data Zone deployment for keeping inference in one place. Source: https://platform.claude.com/docs/en/manage-claude/data-residency
- Anthropic's commercial terms put customers in the EEA, Switzerland and the UK under Anthropic Ireland, Limited and Irish law (effective Jun 17, 2025). Source: https://www.anthropic.com/legal/commercial-terms
- Amazon Bedrock offers Claude Opus 5.5 through the EU profile `eu.anthropic.claude-opus-5-5`. From eu-central-1 (Frankfurt) it routes to Frankfurt, Stockholm, Milan, Spain, Ireland and Paris. Single-region use with the plain model ID exists only in eu-west-2 (London). Source: https://docs.aws.amazon.com/bedrock/latest/userguide/model-card-anthropic-claude-opus-5-5.html
- Claude Sonnet 5.5 has the EU profile `eu.anthropic.claude-sonnet-5-5`, with the same EU destinations from Frankfurt and no single-region endpoint. Source: https://docs.aws.amazon.com/bedrock/latest/userguide/model-card-anthropic-claude-sonnet-5-5.html
- With cross-region profiles, prompts and outputs "may be stored in the opt-in Regions for abuse detection purposes". SCPs and IAM policies control which regions Bedrock may use. Source: https://docs.aws.amazon.com/bedrock/latest/userguide/inference-profiles-support.html
- On Bedrock, model providers have no access to the model deployment accounts, so they cannot see Bedrock logs, prompts or completions. Source: https://docs.aws.amazon.com/bedrock/latest/userguide/data-protection.html
- Bedrock lets you set the data retention mode `none` (zero data retention) per region. Source: https://docs.aws.amazon.com/bedrock/latest/userguide/data-retention.html
- Bedrock's abuse detection page lists 30-day retention for Claude Fable 5 and Fable 5.1, and does not list Opus 5.5 or Sonnet 5.5. Source: https://docs.aws.amazon.com/bedrock/latest/userguide/abuse-detection.html
- Claude Code uses Bedrock with `CLAUDE_CODE_USE_BEDROCK=1` and `AWS_REGION`. In `eu-*` regions it picks `eu.` profiles, and `ANTHROPIC_BEDROCK_REGION_PREFIX=eu` turns the `opus` alias into `eu.anthropic.claude-opus-5-5`. Source: https://code.claude.com/docs/en/amazon-bedrock.md
- Claude Code's docs call this prefix "a preference, not a guarantee": when a model has no profile with that prefix, Claude Code may use another matching profile. Pinned model IDs, for example in `ANTHROPIC_DEFAULT_OPUS_MODEL`, are used as written. Source: https://code.claude.com/docs/en/amazon-bedrock.md
- Vertex AI offers `claude-opus-5-5` and `claude-sonnet-5-5` in a "Europe multi-region", a US multi-region and a global endpoint (pages updated 2026-10-28). Source: https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/partner-models/claude/opus-5-5
- The same Vertex pages list the ML processing locations as US multi-region, Europe multi-region and asia-southeast1, without saying which endpoint uses asia-southeast1. Source: https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/partner-models/claude/sonnet-5-5
- Claude Code uses Vertex with `CLAUDE_CODE_USE_VERTEX=1` and `CLOUD_ML_REGION=eu`, which calls `aiplatform.eu.rep.googleapis.com`. Source: https://code.claude.com/docs/en/google-vertex-ai.md
- Claude Code's deployment table bills Teams as a per-seat subscription, Bedrock as pay-as-you-go through AWS and Vertex as pay-as-you-go through Google Cloud. The Team plan signs in through claude.ai, Bedrock with an API key or AWS credentials, and Vertex with Google Cloud credentials. Source: https://code.claude.com/docs/en/third-party-integrations.md
- Anthropic's list prices are $4 / $20 for Claude Opus 5.5 and $2 / $10 for Sonnet 5.5. On Bedrock and Vertex, regional and multi-region endpoints cost 10% more than global ones, and the clouds' own price pages are the official prices. Source: https://platform.claude.com/docs/en/about-claude/pricing
- AWS's contract party for customers in Europe is Amazon Web Services EMEA SARL in Luxembourg; for the US and countries not listed, it is Amazon Web Services, Inc. in Seattle (agreement updated Aug 14, 2026). Source: https://aws.amazon.com/agreement/
- Google's contract party for EMEA customers (except France, Italy and Poland) is Google Cloud EMEA Limited; Google LLC covers the US and places not listed. Source: https://cloud.google.com/terms/google-entity

## Open questions

- Which cloud and region TypeSafe uses. Its sub-processor list needs JavaScript and I could not read it, and its terms do not name the state of incorporation.
- How well the models behind Berget's `/v1/systemone` answer the factory's eight Jev questions. All three are "preview", Cloudflare's own numbers show Jev ahead on several tests, and Laya's base checkpoint is near chance without fine-tuning. A shadow test on real tickets would settle this, and the thresholds in sections 6.2 and 6.6 would need new tuning.
- Which Laya checkpoint Berget serves, and whether it is calibrated.
- Whether Berget's `/v1/systemone` serves `Cloudflare/clef-flash`. The model list marks it as a "system-one" model, but the endpoint description names only Qwen3.5-2B and Laya.
- What Berget's model list means by its "latency" values (8–89 ms for the decision models). No source gives an end-to-end latency for these models or for one-token log-probability calls on IONOS or Mistral.
- Where Sference, Cortecs's provider for Clef 27B, is based. Third-party listings say London, but I found no primary source. Cortecs does not count it as EU-native.
- Whether Mistral's EU host serves the needed models (Ministral 3, Mistral Medium 3.5, GLM 5.3) and returns `logprobs` there. Listing the EU host's models needs an API key.
- Whether Mistral trains on paid API data by default. The DPA allows training unless the customer opts out, and the help center does not state the default. Opting out in the admin panel and asking for ZDR would remove the doubt.
- Whether OVHcloud and STACKIT return `logprobs` even though their docs do not list it. This needs a test call with an account.
- The currency of OVHcloud's catalog prices. The catalog API gives none, and I did not check the OVHcloud price page.
- The text of STACKIT's DPA. I did not find it in the public docs.
- Cortecs's DPA text, and which terms bind its smaller providers (Tensorix, Inceptron, AKI, Arkane, Entrim). I did not read them.
- Whether Claude on Bedrock is available in the AWS European Sovereign Cloud. Bedrock's regional availability page does not mention it.
- Which Vertex endpoint uses the asia-southeast1 processing location listed for Claude Opus 5.5 and Sonnet 5.5.
- Whether Bedrock or Vertex meets the team's sovereignty rule. Data stays in EU regions and the contract is with an EU entity, but the pages checked here do not say whether the US parent companies' laws (such as the US CLOUD Act) reach that data. Scaleway's privacy page makes this claim only for itself. This is a legal question.
