# 法要予約管理アプリ（temple-reservation）

お寺の職員が、檀家さんから電話で受けた法要の予約を管理するWebアプリです。

紙のカレンダーとGoogleカレンダーでの二重管理をやめて予約を1か所にまとめ、予約の重複をシステムで防ぎます。

> **現在の状況：実装中**（API・画面が完成。AWS への構築はこれから）

## 主な機能

- **月カレンダー**：1か月分の予約を1画面で見渡せる（縦に日付、横に時間枠）
- **法要予約の登録・編集・削除**
- **葬儀の押さえ**：葬儀用に時間枠を確保する（詳細管理はしない）
- **施主名での検索**：部分一致で、過去の予約も検索できる

## 予約のルール

時間枠は10時〜15時開始の1時間枠（6枠）です。

| ルール | 内容 |
| --- | --- |
| 法要は1枠1件 | 同じ日・同じ時間枠に入れられる法要は1件まで |
| 葬儀は1日1件 | 葬儀の押さえは1日に1件まで。葬儀がある枠でも法要は1件受けられる |
| 自宅は総代のみ | 法要の場所は基本お寺。総代さんに限り自宅でも行える |

ルールは画面・API・データベースの制約の3段階でチェックし、同時に登録された場合でも重複を防ぎます。

## 技術スタック

| 区分 | 技術 |
| --- | --- |
| フロントエンド | Next.js + TypeScript |
| バックエンド | Ruby on Rails（APIモード） |
| データベース | MySQL |
| インフラ | AWS（EC2 + RDS） |
| 構成管理 | Terraform |

## ドキュメント

- [要件定義書](docs/requirements.md)
- [基本設計書](docs/basic-design.md)

## ディレクトリ構成

```
temple-reservation/
├── docs/        要件定義書・基本設計書
├── frontend/    Next.js
├── backend/     Rails（APIモード）
└── infra/       Terraform（予定）
```

## 開発環境での起動

必要なもの：Ruby 4.0、MySQL 8.4、Node.js（LTS）

```bash
# バックエンド（http://localhost:3001）
cd backend
bundle install
bin/rails db:prepare
bin/rails server

# フロントエンド（http://localhost:3000）。別のターミナルで
cd frontend
npm install
npm run dev
```

ブラウザで http://localhost:3000 を開きます。

## テスト

```bash
cd backend && bundle exec rspec
cd frontend && npm run lint && npx tsc --noEmit
```

## 公開方法についての注意

本リリースではレビューのため、EC2のパブリックIPにHTTPでアクセスする構成にしています。ログイン機能・IP制限・HTTPS化はまだありません。**本物の個人情報は入力せず、ダミーデータで動作確認してください。**

## 今後の予定

- ログイン機能（中級編）
- IP制限またはログイン機能による利用者の限定
- ドメイン取得とHTTPS化
- Googleカレンダー連携
