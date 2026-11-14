# frontend（Next.js）

法要予約管理アプリの画面です。画面の設計は [基本設計書](../docs/basic-design.md) の 2章・7章を参照してください。

## 開発サーバーの起動

先に Rails（`backend/`、3001番）を起動しておきます。`/api` へのリクエストは Rails に転送されます（`next.config.ts`）。

```bash
npm install
npm run dev      # http://localhost:3000
```

## チェック

```bash
npm run lint
npx tsc --noEmit
npm run build
```
