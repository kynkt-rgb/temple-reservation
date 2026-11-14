import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // 開発時は /api を Rails（3001番）へ転送する。本番では Nginx が振り分ける（基本設計書 1.1）
  async rewrites() {
    const apiOrigin = process.env.API_ORIGIN ?? "http://localhost:3001";
    return [{ source: "/api/:path*", destination: `${apiOrigin}/api/:path*` }];
  },
  cacheComponents: true,
  partialPrefetching: true,
  turbopack: {
    rules: {
      "*.css": {
        loaders: ["@tailwindcss/turbopack"],
        as: "*.css",
      },
    },
  },
};

export default nextConfig;
