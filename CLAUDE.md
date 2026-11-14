# CLAUDE.md

お寺の職員向けの法要予約管理アプリ。

## 返答

- ユーザーへの返答は日本語で書く。

## 実装の方針

- [docs/requirements.md](docs/requirements.md)（要件定義書）と [docs/basic-design.md](docs/basic-design.md)（基本設計書）に従って実装する。
- 要件・ルールの番号（F-01、R-1 など）は設計書と同じものを使う。
- 設計書と違う実装が必要になったときは、勝手に変えずにユーザーに確認し、合意できたら設計書も合わせて更新する。

## 技術スタック

| 区分 | 技術 |
| --- | --- |
| フロントエンド | Next.js + TypeScript（`frontend/`） |
| バックエンド | Ruby on Rails APIモード（`backend/`） |
| データベース | MySQL |
| インフラ | AWS EC2 + RDS、Terraform（`infra/`） |

## コミット

- 作業の区切りごとにコミットする。
- コミットメッセージは日本語で書く。
